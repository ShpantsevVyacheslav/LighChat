
"use client";

import {
  createContext,
  useContext,
  useState,
  useEffect,
  useCallback,
  useRef,
} from 'react';
import { useRouter, usePathname } from 'next/navigation';
import {
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  signInWithPopup,
  signInWithRedirect,
  getRedirectResult,
  GoogleAuthProvider,
  OAuthProvider,
  signOut,
  updatePassword as firebaseUpdatePassword,
  fetchSignInMethodsForEmail,
  type UserCredential,
  type User as FirebaseUser,
  type ActionCodeSettings,
  signInWithCustomToken,
} from 'firebase/auth';
import { getFunctions, httpsCallable } from 'firebase/functions';
import {
  doc,
  collection,
  query,
  where,
  getDocs,
  onSnapshot,
  getDoc,
  getDocFromServer,
  setDoc,
  updateDoc,
  deleteField,
  type Firestore,
} from 'firebase/firestore';

import type { User } from '@/lib/types';
import {
  useFirestore,
  useStorage,
  useAuth as useFirebaseAuth,
  useUser as useFirebaseUser,
  useFirebaseApp,
  updateDocumentNonBlocking,
} from '@/firebase';
import { uploadUserAvatarPair } from '@/lib/upload-user-avatar-pair';
import { useToast } from '@/hooks/use-toast';
import { isAccountBlocked } from '@/lib/account-block-utils';
import { scheduleFirestoreListen } from '@/firebase/schedule-firestore-listen';
import {
  isRegistrationEmailTakenInIndex,
  isRegistrationPhoneTaken,
  isRegistrationUsernameTakenInIndex,
} from '@/lib/registration-field-availability';
import { isAnonymousPlaceholderEmail } from '@/lib/registration-index-keys';
import { isRegistrationProfileComplete } from '@/lib/registration-profile-complete';
import { writeDeviceSession } from '@/lib/device-session';
import { applyPhoneMask, normalizePhoneDigits } from '@/lib/phone-utils';
import { requestVerifiedEmailChange } from '@/lib/auth-email-change';
import { logger } from '@/lib/logger';

import {
  isNormalizedUsernameTokenAllowed,
  normalizeUsernameCandidate,
} from '@/lib/username-candidate';

async function generateUniqueUsernameForUid(opts: {
  firestore: Firestore;
  uid: string;
  displayName: string;
}): Promise<string> {
  const seedFromUid = String(opts.uid).replace(/[^a-zA-Z0-9]/gu, '').slice(-8);
  const fromName = normalizeUsernameCandidate(opts.displayName);
  const base =
    fromName.length >= 3 && isNormalizedUsernameTokenAllowed(fromName)
      ? fromName
      : `user_${seedFromUid || 'new'}`;

  for (let i = 0; i < 20; i++) {
    const candidate = i === 0 ? base : `${base}_${i + 1}`;
    const normalized = normalizeUsernameCandidate(candidate);
    if (normalized.length < 3) continue;
    if (!isNormalizedUsernameTokenAllowed(normalized)) continue;
    const taken = await isRegistrationUsernameTakenInIndex(
      opts.firestore,
      normalized,
      { exceptUid: opts.uid },
    );
    if (!taken) return normalized;
  }

  return `user_${seedFromUid || 'new'}_${Date.now()
    .toString(36)
    .slice(-4)}`.slice(0, 30);
}

function fallbackEmailForUid(uid: string): string {
  const local = String(uid)
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9_]/gu, '_')
    .slice(0, 48);
  return `${local || 'user'}@oauth.local`;
}

const DICEBEAR_AVATAR_HOST = 'api.dicebear.com';

function isDicebearPlaceholderAvatar(avatar: string | undefined): boolean {
  const u = String(avatar ?? '').trim().toLowerCase();
  if (!u) return true;
  try {
    return new URL(u).hostname === DICEBEAR_AVATAR_HOST;
  } catch {
    return false;
  }
}

function formatFirestorePhoneFromAuthPhone(raw: string): string {
  const d = normalizePhoneDigits(String(raw ?? ''));
  if (d.length < 10) return '';
  if (d.length === 11 && d.startsWith('7')) {
    return applyPhoneMask(`+${d}`);
  }
  return `+${d.slice(0, 32)}`;
}

function redactForAuthDebug(value: unknown): unknown {
  if (value == null) return value;
  if (typeof value === 'string') {
    const s = value.trim();
    if (!s) return s;
    if (s.includes('@')) return '<redacted-email>';
    if (s.startsWith('ya29.') || s.length > 120) return '<redacted>';
    return s;
  }
  if (Array.isArray(value)) return value.map(redactForAuthDebug);
  if (typeof value === 'object') {
    const o = value as Record<string, unknown>;
    const out: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(o)) {
      if (/token|secret|hash/i.test(k)) out[k] = '<redacted>';
      else if (/phone/i.test(k)) out[k] = '<redacted-phone>';
      else if (/email/i.test(k)) out[k] = '<redacted-email>';
      else out[k] = redactForAuthDebug(v);
    }
    return out;
  }
  return value;
}

function authDebugEnabled(): boolean {
  return process.env.NEXT_PUBLIC_AUTH_DEBUG === '1';
}

export interface RegisterData {
  name: string;
  username: string;
  phone: string;
  email: string;
  password: string;
  dateOfBirth?: string;
  bio?: string;
  /** Исходный кадр (после обрезки — полноразмерный файл для Storage). */
  avatarFile?: File;
  /** Круг 512×512 из overlay; если нет при `avatarFile`, превью в UI = полный кадр. */
  avatarThumbFile?: File;
}

/** Дозаполнение профиля после входа через Google или Apple (без пароля). */
export interface CompleteGoogleProfileData {
  name: string;
  username: string;
  phone: string;
  email: string;
  dateOfBirth?: string;
  bio?: string;
  avatarFile?: File;
  avatarThumbFile?: File;
}

/** Поле формы регистрации с серверной/бизнес-ошибкой (дубликат и т.д.) */
export type RegisterConflictField = 'email' | 'username' | 'phone' | 'password';

export type RegisterResult =
  | { ok: true }
  | { ok: false; message: string; conflictField?: RegisterConflictField };

export type UpdateUserResult =
  | { ok: true; emailVerificationSent?: boolean }
  | { ok: false; message: string };

const OAUTH_FIRESTORE_AUTH_RETRIES = 8;

/** Провайдеры с тем же сценарием: popup → Firestore, дозаполнение профиля без пароля. */
const OAUTH_SOCIAL_PROVIDER_IDS = ['google.com', 'apple.com'] as const;

function hasOauthSocialProvider(user: FirebaseUser): boolean {
  return user.providerData.some((p) =>
    (OAUTH_SOCIAL_PROVIDER_IDS as readonly string[]).includes(p.providerId)
  );
}

/** Аккаунты с UID `tg_<telegramId>` создаются только callable `signInWithTelegram`. */
function isTelegramFirebaseUid(uid: string): boolean {
  return /^tg_\d+$/.test(uid);
}

/** Аккаунты с UID `ya_<yandex_numeric_id>` — OAuth Яндекс + custom token на сервере Next.js. */
function isYandexFirebaseUid(uid: string): boolean {
  return /^ya_\d+$/.test(uid);
}

/** Форма дозаполнения без пароля: Google, Apple, Telegram или Яндекс (custom token). */
function hasPasswordlessProfileCompletion(user: FirebaseUser): boolean {
  return (
    hasOauthSocialProvider(user) ||
    isTelegramFirebaseUid(user.uid) ||
    isYandexFirebaseUid(user.uid)
  );
}

