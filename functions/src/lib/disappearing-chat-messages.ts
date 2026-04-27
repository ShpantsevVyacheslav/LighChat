import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import type { DocumentReference } from "firebase-admin/firestore";

export function readDisappearingTtlSec(conv: Record<string, unknown> | undefined): number | null {
  if (!conv) return null;
  const v = conv.disappearingMessageTtlSec;
  if (v == null) return null;
  if (typeof v === "number" && Number.isFinite(v) && v > 0) return v;
  return null;
}

export function messageCreatedAtToMillis(data: Record<string, unknown>): number {
  const raw = data.createdAt;
  if (typeof raw === "string") {
    const t = Date.parse(raw);
    if (Number.isFinite(t)) return t;
  }
  if (
    raw &&
    typeof raw === "object" &&
    "toDate" in raw &&
    typeof (raw as { toDate: () => Date }).toDate === "function"
  ) {
    const d = (raw as { toDate: () => Date }).toDate();
    const t = d.getTime();
    if (Number.isFinite(t)) return t;
  }
  return Date.now();
}

/**
 * Выставляет `expireAt` для Firestore TTL (только не-системные сообщения).
 */
export async function trySetMessageExpireAtForDisappearing(opts: {
  db: admin.firestore.Firestore;
  messageRef: DocumentReference;
  messageData: Record<string, unknown>;
  conversationData: Record<string, unknown>;
  conversationId: string;
  messageId: string;
}): Promise<void> {
  const ttl = readDisappearingTtlSec(opts.conversationData);
  if (!ttl) return;

  const senderId = opts.messageData.senderId;
  if (senderId === "__system__") return;
  if (opts.messageData.systemEvent != null) return;

  const ms = messageCreatedAtToMillis(opts.messageData);
  const expireAt = admin.firestore.Timestamp.fromMillis(ms + ttl * 1000);

  try {
    await opts.messageRef.update({ expireAt });
  } catch (e) {
    logger.error("[disappearing] set expireAt failed", {
      conversationId: opts.conversationId,
      messageId: opts.messageId,
      err: String(e),
    });
  }
}
