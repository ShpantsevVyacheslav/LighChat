/**
 * E2EE v2 — persistent IndexedDB-кэш расшифрованного содержимого.
 *
 * Что храним:
 *   - `text` store: ключ `${conversationId}:${messageId}` → plaintext string.
 *   - `media` store: ключ `${conversationId}:${messageId}:${fileId}` →
 *     `{ bytes: Uint8Array, mime: string }`.
 *
 * Зачем: каждый повторный заход в чат (переключение чата, релоад страницы,
 * потеря focus) приводил к полному повтору `decryptMessagePayload` для
 * всей истории и повторному скачиванию + AES-GCM-расшифровке медиа.
 * Persistent кэш устраняет оба повтора — до ручной очистки или logout.
 *
 * Замечания безопасности:
 *  - IndexedDB в браузере хранит данные в пределах origin. Любой JS того же
 *    origin может прочитать их. Наш code base — единственный источник JS,
 *    так что модель угроз не меняется (устройство всё равно может
 *    расшифровать сообщения в любой момент: device-key лежит в IndexedDB).
 *  - При logout следует вызвать `clearAll()` в connected-слое (user rule
 *    #14: «безопасность» — исключаем данные при смене аккаунта).
 */

const DB_NAME = 'lighchat-e2ee-cache';
const DB_VERSION = 1;
const TEXT_STORE = 'text';
const MEDIA_STORE = 'media';

type MediaCacheRecord = {
  bytes: Uint8Array;
  mime: string;
};

let dbPromise: Promise<IDBDatabase> | null = null;

function hasIndexedDB(): boolean {
  return typeof globalThis !== 'undefined' && 'indexedDB' in globalThis;
}

function openDb(): Promise<IDBDatabase> {
  if (dbPromise) return dbPromise;
  if (!hasIndexedDB()) {
    dbPromise = Promise.reject(new Error('E2EE_CACHE_NO_IDB'));
    return dbPromise;
  }
  dbPromise = new Promise<IDBDatabase>((resolve, reject) => {
    const req = indexedDB.open(DB_NAME, DB_VERSION);
    req.onerror = () => reject(req.error);
    req.onupgradeneeded = () => {
      const db = req.result;
      if (!db.objectStoreNames.contains(TEXT_STORE)) {
        db.createObjectStore(TEXT_STORE);
      }
      if (!db.objectStoreNames.contains(MEDIA_STORE)) {
        db.createObjectStore(MEDIA_STORE);
      }
    };
    req.onsuccess = () => resolve(req.result);
    // Blocked / versionchange — закрываем чтобы потом новая страница открыла.
    req.onblocked = () => reject(new Error('E2EE_CACHE_BLOCKED'));
  });
  return dbPromise;
}

function textKey(conversationId: string, messageId: string): string {
  return `${conversationId}:${messageId}`;
}

function mediaKey(
  conversationId: string,
  messageId: string,
  fileId: string
): string {
  return `${conversationId}:${messageId}:${fileId}`;
}

function runGet<T>(
  storeName: string,
  key: string
): Promise<T | undefined> {
  return openDb()
    .then(
      (db) =>
        new Promise<T | undefined>((resolve, reject) => {
          const tx = db.transaction(storeName, 'readonly');
          const store = tx.objectStore(storeName);
          const req = store.get(key);
          req.onsuccess = () => resolve(req.result as T | undefined);
          req.onerror = () => reject(req.error);
        })
    )
    .catch(() => undefined);
}

function runPut(
  storeName: string,
  key: string,
  value: unknown
): Promise<void> {
  return openDb()
    .then(
      (db) =>
        new Promise<void>((resolve, reject) => {
          const tx = db.transaction(storeName, 'readwrite');
          const store = tx.objectStore(storeName);
          const req = store.put(value, key);
          req.onsuccess = () => resolve();
          req.onerror = () => reject(req.error);
        })
    )
    .catch(() => undefined) as Promise<void>;
}

export async function getCachedPlaintext(
  conversationId: string,
  messageId: string
): Promise<string | undefined> {
  return runGet<string>(TEXT_STORE, textKey(conversationId, messageId));
}

export async function putCachedPlaintext(
  conversationId: string,
  messageId: string,
  plaintext: string
): Promise<void> {
  await runPut(TEXT_STORE, textKey(conversationId, messageId), plaintext);
}

export async function getCachedMedia(
  conversationId: string,
  messageId: string,
  fileId: string
): Promise<MediaCacheRecord | undefined> {
  return runGet<MediaCacheRecord>(
    MEDIA_STORE,
    mediaKey(conversationId, messageId, fileId)
  );
}

export async function putCachedMedia(
  conversationId: string,
  messageId: string,
  fileId: string,
  record: MediaCacheRecord
): Promise<void> {
  await runPut(
    MEDIA_STORE,
    mediaKey(conversationId, messageId, fileId),
    record
  );
}

/** Полная очистка (на logout). */
export async function clearAllE2eeCache(): Promise<void> {
  if (!hasIndexedDB()) return;
  try {
    const db = await openDb();
    await new Promise<void>((resolve, reject) => {
      const tx = db.transaction([TEXT_STORE, MEDIA_STORE], 'readwrite');
      tx.objectStore(TEXT_STORE).clear();
      tx.objectStore(MEDIA_STORE).clear();
      tx.oncomplete = () => resolve();
      tx.onerror = () => reject(tx.error);
    });
  } catch {
    // best-effort
  }
}

/** Очистка по conversationId (на удаление чата). */
export async function clearConversationE2eeCache(
  conversationId: string
): Promise<void> {
  if (!hasIndexedDB()) return;
  try {
    const db = await openDb();
    await new Promise<void>((resolve, reject) => {
      const tx = db.transaction([TEXT_STORE, MEDIA_STORE], 'readwrite');
      let remaining = 2;
      const prefix = `${conversationId}:`;
      const done = () => {
        remaining -= 1;
        if (remaining === 0) resolve();
      };
      const cursorHandler = (store: IDBObjectStore) => {
        const req = store.openCursor();
        req.onsuccess = () => {
          const cur = req.result;
          if (!cur) {
            done();
            return;
          }
          if (typeof cur.key === 'string' && cur.key.startsWith(prefix)) {
            cur.delete();
          }
          cur.continue();
        };
        req.onerror = () => reject(req.error);
      };
      cursorHandler(tx.objectStore(TEXT_STORE));
      cursorHandler(tx.objectStore(MEDIA_STORE));
    });
  } catch {
    // best-effort
  }
}
