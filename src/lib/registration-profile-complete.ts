/**
 * Единые критерии «регистрация завершена» для входа и базовой навигации.
 * Совпадают с валидацией форм в `register-profile-schema.ts`.
 */

import type { User } from "@/lib/types";

import {
  isNormalizedUsernameTokenAllowed,
  normalizeUsernameCandidate,
} from "@/lib/username-candidate";

const EMAIL_LIKE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/u;

function normalizedUsername(raw: string): string {
  return normalizeUsernameCandidate(raw);
}

/**
 * @param u — документ `users/*` или снимок профиля из Auth-страницы / дашборда
 */
export function isRegistrationProfileComplete(
  u: Pick<User, "name" | "username" | "phone" | "email"> | null | undefined,
): boolean {
  if (!u) return false;
  const name = String(u.name ?? "").trim();
  if (name.length < 2) return false;
  const username = normalizedUsername(String(u.username ?? ""));
  if (!isNormalizedUsernameTokenAllowed(username)) return false;
  const email = String(u.email ?? "").trim();
  if (!email || !EMAIL_LIKE.test(email)) return false;
  return true;
}
