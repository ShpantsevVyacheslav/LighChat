import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import type { DocumentReference } from "firebase-admin/firestore";
import { deleteChatMessageStorageObjects } from "./chat-message-deleted-storage";

const E2EE_PREVIEW = "Зашифрованное сообщение";

function createdAtComparable(data: Record<string, unknown>): string {
  const c = data.createdAt;
  if (typeof c === "string") return c;
  if (
    c &&
    typeof c === "object" &&
    "toDate" in c &&
    typeof (c as { toDate: () => Date }).toDate === "function"
  ) {
    return (c as { toDate: () => Date }).toDate().toISOString();
  }
  return "";
}

function lastPreviewFromMessageData(d: Record<string, unknown>): { text: string; senderId: string } {
  let text = "Сообщение";
  const e2ee = d.e2ee as { ciphertext?: string; attachments?: unknown[] } | undefined;
  if (e2ee?.ciphertext) {
    if (e2ee.attachments && e2ee.attachments.length > 0) {
      text = "Зашифрованное сообщение (вложение)";
    } else {
      text = E2EE_PREVIEW;
    }
  } else if (typeof d.text === "string" && d.text.trim()) {
    text = d.text.replace(/<[^>]*>/g, "").slice(0, 100);
  } else if (Array.isArray(d.attachments) && d.attachments.length > 0) {
    const first = d.attachments[0] as { type?: string };
    const t = first?.type || "";
    if (t.startsWith("image/svg")) text = "Стикер";
    else if (t.startsWith("image/")) text = "Изображение";
    else if (t.startsWith("video/")) text = "Видео";
    else if (t.startsWith("audio/")) text = "Аудиосообщение";
    else text = "Вложение";
  }
  const senderId = typeof d.senderId === "string" ? d.senderId : "";
  return { text, senderId };
}

async function removePinsForMessageId(convRef: DocumentReference, conv: Record<string, unknown>, messageId: string) {
  const pins = conv.pinnedMessages;
  if (Array.isArray(pins)) {
    const next = pins.filter((p: { messageId?: string }) => p?.messageId !== messageId);
    if (next.length !== pins.length) {
      await convRef.update({
        pinnedMessages: next.length ? next : admin.firestore.FieldValue.delete(),
        pinnedMessage: admin.firestore.FieldValue.delete(),
      });
      logger.log("[disappearing] removed pinned reference", { path: convRef.path, messageId });
    }
  }
  const legacy = conv.pinnedMessage as { messageId?: string } | undefined;
  if (legacy?.messageId === messageId) {
    await convRef.update({ pinnedMessage: admin.firestore.FieldValue.delete() });
    logger.log("[disappearing] removed legacy pinned reference", { path: convRef.path, messageId });
  }
}

async function applyLatestMainMessageAsConversationLast(
  db: admin.firestore.Firestore,
  convRef: DocumentReference
): Promise<void> {
  const col = convRef.collection("messages");
  const snap = await col.orderBy("createdAt", "desc").limit(1).get();
  if (snap.empty) {
    await convRef.update({
      lastMessageText: "",
      lastMessageTimestamp: admin.firestore.FieldValue.delete(),
      lastMessageSenderId: admin.firestore.FieldValue.delete(),
      lastMessageIsThread: false,
    });
    return;
  }
  const d = snap.docs[0].data() as Record<string, unknown>;
  const { text, senderId } = lastPreviewFromMessageData(d);
  const ts = createdAtComparable(d);
  await convRef.update({
    lastMessageText: text,
    lastMessageTimestamp: ts,
    lastMessageSenderId: senderId,
    lastMessageIsThread: false,
  });
}

