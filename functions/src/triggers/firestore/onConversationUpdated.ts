import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import {
  participantIdsFromConversationData,
  syncMemberDocsForConversation,
} from "../../lib/sync-conversation-members";
import { buildDataPayload, evaluateSimpleNotificationPush } from "../../lib/push-notification-policy";
import { sendDataMulticastGrouped } from "../../lib/fcm-send-data-batches";

const db = admin.firestore();
const messaging = admin.messaging();

export const onconversationupdated = onDocumentUpdated("conversations/{conversationId}", async (event) => {
  const beforeData = event.data?.before.data();
  const afterData = event.data?.after.data();

  if (!beforeData || !afterData) {
    logger.log("No data in event for onConversationUpdated.");
    return;
  }

  const beforeParticipantIds = participantIdsFromConversationData(beforeData);
  const afterParticipantIds = participantIdsFromConversationData(afterData);

  const conversationId = event.params.conversationId;

  const participantsKey = (ids: string[]) => [...ids].sort().join("\0");
  if (participantsKey(beforeParticipantIds) !== participantsKey(afterParticipantIds)) {
    try {
      await syncMemberDocsForConversation(conversationId, afterParticipantIds);
      logger.log(`Synced member docs for conversation ${conversationId}.`);
    } catch (error) {
      logger.error("Error syncing conversation member docs.", error);
    }
  }

  // 1. Handle removed participants
  const removedParticipantIds = beforeParticipantIds.filter((id) => !afterParticipantIds.includes(id));
  if (removedParticipantIds.length > 0) {
    const batch = db.batch();
    removedParticipantIds.forEach((userId) => {
      const userChatIndexRef = db.doc(`userChats/${userId}`);
      batch.update(userChatIndexRef, {
        conversationIds: admin.firestore.FieldValue.arrayRemove(conversationId),
      });
    });
    try {
      await batch.commit();
      logger.log(`Removed conversation ${conversationId} from indices for removed users.`);
    } catch (error) {
      logger.error("Error updating userChats for removed participants.", error);
    }
  }

  // 2. Handle newly added participants (add to index and send notification)
  const addedParticipantIds = afterParticipantIds.filter((id) => !beforeParticipantIds.includes(id));
  if (addedParticipantIds.length > 0) {
    const batch = db.batch();
    addedParticipantIds.forEach((userId) => {
      const userChatIndexRef = db.doc(`userChats/${userId}`);
      batch.set(userChatIndexRef, {
        conversationIds: admin.firestore.FieldValue.arrayUnion(conversationId),
      }, { merge: true });
    });
    
    try {
      await batch.commit();
      logger.log(`Added conversation ${conversationId} to indices for ${addedParticipantIds.length} new users.`);
    } catch (error) {
      logger.error("Error updating userChats for added participants.", error);
    }

    if (afterData.isGroup) {
      const groupName = afterData.name || "Групповой чат";
      const now = new Date();
      const plainBody = `Вы стали участником группы "${groupName}"`;
      const noPreviewBody = "Вас добавили в группу";
      const link = `/dashboard/chat?conversationId=${conversationId}`;
      const sendItems: Array<{ tokens: string[]; data: Record<string, string> }> = [];

      for (const userId of addedParticipantIds) {
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
        });
        sendItems.push({ tokens, data });
      }

      if (sendItems.length > 0) {
        try {
          await sendDataMulticastGrouped(messaging, sendItems);
          logger.log(`Sent "Added to group" notifications (${sendItems.length} payload group(s)).`);
        } catch (error) {
          logger.error("Error sending notifications for new group members:", error);
        }
      }
    }
  }
});
