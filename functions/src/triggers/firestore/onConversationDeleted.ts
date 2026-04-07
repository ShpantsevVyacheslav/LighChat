import { onDocumentDeleted } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { deleteAllMemberDocsForConversation } from "../../lib/sync-conversation-members";

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

  // Clean up userChats index
  const batch = db.batch();
  participantIds.forEach((userId: string) => {
    const userChatIndexRef = db.doc(`userChats/${userId}`);
    batch.update(userChatIndexRef, {
      conversationIds: admin.firestore.FieldValue.arrayRemove(conversationId),
    });
  });

  try {
    await batch.commit();
    logger.log(`Cleaned up userChats for conversation ${conversationId}`);
  } catch (error) {
    logger.error(`Error cleaning up userChats for conversation ${conversationId}`, error);
  }
});
