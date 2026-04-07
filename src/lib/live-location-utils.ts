import type { UserLiveLocationShare } from '@/lib/types';

export function isLiveShareExpired(share: UserLiveLocationShare, nowMs: number = Date.now()): boolean {
  if (!share.expiresAt) return false;
  return new Date(share.expiresAt).getTime() <= nowMs;
}

export function isLiveShareVisible(share: UserLiveLocationShare | null | undefined, nowMs?: number): boolean {
  if (!share?.active) return false;
  return !isLiveShareExpired(share, nowMs);
}
