
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
  fetchSignInMethodsForEmail,
  type UserCredential,
} from 'firebase/auth';
import { doc, collection, query, where, getDocs, onSnapshot, getDoc, setDoc, updateDoc } from 'firebase/firestore';

import type { User } from '@/lib/types';
import {
  useFirestore,
  useStorage,
  useAuth as useFirebaseAuth,
  useUser as useFirebaseUser,
  updateDocumentNonBlocking,
} from '@/firebase';
import { ref as storageRef, uploadBytes, getDownloadURL } from 'firebase/storage';
import { compressImage } from '@/lib/image-compression';
import { useToast } from '@/hooks/use-toast';
import { isAccountBlocked } from '@/lib/account-block-utils';
import { scheduleFirestoreListen } from '@/firebase/schedule-firestore-listen';
import {
  isRegistrationEmailTakenInIndex,
  isRegistrationPhoneTaken,
  isRegistrationUsernameTakenInIndex,
} from '@/lib/registration-field-availability';

export interface RegisterData {
  name: string;
  username: string;
  phone: string;
  email: string;
  password: string;
  dateOfBirth?: string;
  bio?: string;
  avatarFile?: File;
}

interface AuthContextType {
  user: User | null;
  login: (email: string, password: string) => Promise<boolean>;
  register: (data: RegisterData) => Promise<boolean>;
  checkUsernameAvailable: (username: string) => Promise<boolean>;
  signInWithGoogle: () => Promise<boolean>;
  logout: () => void;
  updateUser: (
    newUserData: Partial<User & { password?: string }>
  ) => Promise<{ ok: true } | { ok: false; message: string }>;
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
      const userDocRef = doc(firestore, 'users', result.user.uid);
      const userDoc = await getDoc(userDocRef);

      if (userDoc.exists()) {
        if (userDoc.data().deletedAt) {
          await signOut(auth);
          setError('Ваша учетная запись деактивирована.');
          return false;
        }
        return true;
      }

