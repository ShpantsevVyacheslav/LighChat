import * as admin from "firebase-admin";

export const SCHEDULED_MESSAGES_BATCH_LIMIT = 100;

export type ScheduledMessageStatus = "pending" | "sending" | "sent" | "failed";

export interface ScheduledMessageData {
  senderId: string;
  text?: string;
  attachments?: Array<Record<string, unknown>>;
  replyTo?: Record<string, unknown>;
  pendingPoll?: {
    question: string;
    options: string[];
    allowMultiple?: boolean;
    isAnonymous?: boolean;
  };
  locationShare?: Record<string, unknown>;
  scheduledAt: string;
  sendAt: string;
  status: ScheduledMessageStatus;
  failureReason?: string;
  createdAt: string;
  updatedAt?: string;
}

export function isConversationScheduledMessageDocPath(path: string): boolean {
  const parts = path.split("/");
  return (
    parts.length === 4 &&
    parts[0] === "conversations" &&
    parts[2] === "scheduledMessages"
  );
}

export function extractConversationIdFromScheduledPath(path: string): string | null {
  const parts = path.split("/");
  if (!isConversationScheduledMessageDocPath(path)) return null;
  return parts[1];
}

/**
 * Превью текста для lastMessageText (без HTML-тегов, обрезано до 100).
 * Параритет с client-side _mainChatLastPreviewText / web ChatWindow.
 */
function buildLastMessagePreview(data: ScheduledMessageData): string {
  if (data.pendingPoll) return "📊 Опрос";
  if (data.locationShare) return "📍 Локация";
  if (data.text) {
    const stripped = data.text
      .replace(/<[^>]*>/g, "")
      .replace(/&nbsp;/g, " ")
      .trim();
    if (stripped.length > 0) return stripped.slice(0, 100);
  }
  if (data.attachments && data.attachments.length > 0) {
    const first = data.attachments[0] as { name?: string };
    const name = typeof first?.name === "string" ? first.name : "";
    if (name.startsWith("sticker_")) return "Стикер";
    if (name.startsWith("gif_")) return "GIF";
    return "Вложение";
  }
  return "Сообщение";
}

/**
 * Транзакционно «забронировать» отложенное сообщение: pending → sending.
 * Возвращает true, если claim удался; false — если сообщение уже не pending.
 */
export async function claimScheduledMessage(
  db: admin.firestore.Firestore,
  schedRef: admin.firestore.DocumentReference
): Promise<boolean> {
  return await db.runTransaction(async (tx) => {
    const fresh = await tx.get(schedRef);
    if (!fresh.exists) return false;
    const status = (fresh.data() as ScheduledMessageData | undefined)?.status;
    if (status !== "pending") return false;
    tx.update(schedRef, { status: "sending", updatedAt: new Date().toISOString() });
    return true;
  });
}

/**
 * Опубликовать одно отложенное сообщение: создать message в `conversations/{id}/messages/{newId}`,
 * обновить parent-конверсацию (lastMessage*, unreadCounts), при наличии pendingPoll создать poll
 * в том же batch. Помечает scheduled-документ status='sent'.
 *
 * ВАЖНО: вызывать только после успешного claimScheduledMessage().
 */
export async function publishScheduledMessage(opts: {
  db: admin.firestore.Firestore;
  schedDoc: admin.firestore.QueryDocumentSnapshot;
  conversationId: string;
  nowIso: string;
}): Promise<void> {
  const { db, schedDoc, conversationId, nowIso } = opts;
  const data = schedDoc.data() as ScheduledMessageData;
  const senderId = data.senderId;

  const convRef = db.doc(`conversations/${conversationId}`);
  const convSnap = await convRef.get();
  if (!convSnap.exists) {
    await schedDoc.ref.update({
      status: "failed",
      failureReason: "conversation_not_found",
      updatedAt: nowIso,
    });
    return;
  }
  const convData = convSnap.data() ?? {};
  const participantIds: string[] = Array.isArray(convData.participantIds) ?
    (convData.participantIds as string[]).filter((s) => typeof s === "string" && s.length > 0) :
    [];

  if (!participantIds.includes(senderId)) {
    await schedDoc.ref.update({
      status: "failed",
      failureReason: "sender_not_participant",
      updatedAt: nowIso,
    });
    return;
  }

  const messagesRef = db.collection(`conversations/${conversationId}/messages`);
  const messageRef = messagesRef.doc();

  const messagePayload: Record<string, unknown> = {
    senderId,
    createdAt: nowIso,
    readAt: null,
  };
  if (typeof data.text === "string" && data.text.length > 0) {
    messagePayload.text = data.text;
  }
  if (Array.isArray(data.attachments) && data.attachments.length > 0) {
    messagePayload.attachments = data.attachments;
  }
  if (data.replyTo && typeof data.replyTo === "object") {
    messagePayload.replyTo = data.replyTo;
  }
  if (data.locationShare && typeof data.locationShare === "object") {
    messagePayload.locationShare = data.locationShare;
  }

  let pollRef: admin.firestore.DocumentReference | null = null;
  let pollPayload: Record<string, unknown> | null = null;
  if (data.pendingPoll) {
    const question = (data.pendingPoll.question ?? "").trim();
    const options = (data.pendingPoll.options ?? [])
      .map((o) => (typeof o === "string" ? o.trim() : ""))
      .filter((s) => s.length > 0);
    if (question.length > 0 && options.length >= 2) {
      const pollId = `chat-poll-${Date.now()}-${messageRef.id.slice(0, 6)}`;
      pollRef = db.doc(`conversations/${conversationId}/polls/${pollId}`);
      pollPayload = {
        id: pollId,
        question,
        options,
        allowMultiple: data.pendingPoll.allowMultiple === true,
        isAnonymous: data.pendingPoll.isAnonymous === true,
        createdBy: senderId,
        createdAt: nowIso,
        votes: {},
      };
      messagePayload.text = "<p>📊 Опрос</p>";
      messagePayload.chatPollId = pollId;
    }
  }

  const lastPreview = buildLastMessagePreview(data);

  const convUpdate: { [key: string]: admin.firestore.FieldValue | string | boolean } = {
    lastMessageText: lastPreview,
    lastMessageTimestamp: nowIso,
    lastMessageSenderId: senderId,
    lastMessageIsThread: false,
  };
  for (const id of participantIds) {
    if (id !== senderId) {
      convUpdate[`unreadCounts.${id}`] = admin.firestore.FieldValue.increment(1);
    }
  }

  const batch = db.batch();
  if (pollRef && pollPayload) {
    batch.set(pollRef, pollPayload);
  }
  batch.set(messageRef, messagePayload);
  batch.update(convRef, convUpdate);
  batch.update(schedDoc.ref, {
    status: "sent",
    updatedAt: nowIso,
    publishedMessageId: messageRef.id,
  });

  await batch.commit();
}