async function isTelegramProfileUser(u: FirebaseUser): Promise<boolean> {
  if (isTelegramFirebaseUid(u.uid)) return true;
  try {
    const t = await u.getIdTokenResult();
    return t.claims.telegram === true;
  } catch {
    return false;
  }
}

function isYandexProfileUid(u: FirebaseUser): boolean {
  return isYandexFirebaseUid(u.uid);
}

/**
 * После `signInWithPopup` (Google / Apple) persistent Firestore иногда ходит в бэкенд без свежего JWT —
 * `permission-denied`. Повторы с reload + getIdToken(true) и чередование server/client read.
 */
async function firestoreAfterOAuthSignIn<T>(
  credUser: FirebaseUser,
  op: (attemptIndex: number) => Promise<T>
): Promise<T> {
  let lastErr: unknown;
  for (let i = 0; i < OAUTH_FIRESTORE_AUTH_RETRIES; i++) {
    try {
      await credUser.reload().catch(() => undefined);
      await credUser.getIdToken(true);
      return await op(i);
    } catch (e) {
      lastErr = e;
      const c = (e as { code?: string }).code;
      if (c !== 'permission-denied' || i === OAUTH_FIRESTORE_AUTH_RETRIES - 1) throw e;
      await new Promise((r) => setTimeout(r, 50 + i * 100));
    }
  }
  throw lastErr;
}

