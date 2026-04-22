import * as crypto from "crypto";

/**
 * Проверка подписи Telegram Login Widget.
 * @see https://core.telegram.org/widgets/login#checking-authorization
 */
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
  if (ageSec < 0 || ageSec > 86400) {
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
