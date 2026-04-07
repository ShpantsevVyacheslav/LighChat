/**
 * Ключи `registrationIndex/{id}` — должны совпадать с `functions/src/lib/registrationIndexKeys.ts`.
 */

import { normalizePhoneDigits } from "@/lib/phone-utils";

export function utf8ToBase64Url(s: string): string {
  const bytes = new TextEncoder().encode(s);
  let binary = "";
  for (let i = 0; i < bytes.length; i++) {
    binary += String.fromCharCode(bytes[i]!);
  }
  const b64 = btoa(binary);
  return b64.replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/u, "");
}

/** Гостевой email — не участвует в индексе. */
export function isAnonymousPlaceholderEmail(email: string): boolean {
  const e = email.trim().toLowerCase();
  return e.endsWith("@anonymous.com") && e.startsWith("guest_");
}

export function registrationPhoneKey(phone: string): string | null {
  const d = normalizePhoneDigits(String(phone ?? ""));
  if (d.length < 10) return null;
  return `p_${d}`;
}

export function registrationEmailKey(email: string): string | null {
  const n = String(email ?? "").trim().toLowerCase();
  if (!n || isAnonymousPlaceholderEmail(n)) return null;
  return `e_${utf8ToBase64Url(n)}`;
}

export function registrationUsernameKey(username: string): string | null {
  const n = String(username ?? "")
    .trim()
    .replace(/^@/, "")
    .toLowerCase();
  if (!n) return null;
  return `u_${n}`;
}
