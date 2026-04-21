import { onCall, HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { transcodeChatMessageAttachments } from "../../lib/chat-media-transcode";

type RetryChatMediaTranscodeRequest = {
  conversationId: string;
  messageId: string;
  isThread?: boolean;
  parentMessageId?: string;
};

type RetryChatMediaTranscodeResponse = {
  ok: boolean;
};

export const retryChatMediaTranscode = onCall(
  { region: "us-central1", timeoutSeconds: 540, memory: "2GiB", cpu: 2 },
  async (
    request: CallableRequest<RetryChatMediaTranscodeRequest>
  ): Promise<RetryChatMediaTranscodeResponse> => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Требуется вход.");
    }

    const conversationId = `${request.data?.conversationId ?? ""}`.trim();
    const messageId = `${request.data?.messageId ?? ""}`.trim();
    const isThread = request.data?.isThread === true;
    const parentMessageId = `${request.data?.parentMessageId ?? ""}`.trim();

    if (!conversationId || !messageId) {
      throw new HttpsError("invalid-argument", "conversationId и messageId обязательны.");
    }
    if (isThread && !parentMessageId) {
      throw new HttpsError("invalid-argument", "Для thread нужен parentMessageId.");
    }

    const db = admin.firestore();
    const uid = request.auth.uid;

    const convRef = db.collection("conversations").doc(conversationId);
    const convSnap = await convRef.get();
    if (!convSnap.exists) {
      throw new HttpsError("not-found", "Чат не найден.");
    }
    const participantIds = convSnap.data()?.participantIds;
    if (!Array.isArray(participantIds) || !participantIds.includes(uid)) {
      throw new HttpsError("permission-denied", "Нет доступа к этому чату.");
    }

    const messageRef = !isThread ?
      convRef.collection("messages").doc(messageId) :
      convRef.collection("messages").doc(parentMessageId).collection("thread").doc(messageId);

    const messageSnap = await messageRef.get();
    if (!messageSnap.exists) {
      throw new HttpsError("not-found", "Сообщение не найдено.");
    }

    try {
      await transcodeChatMessageAttachments(
        messageRef as admin.firestore.DocumentReference,
        messageSnap.data() ?? {},
        conversationId,
        { forcePendingWrite: true }
      );
      return { ok: true };
    } catch (e) {
      logger.error("retryChatMediaTranscode failed", {
        conversationId,
        messageId,
        isThread,
        parentMessageId: isThread ? parentMessageId : undefined,
        err: e instanceof Error ? e.message : String(e),
      });
      throw new HttpsError("internal", "Не удалось повторно обработать медиа.");
    }
  }
);
