import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

const db = admin.firestore();

/**
 * Cloud Function that triggers when a call document is updated.
 * Creates system events in the conversation when call status changes to missed or cancelled.
 */
export const oncallupdated = onDocumentUpdated(
  { document: "calls/{callId}" },
  async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();

    if (!beforeData || !afterData) {
      logger.log("No data in event for onCallUpdated.");
      return;
    }

    const callId = event.params.callId;
    const beforeStatus = beforeData.status as string;
    const afterStatus = afterData.status as string;
    const callerId = afterData.callerId as string;
    const receiverId = afterData.receiverId as string;
    const isVideo = afterData.isVideo === true;

    // Only process if status changed to missed or cancelled
    if (beforeStatus === afterStatus) {
      return;
    }

    if (afterStatus !== "missed" && afterStatus !== "cancelled") {
      return;
    }

    if (!callerId || !receiverId) {
      logger.warn("Call is missing participants", { callId });
      return;
    }

    try {
      // Find direct conversation between caller and receiver
      const conversationSnapshot = await db
        .collection("conversations")
        .where("isGroup", "==", false)
        .where("participantIds", "array-contains", callerId)
        .get();

      let targetConversationId: string | null = null;

      for (const doc of conversationSnapshot.docs) {
        const data = doc.data();
        const participantIds = (data.participantIds as string[]) || [];
        // Check if this is a 1-on-1 chat with the receiver
        if (
          participantIds.length === 2 &&
          participantIds.includes(callerId) &&
          participantIds.includes(receiverId)
        ) {
          targetConversationId = doc.id;
          break;
        }
      }

      if (!targetConversationId) {
        logger.log(
          "No conversation found for call participants",
          { callId, callerId, receiverId }
        );
        return;
      }

      // Create system event message
      const messageId = db.collection("conversations").doc().id;
      const systemEventType = afterStatus === "missed" ? "call.missed" : "call.cancelled";

      const systemEvent = {
        type: systemEventType,
        data: {
          callId: callId,
          callerId: callerId,
          receiverId: receiverId,
          endedBy: (afterData.endedBy as string | undefined) ?? "",
          rawStatus: afterStatus,
          isVideo: isVideo,
        },
      };

      const chatMessage = {
        id: messageId,
        senderId: "__system__",
        systemEvent: systemEvent,
        createdAt: new Date().toISOString(),
        readAt: null,
      };

      await db
        .doc(`conversations/${targetConversationId}/messages/${messageId}`)
        .set(chatMessage);

      logger.log("System event created for call", {
        callId,
        conversationId: targetConversationId,
        eventType: systemEventType,
      });
    } catch (error) {
      logger.error("Error creating system event for call", {
        callId,
        error: String(error),
      });
    }
  }
);
