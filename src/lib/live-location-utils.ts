import type { UserLiveLocationShare, ChatLocationShare } from '@/lib/types';

/** Живая трансляция: срок из `liveSession.expiresAt` истёк — UI показывает текст вместо карты ([`MessageLocationCard`](../src/components/chat/parts/MessageLocationCard.tsx)). */
export function isChatLiveLocationShareExpired(share: ChatLocationShare, nowMs: number = Date.now()): boolean {
  if (!share.liveSession) return false;
  if (!share.liveSession.expiresAt) return false;
  return new Date(share.liveSession.expiresAt).getTime() <= nowMs;
}

const LIVE_MESSAGE_SESSION_SLOP_MS = 15_000;

/**
 * Сообщение с `liveSession` ещё должно показывать превью карты (таймер «живой» локации).
 * Учитывает: дедлайн `expiresAt`, активную запись `users/{sender}.liveLocationShare` и совпадение
 * сессии с сообщением (`startedAt`), чтобы после «Остановить» и без правки документа сообщения
 * пузырь перешёл в тот же текстовый вид, что и при истечении таймера.
 */
export function isChatLiveLocationMessageStillStreaming(
  share: ChatLocationShare,
  messageCreatedAt: string,
  senderLiveShare: UserLiveLocationShare | null | undefined,
  senderProfileResolved: boolean,
  nowMs: number = Date.now(),
): boolean {
  if (!share.liveSession) return false;

  const expiresAtIso = share.liveSession.expiresAt;
  if (expiresAtIso && new Date(expiresAtIso).getTime() <= nowMs) {
    return false;
  }

  if (!senderProfileResolved) {
    return true;
  }

  if (!senderLiveShare || !isLiveShareVisible(senderLiveShare, nowMs)) {
    return false;
  }

  const msgMs = new Date(messageCreatedAt).getTime();
  const startedMs = new Date(senderLiveShare.startedAt).getTime();
  if (Number.isFinite(msgMs) && Number.isFinite(startedMs) && msgMs + LIVE_MESSAGE_SESSION_SLOP_MS < startedMs) {
    return false;
  }

  return true;
}

export function isLiveShareExpired(share: UserLiveLocationShare, nowMs: number = Date.now()): boolean {
  if (!share.expiresAt) return false;
  return new Date(share.expiresAt).getTime() <= nowMs;
}

export function isLiveShareVisible(share: UserLiveLocationShare | null | undefined, nowMs?: number): boolean {
  if (!share?.active) return false;
  return !isLiveShareExpired(share, nowMs);
}
