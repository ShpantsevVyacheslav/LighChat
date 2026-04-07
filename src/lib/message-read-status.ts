import type { ChatMessage } from '@/lib/types';

/** Входящее сообщение, которое для данного пользователя ещё не помечено прочитанным. */
export function isIncomingUnreadForViewer(
  message: Pick<ChatMessage, 'senderId' | 'readAt'>,
  viewerId: string
): boolean {
  if (message.senderId === viewerId) return false;
  const ra = message.readAt;
  return ra == null || ra === '';
}
