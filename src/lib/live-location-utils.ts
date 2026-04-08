import type { UserLiveLocationShare, ChatLocationShare } from '@/lib/types';

/** Живая трансляция: срок из `liveSession.expiresAt` истёк — UI показывает текст вместо карты ([`MessageLocationCard`](../src/components/chat/parts/MessageLocationCard.tsx)). */
export function isChatLiveLocationShareExpired(share: ChatLocationShare, nowMs: number = Date.now()): boolean {
  if (!share.liveSession) return false;
  if (!share.liveSession.expiresAt) return false;
  return new Date(share.liveSession.expiresAt).getTime() <= nowMs;
}

export function isLiveShareExpired(share: UserLiveLocationShare, nowMs: number = Date.now()): boolean {
  if (!share.expiresAt) return false;
  return new Date(share.expiresAt).getTime() <= nowMs;
}

export function isLiveShareVisible(share: UserLiveLocationShare | null | undefined, nowMs?: number): boolean {
  if (!share?.active) return false;
  return !isLiveShareExpired(share, nowMs);
}
