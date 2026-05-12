/**
 * Серверный OAuth 2.0 Яндекс ID (обмен code → access_token, профиль).
 * @see https://yandex.ru/dev/id/doc/ru/
 */

import { logger } from "@/lib/logger";

const YANDEX_AUTHORIZE = "https://oauth.yandex.ru/authorize";
const YANDEX_TOKEN = "https://oauth.yandex.com/token";
const YANDEX_LOGIN_INFO = "https://login.yandex.ru/info?format=json";

/**
 * Дефолтные права под типовой набор в кабинете Яндекс ID (как в UI: email, ФИО/логин, аватар, ДР, телефон).
 * Для телефона в консоли часто указан scope `login:default_phone` (не путать с устаревшим `login:phone`).
 * Если в приложении включён другой набор — задайте `YANDEX_SCOPE` и/или синхронизируйте права в кабинете, иначе `invalid_scope`.
 */
export const YANDEX_DEFAULT_SCOPES =
  "login:email login:info login:avatar login:birthday login:default_phone";

export function buildYandexAuthorizeUrl(opts: {
  clientId: string;
  redirectUri: string;
  state: string;
  scope?: string;
}): string {
  const p = new URLSearchParams({
    response_type: "code",
    client_id: opts.clientId,
    redirect_uri: opts.redirectUri,
    state: opts.state,
    scope: (opts.scope ?? YANDEX_DEFAULT_SCOPES).trim(),
  });
  return `${YANDEX_AUTHORIZE}?${p.toString()}`;
}

export async function yandexExchangeAuthorizationCode(opts: {
  code: string;
  clientId: string;
  clientSecret: string;
  redirectUri: string;
}): Promise<{ access_token: string }> {
  const body = new URLSearchParams({
    grant_type: "authorization_code",
    code: opts.code,
    client_id: opts.clientId,
    client_secret: opts.clientSecret,
    redirect_uri: opts.redirectUri,
  });

  const res = await fetch(YANDEX_TOKEN, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: body.toString(),
    cache: "no-store",
  });
  const text = await res.text();
  if (!res.ok) {
    throw new Error(
      `Yandex token exchange failed: HTTP ${res.status} ${text.slice(0, 400)}`
    );
  }
  let json: { access_token?: string };
  try {
    json = JSON.parse(text) as { access_token?: string };
  } catch {
    throw new Error("Yandex token response is not JSON");
  }
  if (!json.access_token || typeof json.access_token !== "string") {
    throw new Error("Yandex token response missing access_token");
  }
  return { access_token: json.access_token };
}

export type YandexLoginInfo = {
  id: string | number;
  login?: string;
  first_name?: string;
  last_name?: string;
  display_name?: string;
  real_name?: string;
  default_email?: string;
  emails?: string[];
  /**
   * Телефон при scope `login:default_phone` (кабинет Яндекс ID) или `login:phone` в доке.
   * @see https://yandex.ru/dev/id/doc/ru/user-information
   */
  default_phone?: { id?: number; number?: string } | string;
  /** Дата рождения при scope `login:birthday` (формат зависит от ответа API). */
  birthday?: string;
  default_avatar_id?: string;
  is_avatar_empty?: boolean;
};

function redactYandexLoginInfoForLogs(info: YandexLoginInfo): Record<string, unknown> {
  const out: Record<string, unknown> = { ...info };
  if (typeof out.default_email === "string") out.default_email = "<redacted>";
  if (Array.isArray(out.emails)) out.emails = ["<redacted>"];
  if (typeof out.birthday === "string") out.birthday = "<redacted>";
  const dp = out.default_phone as unknown;
  if (typeof dp === "string") out.default_phone = "<redacted>";
  else if (dp && typeof dp === "object") out.default_phone = { id: (dp as any).id, number: "<redacted>" };
  return out;
}

