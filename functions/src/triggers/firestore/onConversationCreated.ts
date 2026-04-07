import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { MulticastMessage } from "firebase-admin/messaging";
import {
  participantIdsFromConversationData,
  setMemberDocsForConversation,
} from "../../lib/sync-conversation-members";

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Cloud Function that triggers on the creation of a new document in the
 * /conversations collection. Its purpose is to update the /userChats/{userId}
 * index documents for each participant in the new chat and send "added to group" notifications.
 */
export const onconversationcreated = onDocumentCreated(
  "conversations/{conversationId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.log("No data in event for onConversationCreated.");
      return;
    }

    const conversationData = snapshot.data();
    const conversationId = event.params.conversationId;

    const participantIds = participantIdsFromConversationData(conversationData);
    if (participantIds.length === 0) {
      logger.log(
        "Conversation document is missing participantIds.",
        { conversationId: conversationId },
      );
      return;
    }

    try {
      await setMemberDocsForConversation(conversationId, participantIds);
      logger.log(`Member index docs created for conversation ${conversationId}.`);
    } catch (error) {
      logger.error("Error creating conversation member docs.", error);
    }

    const batch = db.batch();

    // 1. Update user indices
    participantIds.forEach((userId) => {
      const userChatIndexRef = db.doc(`userChats/${userId}`);
      batch.set(
        userChatIndexRef,
        {
          conversationIds: admin.firestore.FieldValue.arrayUnion(
            conversationId,
          ),
        },
        { merge: true },
      );
    });

    try {
      await batch.commit();
      logger.log("Chat indices successfully updated.");
    } catch (error) {
      logger.error("Error updating chat indices.", error);
    }

    // 2. Send "Added to group" notification for group chats
    if (conversationData.isGroup) {
      const creatorId = conversationData.createdByUserId;
      const groupName = conversationData.name || "Групповой чат";
      const recipientIds = participantIds.filter(id => id !== creatorId);

      if (recipientIds.length > 0) {
        const tokens: string[] = [];
        for (const userId of recipientIds) {
          const userSnap = await db.doc(`users/${userId}`).get();
          const userData = userSnap.data();
          if (userData && Array.isArray(userData.fcmTokens)) {
            const validTokens = userData.fcmTokens.filter((t): t is string => typeof t === 'string' && t.length > 0);
            tokens.push(...validTokens);
          }
        }

        if (tokens.length > 0) {
          const uniqueTokens = [...new Set(tokens)];
          const message: MulticastMessage = {
            data: {
              title: "Вас добавили в группу",
              body: `Вы стали участником группы "${groupName}"`,
              link: `/dashboard/chat?conversationId=${conversationId}`,
              icon: "/pwa/icon-192.png",
            },
            tokens: uniqueTokens,
          };

          try {
            const response = await messaging.sendEachForMulticast(message);
            logger.log(`Group addition notifications sent. Success: ${response.successCount}`);
          } catch (error) {
            logger.error("Error sending group addition notifications:", error);
          }
        }
      }
    }
  },
);
