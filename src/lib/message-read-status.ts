import type { ChatMessage } from '@/lib/types';

/** Входящее сообщение, которое для данного пользователя ещё не помечено прочитанным. */
export function isIncomingUnreadForViewer(
  message: Pick<ChatMessage, 'senderId' | 'readAt' | 'systemEvent' | 'readByUid'>,
  viewerId: string
): boolean {
  // System timeline markers (e.g. E2EE on/off) must never participate in unread counters.
  if (message.senderId === '__system__' || message.systemEvent != null) return false;
  if (message.senderId === viewerId) return false;
  const ra = message.readAt;
  if (ra != null && ra !== '') return false;
  // Личная отметка прочтения (режим скрытых read-receipts): сам себе помечаем
  // прочитанным, чтобы не было ухода unread-счётчика в минус при повторном входе.
  const personal = message.readByUid?.[viewerId];
  if (personal != null && personal !== '') return false;
  return true;
}