interface AuthContextType {
  user: User | null;
  /** Аккаунт с Google, Apple, Яндекс или Telegram — форма дозаполнения без пароля. */
  googleProfileCompletionFlow: boolean;
  login: (email: string, password: string) => Promise<boolean>;
  register: (data: RegisterData) => Promise<RegisterResult>;
  completeGoogleProfile: (data: CompleteGoogleProfileData) => Promise<RegisterResult>;
  checkUsernameAvailable: (username: string) => Promise<boolean>;
  signInWithGoogle: () => Promise<boolean>;
  signInWithApple: () => Promise<boolean>;
  /** Редирект на `/api/auth/yandex` (OAuth Яндекс → custom token). */
  signInWithYandex: () => Promise<boolean>;
  /** Payload от Telegram Login Widget (поля + hash), см. Cloud Function `signInWithTelegram`. */
  signInWithTelegramPayload: (auth: Record<string, unknown>) => Promise<boolean>;
  logout: () => void;
  updateUser: (newUserData: Partial<User & { password?: string }>) => Promise<UpdateUserResult>;
  resendPendingEmailVerification: () => Promise<{ ok: true } | { ok: false; message: string }>;
  createNewAuthUser: (email: string, password: string) => Promise<UserCredential>;
  isAuthenticated: boolean;
  /**
   * Гость видеоконференции (Firebase Anonymous Auth, без профиля в Firestore).
   * Имеет `user` и `firebaseUser`, но НЕ должен попадать в дашборд / редактировать
   * профиль; `isAuthenticated` для гостя false (см. `contextValue` ниже).
   */
  isGuest: boolean;
  isLoading: boolean;
  isUpdatingUser: boolean;
  error: string | null;
  clearError: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

const INACTIVITY_LIMIT = 60000; // 1 minute in milliseconds
/**
 * Минимум между записями online/lastSeen в Firestore при уже активном пользователе.
 * [audit M-003] Растянуто 45s → 120s: на 1k DAU это ~$70/мес экономии Firestore writes.
 * Серверный `checkUserPresence` теперь использует threshold 180s (см.
 * `functions/src/triggers/scheduler/checkUserPresence.ts`) — buffer 60s
 * на network jitter / clock skew, чтобы активный пользователь не был
 * помечен offline между heartbeat'ами.
 */
const PRESENCE_MIN_WRITE_INTERVAL_MS = 120_000;

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({
  children,
}) => {
  const { user: firebaseUser, isUserLoading: isAuthLoading } = useFirebaseUser();
  const firebaseApp = useFirebaseApp();
  const firestore = useFirestore();
  const storage = useStorage();
  const auth = useFirebaseAuth();
  const router = useRouter();
  const pathname = usePathname();
  const { toast } = useToast();

  const [appUser, setAppUser] = useState<User | null>(null);
  const [isProfileLoading, setIsProfileLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isUpdatingUser, setIsUpdatingUser] = useState(false);

  /** Актуальный профиль для колбэков Firestore (useState отстаёт на один кадр — иначе onSnapshot с кэшем затирает свежий getDoc). */
  const appUserRef = useRef<User | null>(null);

  const googleProfileCompletionFlow =
    !!firebaseUser &&
    !firebaseUser.isAnonymous &&
    hasPasswordlessProfileCompletion(firebaseUser);

  useEffect(() => {
    appUserRef.current = appUser;
  }, [appUser]);

  const lastReportedStatusRef = useRef<boolean | null>(null);
  const lastPresenceUpdateRef = useRef<number>(0);
  const lastActivityRef = useRef<number>(Date.now());

  const logout = useCallback(async () => {
    const logoutUid = auth.currentUser?.uid ?? appUser?.id ?? null;
    if (appUser && firestore && auth.currentUser) {
        const userDocRef = doc(firestore, 'users', appUser.id);
        try {
            await updateDoc(userDocRef, { 
              online: false, 
              lastSeen: new Date().toISOString() 
            });
        } catch (e) {
            logger.warn('auth', 'Presence update failed during logout', e);
        }
    }
    if (logoutUid && firestore) {
      try {
        await writeDeviceSession({
          firestore,
          uid: logoutUid,
          active: false,
        });
      } catch (e) {
        logger.warn('auth', 'Device session update failed during logout', e);
      }
    }
    
    // E2EE: перед тем как unload auth-состояние, сносим кэш расшифрованного
    // содержимого (текст + media), чтобы следующий пользователь на этом же
    // устройстве/браузере не получил доступ к plaintext предыдущего.
    try {
      const { clearAllE2eeCache } = await import('@/lib/e2ee');
      await clearAllE2eeCache();
    } catch (e) {
      logger.warn('auth', 'clearAllE2eeCache failed on logout', e);
    }

    try {
        await signOut(auth);
        router.push('/auth');
    } catch (e) {
        logger.error('auth', 'Logout error', e);
        setError('Произошла ошибка при выходе.');
    }
  }, [auth, router, appUser, firestore]);

  /**
   * После OAuth / custom token (Google, Apple, Telegram, Яндекс): гарантировать `users/{uid}`,
   * подтянуть телефон/аватар из Firebase Auth, если провайдер их отдал и нет конфликта в `registrationIndex`.
   * Дефолтный документ от `onUserCreated` может появиться раньше клиента — тогда дозаполняем username/email и т.д.
   */
  const finalizeOAuthCredential = useCallback(
    async (result: UserCredential): Promise<boolean> => {
      if (!firestore) {
        logger.error('auth', 'OAuth sign-in: Firestore недоступен.');
        setError('Сервис данных недоступен. Обновите страницу и попробуйте снова.');
        return false;
      }

      if (authDebugEnabled()) {
        try {
          const u = result.user;
          logger.debug('auth', 'oauth credential', {
            uid: u.uid,
            providerIds: u.providerData.map((p) => p.providerId),
            email: redactForAuthDebug(u.email),
            phoneNumber: redactForAuthDebug(u.phoneNumber),
            displayName: redactForAuthDebug(u.displayName),
            photoURL: redactForAuthDebug(u.photoURL),
            providerData: redactForAuthDebug(
              u.providerData.map((p) => ({
                providerId: p.providerId,
                uid: p.uid,
                displayName: p.displayName,
                email: p.email,
                phoneNumber: p.phoneNumber,
                photoURL: p.photoURL,
              })),
            ),
          });
        } catch (e) {
          logger.warn('auth', 'failed to log oauth credential', e);
        }
      }

      const userDocRef = doc(firestore, 'users', result.user.uid);
      const userDoc = await firestoreAfterOAuthSignIn(result.user, (attempt) =>
        attempt % 2 === 0 ? getDocFromServer(userDocRef) : getDoc(userDocRef)
      );

      if (userDoc.exists()) {
        const data = userDoc.data() as Record<string, unknown>;
        if (data.deletedAt) {
          await signOut(auth);
          setError('Ваша учетная запись деактивирована.');
          return false;
        }

        const patch: Record<string, unknown> = {};
        const displayName = result.user.displayName || 'Пользователь';

        const usernameNow = String(data.username ?? '').trim();
        if (!usernameNow) {
          patch.username = await generateUniqueUsernameForUid({
            firestore,
            uid: result.user.uid,
            displayName,
          });
        }

        const nameNow = String(data.name ?? '').trim();
        if (
          !nameNow ||
          nameNow === 'Новый пользователь' ||
          nameNow === 'Telegram' ||
          nameNow === 'Yandex'
        ) {
          patch.name = displayName;
        }

        const emailNow = String(data.email ?? '').trim().toLowerCase();
        const nextEmail = (result.user.email || fallbackEmailForUid(result.user.uid))
          .trim()
          .toLowerCase();
        if (!emailNow || isAnonymousPlaceholderEmail(emailNow)) {
          patch.email = nextEmail;
        }

        if (data.role == null && data.deletedAt == null) {
          patch.role = 'worker';
        }

        const phoneRaw = result.user.phoneNumber || '';
        const phoneFormatted = phoneRaw ? formatFirestorePhoneFromAuthPhone(phoneRaw) : '';
        const phoneNow = String(data.phone ?? '').trim();
        if (!phoneNow && phoneFormatted) {
          try {
            const taken = await isRegistrationPhoneTaken(firestore, phoneFormatted, {
              exceptUid: result.user.uid,
            });
            if (!taken) patch.phone = phoneFormatted;
            else
              logger.debug(
                'auth',
                'OAuth enrich: phone from provider skipped (registrationIndex)',
                result.user.uid,
              );
          } catch (e) {
            logger.warn('auth', 'OAuth enrich: phone availability check failed', e);
          }
        }

        const avatarNow = String(data.avatar ?? '').trim();
        const photo = String(result.user.photoURL ?? '').trim();
        if (photo && (!avatarNow || isDicebearPlaceholderAvatar(avatarNow))) {
          patch.avatar = photo;
        }

        if (Object.keys(patch).length > 0) {
          try {
            await firestoreAfterOAuthSignIn(result.user, () => updateDoc(userDocRef, patch));
          } catch (writeErr) {
            logger.error('auth', 'OAuth sign-in: не удалось обновить документ users/', writeErr);
          }
        }

        return true;
      }

      try {
        const displayName = result.user.displayName || 'Пользователь';
        const username = await generateUniqueUsernameForUid({
          firestore,
          uid: result.user.uid,
          displayName,
        });
        const email = (result.user.email || fallbackEmailForUid(result.user.uid))
          .trim()
          .toLowerCase();

        let phoneOut = '';
        const phoneRaw = result.user.phoneNumber || '';
        const phoneFormatted = phoneRaw ? formatFirestorePhoneFromAuthPhone(phoneRaw) : '';
        if (phoneFormatted) {
          try {
            const taken = await isRegistrationPhoneTaken(firestore, phoneFormatted, {
              exceptUid: result.user.uid,
            });
            if (!taken) phoneOut = phoneFormatted;
          } catch (e) {
            logger.warn('auth', 'OAuth create: phone availability check failed', e);
          }
        }

        await firestoreAfterOAuthSignIn(result.user, () =>
          setDoc(userDocRef, {
            id: result.user.uid,
            name: displayName,
            username,
            phone: phoneOut,
            email,
            avatar:
              result.user.photoURL ||
              `https://api.dicebear.com/7.x/avataaars/svg?seed=${result.user.uid}`,
            role: 'worker',
            bio: '',
            dateOfBirth: null,
            createdAt: new Date().toISOString(),
            deletedAt: null,
            online: true,
            lastSeen: new Date().toISOString(),
          })
        );
      } catch (writeErr) {
        logger.error('auth', 'OAuth sign-in: не удалось создать документ users/', writeErr);
        /* Сессия Auth уже есть — слушатель профиля подставит заглушку; не блокируем вход. */
      }
      return true;
    },
    [auth, firestore, setError]
  );

  /**
   * После signInWithRedirect (Google / Apple): обработать результат один раз.
   * Не прерывать finalizeOAuthCredential флагом cancelled — в React Strict Mode эффект
   * размонтируется после первого await, иначе профиль в Firestore не создаётся / сессия «ломается».
   */
  useEffect(() => {
    if (typeof window === 'undefined' || !auth || !firestore) return;
    let cancelled = false;
    (async () => {
      try {
        const result = await getRedirectResult(auth);
        if (!result?.user) return;
        const ok = await finalizeOAuthCredential(result);
        if (ok && pathname === '/auth' && firestore) {
          const uref = doc(firestore, 'users', result.user.uid);
          const snap = await getDoc(uref);
          const prof = snap.exists()
            ? ({ id: snap.id, ...snap.data() } as User)
            : null;
          if (prof && isRegistrationProfileComplete(prof)) {
            router.replace('/dashboard');
          }
        }
      } catch (e: unknown) {
        if (cancelled) return;
        const err = e as { code?: string };
        logger.error('auth', 'OAuth redirect sign-in error', e);
        const msg = (
          {
            'auth/account-exists-with-different-credential':
              'Аккаунт с этим email уже использует другой метод входа.',
            'auth/network-request-failed': 'Ошибка сети. Проверьте подключение.',
            'auth/too-many-requests': 'Слишком много попыток. Подождите.',
          } as Record<string, string>
        )[err.code ?? ''];
        if (msg) setError(msg);
        else if (err.code !== 'auth/popup-closed-by-user')
          setError('Ошибка при входе через Google или Apple.');
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [auth, firestore, pathname, router, finalizeOAuthCredential]);

  useEffect(() => {
    if (isAuthLoading) return;
    
    if (!firebaseUser) {
      appUserRef.current = null;
      setAppUser(null);
      setIsProfileLoading(false);
      return;
    }

    /**
     * Нельзя делать «if (uid === lastUid) return» без сброса ref в cleanup: после React Strict Mode
     * или отмены scheduleFirestoreListen подписка не вешается снова, а isProfileLoading остаётся true —
     * вечный лоадер на дашборде / PWA.
     */
    if (firebaseUser.isAnonymous) {
        const guest = {
            id: firebaseUser.uid,
            name: firebaseUser.displayName || 'Гость',
            avatar: firebaseUser.photoURL || `https://api.dicebear.com/7.x/avataaars/svg?seed=${firebaseUser.uid}`,
            email: firebaseUser.email || `guest_${firebaseUser.uid}@anonymous.com`,
            deletedAt: null,
            createdAt: new Date().toISOString()
        } as User;
        appUserRef.current = guest;
        setAppUser(guest);
        setIsProfileLoading(false);
        return;
    }

    setIsProfileLoading(true);
    const userDocRef = doc(firestore, 'users', firebaseUser.uid);
    
    return scheduleFirestoreListen(() =>
      onSnapshot(
        userDocRef,
        (docSnap) => {
          if (docSnap.exists()) {
            const userData = docSnap.data();
            if (userData.deletedAt) {
              appUserRef.current = null;
              setAppUser(null);
              signOut(auth);
              setError('Ваша учетная запись деактивирована.');
            } else if (isAccountBlocked(userData as Pick<User, 'accountBlock'>)) {
              appUserRef.current = null;
              setAppUser(null);
              signOut(auth);
              setError('Вход для этой учётной записи ограничен администратором.');
            } else {
              const merged = {
                ...userData,
                id: docSnap.id,
              } as User;
              const snapshotFromCache = docSnap.metadata.fromCache;
              /**
               * После register / completeGoogleProfile делаем getDoc с сервера и setAppUser.
               * Следующий onSnapshot часто приходит из локального кэша со старым документом (без username/phone)
               * и откатывает профиль — дашборд снова шлёт на анкету. Не применяем такой откат с кэша.
               */
              const skipStaleIncompleteFromCache = (): boolean => {
                if (!snapshotFromCache) return false;
                const prev = appUserRef.current;
                if (
                  prev &&
                  isRegistrationProfileComplete(prev) &&
                  !isRegistrationProfileComplete(merged)
                ) {
                  logger.debug(
                    'auth',
                    `skip stale cached users/${docSnap.id} snapshot (keep complete profile)`,
                  );
                  setIsProfileLoading(false);
                  return true;
                }
                return false;
              };

              const commitMerged = () => {
                if (skipStaleIncompleteFromCache()) return;
                appUserRef.current = merged;
                setAppUser(merged);
                setError(null);
              };

              /**
               * Safari/WebKit: первый снимок из кэша после входа через Google/Apple может быть старым
               * (пустой username) — на мгновение открывается анкета. Подтверждаем сервером перед применением.
               */
              if (
                snapshotFromCache &&
                !isRegistrationProfileComplete(merged) &&
                hasPasswordlessProfileCompletion(firebaseUser)
              ) {
                void (async () => {
                  try {
                    const serverSnap = await getDocFromServer(userDocRef);
                    if (serverSnap.exists()) {
                      const serverMerged = {
                        ...serverSnap.data(),
                        id: serverSnap.id,
                      } as User;
                      if (isRegistrationProfileComplete(serverMerged)) {
                        appUserRef.current = serverMerged;
                        setAppUser(serverMerged);
                        setError(null);
                        setIsProfileLoading(false);
                        return;
                      }
                    }
                    commitMerged();
                  } catch (e) {
                    logger.warn(
                      'auth',
                      'getDocFromServer after incomplete cached passwordless profile',
                      e,
                    );
                    commitMerged();
                  }
                  setIsProfileLoading(false);
                })();
                return;
              }

              commitMerged();
            }
          } else {
            const stub = {
              id: firebaseUser.uid,
              name: firebaseUser.displayName || 'Пользователь',
              avatar: firebaseUser.photoURL || `https://api.dicebear.com/7.x/avataaars/svg?seed=${firebaseUser.uid}`,
              email: firebaseUser.email || '',
              createdAt: new Date().toISOString(),
              deletedAt: null,
            } as User;
            appUserRef.current = stub;
            setAppUser(stub);
          }
          setIsProfileLoading(false);
        },
        (e) => {
          logger.warn('auth', 'Profile sync warning', e.message);
          /* Сессия Firebase есть, а снимок профиля недоступен (сеть/правила) — не сбрасывать вход. */
          const fallback = {
            id: firebaseUser.uid,
            name: firebaseUser.displayName || 'Пользователь',
            avatar:
              firebaseUser.photoURL ||
              `https://api.dicebear.com/7.x/avataaars/svg?seed=${firebaseUser.uid}`,
            email: firebaseUser.email || '',
            createdAt: new Date().toISOString(),
            deletedAt: null,
          } as User;
          appUserRef.current = fallback;
          setAppUser(fallback);
          setIsProfileLoading(false);
        }
      )
    );
  }, [firebaseUser, isAuthLoading, firestore, auth]);

  /**
   * После перехода по ссылке из `verifyBeforeUpdateEmail` email в Firebase Auth уже новый,
   * а в `users/{uid}` в Firestore может остаться старый — подтягиваем, чтобы профиль и registrationIndex сошлись.
   */
  useEffect(() => {
    if (!firebaseUser?.email || firebaseUser.isAnonymous || !firestore || !appUser?.id) return;
    if (appUser.id !== firebaseUser.uid) return;
    const authEmail = firebaseUser.email.trim();
    const docEmail = (appUser.email ?? '').trim();
    if (!authEmail || authEmail.toLowerCase() === docEmail.toLowerCase()) return;
    const userDocRef = doc(firestore, 'users', appUser.id);
    updateDocumentNonBlocking(userDocRef, {
      email: authEmail,
      pendingEmail: deleteField(),
      pendingEmailRequestedAt: deleteField(),
      updatedAt: new Date().toISOString(),
    });
  }, [
    firebaseUser?.uid,
    firebaseUser?.email,
    firebaseUser?.isAnonymous,
    appUser?.id,
    appUser?.email,
    firestore,
  ]);

  // Presence logic: Strict handling of online/offline status with inactivity timeout
  useEffect(() => {
    if (!firebaseUser || !firestore) return;
    /**
     * Гость (Anonymous Auth) и пользователи без полного профиля в Firestore
     * не должны писать presence: правила `firestore.rules:416` режут
     * `!isAnonymousGuest()`, а на не-существующем `users/{uid}` функция
     * `userSensitiveKeysChanged` падает на `resource.data` → permission-denied
     * → FirebaseErrorListener роняет весь UI в `Критическую ошибку`.
     */
    if (firebaseUser.isAnonymous) return;
    if (!appUser?.id || appUser.id !== firebaseUser.uid) return;

    const userDocRef = doc(firestore, `users/${firebaseUser.uid}`);
    
    const isActuallyActive = () => {
        const now = Date.now();
        const isIdle = now - lastActivityRef.current > INACTIVITY_LIMIT;
        return document.visibilityState === 'visible' && document.hasFocus() && !isIdle;
    };

    const updatePresence = (isOnline: boolean) => {
      if (isOnline && !isActuallyActive()) {
        return;
      }

      const now = Date.now();

      if (!isOnline) {
        if (lastReportedStatusRef.current === true) {
          lastReportedStatusRef.current = false;
          lastPresenceUpdateRef.current = now;
          updateDocumentNonBlocking(userDocRef, {
            online: false,
            lastSeen: new Date().toISOString(),
          });
        }
        return;
      }

      const becomingOnline = lastReportedStatusRef.current !== true;
      const heartbeatDue = now - lastPresenceUpdateRef.current >= PRESENCE_MIN_WRITE_INTERVAL_MS;
      if (becomingOnline || heartbeatDue) {
        lastReportedStatusRef.current = true;
        lastPresenceUpdateRef.current = now;
        updateDocumentNonBlocking(userDocRef, {
          online: true,
          lastSeen: new Date().toISOString(),
        });
      }
    };

    const handleVisibilityChange = () => {
      if (document.visibilityState === 'visible') {
        if (document.hasFocus()) {
          lastActivityRef.current = Date.now();
          updatePresence(true);
        }
      } else {
        updatePresence(false);
      }
    };

    const handleFocus = () => {
      lastActivityRef.current = Date.now();
      updatePresence(true);
    };

    const handleActivity = () => {
      lastActivityRef.current = Date.now();
      if (lastReportedStatusRef.current === false && isActuallyActive()) {
        updatePresence(true);
      }
    };

    if (isActuallyActive()) {
      updatePresence(true);
    } else {
      updatePresence(false);
    }

    const handlePageHide = () => updatePresence(false);

    window.addEventListener('visibilitychange', handleVisibilityChange);
    window.addEventListener('focus', handleFocus);
    window.addEventListener('pagehide', handlePageHide);
    
    window.addEventListener('mousedown', handleActivity);
    window.addEventListener('mousemove', handleActivity);
    window.addEventListener('keydown', handleActivity);
    window.addEventListener('scroll', handleActivity);
    window.addEventListener('touchstart', handleActivity);

    const presenceInterval = setInterval(() => {
      const active = isActuallyActive();
      if (active) {
        updatePresence(true);
      } else if (lastReportedStatusRef.current === true) {
        updatePresence(false);
      }
    }, 15000);

    return () => {
      clearInterval(presenceInterval);
      window.removeEventListener('visibilitychange', handleVisibilityChange);
      window.removeEventListener('focus', handleFocus);
      window.removeEventListener('pagehide', handlePageHide);
      window.removeEventListener('mousedown', handleActivity);
      window.removeEventListener('mousemove', handleActivity);
      window.removeEventListener('keydown', handleActivity);
      window.removeEventListener('scroll', handleActivity);
      window.removeEventListener('touchstart', handleActivity);
    };
  }, [firebaseUser, firestore, appUser?.id]);

  // Device session registry: keeps per-device activity to mitigate multi-device auth desync.
  useEffect(() => {
    if (!firebaseUser || !firestore) return;
    /**
     * Та же логика, что и в presence-блоке выше: гость и пользователи без
     * устоявшегося `appUser` не должны писать `users/{uid}/devices/{...}` —
     * после QR-handover или signInWithCustomToken Firestore-SDK секунду
     * держит старый ID-token в своих gRPC-каналах, и первый write идёт под
     * чужим uid → permission-denied. См. `use-auth.tsx:926`.
     */
    if (firebaseUser.isAnonymous) return;
    if (!appUser?.id || appUser.id !== firebaseUser.uid) return;
    const uid = firebaseUser.uid;

    let disposed = false;
    const safeWrite = async (active: boolean, markLogin = false) => {
      if (disposed) return;
      try {
        // forceRefresh:true гарантирует, что Firestore-SDK получит свежий
        // ID-token прежде чем мы вызовем setDoc. Без force-refresh старый
        // токен из кэша мог проигнорировать промежуточный signInWithCustomToken.
        await firebaseUser.getIdToken(true).catch(() => {});
        await writeDeviceSession({
          firestore,
          uid,
          active,
          markLogin,
        });
      } catch (e) {
        // Permission-denied на этом пути не критичен — прод-фикс из
        // 380f3e9 уже не роняет UI «Критической ошибкой» благодаря фильтру
        // в `non-blocking-updates.tsx`. Здесь setDoc вызывается напрямую,
        // поэтому глушим явно.
        logger.warn('auth', 'Device session write failed', e);
      }
    };

    void safeWrite(true, true);

    const heartbeat = window.setInterval(() => {
      if (document.visibilityState === 'visible') {
        void safeWrite(true, false);
      }
    }, 60000);

    const onVisibility = () => {
      if (document.visibilityState === 'visible') {
        void safeWrite(true, false);
      } else {
        void safeWrite(false, false);
      }
    };
    const onPageHide = () => void safeWrite(false, false);
    window.addEventListener('visibilitychange', onVisibility);
    window.addEventListener('pagehide', onPageHide);

    return () => {
      window.clearInterval(heartbeat);
      window.removeEventListener('visibilitychange', onVisibility);
      window.removeEventListener('pagehide', onPageHide);
      void safeWrite(false, false);
      disposed = true;
    };
  }, [firebaseUser, firestore, appUser?.id]);

  const login = useCallback(
    async (email: string, password: string): Promise<boolean> => {
      setError(null);
      try {
        const userCredential = await signInWithEmailAndPassword(auth, email, password);
        const userDocRef = doc(firestore, 'users', userCredential.user.uid);
        const userDoc = await getDoc(userDocRef);
        
        if (userDoc.exists() && userDoc.data().deletedAt) {
            await signOut(auth);
            setError('Ваша учетная запись деактивирована.');
            return false;
        }
        return true;
      } catch (e: any) {
        logger.error('auth', 'Login error', e);
        const msg = ({
          'auth/user-not-found': 'Пользователь с таким email не найден.',
          'auth/wrong-password': 'Неверный пароль.',
          'auth/invalid-credential': 'Неверный email или пароль.',
          'auth/invalid-email': 'Некорректный формат email.',
          'auth/user-disabled': 'Эта учётная запись заблокирована.',
          'auth/too-many-requests': 'Слишком много попыток. Подождите и попробуйте снова.',
          'auth/network-request-failed': 'Ошибка сети. Проверьте подключение.',
        } as Record<string, string>)[e.code];
        setError(msg || 'Произошла ошибка при входе. Попробуйте ещё раз.');
        return false;
      }
    },
    [auth, firestore]
  );

  const checkUsernameAvailable = useCallback(
    async (username: string): Promise<boolean> => {
      const normalizedUsername = username.toLowerCase().replace(/^@/, '');
      const usersRef = collection(firestore, 'users');
      const q = query(usersRef, where('username', '==', normalizedUsername));
      const snapshot = await getDocs(q);
      return snapshot.empty;
    },
    [firestore]
  );

  const register = useCallback(
    async (data: RegisterData): Promise<RegisterResult> => {
      setError(null);
      if (!firestore) {
        const message = 'Сервис временно недоступен.';
        setError(message);
        return { ok: false, message };
      }

      const normalizedUsername = data.username.toLowerCase().replace(/^@/, '');
      const emailNorm = data.email.trim().toLowerCase();

      try {
        try {
          const methods = await fetchSignInMethodsForEmail(auth, emailNorm);
          if (methods.length > 0) {
            return {
              ok: false,
              message:
                'Этот email уже зарегистрирован. Войдите или укажите другой адрес.',
              conflictField: 'email',
            };
          }
        } catch (preAuthErr: unknown) {
          const err = preAuthErr as { code?: string };
          logger.error('auth', 'Registration: fetchSignInMethodsForEmail', preAuthErr);
          const message =
            err.code === 'auth/network-request-failed'
              ? 'Не удалось проверить email (ошибка сети). Проверьте подключение.'
              : 'Не удалось проверить email. Попробуйте ещё раз.';
          setError(message);
          return { ok: false, message };
        }

        try {
          if (await isRegistrationEmailTakenInIndex(firestore, emailNorm)) {
            return {
              ok: false,
              message: 'Этот email уже занят. Укажите другой адрес.',
              conflictField: 'email',
            };
          }
          if (await isRegistrationPhoneTaken(firestore, data.phone)) {
            return {
              ok: false,
              message:
                'Этот номер телефона уже зарегистрирован. Укажите другой номер.',
              conflictField: 'phone',
            };
          }
          if (await isRegistrationUsernameTakenInIndex(firestore, normalizedUsername)) {
            return {
              ok: false,
              message: 'Этот логин уже занят. Выберите другой.',
              conflictField: 'username',
            };
          }
        } catch (idxErr) {
          logger.error('auth', 'Registration: проверка registrationIndex не удалась', idxErr);
          const message =
            'Не удалось проверить, свободны ли email, телефон и логин. Проверьте сеть и попробуйте снова.';
          setError(message);
          return { ok: false, message };
        }

        const userCredential = await createUserWithEmailAndPassword(
          auth,
          emailNorm,
          data.password
        );

        let avatarUrl = `https://api.dicebear.com/7.x/avataaars/svg?seed=${userCredential.user.uid}`;

        const avatarExtras: Record<string, string> = {};
        if (data.avatarFile && storage) {
          try {
            const { avatarUrl: uploadedUrl, avatarThumbUrl } =
              await uploadUserAvatarPair(
                storage,
                userCredential.user.uid,
                data.avatarFile,
                data.avatarThumbFile,
              );
            avatarUrl = uploadedUrl;
            if (avatarThumbUrl) avatarExtras.avatarThumb = avatarThumbUrl;
          } catch (uploadErr) {
            logger.warn('auth', 'Avatar upload failed, using default', uploadErr);
          }
        }

        const userDocRef = doc(firestore, 'users', userCredential.user.uid);
        await setDoc(userDocRef, {
          id: userCredential.user.uid,
          name: data.name,
          username: normalizedUsername,
          phone: data.phone,
          email: emailNorm,
          avatar: avatarUrl,
          ...avatarExtras,
          role: 'worker',
          bio: data.bio || '',
          dateOfBirth: data.dateOfBirth || null,
          createdAt: new Date().toISOString(),
          deletedAt: null,
          online: true,
          lastSeen: new Date().toISOString(),
        });
        /** Сразу обновляем контекст — иначе router на /dashboard ловит старый appUser и layout шлёт обратно на /. */
        const regFresh = await getDoc(userDocRef);
        if (regFresh.exists()) {
          const regData = regFresh.data();
          if (!regData.deletedAt && !isAccountBlocked(regData as Pick<User, 'accountBlock'>)) {
            const next = { ...regData, id: regFresh.id } as User;
            appUserRef.current = next;
            setAppUser(next);
          }
        }
        return { ok: true };
      } catch (e: unknown) {
        logger.error('auth', 'Registration error', e);
        const err = e as { code?: string };
        const byCode: Record<
          string,
          { message: string; conflictField?: RegisterConflictField }
        > = {
          'auth/email-already-in-use': {
            message: 'Этот email уже зарегистрирован.',
            conflictField: 'email',
          },
          'auth/invalid-email': {
            message: 'Некорректный формат email.',
            conflictField: 'email',
          },
          'auth/weak-password': {
            message: 'Пароль слишком слабый (минимум 6 символов).',
            conflictField: 'password',
          },
          'auth/operation-not-allowed': {
            message: 'Регистрация временно недоступна.',
          },
          'auth/too-many-requests': {
            message: 'Слишком много попыток. Подождите и попробуйте снова.',
          },
          'auth/network-request-failed': {
            message: 'Ошибка сети. Проверьте подключение.',
          },
        };
        const hit = err.code ? byCode[err.code] : undefined;
        const message = hit?.message ?? 'Ошибка при регистрации. Попробуйте ещё раз.';
        const conflictField = hit?.conflictField;
        if (!conflictField) {
          setError(message);
        }
        return { ok: false, message, conflictField };
      }
    },
    [auth, firestore, storage]
  );

  const completeGoogleProfile = useCallback(
    async (data: CompleteGoogleProfileData): Promise<RegisterResult> => {
      setError(null);
      if (!firestore) {
        const message = 'Сервис временно недоступен.';
        setError(message);
        return { ok: false, message };
      }
      const firebaseUser = auth.currentUser;
      if (!firebaseUser) {
        const message =
          'Сессия недействительна. Войдите через Google, Apple, Яндекс или Telegram снова.';
        setError(message);
        return { ok: false, message };
      }
      const isTelegram = await isTelegramProfileUser(firebaseUser);
      const isYandex = isYandexProfileUid(firebaseUser);
      if (!hasOauthSocialProvider(firebaseUser) && !isTelegram && !isYandex) {
        const message =
          'Завершение этого шага доступно только для аккаунта с входом через Google, Apple, Яндекс или Telegram.';
        setError(message);
        return { ok: false, message };
      }

      const emailNorm = data.email.trim().toLowerCase();
      const authEmail = (firebaseUser.email ?? '').trim().toLowerCase();
      if (authEmail.length > 0 && emailNorm !== authEmail) {
        return {
          ok: false,
          message:
            'Email нельзя изменить для этого способа входа. Используйте адрес из аккаунта соцсети или Telegram.',
          conflictField: 'email',
        };
      }

      const normalizedUsername = data.username.toLowerCase().replace(/^@/, '');
      const uid = firebaseUser.uid;

      try {
        if (
          await isRegistrationEmailTakenInIndex(firestore, emailNorm, {
            exceptUid: uid,
          })
        ) {
          return {
            ok: false,
            message: 'Этот email уже занят другим аккаунтом.',
            conflictField: 'email',
          };
        }
        if (
          await isRegistrationPhoneTaken(firestore, data.phone, {
            exceptUid: uid,
          })
        ) {
          return {
            ok: false,
            message:
              'Этот номер телефона уже зарегистрирован. Укажите другой номер.',
            conflictField: 'phone',
          };
        }
        if (
          await isRegistrationUsernameTakenInIndex(
            firestore,
            normalizedUsername,
            { exceptUid: uid },
          )
        ) {
          return {
            ok: false,
            message: 'Этот логин уже занят. Выберите другой.',
            conflictField: 'username',
          };
        }
      } catch (idxErr) {
        logger.error('auth', 'completeGoogleProfile: registrationIndex checks failed', idxErr);
        const message =
          'Не удалось проверить уникальность телефона и логина. Проверьте сеть и попробуйте снова.';
        setError(message);
        return { ok: false, message };
      }

      let avatarUrl =
        firebaseUser.photoURL ||
        `https://api.dicebear.com/7.x/avataaars/svg?seed=${uid}`;
      try {
        const existing = await getDoc(doc(firestore, 'users', uid));
        if (existing.exists()) {
          const prev = existing.data()?.avatar;
          if (typeof prev === 'string' && prev.length > 0) {
            avatarUrl = prev;
          }
        }
      } catch {
        /* оставляем avatarUrl по Auth / dicebear */
      }

      if (data.avatarFile && !storage) {
        const message = 'Хранилище недоступно. Уберите новое фото или попробуйте позже.';
        setError(message);
        return { ok: false, message };
      }

      const thumbOnAvatarUpload: Record<string, unknown> = {};
      if (data.avatarFile) {
        try {
          const { avatarUrl: uploadedUrl, avatarThumbUrl } =
            await uploadUserAvatarPair(storage, uid, data.avatarFile, data.avatarThumbFile);
          avatarUrl = uploadedUrl;
          thumbOnAvatarUpload.avatarThumb = avatarThumbUrl ?? deleteField();
        } catch (uploadErr) {
          logger.warn('auth', 'completeGoogleProfile: avatar upload failed', uploadErr);
        }
      }

      try {
        const userDocRef = doc(firestore, 'users', uid);
        await updateDoc(userDocRef, {
          name: data.name.trim(),
          username: normalizedUsername,
          phone: data.phone,
          email: emailNorm,
          avatar: avatarUrl,
          bio: data.bio?.trim() ? data.bio.trim() : '',
          dateOfBirth: data.dateOfBirth?.trim() ? data.dateOfBirth : null,
          updatedAt: new Date().toISOString(),
          ...thumbOnAvatarUpload,
        } as Record<string, unknown>);

        if (
          (isTelegram || isYandex) &&
          (firebaseUser.email ?? '').trim().length === 0 &&
          emailNorm.length > 0 &&
          typeof window !== 'undefined'
        ) {
          try {
            await requestVerifiedEmailChange({
              firebaseUser,
              newEmail: emailNorm,
              actionCodeSettings: {
                url: `${window.location.origin}/dashboard/profile`,
                handleCodeInApp: false,
              },
            });
          } catch (e) {
            logger.warn('auth', 'completeGoogleProfile: requestVerifiedEmailChange', e);
          }
          try {
            await firebaseUser.reload();
            await firebaseUser.getIdToken(true);
          } catch {
            /* no-op */
          }
        }

        const googleFresh = await getDoc(userDocRef);
        if (googleFresh.exists()) {
          const gData = googleFresh.data();
          if (!gData.deletedAt && !isAccountBlocked(gData as Pick<User, 'accountBlock'>)) {
            const next = { ...gData, id: googleFresh.id } as User;
            appUserRef.current = next;
            setAppUser(next);
          }
        }
        logger.debug('auth', `completeGoogleProfile saved users/${uid}`);
        return { ok: true };
      } catch (e) {
        logger.error('auth', 'completeGoogleProfile: Firestore update failed', e);
        const message = 'Не удалось сохранить профиль. Попробуйте ещё раз.';
        setError(message);
        return { ok: false, message };
      }
    },
    [auth, firestore, storage],
  );

  const signInWithGoogle = useCallback(async (): Promise<boolean> => {
    setError(null);
    const provider = new GoogleAuthProvider();
    provider.setCustomParameters({ prompt: 'select_account' });

    try {
      /** Popup: сразу UserCredential — без гонок getRedirectResult. COOP: same-origin-allow-popups в next.config. */
      const result = await signInWithPopup(auth, provider);
      return await finalizeOAuthCredential(result);
    } catch (e: unknown) {
      const err = e as { code?: string };
      logger.error('auth', 'Google sign-in error', e);

      if (err.code === 'auth/popup-blocked') {
        try {
          await signInWithRedirect(auth, provider);
          return false;
        } catch (re) {
          logger.error('auth', 'Google redirect fallback error', re);
          setError(
            'Браузер заблокировал окно входа. Разрешите всплывающие окна для этого сайта или попробуйте другой браузер.'
          );
          return false;
        }
      }

      if (err.code === 'auth/popup-closed-by-user' || err.code === 'auth/cancelled-popup-request') {
        return false;
      }

      const msg = (
        {
          'auth/account-exists-with-different-credential':
            'Аккаунт с этим email уже использует другой метод входа.',
          'auth/network-request-failed': 'Ошибка сети. Проверьте подключение.',
          'auth/too-many-requests': 'Слишком много попыток. Подождите.',
          'auth/unauthorized-domain':
            'Домен не в списке Authorized domains (Firebase Console → Authentication → Settings).',
          'auth/operation-not-allowed':
            'Вход через Google выключен: Authentication → Sign-in method → Google.',
          /** Firestore после входа (чаще гонка JWT до чтения users/{uid}). */
          'permission-denied':
            'Нет доступа к профилю в базе. Обновите страницу и войдите снова. Если не помогло — проверьте деплой firestore.rules.',
        } as Record<string, string>
      )[err.code ?? ''];
      setError(
        msg ||
          (String((e as { message?: string })?.message ?? '').includes('Missing or insufficient permissions')
            ? 'Нет доступа к данным (Firestore). Обновите страницу и повторите вход.'
            : 'Ошибка при входе через Google.')
      );
      return false;
    }
  }, [auth, finalizeOAuthCredential]);

  const signInWithYandex = useCallback(async (): Promise<boolean> => {
    setError(null);
    if (typeof window === 'undefined') return false;
    /** Сервер проверяет YANDEX_CLIENT_ID / YANDEX_CLIENT_SECRET; публичный ID не обязателен для клика. */
    window.location.assign('/api/auth/yandex');
    return true;
  }, []);

  const signInWithApple = useCallback(async (): Promise<boolean> => {
    setError(null);
    const provider = new OAuthProvider('apple.com');
    provider.addScope('email');
    provider.addScope('name');

    try {
      const result = await signInWithPopup(auth, provider);
      return await finalizeOAuthCredential(result);
    } catch (e: unknown) {
      const err = e as { code?: string };
      logger.error('auth', 'Apple sign-in error', e);

      if (err.code === 'auth/popup-blocked') {
        try {
          await signInWithRedirect(auth, provider);
          return false;
        } catch (re) {
          logger.error('auth', 'Apple redirect fallback error', re);
          setError(
            'Браузер заблокировал окно входа. Разрешите всплывающие окна для этого сайта или попробуйте другой браузер.'
          );
          return false;
        }
      }

      if (err.code === 'auth/popup-closed-by-user' || err.code === 'auth/cancelled-popup-request') {
        return false;
      }

      const msg = (
        {
          'auth/account-exists-with-different-credential':
            'Аккаунт с этим email уже использует другой метод входа.',
          'auth/network-request-failed': 'Ошибка сети. Проверьте подключение.',
          'auth/too-many-requests': 'Слишком много попыток. Подождите.',
          'auth/unauthorized-domain':
            'Домен не в списке Authorized domains (Firebase Console → Authentication → Settings).',
          'auth/operation-not-allowed':
            'Вход через Apple выключен или не настроен: Authentication → Sign-in method → Apple (и Apple Developer Services ID / Key).',
          'permission-denied':
            'Нет доступа к профилю в базе. Обновите страницу и войдите снова. Если не помогло — проверьте деплой firestore.rules.',
        } as Record<string, string>
      )[err.code ?? ''];
      setError(
        msg ||
          (String((e as { message?: string })?.message ?? '').includes('Missing or insufficient permissions')
            ? 'Нет доступа к данным (Firestore). Обновите страницу и повторите вход.'
            : 'Ошибка при входе через Apple.')
      );
      return false;
    }
  }, [auth, finalizeOAuthCredential]);

  const signInWithTelegramPayload = useCallback(
    async (authPayload: Record<string, unknown>): Promise<boolean> => {
      setError(null);
      if (!auth || !firebaseApp) {
        setError('Сервис входа недоступен. Обновите страницу.');
        return false;
      }
      try {
        const functions = getFunctions(firebaseApp, 'us-central1');
        const fn = httpsCallable<
          { auth: Record<string, unknown> },
          { customToken: string }
        >(functions, 'signInWithTelegram');
        const res = await fn({ auth: authPayload });
        const customToken = res.data?.customToken;
        if (!customToken || typeof customToken !== 'string') {
          setError('Сервер не вернул токен. Попробуйте войти через Telegram снова.');
          return false;
        }
        const cred = await signInWithCustomToken(auth, customToken);
        return await finalizeOAuthCredential(cred);
      } catch (e: unknown) {
        logger.error('auth', 'Telegram sign-in error', e);
        const err = e as { code?: string; message?: string };
        const code = err.code ?? '';
        const msg = (
          {
            'functions/permission-denied':
              'Не удалось войти через Telegram: неверные данные или истёкшее время авторизации.',
            'functions/failed-precondition':
              'Вход через Telegram не настроен на сервере (секрет TELEGRAM_BOT_TOKEN).',
            'functions/invalid-argument': 'Некорректные данные входа Telegram.',
            'auth/network-request-failed': 'Ошибка сети. Проверьте подключение.',
          } as Record<string, string>
        )[code];
        setError(
          msg ||
            (typeof err.message === 'string' && err.message.length > 0
              ? err.message
              : 'Ошибка при входе через Telegram.')
        );
        return false;
      }
    },
    [auth, firebaseApp, finalizeOAuthCredential],
  );

  const createNewAuthUser = useCallback(
    async (email: string, password: string): Promise<UserCredential> => {
      setError(null);
      try {
        return await createUserWithEmailAndPassword(auth, email, password);
      } catch (e: any) {
        setError(e.code === 'auth/email-already-use' ? 'Этот email уже используется.' : 'Ошибка при создании пользователя.');
        throw e;
      }
    },
    [auth]
  );

  const updateUser = useCallback(
    async (
      newUserData: Partial<User & { password?: string }>
    ): Promise<UpdateUserResult> => {
    if (!appUser || !firebaseUser || !firestore) {
      return { ok: false, message: 'Нет данных пользователя или Firebase.' };
    }
    setIsUpdatingUser(true);
    setError(null);
    try {
        if (newUserData.password && newUserData.password.length > 0) {
            await firebaseUpdatePassword(firebaseUser, newUserData.password);
        }

        const { password: _pw, ...rest } = newUserData;
        const emailTrim =
          typeof rest.email === 'string' ? rest.email.trim() : undefined;
        let emailVerificationSent = false;
        if (emailTrim && emailTrim !== (firebaseUser.email ?? '')) {
          const mapEmailChangeError = (e: unknown) => {
            const code = (e as { code?: string })?.code;
            return {
              code,
              msg:
                code === 'auth/requires-recent-login'
                  ? 'Для смены email выполните повторный вход и попробуйте снова.'
                  : code === 'auth/email-already-in-use'
                    ? 'Этот email уже используется.'
                    : code === 'auth/invalid-email'
                      ? 'Некорректный формат email.'
                      : code === 'auth/unauthorized-domain'
                        ? 'Домен не в Authorized domains (Firebase Console → Authentication → Settings).'
                        : 'Не удалось отправить письмо подтверждения email.',
            };
          };

          try {
            if (typeof window === 'undefined') {
              const msg = 'Смена email доступна только в браузере.';
              setError(msg);
              return { ok: false, message: msg };
            }
            const actionCodeSettings: ActionCodeSettings = {
              url: `${window.location.origin}/dashboard/profile`,
              handleCodeInApp: false,
            };
            const res = await requestVerifiedEmailChange({
              firebaseUser,
              newEmail: emailTrim,
              actionCodeSettings,
            });
            if (!res.ok) {
              const { msg } = mapEmailChangeError({ code: res.code });
              setError(msg);
              return { ok: false, message: msg };
            }
            emailVerificationSent = true;
          } catch (e: unknown) {
            logger.error('auth', 'requestVerifiedEmailChange', e);
            const { msg } = mapEmailChangeError(e);
            setError(msg);
            return { ok: false, message: msg };
          }
        }

        const prevUsernameNorm = (appUser.username ?? '')
          .trim()
          .replace(/^@/, '')
          .toLowerCase();
        let usernameNorm: string | undefined;
        if (rest.username !== undefined) {
          usernameNorm = String(rest.username)
            .trim()
            .replace(/^@/, '')
            .toLowerCase();
          if (usernameNorm !== prevUsernameNorm && usernameNorm.length > 0) {
            const usersRef = collection(firestore, 'users');
            const q = query(usersRef, where('username', '==', usernameNorm));
            const snapshot = await getDocs(q);
            const taken = snapshot.docs.some((d) => d.id !== appUser.id);
            if (taken) {
              const msg = 'Этот логин уже занят.';
              setError(msg);
              return { ok: false, message: msg };
            }
          }
        }

        const dataToSave: Record<string, unknown> = { ...rest };
        delete dataToSave.password;
        if (emailVerificationSent) {
          delete dataToSave.email;
          dataToSave.pendingEmail = emailTrim?.trim().toLowerCase() || '';
          dataToSave.pendingEmailRequestedAt = new Date().toISOString();
        } else if (emailTrim !== undefined) {
          dataToSave.email = emailTrim;
        }
        if (usernameNorm !== undefined) {
          dataToSave.username = usernameNorm;
        }
        const cleaned: Record<string, unknown> = {};
        for (const [k, v] of Object.entries(dataToSave)) {
          if (v !== undefined) cleaned[k] = v;
        }
        if (cleaned.dateOfBirth === '') {
          cleaned.dateOfBirth = null;
        }
        if (cleaned.bio === '') {
          cleaned.bio = null;
        }

        const userDocRef = doc(firestore, 'users', appUser.id);
        await updateDoc(userDocRef, {
          ...cleaned,
          updatedAt: new Date().toISOString(),
        } as Record<string, unknown>);
        return emailVerificationSent
          ? { ok: true, emailVerificationSent: true }
          : { ok: true };
    } catch (e: any) {
        logger.error('auth', 'Error updating user profile', e);
        const msg = 'Не удалось обновить профиль.';
        setError(msg);
        return { ok: false, message: msg };
    } finally {
        setIsUpdatingUser(false);
    }
  }, [appUser, firebaseUser, firestore]);

  const resendPendingEmailVerification = useCallback(async () => {
    if (!firebaseUser || !firestore || !appUser?.id) {
      return { ok: false as const, message: 'Нет данных пользователя или Firebase.' };
    }
    const pending = String(appUser.pendingEmail ?? '').trim().toLowerCase();
    if (!pending) {
      return { ok: false as const, message: 'Нет email, ожидающего подтверждения.' };
    }
    if (typeof window === 'undefined') {
      return { ok: false as const, message: 'Отправка письма доступна только в браузере.' };
    }
    const res = await requestVerifiedEmailChange({
      firebaseUser,
      newEmail: pending,
      actionCodeSettings: {
        url: `${window.location.origin}/dashboard/profile`,
        handleCodeInApp: false,
      },
    });
    if (!res.ok) {
      const code = res.code ?? '';
      const message =
        code === 'auth/requires-recent-login'
          ? 'Для отправки письма выполните повторный вход и попробуйте снова.'
          : code === 'auth/unauthorized-domain'
            ? 'Домен не в Authorized domains (Firebase Console → Authentication → Settings).'
            : 'Не удалось отправить письмо подтверждения.';
      return { ok: false as const, message };
    }
    await updateDocumentNonBlocking(doc(firestore, 'users', appUser.id), {
      pendingEmailRequestedAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    });
    return { ok: true as const };
  }, [appUser?.id, appUser?.pendingEmail, firebaseUser, firestore]);

  const isLoading = isAuthLoading || isProfileLoading;
  
  useEffect(() => {
    /**
     * Публичные маршруты, на которых неавторизованный пользователь должен
     * оставаться без редиректа: лендинг (/), сама /auth и её OAuth-подпути,
     * страницы встреч (гость), юридические документы и публичный профиль контакта.
     */
    if (
      !isLoading &&
      !appUser &&
      !firebaseUser &&
      pathname !== '/' &&
      pathname !== '/auth' &&
      !pathname.startsWith('/auth/') &&
      !pathname.startsWith('/meetings/') &&
      !pathname.startsWith('/legal') &&
      !pathname.startsWith('/u/')
    ) {
      router.push('/auth');
    }
  }, [isLoading, appUser, firebaseUser, pathname, router]);

  const clearError = useCallback(() => setError(null), []);

  const contextValue = {
    user: appUser,
    googleProfileCompletionFlow,
    login,
    register,
    completeGoogleProfile,
    checkUsernameAvailable,
    signInWithGoogle,
    signInWithApple,
    signInWithYandex,
    signInWithTelegramPayload,
    logout,
    updateUser,
    resendPendingEmailVerification,
    createNewAuthUser,
    /**
     * Гость (Anonymous Auth) считается НЕ-аутентифицированным для приложения:
     * dashboard layout / home redirects используют `isAuthenticated`, и без этого
     * фильтра гость уходит на `/dashboard/profile` через ветку «incomplete profile»
     * (см. dashboard/layout.tsx). MeetingPage берёт `user` напрямую — там guest
     * по-прежнему доступен.
     */
    isAuthenticated: !!appUser && !firebaseUser?.isAnonymous,
    isGuest: !!firebaseUser?.isAnonymous,
    isLoading,
    isUpdatingUser,
    error,
    clearError,
  };

  return (
    <AuthContext.Provider value={contextValue}>{children}</AuthContext.Provider>
  );
};

export const useAuth = (): AuthContextType => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
