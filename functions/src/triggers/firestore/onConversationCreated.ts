import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import {
  participantIdsFromConversationData,
  setMemberDocsForConversation,
} from "../../lib/sync-conversation-members";
import { isSecretConversation } from "../../lib/secret-chat-index";
import { buildDataPayload, evaluateSimpleNotificationPush } from "../../lib/push-notification-policy";
import { sendDataMulticastGrouped } from "../../lib/fcm-send-data-batches";

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

    const secret = isSecretConversation(conversationId, conversationData as Record<string, unknown>);

    const batch = db.batch();

    if (secret) {
      const sc = (conversationData.secretChat ?? {}) as Record<string, unknown>;
      batch.set(
        db.doc(`secretChats/${conversationId}`),
        {
          conversationId,
          participantIds,
          createdAt: typeof sc.createdAt === "string" ? sc.createdAt : admin.firestore.FieldValue.serverTimestamp(),
          expiresAt: typeof sc.expiresAt === "string" ? sc.expiresAt : null,
          ttlPresetSec: typeof sc.ttlPresetSec === "number" ? sc.ttlPresetSec : null,
        },
        { merge: true },
      );
      participantIds.forEach((userId) => {
        batch.set(
          db.doc(`userSecretChats/${userId}`),
          {
            conversationIds: admin.firestore.FieldValue.arrayUnion(conversationId),
          },
          { merge: true },
        );
      });
    } else {
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
    }

    try {
      await batch.commit();
      logger.log(secret ? "Secret chat indices (userSecretChats + secretChats) updated." : "Chat indices successfully updated.");
    } catch (error) {
      logger.error("Error updating chat indices.", error);
    }

    // 2. Send "Added to group" notification for group chats
    if (conversationData.isGroup) {
      const creatorId = conversationData.createdByUserId;
      const groupName = conversationData.name || "Групповой чат";
      const recipientIds = participantIds.filter(id => id !== creatorId);

      if (recipientIds.length > 0) {
        const now = new Date();
        const plainBody = `Вы стали участником группы "${groupName}"`;
        const noPreviewBody = "Вас добавили в группу";
        const link = `/dashboard/chat?conversationId=${conversationId}`;
        const sendItems: Array<{ tokens: string[]; data: Record<string, string> }> = [];

        for (const userId of recipientIds) {
          const userSnap = await db.doc(`users/${userId}`).get();
          if (!userSnap.exists) continue;
          const userData = userSnap.data() as Record<string, unknown>;
          const tokens = (userData.fcmTokens as unknown[] | undefined)?.filter(
            (t): t is string => typeof t === "string" && t.length > 0
          );
          if (!tokens?.length) continue;

          const decision = evaluateSimpleNotificationPush({
            userData,
            plainBody,
            noPreviewBody,
            now,
          });
          if (!decision.deliver) continue;

          const data = buildDataPayload({
            title: "Вас добавили в группу",
            body: decision.body,
            link,
            tag: `group-add-${conversationId}`,
            icon: "/pwa/icon-192.png",
            silent: decision.silent,
            conversationId,
          });
          sendItems.push({ tokens, data });
        }

        if (sendItems.length > 0) {
          try {
            await sendDataMulticastGrouped(messaging, sendItems);
            logger.log(`Group addition notifications sent (${sendItems.length} payload group(s)).`);
          } catch (error) {
            logger.error("Error sending group addition notifications:", error);
          }
        }
      }
    }
  },
);
