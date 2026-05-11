import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

/**
 * Общий слой для крон-функций, фактически применяющих параметры из
 * `platformSettings/main.storage` и поля `storageQuotaBytes`:
 *
 *  - `mediaRetentionCleanupDaily` — удаляет вложения старше N дней (по
 *    `mediaRetentionDays`).
 *  - `enforceStorageQuotasDaily` — FIFO-выселение при превышении квоты
 *    отдельного чата (`conversations.storageQuotaBytes`) и глобальной
 *    квоты проекта (`platformSettings.totalQuotaGb`).
 *
 * Все мутации идут через `evictMessageAttachments`, который:
 *   1. Пытается удалить объекты из GCS (оригинал и `norm/`-вариант).
 *   2. Очищает поле `attachments` в документе сообщения, оставляя метку
 *      `mediaEvictedAt`/`mediaEvictedReason` — клиент должен показывать
 *      такие сообщения как «вложение удалено».
 *   3. НЕ удаляет само сообщение и не трогает текст — это сохраняет
 *      историю переписки.
 *
 * Дальше отдельная задача — пересчёт `conversations.storage` после
 * сессии выселения, см. `recomputeConversationStorage`.
 */

export type EnforcementMode = "off" | "dry_run" | "enforce";

const PLATFORM_SETTINGS_DOC = "main";

export type StoragePolicy = {
  mediaRetentionDays: number | null;
  totalQuotaGb: number | null;
  enforcementMode?: EnforcementMode;
};

export async function loadStoragePolicy(
  db: admin.firestore.Firestore,
): Promise<StoragePolicy> {
  const snap = await db.collection("platformSettings").doc(PLATFORM_SETTINGS_DOC).get();
  if (!snap.exists) {
    return { mediaRetentionDays: null, totalQuotaGb: null, enforcementMode: "off" };
  }
  const data = snap.data() ?? {};
  const storage = (data.storage ?? {}) as Partial<StoragePolicy>;
  const mode = storage.enforcementMode;
  return {
    mediaRetentionDays:
      typeof storage.mediaRetentionDays === "number" ? storage.mediaRetentionDays : null,
    totalQuotaGb:
      typeof storage.totalQuotaGb === "number" ? storage.totalQuotaGb : null,
    // Дефолт «off» — без явного включения админом ни одна крон-функция
    // не должна удалять контент пользователей.
    enforcementMode:
      mode === "enforce" || mode === "dry_run" || mode === "off" ? mode : "off",
  };
}

/**
 * Преобразует download-URL Firebase Storage в внутренний object path
 * (например `chat-attachments/{cid}/abc.jpg`). Возвращает null, если
 * URL не указывает на наш бакет или находится в `norm/` (нормализованную
 * версию удаляем отдельно по конкретному пути).
 */
export function attachmentUrlToObjectPath(url: string): string | null {
  try {
    const u = new URL(url);
    if (!u.hostname.includes("firebasestorage.googleapis.com")) return null;
    const segs = u.pathname.split("/").filter(Boolean);
    const oIdx = segs.indexOf("o");
    if (oIdx < 0 || oIdx >= segs.length - 1) return null;
    const encoded = segs.slice(oIdx + 1).join("/");
    const objectPath = decodeURIComponent(encoded);
    if (!objectPath.startsWith("chat-attachments/") &&
        !objectPath.startsWith("chat-attachments-enc/")) {
      return null;
    }
    return objectPath;
  } catch {
    return null;
  }
}

/**
 * Удаляет один объект GCS, игнорируя 404. Логирует прочие ошибки.
 */
async function deleteObjectIfExists(
  bucket: ReturnType<ReturnType<typeof admin.storage>["bucket"]>,
  objectPath: string,
): Promise<void> {
  try {
    await bucket.file(objectPath).delete({ ignoreNotFound: true });
  } catch (e) {
    logger.warn("[storage-quota-enforcement] failed to delete object", {
      objectPath,
      error: String(e),
    });
  }
}

/**
 * Удаляет в GCS все объекты, ассоциированные с конкретным attachment:
 *   - оригинальный URL,
 *   - предполагаемый `norm/` вариант под тем же conversationId/messageId.
 */
async function deleteAttachmentObjects(
  bucket: ReturnType<ReturnType<typeof admin.storage>["bucket"]>,
  attachment: Record<string, unknown>,
): Promise<void> {
  const url = typeof attachment.url === "string" ? attachment.url : null;
  if (!url) return;
  const path = attachmentUrlToObjectPath(url);
  if (path) {
    await deleteObjectIfExists(bucket, path);
  }
  // Парные превью/нормализованные файлы пишутся рядом — попытка точечного
  // удаления возможна только если клиент кладёт thumb-url в это же
  // attachment. Полный «рядом-расположенный мусор» можно подбирать через
  // prefix-list, но это вне scope cron-задачи. Оставляем на retention.
}

export type EvictionReason =
  | "retention"
  | "quota_conversation"
  | "quota_total";

