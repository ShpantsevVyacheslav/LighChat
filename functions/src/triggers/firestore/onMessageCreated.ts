import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { MulticastMessage } from "firebase-admin/messaging";

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Cloud Function that triggers on the creation of a new message.
 * It sends a push notification to the other participants of the conversation.
 * Uses 'data' only payload to prevent doubling in foreground.
 */
export const onmessagecreated = onDocumentCreated(
  "conversations/{conversationId}/messages/{messageId}",
  async (event) => {
    const messageSnapshot = event.data;
    if (!messageSnapshot) {
      logger.log("No data in event for onMessageCreated.");
      return;
    }

    const messageData = messageSnapshot.data();
    const senderId = messageData.senderId;
    const conversationId = event.params.conversationId;

    // 1. Get conversation to find participants
    const conversationRef = db.doc(`conversations/${conversationId}`);
    const conversationSnap = await conversationRef.get();
    if (!conversationSnap.exists) {
      logger.error("Conversation not found for message.", { conversationId });
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
      logger.log("No recipients to notify.", { conversationId });
      return;
    }

    // 2. Get sender's name
    const senderSnap = await db.doc(`users/${senderId}`).get();
    const senderName = senderSnap.exists ? senderSnap.data()?.name ?? "Новое сообщение" : "Новое сообщение";

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
      logger.log("No FCM tokens found for recipients.", { recipientIds });
      return;
    }
    const uniqueTokens = [...new Set(tokens)];

    // 4. Determine message body
    let messageBody = "Вам сообщение";
    if (messageData.text) {
      // Clean HTML tags for push notification
      messageBody = messageData.text.replace(/<[^>]*>/g, '');
    } else if (messageData.attachments && messageData.attachments.length > 0) {
      const firstAttachment = messageData.attachments[0];
      if (firstAttachment.type.startsWith("image/svg")) {
        messageBody = "Стикер";
      } else if (firstAttachment.type.startsWith("image/")) {
        messageBody = "Изображение";
      } else if (firstAttachment.type.startsWith("video/")) {
        messageBody = "Видео";
      } else if (firstAttachment.type.startsWith("audio/")) {
        messageBody = "Аудиосообщение";
      } else {
        messageBody = "Вложение";
      }
    }

    // 5. Construct notification payload
    // IMPORTANT: No 'notification' block here to prevent browser doubling in foreground.
    // The Service Worker handles showing the notification if the app is backgrounded.
    const message: MulticastMessage = {
      data: {
        title: senderName,
        body: messageBody,
        link: `/dashboard/chat?conversationId=${conversationId}`,
        icon: "/pwa/icon-192.png",
        tag: conversationId,
      },
      tokens: uniqueTokens,
    };

    // 6. Send notification
    try {
      const response = await messaging.sendEachForMulticast(message);
      logger.log(`Successfully sent ${response.successCount} messages for conversation ${conversationId}`);
    } catch (error) {
      logger.error("Error sending message via FCM:", error);
    }
  },
);