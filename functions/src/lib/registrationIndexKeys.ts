/**
 * Ключи документов `registrationIndex/{id}` — должны совпадать с клиентом (`src/lib/registration-index-keys.ts`).
 * Индекс обновляет только Admin SDK (Cloud Functions); клиент делает getDoc до регистрации.
 */

export function normalizePhoneDigits(input: string): string {
  let d = input.replace(/\D/g, "");
  if (d.startsWith("8") && d.length === 11) d = "7" + d.slice(1);
  if (d.length === 10) d = "7" + d;
  return d;
}

export function utf8ToBase64Url(s: string): string {
  return Buffer.from(s, "utf8").toString("base64url");
}

/** Гостевой email из Firebase Auth / onUserCreated — не индексируем. */
export function isAnonymousPlaceholderEmail(email: string): boolean {
  const e = email.trim().toLowerCase();
  return e.endsWith("@anonymous.com") && e.startsWith("guest_");
}

/** Firestore: `registrationIndex/p_79001234567` */
export function registrationPhoneKey(phone: string): string | null {
  const d = normalizePhoneDigits(String(phone ?? ""));
  if (d.length < 10) return null;
  return `p_${d}`;
}

/** Firestore: `registrationIndex/e_<base64url(lowercase email)>` */
export function registrationEmailKey(email: string): string | null {
  const n = String(email ?? "").trim().toLowerCase();
  if (!n || isAnonymousPlaceholderEmail(n)) return null;
  return `e_${utf8ToBase64Url(n)}`;
}

/** Firestore: `registrationIndex/u_username` */
export function registrationUsernameKey(username: string): string | null {
  const n = String(username ?? "")
    .trim()
    .replace(/^@/, "")
    .toLowerCase();
  if (!n) return null;
  return `u_${n}`;
}

export type RegistrationIndexField = "phone" | "email" | "username";

export interface RegistrationIndexEntry {
  id: string;
  field: RegistrationIndexField;
}

/**
 * Какие документы `registrationIndex/{id}` должны существовать для данного профиля `users/*`.
 */
export function registrationEntriesForProfile(
  data:
    | {
        deletedAt?: unknown;
        phone?: unknown;
        email?: unknown;
        username?: unknown;
      }
    | undefined
    | null,
): RegistrationIndexEntry[] {
  if (!data || data.deletedAt) return [];

  const out: RegistrationIndexEntry[] = [];

  const phoneKey = registrationPhoneKey(String(data.phone ?? ""));
  if (phoneKey) out.push({ id: phoneKey, field: "phone" });

  const emailRaw = String(data.email ?? "").trim();
  if (emailRaw && !isAnonymousPlaceholderEmail(emailRaw)) {
    const emailKey = registrationEmailKey(emailRaw);
    if (emailKey) out.push({ id: emailKey, field: "email" });
  }

  const userKey = registrationUsernameKey(String(data.username ?? ""));
  if (userKey) out.push({ id: userKey, field: "username" });

  return out;
}
