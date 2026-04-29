import { onDocumentDeleted } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { deleteAllMemberDocsForConversation } from "../../lib/sync-conversation-members";
import { isSecretConversation } from "../../lib/secret-chat-index";

const db = admin.firestore();

/**
 * Cloud Function that triggers on the deletion of a conversation document.
 * It cleans up the userChats index for all participants.
 * Notification sending was removed to comply with worker role restrictions.
 */
export const onconversationdeleted = onDocumentDeleted("conversations/{conversationId}", async (event) => {
  const deletedConversation = event.data?.data();
  const conversationId = event.params.conversationId;

  if (!deletedConversation) {
    logger.log(`Conversation document data not available for deleted conversation ${conversationId}`);
    return;
  }

  const { participantIds } = deletedConversation;

  try {
    await deleteAllMemberDocsForConversation(conversationId);
    logger.log(`Deleted member docs for conversation ${conversationId}`);
  } catch (error) {
    logger.error(`Error deleting member docs for ${conversationId}`, error);
  }

  if (!participantIds || !Array.isArray(participantIds) || participantIds.length === 0) {
    logger.log(`No participants found for deleted conversation ${conversationId}`);
    return;
  }

  const secret = isSecretConversation(conversationId, deletedConversation as Record<string, unknown>);
  const batch = db.batch();

  participantIds.forEach((userId: string) => {
    if (secret) {
      batch.set(
        db.doc(`userSecretChats/${userId}`),
        { conversationIds: admin.firestore.FieldValue.arrayRemove(conversationId) },
        { merge: true },
      );
      batch.set(
        db.doc(`userChats/${userId}`),
        { conversationIds: admin.firestore.FieldValue.arrayRemove(conversationId) },
        { merge: true },
      );
    } else {
      batch.update(db.doc(`userChats/${userId}`), {
        conversationIds: admin.firestore.FieldValue.arrayRemove(conversationId),
      });
    }
  });

  if (secret) {
    batch.delete(db.doc(`secretChats/${conversationId}`));
  }

  try {
    await batch.commit();
    logger.log(`Cleaned up chat indices for conversation ${conversationId} (secret=${secret})`);
  } catch (error) {
    logger.error(`Error cleaning up indices for conversation ${conversationId}`, error);
  }
});
