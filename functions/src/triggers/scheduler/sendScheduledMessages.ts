import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import {
  SCHEDULED_MESSAGES_BATCH_LIMIT,
  claimScheduledMessage,
  extractConversationIdFromScheduledPath,
  publishScheduledMessage,
} from "../../lib/scheduled-messages";

const db = admin.firestore();

/**
 * Публикация отложенных сообщений (scheduled messages).
 * Запускается каждую минуту и обрабатывает все scheduledMessages с
 * status='pending' и sendAt <= now.
 *
 * Для каждого: транзакционный claim (pending → sending), затем создание
 * реального сообщения в conversations/{id}/messages/{newId}. Существующий
 * onMessageCreated CF сам пошлёт push-уведомления — никаких изменений
 * в нотификациях не требуется.
 */
export const sendScheduledMessages = onSchedule(
  {
    schedule: "every 1 minutes",
    timeZone: "Europe/Moscow",
  },
  async () => {
    const nowIso = new Date().toISOString();

    let snap: admin.firestore.QuerySnapshot;
    try {
      snap = await db
        .collectionGroup("scheduledMessages")
        .where("status", "==", "pending")
        .where("sendAt", "<=", nowIso)
        .limit(SCHEDULED_MESSAGES_BATCH_LIMIT)
        .get();
    } catch (e) {
      logger.error("[sendScheduledMessages] query failed", { err: String(e) });
      return;
    }

    if (snap.empty) return;

    let publishedCount = 0;
    let failedCount = 0;

    for (const doc of snap.docs) {
      const conversationId = extractConversationIdFromScheduledPath(doc.ref.path);
      if (!conversationId) {
        logger.warn("[sendScheduledMessages] invalid path", { path: doc.ref.path });
        continue;
      }

      try {
        const claimed = await claimScheduledMessage(db, doc.ref);
        if (!claimed) continue;

        await publishScheduledMessage({
          db,
          schedDoc: doc,
          conversationId,
          nowIso,
        });
        publishedCount++;
      } catch (e) {
        failedCount++;
        logger.error("[sendScheduledMessages] publish failed", {
          path: doc.ref.path,
          err: String(e),
        });
        try {
          await doc.ref.update({
            status: "failed",
            failureReason: String(e).slice(0, 500),
            updatedAt: nowIso,
          });
        } catch (updateErr) {
          logger.error("[sendScheduledMessages] failed to mark failed", {
            path: doc.ref.path,
            err: String(updateErr),
          });
        }
      }
    }

    if (publishedCount > 0 || failedCount > 0) {
      logger.info("[sendScheduledMessages] processed batch", {
        publishedCount,
        failedCount,
        totalChecked: snap.docs.length,
      });
    }
  }
);