async function refreshParentThreadSummary(
  db: admin.firestore.Firestore,
  conversationId: string,
  parentMessageId: string
): Promise<void> {
  const parentRef = db.doc(`conversations/${conversationId}/messages/${parentMessageId}`);
  const tcol = parentRef.collection("thread");
  const snap = await tcol.orderBy("createdAt", "desc").limit(1).get();
  if (snap.empty) {
    await parentRef.update({
      lastThreadMessageText: admin.firestore.FieldValue.delete(),
      lastThreadMessageSenderId: admin.firestore.FieldValue.delete(),
      lastThreadMessageTimestamp: admin.firestore.FieldValue.delete(),
    });
    return;
  }
  const d = snap.docs[0].data() as Record<string, unknown>;
  const { text, senderId } = lastPreviewFromMessageData(d);
  const ts = createdAtComparable(d);
  await parentRef.update({
    lastThreadMessageText: text,
    lastThreadMessageSenderId: senderId,
    lastThreadMessageTimestamp: ts,
  });
}

/**
 * После удаления документа сообщения (TTL или вручную): закрепы и пересчёт lastMessage* на беседе.
 */
export async function handleChatMessageDeleted(opts: {
  db: admin.firestore.Firestore;
  conversationId: string;
  /** id удалённого документа (основное сообщение или комментарий в thread) */
  deletedDocId: string;
  deletedData: Record<string, unknown> | undefined;
  kind: "main" | "thread";
  parentMessageId?: string;
}): Promise<void> {
  const { db, conversationId, deletedDocId, deletedData, kind, parentMessageId } = opts;
  if (!deletedData) return;

  try {
    await deleteChatMessageStorageObjects({
      conversationId,
      messageDocId: deletedDocId,
      messageData: deletedData,
    });
  } catch (e) {
    logger.error("[chat-delete-storage] failed", {
      conversationId,
      deletedDocId,
      err: String(e),
    });
  }

  const convRef = db.doc(`conversations/${conversationId}`);
  const convSnap = await convRef.get();
  if (!convSnap.exists) return;
  const conv = convSnap.data() as Record<string, unknown>;

  const delCreated = createdAtComparable(deletedData);
  const delSender = typeof deletedData.senderId === "string" ? deletedData.senderId : "";

  if (kind === "main") {
    await removePinsForMessageId(convRef, conv, deletedDocId);
  }

  const lastTs = typeof conv.lastMessageTimestamp === "string" ? conv.lastMessageTimestamp : "";
  const lastSender = typeof conv.lastMessageSenderId === "string" ? conv.lastMessageSenderId : "";
  const lastIsThread = conv.lastMessageIsThread === true;

  if (kind === "main") {
    if (!lastIsThread && lastTs === delCreated && lastSender === delSender) {
      try {
        await applyLatestMainMessageAsConversationLast(db, convRef);
      } catch (e) {
        logger.error("[disappearing] refresh conv last after main delete failed", {
          conversationId,
          err: String(e),
        });
      }
    }
    return;
  }

  // thread reply deleted
  if (!parentMessageId) return;

  try {
    await refreshParentThreadSummary(db, conversationId, parentMessageId);
  } catch (e) {
    logger.error("[disappearing] refresh parent thread summary failed", {
      conversationId,
      parentMessageId,
      err: String(e),
    });
  }

  const parentRef = db.doc(`conversations/${conversationId}/messages/${parentMessageId}`);

  if (lastIsThread && lastTs === delCreated && lastSender === delSender) {
    const tcol = parentRef.collection("thread");
    const latest = await tcol.orderBy("createdAt", "desc").limit(1).get();
    if (!latest.empty) {
      const d = latest.docs[0].data() as Record<string, unknown>;
      const { text, senderId } = lastPreviewFromMessageData(d);
      const ts = createdAtComparable(d);
      await convRef.update({
        lastMessageText: text,
        lastMessageTimestamp: ts,
        lastMessageSenderId: senderId,
        lastMessageIsThread: true,
      });
    } else {
      try {
        await applyLatestMainMessageAsConversationLast(db, convRef);
      } catch (e) {
        logger.error("[disappearing] refresh conv last after thread emptied failed", {
          conversationId,
          err: String(e),
        });
      }
    }
  }
}
