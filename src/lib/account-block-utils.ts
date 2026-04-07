import type { User } from '@/lib/types';

/** Активна ли блокировка сейчас (с учётом срока until). */
export function isAccountBlocked(user: Pick<User, 'accountBlock'> | null | undefined, nowMs: number = Date.now()): boolean {
  const b = user?.accountBlock;
  if (!b?.active) return false;
  if (!b.until) return true;
  return new Date(b.until).getTime() > nowMs;
}
