
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
  signOut,
  updatePassword as firebaseUpdatePassword,
  updateEmail,
  verifyBeforeUpdateEmail,
  fetchSignInMethodsForEmail,
  type UserCredential,
  type User as FirebaseUser,
  type ActionCodeSettings,
} from 'firebase/auth';
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
} from 'firebase/firestore';

import type { User } from '@/lib/types';
import {
  useFirestore,
  useStorage,
  useAuth as useFirebaseAuth,
  useUser as useFirebaseUser,
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
import { isRegistrationProfileComplete } from '@/lib/registration-profile-complete';

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

/** Дозаполнение профиля после входа через Google (без пароля). */
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

/**
 * В консоли Firebase для смены email может быть включено «сначала подтвердить новый адрес»;
 * тогда прямой `updateEmail` отклоняется с auth/operation-not-allowed.
 */
function isFirebaseVerifyNewEmailBeforeChangeError(error: unknown): boolean {
  const code = (error as { code?: string })?.code;
  const message = String((error as { message?: string })?.message ?? '').toLowerCase();
  return (
    code === 'auth/operation-not-allowed' &&
    (message.includes('verify') || message.includes('подтверд'))
  );
}

const GOOGLE_FIRESTORE_AUTH_RETRIES = 8;

/**
 * После `signInWithPopup` persistent Firestore иногда ходит в бэкенд без свежего JWT —
 * `permission-denied`. Повторы с reload + getIdToken(true) и чередование server/client read.
 */
async function firestoreAfterGoogleSignIn<T>(
  credUser: FirebaseUser,
  op: (attemptIndex: number) => Promise<T>
): Promise<T> {
  let lastErr: unknown;
  for (let i = 0; i < GOOGLE_FIRESTORE_AUTH_RETRIES; i++) {
    try {
      await credUser.reload().catch(() => undefined);
      await credUser.getIdToken(true);
      return await op(i);
    } catch (e) {
      lastErr = e;
      const c = (e as { code?: string }).code;
      if (c !== 'permission-denied' || i === GOOGLE_FIRESTORE_AUTH_RETRIES - 1) throw e;
      await new Promise((r) => setTimeout(r, 50 + i * 100));
    }
  }
  throw lastErr;
}

interface AuthContextType {
  user: User | null;
  /** Аккаунт с провайдером Google — форма дозаполнения без пароля. */
  googleProfileCompletionFlow: boolean;
  login: (email: string, password: string) => Promise<boolean>;
  register: (data: RegisterData) => Promise<RegisterResult>;
  completeGoogleProfile: (data: CompleteGoogleProfileData) => Promise<RegisterResult>;
  checkUsernameAvailable: (username: string) => Promise<boolean>;
  signInWithGoogle: () => Promise<boolean>;
  logout: () => void;
  updateUser: (newUserData: Partial<User & { password?: string }>) => Promise<UpdateUserResult>;
  createNewAuthUser: (email: string, password: string) => Promise<UserCredential>;
  isAuthenticated: boolean;
  isLoading: boolean;
  isUpdatingUser: boolean;
  error: string | null;
  clearError: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

const INACTIVITY_LIMIT = 60000; // 1 minute in milliseconds
/** Минимум между записями online/lastSeen в Firestore при уже активном пользователе (снижает writes). */
const PRESENCE_MIN_WRITE_INTERVAL_MS = 45000;

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({
  children,
}) => {
  const { user: firebaseUser, isUserLoading: isAuthLoading } = useFirebaseUser();
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
    firebaseUser.providerData.some((p) => p.providerId === 'google.com');

  useEffect(() => {
    appUserRef.current = appUser;
  }, [appUser]);

  const lastReportedStatusRef = useRef<boolean | null>(null);
  const lastPresenceUpdateRef = useRef<number>(0);
  const lastActivityRef = useRef<number>(Date.now());

  const logout = useCallback(async () => {
    if (appUser && firestore && auth.currentUser) {
        const userDocRef = doc(firestore, 'users', appUser.id);
        try {
            await updateDoc(userDocRef, { 
              online: false, 
              lastSeen: new Date().toISOString() 
            });
        } catch (e) {
            console.warn("Presence update failed during logout", e);
        }
    }
    
    try {
        await signOut(auth);
        router.push('/');
    } catch (e) {
        console.error('Logout error', e);
        setError('Произошла ошибка при выходе.');
    }
  }, [auth, router, appUser, firestore]);

  /** После signInWithRedirect: создать профиль в Firestore при первом входе, проверить блокировки. */
  const finalizeGoogleCredential = useCallback(
    async (result: UserCredential): Promise<boolean> => {
      if (!firestore) {
        console.error('Google sign-in: Firestore недоступен.');
        setError('Сервис данных недоступен. Обновите страницу и попробуйте снова.');
        return false;
      }

      const userDocRef = doc(firestore, 'users', result.user.uid);
      const userDoc = await firestoreAfterGoogleSignIn(result.user, (attempt) =>
        attempt % 2 === 0 ? getDocFromServer(userDocRef) : getDoc(userDocRef)
      );

      if (userDoc.exists()) {
        if (userDoc.data().deletedAt) {
          await signOut(auth);
          setError('Ваша учетная запись деактивирована.');
          return false;
        }
        return true;
      }

      try {
        await firestoreAfterGoogleSignIn(result.user, () =>
          setDoc(userDocRef, {
            id: result.user.uid,
            name: result.user.displayName || 'Пользователь',
            username: '',
            phone: result.user.phoneNumber || '',
            email: result.user.email || '',
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
        console.error('Google sign-in: не удалось создать документ users/', writeErr);
        /* Сессия Auth уже есть — слушатель профиля подставит заглушку; не блокируем вход. */
      }
      return true;
    },
    [auth, firestore, setError]
  );

  /**
   * После signInWithRedirect: обработать результат один раз.
   * Не прерывать finalizeGoogleCredential флагом cancelled — в React Strict Mode эффект
   * размонтируется после первого await, иначе профиль в Firestore не создаётся / сессия «ломается».
   */
  useEffect(() => {
    if (typeof window === 'undefined' || !auth || !firestore) return;
    let cancelled = false;
    (async () => {
      try {
        const result = await getRedirectResult(auth);
        if (!result?.user) return;
        const ok = await finalizeGoogleCredential(result);
        if (ok && pathname === '/' && firestore) {
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
        console.error('Google redirect sign-in error:', e);
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
          setError('Ошибка при входе через Google.');
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [auth, firestore, pathname, router, finalizeGoogleCredential]);

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
              /**
               * После register / completeGoogleProfile делаем getDoc с сервера и setAppUser.
               * Следующий onSnapshot часто приходит из локального кэша со старым документом (без username/phone)
               * и откатывает профиль — дашборд снова шлёт на анкету. Не применяем такой откат с кэша.
               */
              if (docSnap.metadata.fromCache) {
                const prev = appUserRef.current;
                if (
                  prev &&
                  isRegistrationProfileComplete(prev) &&
                  !isRegistrationProfileComplete(merged)
                ) {
                  console.info(
                    '[auth] skip stale cached users/%s snapshot (keep complete profile)',
                    docSnap.id,
                  );
                  setIsProfileLoading(false);
                  return;
                }
              }
              appUserRef.current = merged;
              setAppUser(merged);
              setError(null);
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
          console.warn('Profile sync warning:', e.message);
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
  }, [firebaseUser, firestore]);

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
        console.error('Login error:', e);
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
          console.error('Registration: fetchSignInMethodsForEmail', preAuthErr);
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
          console.error('Registration: проверка registrationIndex не удалась', idxErr);
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
            console.warn('Avatar upload failed, using default:', uploadErr);
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
        console.error('Registration error:', e);
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
        const message = 'Сессия недействительна. Войдите через Google снова.';
        setError(message);
        return { ok: false, message };
      }
      const hasGoogle = firebaseUser.providerData.some(
        (p) => p.providerId === 'google.com',
      );
      if (!hasGoogle) {
        const message =
          'Завершение этого шага доступно только для аккаунта с входом через Google.';
        setError(message);
        return { ok: false, message };
      }

      const emailNorm = data.email.trim().toLowerCase();
      const authEmail = (firebaseUser.email ?? '').trim().toLowerCase();
      if (emailNorm !== authEmail) {
        return {
          ok: false,
          message: 'Email нельзя изменить для аккаунта Google. Используйте адрес из аккаунта Google.',
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
        console.error('completeGoogleProfile: registrationIndex checks failed', idxErr);
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
          console.warn('completeGoogleProfile: avatar upload failed', uploadErr);
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
        const googleFresh = await getDoc(userDocRef);
        if (googleFresh.exists()) {
          const gData = googleFresh.data();
          if (!gData.deletedAt && !isAccountBlocked(gData as Pick<User, 'accountBlock'>)) {
            const next = { ...gData, id: googleFresh.id } as User;
            appUserRef.current = next;
            setAppUser(next);
          }
        }
        console.info('[auth] completeGoogleProfile saved users/%s', uid);
        return { ok: true };
      } catch (e) {
        console.error('completeGoogleProfile: Firestore update failed', e);
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
      return await finalizeGoogleCredential(result);
    } catch (e: unknown) {
      const err = e as { code?: string };
      console.error('Google sign-in error:', e);

      if (err.code === 'auth/popup-blocked') {
        try {
          await signInWithRedirect(auth, provider);
          return false;
        } catch (re) {
          console.error('Google redirect fallback error:', re);
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
  }, [auth, finalizeGoogleCredential]);

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
                      : 'Не удалось сменить email в Firebase Auth.',
            };
          };

          try {
            await updateEmail(firebaseUser, emailTrim);
          } catch (e: unknown) {
            console.error('updateEmail:', e);
            if (isFirebaseVerifyNewEmailBeforeChangeError(e)) {
              if (typeof window === 'undefined') {
                const msg = 'Смена email доступна только в браузере.';
                setError(msg);
                return { ok: false, message: msg };
              }
              const actionCodeSettings: ActionCodeSettings = {
                url: `${window.location.origin}/dashboard/profile`,
                handleCodeInApp: false,
              };
              try {
                await verifyBeforeUpdateEmail(
                  firebaseUser,
                  emailTrim,
                  actionCodeSettings
                );
                emailVerificationSent = true;
              } catch (e2: unknown) {
                console.error('verifyBeforeUpdateEmail:', e2);
                const { msg } = mapEmailChangeError(e2);
                setError(msg);
                return { ok: false, message: msg };
              }
            } else {
              const { msg } = mapEmailChangeError(e);
              setError(msg);
              return { ok: false, message: msg };
            }
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
        console.error("Error updating user profile:", e);
        const msg = 'Не удалось обновить профиль.';
        setError(msg);
        return { ok: false, message: msg };
    } finally {
        setIsUpdatingUser(false);
    }
  }, [appUser, firebaseUser, firestore]);

  const isLoading = isAuthLoading || isProfileLoading;
  
  useEffect(() => {
    if (
      !isLoading &&
      !appUser &&
      !firebaseUser &&
      pathname !== '/' &&
      !pathname.startsWith('/meetings/')
    ) {
      router.push('/');
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
    logout,
    updateUser,
    createNewAuthUser,
    isAuthenticated: !!appUser,
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
