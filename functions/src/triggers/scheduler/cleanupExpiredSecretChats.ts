import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { cleanupSecretChatConversationFully } from "../../lib/secret-chat-cleanup";

const db = admin.firestore();

/**
 * Scheduled cleanup for expired Secret Chats.
 *
 * Why scheduled cleanup (not Firestore TTL):
 * - Firestore TTL is per-document and does not cascade to subcollections.
 * - Secret chat must be fully removed (conversation + all subcollections + Storage).
 */
export const cleanupExpiredSecretChats = onSchedule({
  schedule: "every 5 minutes",
  timeZone: "Europe/Moscow",
}, async () => {
  const nowIso = new Date().toISOString();
  try {
    const snap = await db
      .collection("conversations")
      .where("secretChat.enabled", "==", true)
      .where("secretChat.expiresAt", "<=", nowIso)
      .limit(50)
      .get();

    if (snap.empty) return;

    let ok = 0;
    let failed = 0;
    for (const doc of snap.docs) {
      try {
        await cleanupSecretChatConversationFully(doc.id, (doc.data() || {}) as Record<string, unknown>);
        ok++;
      } catch (e) {
        failed++;
        logger.error("[cleanupExpiredSecretChats] failed conversation cleanup", {
          conversationId: doc.id,
          err: String(e),
        });
      }
    }

    logger.info("[cleanupExpiredSecretChats] done", { scanned: snap.size, ok, failed });
  } catch (e) {
    logger.error("[cleanupExpiredSecretChats] query failed", { err: String(e) });
  }
});
