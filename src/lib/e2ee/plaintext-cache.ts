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
const DB_VERSION = 2;
const TEXT_STORE = 'text';
const MEDIA_STORE = 'media';
/**
 * Preview store: ключ `${conversationId}` → последний расшифрованный
 * текст-превью для списка чатов. Нужен потому, что в Firestore
 * `conversations/{id}.lastMessageText` для E2EE-сообщений хранит
 * плейсхолдер «Зашифрованное сообщение» — серверу плейнтекст не доверяем.
 * Кеш позволяет показать настоящий текст в сайдбаре на тех устройствах,
 * где сообщение уже было расшифровано (открывали чат / сами отправляли).
 *
 * `ts` — копия `conversation.lastMessageTimestamp` на момент кеширования.
 * При несовпадении с текущим Firestore-значением ConversationItem не
 * показывает кешированный текст (значит, поверх пришло более новое).
 */
const PREVIEW_STORE = 'preview';

/** Same-tab уведомление о смене preview (cross-tab — через storage-eviction
 *  на следующем рендере, BroadcastChannel пока не нужен). */
const PREVIEW_EVENT = 'lighchat:e2ee-preview-changed';

type MediaCacheRecord = {
  bytes: Uint8Array;
  mime: string;
};

export type ConversationPreviewRecord = {
  /** Plaintext-превью (HTML уже strip-нут до отображаемого текста). */
  text: string;
  /** ISO-строка `conversation.lastMessageTimestamp` для сообщения, чей текст в `text`. */
  ts: string;
  /** id сообщения, к которому относится preview (для отладки и будущей валидации). */
  messageId: string;
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
      if (!db.objectStoreNames.contains(PREVIEW_STORE)) {
        db.createObjectStore(PREVIEW_STORE);
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

export async function getCachedConversationPreview(
  conversationId: string
): Promise<ConversationPreviewRecord | undefined> {
  return runGet<ConversationPreviewRecord>(PREVIEW_STORE, conversationId);
}

export async function putCachedConversationPreview(
  conversationId: string,
  record: ConversationPreviewRecord
): Promise<void> {
  await runPut(PREVIEW_STORE, conversationId, record);
  if (typeof window !== 'undefined') {
    try {
      window.dispatchEvent(
        new CustomEvent(PREVIEW_EVENT, {
          detail: { conversationId, record },
        })
      );
    } catch {
      // best-effort
    }
  }
}

export type ConversationPreviewListener = (
  conversationId: string,
  record: ConversationPreviewRecord
) => void;

/** Подписка на изменения preview в той же вкладке. Возвращает unsubscribe. */
export function subscribeConversationPreviewChanges(
  listener: ConversationPreviewListener
): () => void {
  if (typeof window === 'undefined') return () => undefined;
  const handler = (e: Event) => {
    const detail = (e as CustomEvent).detail as
      | { conversationId?: string; record?: ConversationPreviewRecord }
      | undefined;
    if (!detail?.conversationId || !detail.record) return;
    listener(detail.conversationId, detail.record);
  };
  window.addEventListener(PREVIEW_EVENT, handler);
  return () => window.removeEventListener(PREVIEW_EVENT, handler);
}

/** Полная очистка (на logout). */
export async function clearAllE2eeCache(): Promise<void> {
  if (!hasIndexedDB()) return;
  try {
    const db = await openDb();
    await new Promise<void>((resolve, reject) => {
      const tx = db.transaction(
        [TEXT_STORE, MEDIA_STORE, PREVIEW_STORE],
        'readwrite'
      );
      tx.objectStore(TEXT_STORE).clear();
      tx.objectStore(MEDIA_STORE).clear();
      tx.objectStore(PREVIEW_STORE).clear();
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
      const tx = db.transaction(
        [TEXT_STORE, MEDIA_STORE, PREVIEW_STORE],
        'readwrite'
      );
      let remaining = 3;
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
      // Preview store — ключ ровно conversationId, без префикса.
      const previewReq = tx.objectStore(PREVIEW_STORE).delete(conversationId);
      previewReq.onsuccess = () => done();
      previewReq.onerror = () => reject(previewReq.error);
    });
  } catch {
    // best-effort
  }
}
