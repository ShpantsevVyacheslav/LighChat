import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { senderListAvatarForPush } from "../../lib/push-sender-avatar";
import { buildDataPayload, evaluateChatMessagePush } from "../../lib/push-notification-policy";
import { sendDataMulticastGrouped } from "../../lib/fcm-send-data-batches";
import { trySetMessageExpireAtForDisappearing } from "../../lib/disappearing-chat-messages";

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Push по новому комментарию в ветке — те же правила, что и для сообщений чата.
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
    const parentMessageId = event.params.messageId;

    const conversationRef = db.doc(`conversations/${conversationId}`);
    const conversationSnap = await conversationRef.get();
    if (!conversationSnap.exists) {
      logger.error("Conversation not found for thread message.", { conversationId });
      return;
    }
    const conversationData = conversationSnap.data();
    if (!conversationData) {
      logger.error("Conversation data is empty for thread message.", { conversationId });
      return;
    }

    await trySetMessageExpireAtForDisappearing({
      db,
      messageRef: messageSnapshot.ref,
      messageData: messageData as Record<string, unknown>,
      conversationData: conversationData as Record<string, unknown>,
      conversationId,
      messageId: event.params.threadMessageId,
    });

    const participantIds: string[] = conversationData.participantIds;

    const recipientIds = participantIds.filter((id) => id !== senderId);

    if (recipientIds.length === 0) {
      logger.log("No recipients to notify for thread message.", { conversationId });
      return;
    }

    const senderSnap = await db.doc(`users/${senderId}`).get();
    const senderDoc = senderSnap.exists ? senderSnap.data() : undefined;
    const senderName = senderDoc?.name ?? "Участник";
    const senderIcon = senderListAvatarForPush(senderDoc as Record<string, unknown> | undefined);
    const senderFcmTokenSet = new Set<string>(
      (senderDoc?.fcmTokens as unknown[] | undefined)?.filter(
        (t): t is string => typeof t === "string" && t.length > 0
      ) ?? []
    );

    let bodyPlain = (messageData.text || "Новый ответ в ветке").replace(/<[^>]*>/g, "");
    if (messageData.e2ee?.ciphertext) {
      if (messageData.attachments && messageData.attachments.length > 0) {
        bodyPlain = "Зашифрованный ответ (вложение)";
      } else {
        bodyPlain = "Зашифрованный ответ в ветке";
      }
    }

    const title = `${senderName} (комментарий)`;
    const noPreviewBody = "Новый комментарий в чате";
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
        )?.filter((t) => !senderFcmTokenSet.has(t));
        if (!tokens?.length) continue;

        const prefSnap = await db.doc(`users/${userId}/chatConversationPrefs/${conversationId}`).get();
        const chatPrefs = prefSnap.exists ? (prefSnap.data() as Record<string, unknown>) : undefined;

        const decision = evaluateChatMessagePush({
          userData,
          chatPrefs,
          plainBody: bodyPlain,
          noPreviewBody,
          now,
        });

        if (!decision.deliver) continue;

        const data = buildDataPayload({
          title,
          body: decision.body,
          link,
          tag: `thread-${parentMessageId}`,
          icon: senderIcon,
          silent: decision.silent,
          conversationId,
        });

        sendItems.push({ tokens, data });
      } catch (e) {
        logger.error(`Error building thread push for ${userId}`, e);
      }
    }

    if (sendItems.length === 0) {
      logger.log("No thread FCM payloads after policy.", { conversationId });
      return;
    }

    try {
      await sendDataMulticastGrouped(messaging, sendItems);
      logger.log(`Thread push batches sent for conversation ${conversationId}`);
    } catch (error) {
      logger.error("Error sending thread message via FCM:", error);
    }
  },
);
