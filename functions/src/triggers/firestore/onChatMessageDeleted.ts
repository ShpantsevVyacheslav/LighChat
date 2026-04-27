import { onDocumentDeleted } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { handleChatMessageDeleted } from "../../lib/chat-message-deleted-cleanup";

const db = admin.firestore();

export const onchatmessagedeleted = onDocumentDeleted(
  "conversations/{conversationId}/messages/{messageId}",
  async (event) => {
    try {
      const snap = event.data;
      const data = snap?.data() as Record<string, unknown> | undefined;
      await handleChatMessageDeleted({
        db,
        conversationId: event.params.conversationId,
        deletedDocId: event.params.messageId,
        deletedData: data,
        kind: "main",
      });
    } catch (e) {
      logger.error("[onchatmessagedeleted] failed", { err: String(e) });
    }
  },
);

export const onchatthreadmessagedeleted = onDocumentDeleted(
  "conversations/{conversationId}/messages/{messageId}/thread/{threadMessageId}",
  async (event) => {
    try {
      const snap = event.data;
      const data = snap?.data() as Record<string, unknown> | undefined;
      await handleChatMessageDeleted({
        db,
        conversationId: event.params.conversationId,
        deletedDocId: event.params.threadMessageId,
        deletedData: data,
        kind: "thread",
        parentMessageId: event.params.messageId,
      });
    } catch (e) {
      logger.error("[onchatthreadmessagedeleted] failed", { err: String(e) });
    }
  },
);
