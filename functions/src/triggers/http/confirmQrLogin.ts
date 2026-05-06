import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { hashNonceForStorage } from "./requestQrLogin";

/**
 * Вызывается на залогиненном устройстве после сканирования QR.
 * Тело: { sessionId, nonce, allow }.
 *
 * Шаги:
 *  1. Загружаем `qrLoginSessions/{sessionId}`. Если не существует, expired,
 *     или nonce не совпадает с хэшем — invalid-argument.
 *  2. Если `allow == false` → state='rejected', возвращаем {state:'rejected'}.
 *  3. Если `allow == true`:
 *     - создаём custom token для текущего auth.uid (`admin.auth().createCustomToken`);
 *     - пишем в документ: state='approved', scannerUid=uid, approvedAt, customToken,
 *       deviceFingerprint (chunks SHA-256 от ephemeralPubKeySpki — для UI верификации).
 *  4. Новое устройство по листенеру забирает customToken, делает signInWithCustomToken
 *     и **удаляет документ** (чтобы customToken был использован один раз).
 *
 * Доп. защиты:
 *  - блокированные пользователи (`accountBlock.active == true`) не могут
 *    подтверждать вход — это уже автоматически отклоняется Firebase Auth, но
 *    добавим раннюю проверку для понятного сообщения.
 *
 * Логика поделена на чистое ядро [`runConfirmQrLogin`] и onCall-обёртку: ядро
 * принимает Firestore + функцию выпуска customToken и тестируется в spec против
 * Firestore-эмулятора без полного functions-runtime.
 */

export type ConfirmQrLoginInput = {
  sessionId?: unknown;
  nonce?: unknown;
  allow?: unknown;
};

export type ConfirmQrLoginResult =
  | {
      state: "approved";
      uid: string;
      ephemeralPubKeySpki: string;
      devicePlatform: string;
      deviceLabel: string;
      deviceId: string;
    }
  | { state: "rejected" };

export type ConfirmQrLoginDeps = {
  db: admin.firestore.Firestore;
  /** Возвращает custom token для signInWithCustomToken на новом устройстве. */
  createCustomToken: (uid: string) => Promise<string>;
  /** Текущая дата (для тестирования истечения сессий). */
  now?: () => Date;
};

const APPROVED_TOKEN_TTL_SEC = 60; // окно использования customToken

/**
 * Чистое ядро `confirmQrLogin`. Не зависит от Cloud Functions runtime — тесты
 * вызывают эту функцию с Firestore-эмулятором и фейковым createCustomToken.
 */