export async function yandexFetchLoginInfo(
  accessToken: string
): Promise<YandexLoginInfo> {
  const res = await fetch(YANDEX_LOGIN_INFO, {
    headers: { Authorization: `OAuth ${accessToken}` },
    cache: "no-store",
  });
  const text = await res.text();
  if (!res.ok) {
    throw new Error(
      `Yandex login/info failed: HTTP ${res.status} ${text.slice(0, 400)}`
    );
  }
  const parsed = JSON.parse(text) as YandexLoginInfo;
  if (process.env.YANDEX_DEBUG_LOGIN_INFO === "1") {
    try {
      logger.debug('yandex-oauth', 'login/info keys', Object.keys(parsed as Record<string, unknown>).sort());
      logger.debug('yandex-oauth', 'login/info redacted', redactYandexLoginInfoForLogs(parsed));
    } catch {
      /* ignore logging errors */
    }
  }
  return parsed;
}

export function yandexNumericUserId(info: YandexLoginInfo): string {
  const raw = info.id;
  const s = typeof raw === "number" ? String(raw) : String(raw ?? "").trim();
  if (!/^\d+$/u.test(s)) {
    throw new Error("Yandex profile: invalid numeric user id");
  }
  return s;
}

export function yandexDisplayName(info: YandexLoginInfo): string {
  const parts = [
    typeof info.first_name === "string" ? info.first_name.trim() : "",
    typeof info.last_name === "string" ? info.last_name.trim() : "",
  ].filter(Boolean);
  const combined = parts.join(" ").trim();
  if (combined.length > 0) return combined.slice(0, 128);
  for (const k of ["real_name", "display_name"] as const) {
    const v = info[k];
    if (typeof v === "string" && v.trim().length > 0) return v.trim().slice(0, 128);
  }
  const login = typeof info.login === "string" ? info.login.trim() : "";
  if (login.length > 0) return login.slice(0, 128);
  return "Yandex";
}

const EMAIL_LIKE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/u;

export function yandexPrimaryEmail(info: YandexLoginInfo): string | undefined {
  const raw =
    (typeof info.default_email === "string" ? info.default_email : "") ||
    (Array.isArray(info.emails) && typeof info.emails[0] === "string"
      ? info.emails[0]
      : "");
  const e = raw.trim().toLowerCase();
  if (!e || !EMAIL_LIKE.test(e)) return undefined;
  return e;
}

export function yandexPhotoUrl(info: YandexLoginInfo): string | undefined {
  if (info.is_avatar_empty) return undefined;
  const id =
    typeof info.default_avatar_id === "string" &&
    info.default_avatar_id.trim().length > 0
      ? info.default_avatar_id.trim()
      : typeof info.login === "string" && info.login.trim().length > 0
        ? info.login.trim()
        : "";
  if (!id) return undefined;
  return `https://avatars.yandex.net/get-yapic/${encodeURIComponent(id)}/islands-200`;
}

export function yandexPrimaryPhone(info: YandexLoginInfo): string | undefined {
  const raw = info.default_phone;
  const num =
    typeof raw === "string"
      ? raw.trim()
      : raw && typeof raw === "object" && typeof raw.number === "string"
        ? raw.number.trim()
        : "";
  if (!num) return undefined;
  return num.slice(0, 32);
}

const BIRTHDAY_ISO = /^\d{4}-\d{2}-\d{2}$/u;

/**
 * Дата рождения из Яндекса: `YYYY-MM-DD`.
 * Неизвестные части даты заполняются нулями (например `0000-12-23`), либо `null`.
 */
export function yandexPrimaryDateOfBirth(
  info: YandexLoginInfo,
): string | undefined {
  const raw = typeof info.birthday === "string" ? info.birthday.trim() : "";
  if (!raw || !BIRTHDAY_ISO.test(raw)) return undefined;
  // Drop fully-unknown or impossible values (keep partial like 0000-12-23).
  if (raw === "0000-00-00") return undefined;
  return raw;
}
