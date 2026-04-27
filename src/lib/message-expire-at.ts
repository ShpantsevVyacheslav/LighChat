import type { Timestamp } from 'firebase/firestore';

/**
 * Миллисекунды момента автоудаления из поля `expireAt` (Firestore Timestamp на клиенте).
 */
export function getExpireAtMillisFromUnknown(expireAt: unknown): number | null {
  if (expireAt == null) return null;
  if (typeof expireAt === 'object' && expireAt !== null && 'toMillis' in expireAt) {
    const ms = (expireAt as Timestamp).toMillis();
    return Number.isFinite(ms) ? ms : null;
  }
  return null;
}
