import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

const db = admin.firestore();

async function cleanupOneConversation(conversationId: string, convData: Record<string, unknown>): Promise<void> {
  const bucket = admin.storage().bucket();

  const rawParticipantIds = (convData as Record<string, unknown>).participantIds;
  let participantIds: string[] = [];
  if (Array.isArray(rawParticipantIds)) {
    participantIds = rawParticipantIds.filter((x) => typeof x === "string") as string[];
  }

  // 1) Remove from user chat indexes (best-effort; do not fail cleanup on one user).
  const arrayRemove = admin.firestore.FieldValue.arrayRemove(conversationId);
  await Promise.all(
    participantIds.map(async (uid) => {
      try {
        await db.doc(`userChats/${uid}`).set({ conversationIds: arrayRemove }, { merge: true });
      } catch (e) {
        logger.warn("[cleanupExpiredSecretChats] userChats update", { uid, conversationId, err: String(e) });
      }
    })
  );

  // 2) Delete Storage prefixes for both plaintext and E2EE media.
  const plainPrefix = `chat-attachments/${conversationId}/`;
  const encPrefix = `chat-attachments-enc/${conversationId}/`;
  try {
    await bucket.deleteFiles({ prefix: plainPrefix });
    logger.debug("[cleanupExpiredSecretChats] removed storage prefix", { prefix: plainPrefix, conversationId });
  } catch (e) {
    logger.warn("[cleanupExpiredSecretChats] storage delete prefix", { prefix: plainPrefix, conversationId, err: String(e) });
  }
  try {
    await bucket.deleteFiles({ prefix: encPrefix });
    logger.debug("[cleanupExpiredSecretChats] removed storage prefix", { prefix: encPrefix, conversationId });
  } catch (e) {
    logger.warn("[cleanupExpiredSecretChats] storage delete prefix", { prefix: encPrefix, conversationId, err: String(e) });
  }

  // 3) Delete Firestore conversation recursively (messages, members, typing, polls, e2eeSessions, secretAccess, etc.).
  await db.recursiveDelete(db.doc(`conversations/${conversationId}`));
}

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
        await cleanupOneConversation(doc.id, (doc.data() || {}) as Record<string, unknown>);
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

