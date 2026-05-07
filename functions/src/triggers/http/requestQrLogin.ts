import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import * as nodeCrypto from "node:crypto";

import { callerIpKey, consumeRateLimit } from "../../lib/rate-limit";

/**
 * Создаёт эфемерную QR-login сессию для нового устройства (Telegram-style):
 *  - клиент (новое устройство, ещё без auth) запрашивает sessionId+nonce;
 *  - сессия хранится в `qrLoginSessions/{sessionId}`, TTL 90с (60с QR + 30с задел);
 *  - старое устройство сканирует QR, вызывает `confirmQrLogin`, та проставляет
 *    customToken;
 *  - новое устройство полит документ листенером, при `state == 'approved'`
 *    использует `customToken` для signInWithCustomToken и удаляет документ.
 *
 * Поскольку вызов идёт ДО auth, callable не требует request.auth. Мы ограничиваем
 * злоупотребления тем, что:
 *   - sessionId — 24 байта рандомных, не угадывается;
 *   - nonce — отдельный 24-байтный секрет, сервер сравнивает его SHA-256 в confirm;
 *   - TTL короткий, scheduled cleanup собирает мусор.
 *
 * Логика поделена на чистое ядро [`runRequestQrLogin`] и onCall-обёртку — это
 * позволяет покрыть ядро интеграционными тестами против Firestore-эмулятора без
 * подъёма всего functions runtime (см. `functions/test/qr-login-emulator.spec.ts`).
 */

export type RequestQrLoginInput = {
  ephemeralPubKeySpki?: unknown;
  devicePlatform?: unknown;
  deviceLabel?: unknown;
  deviceId?: unknown;
};

export type RequestQrLoginContext = {
  /**
   * [audit H-003] `ip` / `userAgent` намеренно не передаются: они не
   * сохраняются в публично-читаемый `qrLoginSessions/{sessionId}`, а для
   * rate-limit достаточно `callerIpKey(request.rawRequest)` снаружи.
   */
  /** ISO-2 country код, обычно из заголовка `X-Appengine-Country`. */
  country?: string;
  /** Город из заголовка `X-Appengine-City` (если доступен). */
  city?: string;
};

export type RequestQrLoginResult = {
  sessionId: string;
  nonce: string;
  expiresAt: string;
  ttlSec: number;
};

const PLATFORMS = new Set(["web", "ios", "android"]);
export const QR_LOGIN_TTL_SEC = 90;

