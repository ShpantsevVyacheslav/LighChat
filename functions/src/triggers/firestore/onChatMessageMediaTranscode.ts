import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import { transcodeChatMessageAttachments } from "../../lib/chat-media-transcode";

const opts = {
  timeoutSeconds: 540,
  memory: "2GiB" as const,
  cpu: 2,
};

/**
 * Нормализация медиа вложений основного чата: WebM/MOV/… → MP4 (H.264+AAC),
 * аудио (кроме mp3/m4a) → M4A (AAC). Обновляет attachments[] на месте.
 */
export const onchatmessagemediatranscode = onDocumentCreated(
  {
    document: "conversations/{conversationId}/messages/{messageId}",
    ...opts,
  },
  async (event) => {
    const snap = event.data;
    if (!snap) {
      logger.log("onchatmessagemediatranscode: no snapshot");
      return;
    }
    const conversationId = event.params.conversationId;
    const ref = snap.ref;
    try {
      await transcodeChatMessageAttachments(ref, snap.data(), conversationId);
    } catch (e) {
      logger.error("onchatmessagemediatranscode failed", {
        conversationId,
        messageId: event.params.messageId,
        err: e instanceof Error ? e.message : String(e),
      });
    }
  }
);

export const onchatthreadmessagemediatranscode = onDocumentCreated(
  {
    document: "conversations/{conversationId}/messages/{parentMessageId}/thread/{messageId}",
    ...opts,
  },
  async (event) => {
    const snap = event.data;
    if (!snap) {
      logger.log("onchatthreadmessagemediatranscode: no snapshot");
      return;
    }
    const conversationId = event.params.conversationId;
    const ref = snap.ref;
    try {
      await transcodeChatMessageAttachments(ref, snap.data(), conversationId);
    } catch (e) {
      logger.error("onchatthreadmessagemediatranscode failed", {
        conversationId,
        parentMessageId: event.params.parentMessageId,
        messageId: event.params.messageId,
        err: e instanceof Error ? e.message : String(e),
      });
    }
  }
);