      try {
        await setDoc(userDocRef, {
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
        });
      } catch (writeErr) {
        console.error('Google sign-in: не удалось создать документ users/', writeErr);
        /* Сессия Auth уже есть — слушатель профиля подставит заглушку; не блокируем вход. */
      }
      return true;
    },
    [auth, firestore]
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
        /* replace без проверки cancelled: при Strict Mode cleanup иначе не переходим с `/` в дашборд. */
        if (ok && pathname === '/') {
          router.replace('/dashboard');
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
        setAppUser({
            id: firebaseUser.uid,
            name: firebaseUser.displayName || 'Гость',
            avatar: firebaseUser.photoURL || `https://api.dicebear.com/7.x/avataaars/svg?seed=${firebaseUser.uid}`,
            email: firebaseUser.email || `guest_${firebaseUser.uid}@anonymous.com`,
            deletedAt: null,
            createdAt: new Date().toISOString()
        } as User);
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
              setAppUser(null);
              signOut(auth);
              setError('Ваша учетная запись деактивирована.');
            } else if (isAccountBlocked(userData as Pick<User, 'accountBlock'>)) {
              setAppUser(null);
              signOut(auth);
              setError('Вход для этой учётной записи ограничен администратором.');
            } else {
              setAppUser({
                ...userData,
                id: docSnap.id,
              } as User);
              setError(null);
            }
          } else {
            setAppUser({
              id: firebaseUser.uid,
              name: firebaseUser.displayName || 'Пользователь',
              avatar: firebaseUser.photoURL || `https://api.dicebear.com/7.x/avataaars/svg?seed=${firebaseUser.uid}`,
              email: firebaseUser.email || '',
              createdAt: new Date().toISOString(),
              deletedAt: null,
            } as User);
          }
          setIsProfileLoading(false);
        },
        (e) => {
          console.warn('Profile sync warning:', e.message);
          /* Сессия Firebase есть, а снимок профиля недоступен (сеть/правила) — не сбрасывать вход. */
          setAppUser({
            id: firebaseUser.uid,
            name: firebaseUser.displayName || 'Пользователь',
            avatar:
              firebaseUser.photoURL ||
              `https://api.dicebear.com/7.x/avataaars/svg?seed=${firebaseUser.uid}`,
            email: firebaseUser.email || '',
            createdAt: new Date().toISOString(),
            deletedAt: null,
          } as User);
          setIsProfileLoading(false);
        }
      )
    );
  }, [firebaseUser, isAuthLoading, firestore, auth]);

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
    async (data: RegisterData): Promise<boolean> => {
      setError(null);
      if (!firestore) {
        setError('Сервис временно недоступен.');
        return false;
      }

      const normalizedUsername = data.username.toLowerCase().replace(/^@/, '');
      const emailNorm = data.email.trim().toLowerCase();

      try {
        const methods = await fetchSignInMethodsForEmail(auth, emailNorm);
        if (methods.length > 0) {
          setError('Этот email уже зарегистрирован.');
          return false;
        }

        try {
          if (await isRegistrationEmailTakenInIndex(firestore, emailNorm)) {
            setError('Этот email уже зарегистрирован.');
            return false;
          }
          if (await isRegistrationPhoneTaken(firestore, data.phone)) {
            setError('Этот номер телефона уже зарегистрирован.');
            return false;
          }
          if (await isRegistrationUsernameTakenInIndex(firestore, normalizedUsername)) {
            setError('Этот логин уже занят.');
            return false;
          }
        } catch (idxErr) {
          console.error('Registration: проверка registrationIndex не удалась', idxErr);
          setError(
            'Не удалось проверить уникальность данных. Проверьте сеть и попробуйте снова.'
          );
          return false;
        }

        const userCredential = await createUserWithEmailAndPassword(
          auth,
          emailNorm,
          data.password
        );

        let avatarUrl = `https://api.dicebear.com/7.x/avataaars/svg?seed=${userCredential.user.uid}`;

        if (data.avatarFile) {
          try {
            const compressed = await compressImage(data.avatarFile, 0.85, 400);
            const response = await fetch(compressed);
            const blob = await response.blob();
            const filePath = `avatars/${userCredential.user.uid}/${Date.now()}.jpg`;
            const fileRef = storageRef(storage, filePath);
            await uploadBytes(fileRef, blob);
            avatarUrl = await getDownloadURL(fileRef);
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
          role: 'worker',
          bio: data.bio || '',
          dateOfBirth: data.dateOfBirth || null,
          createdAt: new Date().toISOString(),
          deletedAt: null,
          online: true,
          lastSeen: new Date().toISOString(),
        });
        return true;
      } catch (e: any) {
        console.error('Registration error:', e);
        const msg = ({
          'auth/email-already-in-use': 'Этот email уже зарегистрирован.',
          'auth/invalid-email': 'Некорректный формат email.',
          'auth/weak-password': 'Пароль слишком слабый (минимум 6 символов).',
          'auth/operation-not-allowed': 'Регистрация временно недоступна.',
          'auth/too-many-requests': 'Слишком много попыток. Подождите и попробуйте снова.',
          'auth/network-request-failed': 'Ошибка сети. Проверьте подключение.',
        } as Record<string, string>)[e.code];
        setError(msg || 'Ошибка при регистрации. Попробуйте ещё раз.');
        return false;
      }
    },
    [auth, firestore, storage]
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
        } as Record<string, string>
      )[err.code ?? ''];
      setError(msg || 'Ошибка при входе через Google.');
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
    ): Promise<{ ok: true } | { ok: false; message: string }> => {
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
        if (emailTrim && emailTrim !== (firebaseUser.email ?? '')) {
          try {
            await updateEmail(firebaseUser, emailTrim);
          } catch (e: unknown) {
            const code = (e as { code?: string })?.code;
            console.error('updateEmail:', e);
            const msg =
              code === 'auth/requires-recent-login'
                ? 'Для смены email выполните повторный вход и попробуйте снова.'
                : code === 'auth/email-already-in-use'
                  ? 'Этот email уже используется.'
                  : 'Не удалось сменить email в Firebase Auth.';
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
        if (emailTrim !== undefined) {
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
        return { ok: true };
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
    login,
    register,
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
