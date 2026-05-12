import {
  onCall,
  HttpsError,
  type CallableRequest,
} from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

import { callerIpKey, consumeRateLimit } from "../../lib/rate-limit";
import { generateUniqueUsernameAdmin } from "../../lib/generate-unique-username-admin";

/**
 * Yandex OAuth flow для Flutter-клиентов (включая macOS Debug на free
 * Apple ID, где `_auth.signInWithProvider` не работает).
 *
 * Flow:
 *   1. Клиент открывает webview на
 *      `https://oauth.yandex.ru/authorize?response_type=code&client_id=YANDEX_CLIENT_ID&redirect_uri=lighchat://yandex/callback`.
 *   2. Пользователь авторизуется → Yandex редиректит на
 *      `lighchat://yandex/callback?code=...`.
 *   3. Клиент вызывает эту функцию с `{ code }`.
 *   4. Функция меняет code → access_token (POST на `oauth.yandex.ru/token`),
 *      загружает user info (`login.yandex.ru/info`), создаёт/находит
 *      Firebase user и возвращает `customToken` для
 *      `_auth.signInWithCustomToken`.
 *
 * Серверные секреты:
 *   - `YANDEX_CLIENT_ID` — ID OAuth-приложения Yandex.
 *   - `YANDEX_CLIENT_SECRET` — secret OAuth-приложения.
 */

const yandexClientId = defineSecret("YANDEX_CLIENT_ID");
const yandexClientSecret = defineSecret("YANDEX_CLIENT_SECRET");

const db = admin.firestore();

interface YandexTokenResponse {
  access_token?: string;
  expires_in?: number;
  refresh_token?: string;
  token_type?: string;
}

interface YandexUserInfo {
  id?: string;
  login?: string;
  display_name?: string;
  real_name?: string;
  first_name?: string;
  last_name?: string;
  default_email?: string;
  default_avatar_id?: string;
  is_avatar_empty?: boolean;
  default_phone?: { number?: string };
}

export const signInWithYandex = onCall(
  {
    region: "us-central1",
    enforceAppCheck: false,
    timeoutSeconds: 60,
    memory: "256MiB",
    secrets: [yandexClientId, yandexClientSecret],
  },
  async (
    request: CallableRequest<{ code?: string; redirectUri?: string }>,
  ): Promise<{ customToken: string }> => {
    const code = (request.data?.code ?? "").trim();
    if (!code) {
      throw new HttpsError("invalid-argument", "code is required");
    }
    const redirectUri =
      (request.data?.redirectUri ?? "").trim() || "lighchat://yandex/callback";

    // Rate-limit: 10 попыток / минуту на IP, чтобы code-grant нельзя было
    // запоить на сервере.
    const ipKey = callerIpKey(request.rawRequest);
    const rateLimit = await consumeRateLimit(db, {
      key: `signInWithYandex:${ipKey}`,
      limit: 10,
      windowSec: 60,
    });
    if (!rateLimit.allowed) {
      throw new HttpsError("resource-exhausted", "Too many requests");
    }

    // 1. Обмен code → access_token.
    let tokenResp: YandexTokenResponse;
    try {
      const tokenRes = await fetch("https://oauth.yandex.ru/token", {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: new URLSearchParams({
          grant_type: "authorization_code",
          code,
          client_id: yandexClientId.value(),
          client_secret: yandexClientSecret.value(),
          redirect_uri: redirectUri,
        }).toString(),
      });
      if (!tokenRes.ok) {
        const body = await tokenRes.text();
        logger.warn("signInWithYandex: token exchange failed", {
          status: tokenRes.status,
          body: body.slice(0, 500),
        });
        throw new HttpsError("permission-denied", "yandex_code_invalid");
      }
      tokenResp = (await tokenRes.json()) as YandexTokenResponse;
    } catch (e) {
      if (e instanceof HttpsError) throw e;
      logger.error("signInWithYandex: token request error", e);
      throw new HttpsError("internal", "yandex_token_request_failed");
    }
    const accessToken = tokenResp.access_token;
    if (!accessToken) {
      throw new HttpsError("permission-denied", "yandex_no_access_token");
    }

    // 2. user info.
    let info: YandexUserInfo;
    try {
      const infoRes = await fetch("https://login.yandex.ru/info?format=json", {
        headers: { Authorization: `OAuth ${accessToken}` },
      });
      if (!infoRes.ok) {
        throw new HttpsError("internal", "yandex_userinfo_failed");
      }
      info = (await infoRes.json()) as YandexUserInfo;
    } catch (e) {
      if (e instanceof HttpsError) throw e;
      logger.error("signInWithYandex: userinfo error", e);
      throw new HttpsError("internal", "yandex_userinfo_request_failed");
    }
    const yandexId = info.id;
    if (!yandexId) {
      throw new HttpsError("internal", "yandex_no_user_id");
    }

    // 3. Find or create Firebase user. UID-схема: `yandex:{yandexId}` —
    // совпадает с веб-конвенцией provider-id-based UID.
    const uid = `yandex:${yandexId}`;
    const email = info.default_email?.trim();
    const displayName =
      info.display_name ||
      info.real_name ||
      [info.first_name, info.last_name].filter(Boolean).join(" ") ||
      info.login ||
      `user_${yandexId}`;
    const photoURL = info.default_avatar_id && !info.is_avatar_empty ?
      `https://avatars.yandex.net/get-yapic/${info.default_avatar_id}/islands-200` :
      undefined;

    try {
      await admin.auth().getUser(uid);
    } catch (e: unknown) {
      const code = (e as { code?: string })?.code ?? "";
      if (code === "auth/user-not-found") {
        await admin.auth().createUser({
          uid,
          displayName,
          ...(email ? { email, emailVerified: true } : {}),
          ...(photoURL ? { photoURL } : {}),
        });
        const username = await generateUniqueUsernameAdmin({
          db,
          uid,
          preferredCandidate: info.login || displayName,
        });
        await db.collection("users").doc(uid).set(
          {
            uid,
            displayName,
            email: email ?? null,
            photoURL: photoURL ?? null,
            username,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            providers: admin.firestore.FieldValue.arrayUnion("yandex"),
            yandexId,
          },
          { merge: true },
        );
      } else {
        logger.error("signInWithYandex: getUser failed", e);
        throw new HttpsError("internal", "auth_lookup_failed");
      }
    }

    // 4. Custom token.
    let customToken: string;
    try {
      customToken = await admin
        .auth()
        .createCustomToken(uid, { yandex: true });
    } catch (e) {
      logger.error("signInWithYandex: createCustomToken failed", e);
      throw new HttpsError("internal", "custom_token_failed");
    }

    return { customToken };
  },
);
