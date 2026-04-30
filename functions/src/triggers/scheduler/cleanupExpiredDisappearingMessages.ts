import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import {
  deleteExpiredDisappearingMessagesBatch,
  isConversationMessageDocPath,
  isConversationThreadMessageDocPath,
} from "../../lib/expired-disappearing-messages-cleanup";

const db = admin.firestore();

/**
 * Bounded fallback for disappearing messages.
 *
 * Firestore TTL remains the canonical physical deletion mechanism, but TTL is
 * intentionally delayed. This scheduler removes expired chat messages promptly
 * and lets existing onDelete triggers clean pins, lastMessage* and Storage.
 */
export const cleanupExpiredDisappearingMessages = onSchedule({
  schedule: "every 1 minutes",
  timeZone: "Europe/Moscow",
}, async () => {
  const now = admin.firestore.Timestamp.now();
  try {
    const [mainDeleted, threadDeleted] = await Promise.all([
      deleteExpiredDisappearingMessagesBatch({
        db,
        now,
        collectionGroupId: "messages",
        pathGuard: isConversationMessageDocPath,
      }),
      deleteExpiredDisappearingMessagesBatch({
        db,
        now,
        collectionGroupId: "thread",
        pathGuard: isConversationThreadMessageDocPath,
      }),
    ]);

    if (mainDeleted > 0 || threadDeleted > 0) {
      logger.info("[cleanupExpiredDisappearingMessages] deleted expired messages", {
        mainDeleted,
        threadDeleted,
      });
    }
  } catch (e) {
    logger.error("[cleanupExpiredDisappearingMessages] cleanup failed", { err: String(e) });
  }
});
