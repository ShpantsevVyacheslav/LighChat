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
 * [audit M-012] Безопасное приведение HTML-сообщения к plaintext'у для push.
 * Раньше использовался `text.replace(/<[^>]*>/g, "")` — не декодировал
 * entities (`Hello &amp; world` уходил в push как есть). Push body на iOS/
 * Android отображается как plaintext, так что XSS не было; но UX был
 * грязный. Этот хелпер чистит теги и декодирует наиболее частые HTML
 * entities. Не использует `dompurify` — JSDOM heavyweight для Cloud
 * Functions cold start.
 */
function htmlToPlainTextForPush(html: string): string {
  if (!html) return "";
  const stripped = html.replace(/<[^>]*>/g, "");
  return stripped
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, "\"")
    .replace(/&#x27;|&#39;|&apos;/g, "'")
    .replace(/&nbsp;/g, " ")
    .replace(/&#x([0-9a-fA-F]+);/g, (_m, hex: string) =>
      String.fromCodePoint(parseInt(hex, 16)))
    .replace(/&#(\d+);/g, (_m, dec: string) => String.fromCodePoint(parseInt(dec, 10)))
    .slice(0, 200);
}

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
    const messageId = event.params.messageId;

    // [audit H-006] System-сообщения (game lobby события и пр.) не шлются
    // push'ами и не должны тащить N+1 чтения recipient'ов. Ранний exit
    // экономит per-message ~200 reads на групповых чатах.
    if (senderId === "__system__" || messageData.systemEvent != null) {
      return;
    }

    // [audit H-011] Cloud Functions v2 имеет at-least-once delivery: при
    // retry триггера вторая отправка push дублирует уведомление (на iOS
    // APNs тег `tag: conversationId` не дедуплицирует до доставки).
    // Marker-doc `pushDelivered/{messageId}` через .create() — атомарный:
    // вторая попытка получает ALREADY_EXISTS → ранний return.
    try {
      await db.doc(`pushDelivered/${messageId}`).create({
        conversationId,
        senderId,
        deliveredAt: admin.firestore.FieldValue.serverTimestamp(),
        // Поле для Firebase Console TTL-policy: настроить
        // `pushDelivered.expireAt` → авточистка за 7 дней.
        expireAt: admin.firestore.Timestamp.fromMillis(Date.now() + 7 * 24 * 60 * 60 * 1000),
      });
    } catch (e) {
      if (e instanceof Error && /already exists/i.test(e.message)) {
        logger.log("[onmessagecreated] duplicate trigger — push already sent", {
          messageId,
          conversationId,
        });
        return;
      }
      logger.warn("[onmessagecreated] pushDelivered marker write failed", {
        messageId,
        error: String(e),
      });
      // Не блокируем доставку push — fail open (лучше дубль, чем потеря).
    }

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

    await trySetMessageExpireAtForDisappearing({
      db,
      messageRef: messageSnapshot.ref,
      messageData: messageData as Record<string, unknown>,
      conversationData: conversationData as Record<string, unknown>,
      conversationId,
      messageId: event.params.messageId,
    });

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
    const senderFcmTokenSet = new Set<string>(
      (senderDoc?.fcmTokens as unknown[] | undefined)?.filter(
        (t): t is string => typeof t === "string" && t.length > 0
      ) ?? []
    );

    let messageBody = "Вам сообщение";
    if (messageData.e2ee?.ciphertext) {
      if (messageData.attachments && messageData.attachments.length > 0) {
        messageBody = "Зашифрованное сообщение (вложение)";
      } else {
        messageBody = "Зашифрованное сообщение";
      }
    } else if (messageData.text) {
      messageBody = htmlToPlainTextForPush(messageData.text);
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

    // [audit H-006] Раньше per-recipient делалось 2 await get'а
    // (`users/{uid}` + `chatConversationPrefs/{convId}`) последовательно —
    // на 100-членной группе это 200 reads + 200 round-trip latency.
    // Сейчас один `db.getAll(...)` достаёт всё параллельно: и для бюджета
    // (Firestore не тарифицирует getAll отдельно от обычных reads, но
    // single-RPC намного быстрее), и для p99-latency триггера.
    const userRefs = recipientIds.map((uid) => db.doc(`users/${uid}`));
    const prefRefs = recipientIds.map((uid) =>
      db.doc(`users/${uid}/chatConversationPrefs/${conversationId}`)
    );
    let allSnaps: admin.firestore.DocumentSnapshot[];
    try {
      allSnaps = await db.getAll(...userRefs, ...prefRefs);
    } catch (e) {
      logger.error(`onMessageCreated: getAll recipients failed`, { conversationId, error: String(e) });
      return;
    }
    const userSnaps = allSnaps.slice(0, recipientIds.length);
    const prefSnaps = allSnaps.slice(recipientIds.length);

    for (let i = 0; i < recipientIds.length; i++) {
      const userId = recipientIds[i];
      try {
        const userSnap = userSnaps[i];
        if (!userSnap.exists) continue;
        const userData = userSnap.data() as Record<string, unknown>;
        const tokens = (userData.fcmTokens as unknown[] | undefined)?.filter(
          (t): t is string => typeof t === "string" && t.length > 0
        )?.filter((t) => !senderFcmTokenSet.has(t));
        if (!tokens?.length) continue;

        const prefSnap = prefSnaps[i];
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
