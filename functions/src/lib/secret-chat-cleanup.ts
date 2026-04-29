import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

const db = admin.firestore();

/**
 * Fully removes a secret chat: indexes, secretChats metadata doc, Storage, recursive conversation delete.
 */
export async function cleanupSecretChatConversationFully(
  conversationId: string,
  convData: Record<string, unknown>,
): Promise<void> {
  const bucket = admin.storage().bucket();

  const rawParticipantIds = convData.participantIds;
  let participantIds: string[] = [];
  if (Array.isArray(rawParticipantIds)) {
    participantIds = rawParticipantIds.filter((x) => typeof x === "string") as string[];
  }

  const arrayRemove = admin.firestore.FieldValue.arrayRemove(conversationId);
  await Promise.all(
    participantIds.map(async (uid) => {
      try {
        await db.doc(`userSecretChats/${uid}`).set({ conversationIds: arrayRemove }, { merge: true });
      } catch (e) {
        logger.warn("[secret-chat-cleanup] userSecretChats update", { uid, conversationId, err: String(e) });
      }
      try {
        await db.doc(`userChats/${uid}`).set({ conversationIds: arrayRemove }, { merge: true });
      } catch (e) {
        logger.warn("[secret-chat-cleanup] userChats update", { uid, conversationId, err: String(e) });
      }
    }),
  );

  try {
    await db.doc(`secretChats/${conversationId}`).delete();
  } catch (e) {
    logger.warn("[secret-chat-cleanup] secretChats delete", { conversationId, err: String(e) });
  }

  const plainPrefix = `chat-attachments/${conversationId}/`;
  const encPrefix = `chat-attachments-enc/${conversationId}/`;
  try {
    await bucket.deleteFiles({ prefix: plainPrefix });
  } catch (e) {
    logger.warn("[secret-chat-cleanup] storage delete prefix", { prefix: plainPrefix, conversationId, err: String(e) });
  }
  try {
    await bucket.deleteFiles({ prefix: encPrefix });
  } catch (e) {
    logger.warn("[secret-chat-cleanup] storage delete prefix", { prefix: encPrefix, conversationId, err: String(e) });
  }

  await db.recursiveDelete(db.doc(`conversations/${conversationId}`));
}
