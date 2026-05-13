import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import {
  telegramUserIdFromPayload,
  verifyTelegramLoginWidget,
} from "../../lib/telegram-widget-verify";
import { mergeProviderPhoneAndAvatarIntoUserDoc } from "../../lib/merge-provider-profile-firestore";
import { generateUniqueUsernameAdmin } from "../../lib/generate-unique-username-admin";
import { callerIpKey, consumeRateLimit } from "../../lib/rate-limit";
import { claimTelegramAuthOnce } from "../../lib/telegram-widget-replay-store";

const telegramBotToken = defineSecret("TELEGRAM_BOT_TOKEN");

// [audit H-005] redactTelegramAuthPayloadForLogs удалён вместе с веткой
// `TELEGRAM_DEBUG_LOGIN_INFO` — раньше пропускал first_name/last_name/
// username/photo_url в Cloud Logging. Если для разовой отладки нужен
// payload, проще снять через `gcloud logging read` чем держать prod-flag.

/** Код ошибки Firebase Auth Admin (разные версии SDK кладут `code` или `errorInfo.code`). */
function firebaseAuthErrorCode(e: unknown): string {
  if (typeof e !== "object" || e === null) return "";
  const o = e as Record<string, unknown>;
  if (typeof o.code === "string") return o.code;
  const ei = o.errorInfo;
  if (ei && typeof ei === "object" && ei !== null) {
    const c = (ei as Record<string, unknown>).code;
    if (typeof c === "string") return c;
  }
  return "";
}

async function updateTelegramUserProfile(
  uid: string,
  displayName: string,
  photoURL: string | undefined
): Promise<void> {
  try {
    await admin.auth().updateUser(uid, {
      displayName,
      ...(photoURL ? { photoURL } : {}),
    });
  } catch (e: unknown) {
    if (photoURL) {
      logger.warn("signInWithTelegram: updateUser with photoURL failed, retry without photo", e);
      await admin.auth().updateUser(uid, { displayName });
      return;
    }
    throw e;
  }
}

async function getOrCreateTelegramAuthUser(
  uid: string,
  displayName: string,
  photoURL: string | undefined
): Promise<void> {
  try {
    await admin.auth().getUser(uid);
    await updateTelegramUserProfile(uid, displayName, photoURL);
    return;
  } catch (e: unknown) {
    const code = firebaseAuthErrorCode(e);
    if (code !== "auth/user-not-found") {
      logger.error("signInWithTelegram: getUser error", e);
      throw new HttpsError("internal", "Could not load Firebase user.");
    }
  }

  try {
    await admin.auth().createUser({
      uid,
      displayName,
      ...(photoURL ? { photoURL } : {}),
    });
  } catch (e: unknown) {
    const code = firebaseAuthErrorCode(e);
    if (code === "auth/uid-already-exists") {
      logger.warn("signInWithTelegram: createUser race (uid exists), updating profile");
      await updateTelegramUserProfile(uid, displayName, photoURL);
      return;
    }
    if (photoURL) {
      try {
        await admin.auth().createUser({ uid, displayName });
        return;
      } catch (e2: unknown) {
        const c2 = firebaseAuthErrorCode(e2);
        if (c2 === "auth/uid-already-exists") {
          await updateTelegramUserProfile(uid, displayName, undefined);
          return;
        }
        logger.error("signInWithTelegram: createUser without photo failed", e2);
        throw new HttpsError("internal", "Could not create Firebase user.");
      }
    }
    logger.error("signInWithTelegram: createUser failed", e);
    throw new HttpsError("internal", "Could not create Firebase user.");
  }
}

function displayNameFromTelegram(raw: Record<string, unknown>): string {
  const first = typeof raw.first_name === "string" ? raw.first_name.trim() : "";
  const last = typeof raw.last_name === "string" ? raw.last_name.trim() : "";
  const combined = [first, last].filter(Boolean).join(" ").trim();
  if (combined.length > 0) return combined.slice(0, 128);
  const un = typeof raw.username === "string" ? raw.username.trim() : "";
  if (un.length > 0) return un.slice(0, 128);
  return "Telegram";
}

function photoUrlFromTelegram(raw: Record<string, unknown>): string | undefined {
  const u = raw.photo_url;
  if (typeof u !== "string" || u.trim().length === 0) return undefined;
  try {
    const url = new URL(u);
    if (url.protocol !== "https:") return undefined;
    return u.slice(0, 2048);
  } catch {
    return undefined;
  }
}

function phoneFromTelegramPayload(raw: Record<string, unknown>): string | undefined {
  const candidates = [raw.phone_number, raw.phone, raw.contact_phone];
  for (const c of candidates) {
    if (typeof c !== "string") continue;
    const s = c.trim();
    if (s.length < 8 || s.length > 32) continue;
    if (s.startsWith("+") || /^\d/u.test(s)) return s;
  }
  return undefined;
}

/**
 * Публичный callable: клиент передаёт объект авторизации Telegram Login Widget;
 * проверяется HMAC, создаётся/обновляется пользователь Firebase с UID `tg_<id>`,
 * возвращается custom token с claim `telegram: true`.
 *
 * Секрет: `firebase functions:secrets:set TELEGRAM_BOT_TOKEN`
 */
