import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { defineSecret } from "firebase-functions/params";
import { MulticastMessage } from "firebase-admin/messaging";
import { isApnsVoipConfigured, sendApnsVoipMulticast } from "../../lib/apns-voip";
import { apnsVoipConfigFromJsonSecret } from "../../lib/apns-voip-config-secret";
import { mergeNotificationSettings } from "../../lib/push-notification-policy";

const db = admin.firestore();
const messaging = admin.messaging();
/** Один JSON-секрет вместо пяти отдельных — проще первый деплой и меньше точек отказа GSM. */
const apnsVoipConfigSecret = defineSecret("APNS_VOIP_CONFIG");

const staleVoipReasons = new Set<string>([
  "baddevicetoken",
  "unregistered",
  "devicetokennotfortopic",
]);

function stringList(raw: unknown): string[] {
  if (!Array.isArray(raw)) return [];
  return raw
    .map((v) => (typeof v === "string" ? v.trim() : ""))
    .filter((v) => v.length > 0);
}

/**
 * Cloud Function that triggers when a new call document is created.
 * It sends high-priority push notifications to the receiver.
 */
export const oncallcreated = onDocumentCreated(
  {
    document: "calls/{callId}",
    secrets: [apnsVoipConfigSecret],
  },
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
    const isVideo = callData.isVideo === true;
    const callId = event.params.callId;

    if (!receiverId || !callerId) {
      logger.error("Call document is missing participants.", { callId });
      return;
    }

    // [audit M-006 / H-011] At-least-once delivery Cloud Functions v2: при
    // retry триггера второй VoIP-push на iOS = два инцидента CallKit (UX
    // проседает: телефон звонит дважды). Marker `pushDelivered/call_{callId}`
    // через .create() — атомарный: дубль ловится ALREADY_EXISTS.
    try {
      await db.doc(`pushDelivered/call_${callId}`).create({
        callId,
        callerId,
        receiverId,
        deliveredAt: admin.firestore.FieldValue.serverTimestamp(),
        // Поле для Firebase Console TTL-policy на `pushDelivered`.
        expireAt: admin.firestore.Timestamp.fromMillis(Date.now() + 7 * 24 * 60 * 60 * 1000),
      });
    } catch (e) {
      if (e instanceof Error && /already exists/i.test(e.message)) {
        logger.log("[oncallcreated] duplicate trigger — VoIP push already sent", { callId });
        return;
      }
      logger.warn("[oncallcreated] pushDelivered marker write failed", {
        callId,
        error: String(e),
      });
      // fail open
    }
    if (receiverId === callerId) {
      logger.warn("Call push skipped: receiverId equals callerId.", { callId, callerId });
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
      const ns = mergeNotificationSettings(userData?.notificationSettings);
      if (ns.muteAll) {
        logger.log("Call push skipped: receiver muteAll.", { receiverId });
        return;
      }

      const callerSnap = await db.doc(`users/${callerId}`).get();
      const callerData = callerSnap.exists ? callerSnap.data() : undefined;
      const callerTokenSet = new Set<string>(stringList(callerData?.fcmTokens));

      const fcmTokens = [
        ...new Set(stringList(userData?.fcmTokens).filter((t) => !callerTokenSet.has(t))),
      ];
      const voipTokens = [...new Set(stringList(userData?.voipTokens))];
      if (!fcmTokens.length && !voipTokens.length) {
        logger.log("Receiver has no call push tokens.", { receiverId });
        return;
      }

      if (fcmTokens.length > 0) {
        // 3. Construct FCM payload
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
            callerId: callerId,
            callerName: callerName,
            isVideo: isVideo ? "1" : "0",
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
          tokens: fcmTokens,
        };

        const response = await messaging.sendEachForMulticast(payload);
        logger.log("Call FCM notification sent.", {
          receiverId,
          callId,
          successCount: response.successCount,
          failureCount: response.failureCount,
        });
      }

      if (voipTokens.length > 0) {
        const apnsConfig = apnsVoipConfigFromJsonSecret(apnsVoipConfigSecret.value());
        if (!isApnsVoipConfigured(apnsConfig)) {
          logger.warn("APNs VoIP config is missing. Skipping VoIP push.", {
            receiverId,
            callId,
          });
        } else {
          const result = await sendApnsVoipMulticast({
            config: apnsConfig,
            tokens: voipTokens,
            payload: {
              callId,
              callerId,
              callerName,
              isVideo,
            },
          });
          logger.log("Call APNs VoIP push sent.", {
            receiverId,
            callId,
            successCount: result.successCount,
            failureCount: result.failureCount,
            useSandbox: apnsConfig.useSandbox,
          });

          const staleTokens = result.failures
            .filter((f) => staleVoipReasons.has(f.reason.trim().toLowerCase()))
            .map((f) => f.token);
          if (staleTokens.length > 0) {
            await db.doc(`users/${receiverId}`).set(
              {
                voipTokens: admin.firestore.FieldValue.arrayRemove(...staleTokens),
              },
              { merge: true }
            );
            logger.log("Removed stale VoIP tokens after APNs response.", {
              receiverId,
              removed: staleTokens.length,
            });
          }
        }
      }
    } catch (error) {
      logger.error("Error sending call notification.", { error, receiverId });
    }
  }
);
