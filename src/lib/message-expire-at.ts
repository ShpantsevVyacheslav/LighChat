import type { Timestamp } from 'firebase/firestore';
import type { ChatMessage } from '@/lib/types';

/**
 * Миллисекунды момента автоудаления из поля `expireAt` (Firestore Timestamp на клиенте).
 */
export function getExpireAtMillisFromUnknown(expireAt: unknown): number | null {
  if (expireAt == null) return null;
  if (typeof expireAt === 'object' && expireAt !== null && 'toMillis' in expireAt) {
    const ms = (expireAt as Timestamp).toMillis();
    return Number.isFinite(ms) ? ms : null;
  }
  if (expireAt instanceof Date) {
    const ms = expireAt.getTime();
    return Number.isFinite(ms) ? ms : null;
  }
  if (typeof expireAt === 'string' || typeof expireAt === 'number') {
    const ms = typeof expireAt === 'number' ? expireAt : Date.parse(expireAt);
    return Number.isFinite(ms) ? ms : null;
  }
  return null;
}

export function isChatMessageExpired(message: Pick<ChatMessage, 'expireAt'>, nowMs = Date.now()): boolean {
  const expireMs = getExpireAtMillisFromUnknown(message.expireAt);
  return expireMs != null && expireMs <= nowMs;
}

export function nextChatMessageExpireAtMillis(
  messages: Array<Pick<ChatMessage, 'expireAt'>>,
  nowMs = Date.now(),
): number | null {
  let next: number | null = null;
  for (const message of messages) {
    const expireMs = getExpireAtMillisFromUnknown(message.expireAt);
    if (expireMs == null || expireMs <= nowMs) continue;
    if (next == null || expireMs < next) next = expireMs;
  }
  return next;
}
