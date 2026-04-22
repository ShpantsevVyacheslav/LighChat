import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import {
  telegramUserIdFromPayload,
  verifyTelegramLoginWidget,
} from "../../lib/telegram-widget-verify";

const telegramBotToken = defineSecret("TELEGRAM_BOT_TOKEN");

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
    cors: true,
  },
  async (request) => {
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

    if (!verifyTelegramLoginWidget(raw, botToken)) {
      logger.warn("signInWithTelegram: invalid telegram hash");
      throw new HttpsError("permission-denied", "Invalid Telegram authorization.");
    }

    const telegramId = telegramUserIdFromPayload(raw);
    if (!telegramId) {
      throw new HttpsError("invalid-argument", "Invalid Telegram user id.");
    }

    const uid = `tg_${telegramId}`;
    const displayName = displayNameFromTelegram(raw);
    const photoURL = photoUrlFromTelegram(raw);

    try {
      await admin.auth().getUser(uid);
      await admin.auth().updateUser(uid, {
        displayName,
        ...(photoURL ? { photoURL } : {}),
      });
    } catch (e: unknown) {
      const code =
        typeof e === "object" && e !== null && "code" in e
          ? String((e as { code: unknown }).code)
          : "";
      if (code === "auth/user-not-found") {
        await admin.auth().createUser({
          uid,
          displayName,
          ...(photoURL ? { photoURL } : {}),
        });
      } else {
        logger.error("signInWithTelegram: auth user error", e);
        throw new HttpsError("internal", "Could not create or update Firebase user.");
      }
    }

    const customToken = await admin
      .auth()
      .createCustomToken(uid, { telegram: true });

    return { customToken, uid };
  }
);