function randomB64Url(byteLength: number): string {
  const buf = nodeCrypto.randomBytes(byteLength);
  return buf
    .toString("base64")
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

/** Серверный hash nonce — клиент знает только сырой nonce, сервер хранит SHA-256(sessionId|nonce). */
export function hashNonceForStorage(nonce: string, sessionId: string): string {
  return nodeCrypto
    .createHash("sha256")
    .update(`${sessionId}|${nonce}`, "utf8")
    .digest("base64");
}

/**
 * Чистое ядро `requestQrLogin`. Не зависит от Cloud Functions runtime —
 * принимает Firestore-инстанс явно, что позволяет вызывать его в тестах
 * против эмулятора. onCall-обёртка ниже просто прокидывает `admin.firestore()`
 * и заголовки запроса.
 */
export async function runRequestQrLogin(
  db: admin.firestore.Firestore,
  data: RequestQrLoginInput,
  ctx: RequestQrLoginContext = {}
): Promise<RequestQrLoginResult> {
  const pubKey = typeof data?.ephemeralPubKeySpki === "string" ?
    data.ephemeralPubKeySpki.trim() :
    "";
  const platformRaw = typeof data?.devicePlatform === "string" ?
    data.devicePlatform.trim().toLowerCase() :
    "";
  const labelRaw = typeof data?.deviceLabel === "string" ?
    data.deviceLabel.trim().slice(0, 120) :
    "";
  const deviceId = typeof data?.deviceId === "string" ?
    data.deviceId.trim().slice(0, 64) :
    "";

  if (!deviceId || deviceId.length < 4) {
    throw new HttpsError("invalid-argument", "Bad deviceId.");
  }
  // deviceId дальше попадёт в Firestore document path (`e2eeDevices/{id}`).
  // Любые `/`, `.`, control-chars и т.п. ломают путь и вызывают
  // непрозрачную "internal" ошибку в Cloud Function. Жёстко требуем
  // безопасный набор символов — все наши клиенты (web ULID, mobile ULID)
  // ему удовлетворяют.
  if (!/^[A-Za-z0-9_-]+$/.test(deviceId)) {
    throw new HttpsError("invalid-argument", "Bad deviceId format.");
  }
  if (pubKey.length < 16 || pubKey.length > 4096) {
    throw new HttpsError("invalid-argument", "Bad ephemeralPubKeySpki.");
  }
  const platform = PLATFORMS.has(platformRaw) ? platformRaw : "web";
  const label = labelRaw || `${platform}-device`;

  const sessionId = randomB64Url(24);
  const nonce = randomB64Url(24);
  const nowMs = Date.now();
  const expiresAtIso = new Date(nowMs + QR_LOGIN_TTL_SEC * 1000).toISOString();
  const createdAtIso = new Date(nowMs).toISOString();

  // SECURITY [audit H-003]: `qrLoginSessions/{sessionId}` is intentionally
  // world-readable (the requesting client polls anonymously). We no longer
  // store `ip`/`userAgent` here — their leak via the 192-bit sessionId would
  // deanonymize the requesting device. `country`/`city`/`deviceLabel` are
  // low-PII and remain to surface "вход из X" in the approval UI. Full IP
  // history, if needed, lives in admin-only Cloud Logging.
  await db.doc(`qrLoginSessions/${sessionId}`).set({
    sessionId,
    nonceHash: hashNonceForStorage(nonce, sessionId),
    ephemeralPubKeySpki: pubKey,
    devicePlatform: platform,
    deviceLabel: label,
    deviceId,
    state: "awaiting_scan",
    createdAt: createdAtIso,
    expiresAt: expiresAtIso,
    country: (ctx.country || "").slice(0, 8),
    city: (ctx.city || "").slice(0, 64),
  });

  return {
    sessionId,
    nonce,
    expiresAt: expiresAtIso,
    ttlSec: QR_LOGIN_TTL_SEC,
  };
}

export const requestQrLogin = onCall(
  { region: "us-central1", cors: true },
  async (request) => {
    const headers = request.rawRequest?.headers ?? {};
    const xff = headers["x-forwarded-for"];
    const ipFromXff = typeof xff === "string" ?
      xff.split(",")[0]?.trim() ?? "" :
      Array.isArray(xff) ? xff[0]?.trim() ?? "" : "";
    const ip = request.rawRequest?.ip || ipFromXff || "";
    const ua = typeof headers["user-agent"] === "string" ? headers["user-agent"] : "";

    // SECURITY: this callable is intentionally pre-auth (it issues a QR
    // pairing session BEFORE the new device has any credentials). That makes
    // it a dream DoS target — every call writes a new Firestore document. Cap
    // each source IP to 10 calls per minute. App Check, when enforced, will
    // reduce this further by rejecting non-app callers entirely.
    const rl = await consumeRateLimit(admin.firestore(), {
      key: `requestQrLogin:${callerIpKey(request.rawRequest)}`,
      limit: 10,
      windowSec: 60,
    });
    if (!rl.allowed) {
      throw new HttpsError("resource-exhausted", "RATE_LIMITED");
    }
    // Google Cloud Functions/App Hosting проставляет эти заголовки на основе
    // GeoIP клиентского запроса. Бесплатно и без external API — отлично для
    // показа «последняя локация» на странице устройств.
    const country = typeof headers["x-appengine-country"] === "string" ?
      headers["x-appengine-country"] :
      "";
    const city = typeof headers["x-appengine-city"] === "string" ?
      headers["x-appengine-city"] :
      "";
    // ip/ua used only for rate-limit (callerIpKey above) and structured logs
    // — никогда в Firestore (audit H-003). Молча обозначаем void, чтобы
    // ESLint не ругался на unused.
    void ip;
    void ua;
    try {
      return await runRequestQrLogin(
        admin.firestore(),
        request.data as RequestQrLoginInput,
        { country, city }
      );
    } catch (e) {
      if (e instanceof HttpsError) throw e;
      const msg = e instanceof Error ? e.message : String(e);
      // [audit H-005] Полный stack может содержать пути файлов c uid'ами
      // или snapshot data. Cloud Logging тарифицируется поштучно — режем
      // первые 300 символов (хватит для top frame'ов, без leak'а PII).
      const stack = e instanceof Error && typeof e.stack === "string" ?
        e.stack.slice(0, 300) :
        undefined;
      logger.error("requestQrLogin: unexpected failure", {
        error: msg.slice(0, 200),
        stack,
      });
      throw new HttpsError("internal", "requestQrLogin failed");
    }
  }
);