export async function runConfirmQrLogin(
  uid: string,
  data: ConfirmQrLoginInput,
  deps: ConfirmQrLoginDeps
): Promise<ConfirmQrLoginResult> {
  const { db, createCustomToken } = deps;
  const now = (deps.now ?? (() => new Date()))();

  const sessionId = typeof data?.sessionId === "string" ? data.sessionId.trim() : "";
  const nonce = typeof data?.nonce === "string" ? data.nonce.trim() : "";
  const allow = data?.allow === true;

  if (!sessionId || sessionId.length < 16 || sessionId.length > 256) {
    throw new HttpsError("invalid-argument", "Bad sessionId.");
  }
  if (!nonce || nonce.length < 16 || nonce.length > 256) {
    throw new HttpsError("invalid-argument", "Bad nonce.");
  }

  const ref = db.doc(`qrLoginSessions/${sessionId}`);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "QR session not found or expired.");
  }
  const docData = snap.data() ?? {};
  const expiresAt = typeof docData.expiresAt === "string" ? docData.expiresAt : "";
  if (!expiresAt || new Date(expiresAt).getTime() < now.getTime()) {
    try {
      await ref.delete();
    } catch {
      // ignore — TTL cleanup CF добьёт.
    }
    throw new HttpsError("deadline-exceeded", "QR session expired.");
  }
  if (docData.state !== "awaiting_scan") {
    throw new HttpsError("failed-precondition", `QR session in state ${String(docData.state)}.`);
  }

  const expectedHash = hashNonceForStorage(nonce, sessionId);
  if (typeof docData.nonceHash !== "string" || docData.nonceHash !== expectedHash) {
    throw new HttpsError("permission-denied", "Bad nonce.");
  }

  if (!allow) {
    try {
      await ref.set({
        state: "rejected",
        rejectedAt: now.toISOString(),
        scannerUid: uid,
      }, { merge: true });
    } catch (e) {
      logger.error("confirmQrLogin: reject write failed", e);
    }
    return { state: "rejected" };
  }

  let userBlocked = false;
  try {
    const userSnap = await db.doc(`users/${uid}`).get();
    const blk = userSnap.exists ? (userSnap.data()?.accountBlock as { active?: boolean } | undefined) : undefined;
    if (blk?.active === true) userBlocked = true;
  } catch (e) {
    logger.warn("confirmQrLogin: user block lookup failed", e);
  }
  if (userBlocked) {
    throw new HttpsError("permission-denied", "Account is blocked.");
  }

  let customToken: string;
  try {
    customToken = await createCustomToken(uid);
  } catch (e) {
    logger.error("confirmQrLogin: createCustomToken failed", e);
    throw new HttpsError("internal", "Could not issue sign-in token.");
  }

  const approvedAtIso = now.toISOString();
  const tokenExpiresAtIso = new Date(now.getTime() + APPROVED_TOKEN_TTL_SEC * 1000).toISOString();
  try {
    await ref.set({
      state: "approved",
      scannerUid: uid,
      approvedAt: approvedAtIso,
      customToken,
      tokenExpiresAt: tokenExpiresAtIso,
    }, { merge: true });
  } catch (e) {
    logger.error("confirmQrLogin: approve write failed", e);
    throw new HttpsError("internal", "Could not write approval.");
  }

  // Best-effort: записываем геолокацию устройства в e2eeDevices, чтобы UI
  // на странице «Устройства» мог показать «последний вход: <city>, <country>».
  // Если запись падает — не валим весь approve.
  try {
    const newDeviceId = typeof docData.deviceId === "string" ? docData.deviceId : "";
    // Дополнительная защита: deviceId должен быть валидным document-id.
    // Старые qrLoginSessions, созданные без regex-валидации, могут содержать
    // мусор — пропускаем enrichment, чтобы не уронить approve.
    if (newDeviceId.length >= 4 && /^[A-Za-z0-9_-]+$/.test(newDeviceId)) {
      const country = typeof docData.country === "string" ? docData.country : "";
      const city = typeof docData.city === "string" ? docData.city : "";
      const ip = typeof docData.ip === "string" ? docData.ip : "";
      await db.doc(`users/${uid}/e2eeDevices/${newDeviceId}`).set({
        lastLoginAt: approvedAtIso,
        lastLoginCountry: country,
        lastLoginCity: city,
        lastLoginIp: ip,
      }, { merge: true });
    }
  } catch (e) {
    logger.warn("confirmQrLogin: failed to enrich e2eeDevice with location", e);
  }

  return {
    state: "approved",
    uid,
    ephemeralPubKeySpki: typeof docData.ephemeralPubKeySpki === "string" ? docData.ephemeralPubKeySpki : "",
    devicePlatform: typeof docData.devicePlatform === "string" ? docData.devicePlatform : "web",
    deviceLabel: typeof docData.deviceLabel === "string" ? docData.deviceLabel : "",
    deviceId: typeof docData.deviceId === "string" ? docData.deviceId : "",
  };
}

export const confirmQrLogin = onCall(
  { region: "us-central1", cors: true },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Sign in to approve a new device.");
    }
    return runConfirmQrLogin(
      request.auth.uid,
      request.data as ConfirmQrLoginInput,
      {
        db: admin.firestore(),
        createCustomToken: (uid: string) =>
          admin.auth().createCustomToken(uid, { qrLogin: true }),
      }
    );
  }
);
