import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { MulticastMessage } from "firebase-admin/messaging";

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Cloud Function that triggers when a new call document is created.
 * It sends high-priority push notifications to the receiver.
 */
export const oncallcreated = onDocumentCreated(
  "calls/{callId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      logger.log("No data in event for onCallCreated.");
      return;
    }

    const callData = snapshot.data();
    const callerId = callData.callerId;
    const receiverId = callData.receiverId;
    const callerName = callData.callerName || "Кто-то";
    const callId = event.params.callId;

    if (!receiverId || !callerId) {
      logger.error("Call document is missing participants.", { callId });
      return;
    }

    // 1. Update call history indices for both participants
    const batch = db.batch();
    const participants = [callerId, receiverId];

    participants.forEach((userId) => {
      const userCallIndexRef = db.doc(`userCalls/${userId}`);
      batch.set(
        userCallIndexRef,
        {
          callIds: admin.firestore.FieldValue.arrayUnion(callId),
        },
        { merge: true }
      );
    });

    try {
      await batch.commit();
      logger.log("Call indices successfully updated.", { callId, users: participants });
    } catch (error) {
      logger.error("Error updating call indices.", { error, callId });
    }

    // 2. Get receiver's FCM tokens
    try {
      const userSnap = await db.doc(`users/${receiverId}`).get();
      if (!userSnap.exists) {
        logger.error("Receiver user not found.", { receiverId });
        return;
      }

      const userData = userSnap.data();
      if (!userData?.fcmTokens || !Array.isArray(userData.fcmTokens) || userData.fcmTokens.length === 0) {
        logger.log("Receiver has no FCM tokens.", { receiverId });
        return;
      }

      const tokens = userData.fcmTokens.filter(Boolean);
      const uniqueTokens = [...new Set(tokens)];

      // 3. Construct notification payload
      const payload: MulticastMessage = {
        notification: {
          title: "Входящий вызов",
          body: `Вам звонит ${callerName}`,
        },
        data: {
          title: "Входящий вызов",
          body: `Вам звонит ${callerName}`,
          link: "/dashboard/chat",
          icon: "/pwa/icon-192.png",
          callId: callId,
        },
        android: {
          priority: "high",
          notification: {
            sound: "default",
            clickAction: "OPEN_CHAT_CALL",
            channelId: "calls",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              contentAvailable: true,
            },
          },
        },
        tokens: uniqueTokens,
      };

      // 4. Send notification
      const response = await messaging.sendEachForMulticast(payload);
      logger.log(`Call notification sent. Success: ${response.successCount}`);
    } catch (error) {
      logger.error("Error sending call notification.", { error, receiverId });
    }
  }
);
