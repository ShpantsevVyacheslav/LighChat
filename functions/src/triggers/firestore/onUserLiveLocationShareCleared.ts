import { onDocumentWritten } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

const db = admin.firestore();

/**
 * Bug 13 (Phase 13): fallback-cleanup для live-location trackPoints.
 *
 * Клиент при тапе Stop в LiveLocationStopBanner делает два действия:
 *  1) `users/{uid}` update — удаляет поле `liveLocationShare`,
 *  2) batched-delete всех документов в sub-collection
 *     `users/{uid}/liveLocationTrackPoints`.
 *
 * Если между (1) и (2) app свернётся / упадёт сеть / процесс прибьют —
 * sub-collection «осиротеет». Этот триггер ловит исчезновение поля
 * `liveLocationShare` и сам каскадно удаляет sub-collection.
 *
 * Перенос ответственности:
 *  - **happy path**: клиент удаляет trackPoints сам — триггер видит
 *    уже пустую sub-collection и завершается no-op.
 *  - **sad path**: клиент не успел — триггер дочищает.
 *
 * Idempotent: повторное срабатывание (например, после client-side
 * cleanup) безопасно — listAllChildren вернёт пустой список.
 *
 * Размер: hard cap на 5000 документов за один вызов (одной траектории
 * пешком на 30+ часов записи). Если в будущем понадобится больше —
 * paginate. Документ live-share активен максимум `forever`, но в
 * practice — до суток (`d1`).
 */
const MAX_CLEANUP_DOCS = 5000;
const BATCH_SIZE = 400;

async function deleteAllTrackPoints(uid: string): Promise<number> {
  const col = db
    .collection("users")
    .doc(uid)
    .collection("liveLocationTrackPoints");
  let totalDeleted = 0;
  while (totalDeleted < MAX_CLEANUP_DOCS) {
    const snap = await col.limit(BATCH_SIZE).get();
    if (snap.empty) break;
    const batch = db.batch();
    for (const doc of snap.docs) {
      batch.delete(doc.ref);
    }
    await batch.commit();
    totalDeleted += snap.docs.length;
    if (snap.docs.length < BATCH_SIZE) break;
  }
  return totalDeleted;
}

export const onUserLiveLocationShareCleared = onDocumentWritten(
  {
    document: "users/{userId}",
    // Регион/runtime по умолчанию — совпадает с остальными триггерами
    // на этом проекте; если в `functions/src/index.ts` для других
    // триггеров задан кастомный регион, можно унаследовать.
  },
  async (event) => {
    const before = event.data?.before.data() as Record<string, unknown> | undefined;
    const after = event.data?.after.data() as Record<string, unknown> | undefined;
    const hadShare = before?.liveLocationShare != null;
    const hasShare = after?.liveLocationShare != null;
    // Реагируем только на переход «было → не стало». Все остальные
    // изменения пользователя (никнейм, аватар, и т.п.) игнорируем.
    if (!hadShare || hasShare) return;
    const uid = event.params.userId as string;
    try {
      const deleted = await deleteAllTrackPoints(uid);
      if (deleted > 0) {
        logger.info(
          `liveLocationTrackPoints: cleaned up ${deleted} orphan docs for uid=${uid}`,
        );
      }
    } catch (e) {
      logger.error(`liveLocationTrackPoints cleanup failed for uid=${uid}`, e);
    }
  },
);
