/**
 * Единые критерии «регистрация завершена» для email и Google (имя, логин, телефон, email).
 * Совпадают с валидацией форм в `register-profile-schema.ts`.
 */

import type { User } from "@/lib/types";

const EMAIL_LIKE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/u;

function normalizedUsername(raw: string): string {
  return String(raw ?? "")
    .trim()
    .replace(/^@/, "")
    .toLowerCase();
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
  if (username.length < 3 || username.length > 30) return false;
  if (!/^[a-zA-Z0-9_]+$/u.test(username)) return false;
  const phoneDigits = String(u.phone ?? "").replace(/\D/g, "");
  if (phoneDigits.length !== 11) return false;
  const email = String(u.email ?? "").trim();
  if (!email || !EMAIL_LIKE.test(email)) return false;
  return true;
}
