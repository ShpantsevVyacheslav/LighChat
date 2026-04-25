import type { ChatMessage } from '@/lib/types';

/** Входящее сообщение, которое для данного пользователя ещё не помечено прочитанным. */
export function isIncomingUnreadForViewer(
  message: Pick<ChatMessage, 'senderId' | 'readAt' | 'systemEvent'>,
  viewerId: string
): boolean {
  // System timeline markers (e.g. E2EE on/off) must never participate in unread counters.
  if (message.senderId === '__system__' || message.systemEvent != null) return false;
  if (message.senderId === viewerId) return false;
  const ra = message.readAt;
  return ra == null || ra === '';
}
