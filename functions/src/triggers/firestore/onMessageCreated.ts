import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { senderListAvatarForPush } from "../../lib/push-sender-avatar";
import { buildDataPayload, evaluateChatMessagePush } from "../../lib/push-notification-policy";
import { sendDataMulticastGrouped } from "../../lib/fcm-send-data-batches";

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Cloud Function that triggers on the creation of a new message.
 * Учитывает notificationSettings и chatConversationPrefs получателя.
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

    const conversationRef = db.doc(`conversations/${conversationId}`);
    const conversationSnap = await conversationRef.get();
    if (!conversationSnap.exists) {
      logger.error("Conversation not found for message.", { conversationId });
      return;
    }
    const conversationData = conversationSnap.data();
    if (!conversationData) {
      logger.error("Conversation data is empty for message.", { conversationId });
      return;
    }
    const participantIds: string[] = conversationData.participantIds;

    const recipientIds = participantIds.filter((id) => id !== senderId);

    if (recipientIds.length === 0) {
      logger.log("No recipients to notify.", { conversationId });
      return;
    }

    const senderSnap = await db.doc(`users/${senderId}`).get();
    const senderDoc = senderSnap.exists ? senderSnap.data() : undefined;
    const senderName = senderDoc?.name ?? "Новое сообщение";
    const senderIcon = senderListAvatarForPush(senderDoc as Record<string, unknown> | undefined);

    let messageBody = "Вам сообщение";
    if (messageData.e2ee?.ciphertext) {
      if (messageData.attachments && messageData.attachments.length > 0) {
        messageBody = "Зашифрованное сообщение (вложение)";
      } else {
        messageBody = "Зашифрованное сообщение";
      }
    } else if (messageData.text) {
      messageBody = messageData.text.replace(/<[^>]*>/g, "");
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

    const noPreviewBody = "Новое сообщение";
    const link = `/dashboard/chat?conversationId=${conversationId}`;
    const now = new Date();

    const sendItems: Array<{ tokens: string[]; data: Record<string, string> }> = [];

    for (const userId of recipientIds) {
      try {
        const userSnap = await db.doc(`users/${userId}`).get();
        if (!userSnap.exists) continue;
        const userData = userSnap.data() as Record<string, unknown>;
        const tokens = (userData.fcmTokens as unknown[] | undefined)?.filter(
          (t): t is string => typeof t === "string" && t.length > 0
        );
        if (!tokens?.length) continue;

        const prefSnap = await db.doc(`users/${userId}/chatConversationPrefs/${conversationId}`).get();
        const chatPrefs = prefSnap.exists ? (prefSnap.data() as Record<string, unknown>) : undefined;

        const decision = evaluateChatMessagePush({
          userData,
          chatPrefs,
          plainBody: messageBody,
          noPreviewBody,
          now,
        });

        if (!decision.deliver) {
          continue;
        }

        const data = buildDataPayload({
          title: senderName,
          body: decision.body,
          link,
          tag: conversationId,
          icon: senderIcon,
          silent: decision.silent,
          conversationId,
        });

        sendItems.push({ tokens, data });
      } catch (e) {
        logger.error(`Error building push for recipient ${userId}`, e);
      }
    }

    if (sendItems.length === 0) {
      logger.log("No FCM payloads after notification policy.", { conversationId, recipientIds });
      return;
    }

    try {
      await sendDataMulticastGrouped(messaging, sendItems);
      logger.log(`Message push batches sent for conversation ${conversationId}`);
    } catch (error) {
      logger.error("Error sending message via FCM:", error);
    }
  },
);