export const signInWithTelegram = onCall(
  {
    region: "us-central1",
    secrets: [telegramBotToken],
    enforceAppCheck: false,
    cors: true,
  },
  async (request) => {
    // SECURITY: pre-auth callable. Per-IP rate limit (10 req / minute).
    // Same rationale as requestQrLogin: stop automated brute-force /
    // resource exhaustion before we touch HMAC verification, Firestore writes
    // or Auth user creation. Once App Check is enforced this becomes a
    // belt-and-suspenders second line of defence.
    const rlIp = await consumeRateLimit(admin.firestore(), {
      key: `signInWithTelegram:ip:${callerIpKey(request.rawRequest)}`,
      limit: 10,
      windowSec: 60,
    });
    if (!rlIp.allowed) {
      throw new HttpsError("resource-exhausted", "RATE_LIMITED");
    }

    const botToken = telegramBotToken.value().trim();
    if (!botToken) {
      throw new HttpsError(
        "failed-precondition",
        "TELEGRAM_BOT_TOKEN is not configured."
      );
    }

    const body = request.data as { auth?: Record<string, unknown> };
    const raw = body?.auth;
    if (!raw || typeof raw !== "object") {
      throw new HttpsError("invalid-argument", "Missing auth payload.");
    }

    // [audit H-005] TELEGRAM_DEBUG_LOGIN_INFO ветка снята — раньше при
    // включённом env flag в Cloud Logging писался полный payload (хоть и
    // через redactor, который пропускал first_name/last_name/username).
    // Если для отладки нужен payload — лог разово через `gcloud functions
    // logs` руками, а не через persistent prod-flag.

    if (!verifyTelegramLoginWidget(raw, botToken)) {
      logger.warn("signInWithTelegram: invalid telegram hash");
      throw new HttpsError("permission-denied", "Invalid Telegram authorization.");
    }

    // SECURITY: anti-replay. The widget signature is valid for some TTL; an
    // attacker who captures one payload (logs / shared screenshot of the
    // login URL) could otherwise reuse it any number of times within the
    // window. Burn the (auth_date, hash) tuple via Firestore-create — second
    // use returns ALREADY_EXISTS and we reject.
    const authDate = Number(raw.auth_date);
    const hash = String(raw.hash);
    const replay = await claimTelegramAuthOnce(
      admin.firestore(),
      authDate,
      hash,
      600, // matches TELEGRAM_AUTH_MAX_AGE_SEC in telegram-widget-verify.ts
    );
    if (!replay.ok) {
      if (replay.reason === "REPLAY") {
        logger.warn("signInWithTelegram: replay attempt", { authDate });
        throw new HttpsError("permission-denied", "TELEGRAM_AUTH_ALREADY_USED");
      }
      // Storage failure: fail closed for this auth attempt — better to ask
      // the user to retry than to allow a potentially-replayed signature.
      logger.warn("signInWithTelegram: replay store unavailable, refusing");
      throw new HttpsError("unavailable", "TRY_AGAIN");
    }

    const telegramId = telegramUserIdFromPayload(raw);
    if (!telegramId) {
      throw new HttpsError("invalid-argument", "Invalid Telegram user id.");
    }

    const uid = `tg_${telegramId}`;
    const displayName = displayNameFromTelegram(raw);
    const photoURL = photoUrlFromTelegram(raw);
    const phoneRaw = phoneFromTelegramPayload(raw);

    await getOrCreateTelegramAuthUser(uid, displayName, photoURL);

    const db = admin.firestore();

    try {
      await mergeProviderPhoneAndAvatarIntoUserDoc({
        db,
        uid,
        providerPhoneRaw: phoneRaw,
        providerPhotoUrl: photoURL,
        log: logger,
      });
    } catch (e) {
      logger.warn("signInWithTelegram: profile merge skipped", { uid, e });
    }

    try {
      const userRef = db.doc(`users/${uid}`);
      let userSnap = await userRef.get();
      for (let attempt = 0; attempt < 6 && !userSnap.exists; attempt++) {
        await new Promise((r) => setTimeout(r, 150));
        userSnap = await userRef.get();
      }
      if (!userSnap.exists) {
        logger.warn("signInWithTelegram: users doc not ready, skip username bootstrap", {
          uid,
        });
      } else {
        const data = userSnap.data() ?? {};
        const existingUsername = String(data.username ?? "")
          .trim()
          .replace(/^@/, "");
        if (!existingUsername) {
          const tgHandle =
            typeof raw.username === "string" && raw.username.trim().length > 0 ?
              raw.username.trim() :
              undefined;
          const username = await generateUniqueUsernameAdmin({
            db,
            uid,
            preferredCandidate: tgHandle,
            fallbackCandidate: displayName,
          });
          await userRef.set({ username }, { merge: true });
        }
      }
    } catch (e) {
      logger.warn("signInWithTelegram: username bootstrap skipped", { uid, e });
    }

    try {
      const customToken = await admin
        .auth()
        .createCustomToken(uid, { telegram: true });
      return { customToken, uid };
    } catch (e: unknown) {
      logger.error("signInWithTelegram: createCustomToken failed", e);
      throw new HttpsError("internal", "Could not issue sign-in token.");
    }
  }
);