/**
 * Применяет выселение к одному документу сообщения: удаляет файлы в GCS
 * (если `mode==='enforce'`) и зачищает поле `attachments` в Firestore.
 * Возвращает суммарные байты, освобождённые этим документом (для
 * прогрессного выхода из цикла FIFO).
 */
export async function evictMessageAttachments(opts: {
  bucket: ReturnType<ReturnType<typeof admin.storage>["bucket"]>;
  messageRef: admin.firestore.DocumentReference;
  reason: EvictionReason;
  mode: EnforcementMode;
}): Promise<number> {
  const { bucket, messageRef, reason, mode } = opts;
  if (mode === "off") return 0;

  const snap = await messageRef.get();
  if (!snap.exists) return 0;
  const data = snap.data() ?? {};
  const attachments = Array.isArray(data.attachments) ?
    (data.attachments as Array<Record<string, unknown>>) :
    [];
  if (attachments.length === 0) return 0;

  const totalBytes = attachments.reduce((acc, a) => {
    const size = Number(a.fileSizeBytes ?? a.size ?? 0);
    return acc + (Number.isFinite(size) && size > 0 ? size : 0);
  }, 0);

  if (mode === "dry_run") {
    logger.info("[storage-quota-enforcement] dry_run evict", {
      path: messageRef.path,
      reason,
      bytes: totalBytes,
      attachments: attachments.length,
    });
    return totalBytes;
  }

  await Promise.all(
    attachments.map((a) => deleteAttachmentObjects(bucket, a)),
  );

  await messageRef.update({
    attachments: admin.firestore.FieldValue.delete(),
    mediaEvictedAt: admin.firestore.FieldValue.serverTimestamp(),
    mediaEvictedReason: reason,
    mediaEvictedBytes: totalBytes,
  });

  return totalBytes;
}

/**
 * Идём по сообщениям с вложениями в одном чате (oldest first) и выселяем,
 * пока суммарный байт не упадёт ниже `targetBytes` (или пока сообщения не
 * закончатся). Возвращает количество выселенных документов и освобождённые
 * байты.
 */
export async function evictConversationUntilUnder(opts: {
  db: admin.firestore.Firestore;
  bucket: ReturnType<ReturnType<typeof admin.storage>["bucket"]>;
  conversationId: string;
  startBytes: number;
  targetBytes: number;
  mode: EnforcementMode;
  reason: EvictionReason;
  maxDocsPerRun?: number;
}): Promise<{ evictedDocs: number; freedBytes: number; reachedTarget: boolean }> {
  const PAGE = 200;
  const limit = opts.maxDocsPerRun ?? 5000;
  let evictedDocs = 0;
  let freedBytes = 0;
  let remaining = opts.startBytes;

  // Сканируем сообщения oldest-first без `where attachments != null`, чтобы
  // не требовать составной индекс. Документы без вложений выходят
  // нулевыми (freed=0) и не учитываются. Дёшево, потому что Firestore всё
  // равно вернёт по 200 за запрос.
  const baseQuery = opts.db
    .collection("conversations")
    .doc(opts.conversationId)
    .collection("messages")
    .orderBy("createdAt", "asc")
    .limit(PAGE);

  let lastDoc: admin.firestore.QueryDocumentSnapshot | null = null;
  while (remaining > opts.targetBytes && evictedDocs < limit) {
    const page: admin.firestore.QuerySnapshot = lastDoc ?
      await baseQuery.startAfter(lastDoc).get() :
      await baseQuery.get();
    if (page.empty) break;

    for (const doc of page.docs) {
      const freed = await evictMessageAttachments({
        bucket: opts.bucket,
        messageRef: doc.ref,
        reason: opts.reason,
        mode: opts.mode,
      });
      if (freed > 0) {
        evictedDocs += 1;
        freedBytes += freed;
        remaining -= freed;
        if (remaining <= opts.targetBytes) break;
      }
      if (evictedDocs >= limit) break;
    }

    if (page.docs.length < PAGE) break;
    lastDoc = page.docs[page.docs.length - 1];
  }

  return {
    evictedDocs,
    freedBytes,
    reachedTarget: remaining <= opts.targetBytes,
  };
}

/**
 * Пересчитывает `conversations/{cid}.storage` после выселения. Минимальный
 * пересчёт: вычитаем уже посчитанные байты и проставляем `recountedAt`,
 * чтобы избежать повторного скана коллекции сообщений (тот же скан делает
 * `adminRecomputeStorageStats`).
 */
export async function decrementConversationStorage(opts: {
  db: admin.firestore.Firestore;
  conversationId: string;
  freedBytes: number;
}): Promise<void> {
  if (opts.freedBytes <= 0) return;
  await opts.db.collection("conversations").doc(opts.conversationId).set(
    {
      storage: {
        totalBytes: admin.firestore.FieldValue.increment(-opts.freedBytes),
        recountedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
    },
    { merge: true },
  );
}
