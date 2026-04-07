import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { MulticastMessage } from "firebase-admin/messaging";

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Cloud Function that triggers on the creation of a new thread message (comment).
 * It sends a push notification to other participants of the conversation.
 */
export const onthreadmessagecreated = onDocumentCreated(
  "conversations/{conversationId}/messages/{messageId}/thread/{threadMessageId}",
  async (event) => {
    const messageSnapshot = event.data;
    if (!messageSnapshot) {
      logger.log("No data in event for onThreadMessageCreated.");
      return;
    }

    const messageData = messageSnapshot.data();
    const senderId = messageData.senderId;
    const conversationId = event.params.conversationId;

    // 1. Get conversation to find participants
    const conversationRef = db.doc(`conversations/${conversationId}`);
    const conversationSnap = await conversationRef.get();
    if (!conversationSnap.exists) {
      logger.error("Conversation not found for thread message.", { conversationId });
      return;
    }
    const conversationData = conversationSnap.data();
    if (!conversationData) {
      logger.error("Conversation data is empty.", { conversationId });
      return;
    }
    const participantIds: string[] = conversationData.participantIds;
    
    // Filter out the sender
    const recipientIds = participantIds.filter((id) => id !== senderId);

    if (recipientIds.length === 0) {
      logger.log("No recipients to notify for thread message.", { conversationId });
      return;
    }

    // 2. Get sender's name
    const senderSnap = await db.doc(`users/${senderId}`).get();
    const senderName = senderSnap.exists ? senderSnap.data()?.name ?? "Новый комментарий" : "Новый комментарий";

    // 3. Get recipients' FCM tokens
    const tokens: string[] = [];
    for (const userId of recipientIds) {
      try {
        const userSnap = await db.doc(`users/${userId}`).get();
        if (userSnap.exists) {
          const userData = userSnap.data();
          if (userData?.fcmTokens && Array.isArray(userData.fcmTokens)) {
            tokens.push(...userData.fcmTokens.filter(Boolean));
          }
        }
      } catch (e) {
        logger.error(`Error fetching user tokens for user ${userId}`, e);
      }
    }

    if (tokens.length === 0) {
      logger.log("No FCM tokens found for thread message recipients.", { recipientIds });
      return;
    }
    const uniqueTokens = [...new Set(tokens)];

    // 4. Construct notification payload
    const message: MulticastMessage = {
      data: {
        title: `${senderName} (комментарий)`,
        body: (messageData.text || "Новый ответ в ветке").replace(/<[^>]*>/g, ''),
        link: `/dashboard/chat?conversationId=${conversationId}`,
        icon: "/pwa/icon-192.png",
        tag: `thread-${event.params.messageId}`,
      },
      tokens: uniqueTokens,
    };

    // 5. Send notification
    try {
      const response = await messaging.sendEachForMulticast(message);
      logger.log(`Successfully sent ${response.successCount} thread notifications for conversation ${conversationId}`);
    } catch (error) {
      logger.error("Error sending thread message via FCM:", error);
    }
  },
);