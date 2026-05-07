import * as crypto from "crypto";

/**
 * Проверка подписи Telegram Login Widget.
 * @see https://core.telegram.org/widgets/login#checking-authorization
 *
 * SECURITY: Telegram's own login widget UI signs `auth_date` once and the
 * same payload remains valid until rejected by the server. The previous TTL
 * of 86 400 sec (24 hours) gave attackers a full-day window to use a
 * stolen/leaked payload — typical leak vectors include browser history,
 * server logs that captured the login URL, or shared screenshots that
 * exposed the hash. Telegram's own examples use 5–10 minutes; we settle
 * on 10 minutes as a comfortable trade-off between UX (slow networks /
 * suspended laptops) and replay risk.
 *
 * For full anti-replay we also remember (auth_date, hash) tuples on the
 * server side — see telegram-widget-replay-store.ts and the use site in
 * signInWithTelegram.ts. The TTL here keeps the replay store small.
 */
const TELEGRAM_AUTH_MAX_AGE_SEC = 600; // 10 minutes

export function verifyTelegramLoginWidget(
  raw: Record<string, unknown>,
  botToken: string
): boolean {
  if (!botToken || typeof raw.hash !== "string") {
    return false;
  }
  const hash = raw.hash as string;
  const authDate = raw.auth_date;
  if (authDate === undefined || authDate === null) {
    return false;
  }
  const ts = Number(authDate);
  if (!Number.isFinite(ts)) {
    return false;
  }
  const ageSec = Math.floor(Date.now() / 1000) - ts;
  if (ageSec < 0 || ageSec > TELEGRAM_AUTH_MAX_AGE_SEC) {
    return false;
  }

  const pairs: [string, string][] = [];
  for (const [k, v] of Object.entries(raw)) {
    if (k === "hash") continue;
    if (v === undefined || v === null) continue;
    const str = typeof v === "string" ? v : String(v);
    pairs.push([k, str]);
  }
  pairs.sort((a, b) => a[0].localeCompare(b[0]));
  const dataCheckString = pairs.map(([k, v]) => `${k}=${v}`).join("\n");

  const secretKey = crypto.createHash("sha256").update(botToken).digest();
  const hmac = crypto
    .createHmac("sha256", secretKey)
    .update(dataCheckString)
    .digest("hex");

  try {
    const a = Buffer.from(hmac, "hex");
    const b = Buffer.from(hash, "hex");
    if (a.length !== b.length) return false;
    return crypto.timingSafeEqual(a, b);
  } catch {
    return false;
  }
}

export function telegramUserIdFromPayload(raw: Record<string, unknown>): string | null {
  const id = raw.id;
  if (id === undefined || id === null) return null;
  const s = typeof id === "string" ? id.trim() : String(id).trim();
  if (!/^\d+$/.test(s)) return null;
  return s;
}
