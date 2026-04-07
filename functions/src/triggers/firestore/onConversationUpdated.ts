import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { MulticastMessage } from "firebase-admin/messaging";
import {
  participantIdsFromConversationData,
  syncMemberDocsForConversation,
} from "../../lib/sync-conversation-members";

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
      const tokens: string[] = [];

      for (const userId of addedParticipantIds) {
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
          await messaging.sendEachForMulticast(message);
          logger.log(`Sent "Added to group" notifications to ${addedParticipantIds.length} new users.`);
        } catch (error) {
          logger.error("Error sending notifications for new group members:", error);
        }
      }
    }
  }
});
