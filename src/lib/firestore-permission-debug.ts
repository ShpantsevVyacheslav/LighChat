import { getAuth } from 'firebase/auth';
import type { Firestore } from 'firebase/firestore';

/**
 * Подробные логи при `permission-denied` (только в dev или если в консоли браузера выполнить:
 * `localStorage.setItem('lighchat_firestore_debug','1')` и перезагрузить страницу).
 */
/** `FirebaseError` / Firestore с `code === 'permission-denied'`. */
export function isFirestorePermissionDeniedError(error: unknown): boolean {
  return (
    typeof error === 'object' &&
    error !== null &&
    'code' in error &&
    (error as { code: string }).code === 'permission-denied'
  );
}

export function isFirestorePermissionDebugEnabled(): boolean {
  if (typeof window === 'undefined') return false;
  if (process.env.NODE_ENV === 'development') return true;
  try {
    return window.localStorage.getItem('lighchat_firestore_debug') === '1';
  } catch {
    return false;
  }
}

export interface FirestorePermissionLogPayload {
  /** Откуда вызвано: useCollection, useDoc, ensureSavedMessagesChat, … */
  source: string;
  /** list | get | write | create и т.д. */
  operation: string;
  path?: string;
  firestore?: Firestore | null;
  failedStep?: string;
  extra?: Record<string, unknown>;
  error: unknown;
}

function safeAuthSnapshot(firestore: Firestore | null | undefined) {
  if (!firestore) {
    return {
      projectId: undefined as string | undefined,
      authUid: null as string | null,
      authEmail: null as string | null,
      isAnonymous: undefined as boolean | undefined,
      authNote: 'firestore не передан — projectId/auth не определены',
    };
  }
  try {
    const projectId = firestore.app.options.projectId;
    const auth = getAuth(firestore.app);
    const u = auth.currentUser;
    return {
      projectId,
      authUid: u?.uid ?? null,
      authEmail: u?.email ?? null,
      isAnonymous: u?.isAnonymous,
      authNote: u
        ? 'Firebase Auth: пользователь есть (uid должен совпадать с правилами и с user.id в запросах)'
        : 'ВАЖНО: auth.currentUser === null — в правилах request.auth == null → почти все allow read/write дадут deny',
    };
  } catch (e) {
    return {
      projectId: undefined,
      authUid: null,
      authEmail: null,
      isAnonymous: undefined,
      authNote: `getAuth failed: ${e instanceof Error ? e.message : String(e)}`,
    };
  }
}

/**
 * Развёрнутый вывод в консоль при отказе правил Firestore.
 */
export function logFirestorePermissionDenied(payload: FirestorePermissionLogPayload): void {
  if (!isFirestorePermissionDebugEnabled()) return;

  const err = payload.error;
  const code =
    err && typeof err === 'object' && 'code' in err ? String((err as { code: string }).code) : '';
  const message =
    err && typeof err === 'object' && 'message' in err ? String((err as Error).message) : String(err);

  const snap = safeAuthSnapshot(payload.firestore ?? null);

  const report = {
    source: payload.source,
    operation: payload.operation,
    failedStep: payload.failedStep,
    path: payload.path,
    firebase: {
      projectId: snap.projectId,
      appName: payload.firestore?.app.name,
    },
    auth: {
      uid: snap.authUid,
      email: snap.authEmail,
      isAnonymous: snap.isAnonymous,
      note: snap.authNote,
    },
    error: { code, message },
    extra: payload.extra ?? {},
  };

  console.groupCollapsed(
    `[LighChat Firestore] permission-denied · ${payload.source} · ${payload.operation}${payload.path ? ` · ${payload.path}` : ''}`
  );
  console.info('Контекст (JSON для поддержки / чата):');
  console.info(JSON.stringify(report, null, 2));
  console.table({
    projectId: snap.projectId ?? '(нет)',
    path: payload.path ?? '(нет)',
    authUid: snap.authUid ?? '(null)',
    errorCode: code || '(нет)',
  });
  console.info(
    'Что проверить: 1) `npm run deploy:firestore` для projectId выше 2) Firebase Console → Firestore → Rules (дата публикации) 3) документ чата: participantIds содержит тот же uid 4) если authUid null — ждите onAuthStateChanged или проверьте вход'
  );
  console.info(
    'Логи в production-сборке: localStorage.setItem("lighchat_firestore_debug","1"); location.reload();'
  );
  console.groupEnd();
}
