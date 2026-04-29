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
    const metaSnap = await db
      .collection("secretChats")
      .where("expiresAt", "<=", nowIso)
      .limit(50)
      .get();

    if (metaSnap.empty) {
      logger.info("[cleanupExpiredSecretChats] no expired secret chats", {
        scanned: 0,
        ok: 0,
        failed: 0,
        nowIso,
      });
      return;
    }

    let ok = 0;
    let failed = 0;
    for (const metaDoc of metaSnap.docs) {
      const conversationId = metaDoc.id;
      try {
        const convSnap = await db.doc(`conversations/${conversationId}`).get();
        if (!convSnap.exists) {
          // Index/meta can remain after partial failures from older versions.
          await db.doc(`secretChats/${conversationId}`).delete();
          ok++;
          continue;
        }
        await cleanupSecretChatConversationFully(
          conversationId,
          (convSnap.data() || {}) as Record<string, unknown>,
        );
        ok++;
      } catch (e) {
        failed++;
        logger.error("[cleanupExpiredSecretChats] failed conversation cleanup", {
          conversationId,
          err: String(e),
        });
      }
    }

    logger.info("[cleanupExpiredSecretChats] done", { scanned: metaSnap.size, ok, failed });
  } catch (e) {
    logger.error("[cleanupExpiredSecretChats] query failed", { err: String(e) });
  }
});
