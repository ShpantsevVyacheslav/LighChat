'use client';

import { firebaseConfig } from '@/firebase/config';
import { shouldForceFirestoreLongPolling } from '@/firebase/firestore-transport';
import { initializeApp, getApps, getApp, FirebaseApp } from 'firebase/app';
import { getAuth, setPersistence, browserLocalPersistence, Auth } from 'firebase/auth';
import { 
    getFirestore, 
    Firestore, 
    initializeFirestore, 
    persistentLocalCache, 
    persistentSingleTabManager,
} from 'firebase/firestore';
import { getStorage, FirebaseStorage } from 'firebase/storage';
import { initLighChatAppCheck } from '@/firebase/app-check';
import { logger } from '@/lib/logger';

type FirebaseServices = {
    firebaseApp: FirebaseApp;
    auth: Auth;
    firestore: Firestore;
    storage: FirebaseStorage;
};

let firebaseInitializationPromise: Promise<FirebaseServices> | null = null;

function longPollingFirestoreSettings():
  | {
      experimentalForceLongPolling: true;
      experimentalAutoDetectLongPolling: false;
      experimentalLongPollingOptions: { timeoutSeconds: number };
    }
  | Record<string, never> {
  return shouldForceFirestoreLongPolling()
    ? {
        experimentalForceLongPolling: true,
        experimentalAutoDetectLongPolling: false,
        experimentalLongPollingOptions: { timeoutSeconds: 30 },
      }
    : {};
}

/** Повторная инициализация без кэша IndexedDB; на WebKit сохраняет long polling. */
function initializeFirestoreWithoutPersistentCache(app: FirebaseApp): Firestore {
  return initializeFirestore(app, {
    ...longPollingFirestoreSettings(),
  });
}

/**
 * Последний шанс: на WebKit не оставлять «голый» getFirestore (WebChannel), если long polling возможен.
 */
function getFirestoreLastResort(app: FirebaseApp): Firestore {
  const lp = longPollingFirestoreSettings();
  if (Object.keys(lp).length > 0) {
    try {
      return initializeFirestore(app, lp);
    } catch (e) {
      logger.warn('firebase', 'initializeFirestore(long poll only) failed; using getFirestore.', e);
    }
  }
  return getFirestore(app);
}

async function internalInitialize(): Promise<FirebaseServices> {
    const app = getApps().length > 0 ? getApp() : initializeApp(firebaseConfig);

    // [audit CR-002] App Check ДО создания auth/storage/firestore — иначе их
    // первые запросы уходят без App Check token и не заверены.
    // Monitor mode пока что: failure to init не валит остальной флоу.
    initLighChatAppCheck(app);

    const auth = getAuth(app);
    const storage = getStorage(app);
    
    try {
        // Устанавливаем локальную персистентность для сохранения авторизации при закрытии PWA
        await setPersistence(auth, browserLocalPersistence);
        logger.debug('firebase', 'auth persistence set to local successfully');
    } catch (error) {
        logger.error('firebase', 'auth persistence could not be set', error);
    }

    let firestore: Firestore;
    try {
        if (shouldForceFirestoreLongPolling()) {
            logger.debug(
                'firebase',
                'Firestore: включён long polling для стабильности на iOS / WebKit (PWA и Safari).',
            );
        }
        // Постоянный кэш IndexedDB. Single-tab manager: меньше гонок внутри SDK при множестве
        // слушателей + React Strict Mode (см. scheduleFirestoreListen). Другие вкладки не синхронизируют кэш между собой.
        //
        // experimentalForceLongPolling несовместим с experimentalAutoDetectLongPolling — на WebKit отключаем авто.
        firestore = initializeFirestore(app, {
            localCache: persistentLocalCache({
                tabManager: persistentSingleTabManager(undefined),
            }),
            ...longPollingFirestoreSettings(),
        });
    } catch (error: any) {
        logger.warn(
          'firebase',
          'Firestore с persistentLocalCache не поднялся (часто IndexedDB на iOS). Повтор без кэша.',
          error,
        );
        try {
            firestore = initializeFirestoreWithoutPersistentCache(app);
        } catch (e2) {
            logger.error('firebase', 'Повторная инициализация Firestore не удалась', e2);
            firestore = getFirestoreLastResort(app);
        }
    }

    return { firebaseApp: app, auth, firestore, storage };
}

/**
 * Минимальная инициализация без persistentLocalCache (IndexedDB в приватном режиме iOS / квотах
 * иногда ломает initializeFirestore). Сохраняется long polling на iOS.
 */
async function internalInitializeMemoryFirestore(): Promise<FirebaseServices> {
    const app = getApps().length > 0 ? getApp() : initializeApp(firebaseConfig);
    // [audit CR-002] Дубль init'а App Check для fallback-пути (если первый
    // вызов уже стартанул — initLighChatAppCheck идемпотентен).
    initLighChatAppCheck(app);
    const auth = getAuth(app);
    const storage = getStorage(app);
    try {
        await setPersistence(auth, browserLocalPersistence);
    } catch (error) {
        logger.warn('firebase', 'Fallback: persistence unavailable', error);
    }
    if (shouldForceFirestoreLongPolling()) {
        logger.debug('firebase', 'Firestore (fallback): long polling для iOS / WebKit.');
    }
    let firestore: Firestore;
    try {
        firestore = initializeFirestore(app, {
            ...longPollingFirestoreSettings(),
        });
    } catch {
        firestore = getFirestoreLastResort(app);
    }
    return { firebaseApp: app, auth, firestore, storage };
}

async function internalInitializeWithFallback(): Promise<FirebaseServices> {
    try {
        return await internalInitialize();
    } catch (err) {
        logger.error('firebase', 'Primary initialization failed, using memory Firestore fallback.', err);
        try {
            return await internalInitializeMemoryFirestore();
        } catch (err2) {
            logger.error('firebase', 'Memory Firestore fallback failed, last-resort Firestore.', err2);
            const app = getApps().length > 0 ? getApp() : initializeApp(firebaseConfig);
            return {
                firebaseApp: app,
                auth: getAuth(app),
                firestore: getFirestoreLastResort(app),
                storage: getStorage(app),
            };
        }
    }
}

export function initializeFirebase(): Promise<FirebaseServices> {
    if (!firebaseInitializationPromise) {
        firebaseInitializationPromise = internalInitializeWithFallback();
    }
    return firebaseInitializationPromise;
}

export * from './provider';
export * from './client-provider';
export * from './firestore/use-collection';
export * from './firestore/use-doc';
export * from './firestore/use-users-by-document-ids';
export * from './firestore/use-calls-by-document-ids';
export * from './firestore/use-conversations-by-document-ids';
export * from './non-blocking-updates';
export * from './non-blocking-login';
export * from './errors';
export * from './error-emitter';
export * from 'firebase/firestore';