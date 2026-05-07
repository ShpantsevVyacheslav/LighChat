/**
 * [audit H-004] Pre-auth callable, проверяющий «свободен ли ключ регистрации»
 * (телефон / email / username). Возвращает только `{ available: boolean }` —
 * НЕ uid владельца, чтобы атакующий не смог энумерировать
 * `registrationIndex/...` → uid → users/{uid}.
 *
 * Раньше клиент звал `getDoc(registrationIndex/...)` напрямую без auth, что
 * позволяло массово проверить, кто из «известных номеров телефонов» имеет
 * аккаунт в LighChat (и затем читать профили через `signInAnonymously`).
 *
 * Защита от перебора: per-IP rate-limit (60/min — выше pre-auth callable
 * QR-login потому, что в форме регистрации валидация ловит каждый keystroke
 * с дебаунсом, и одна сессия может легитимно сделать ~5-10 проверок).
 * App Check, когда включат, сузит до App-аутентифицированных вызовов.
 */

import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { callerIpKey, consumeRateLimit } from "../../lib/rate-limit";
import {
  registrationEmailKey,
  registrationPhoneKey,
  registrationUsernameKey,
} from "../../lib/registrationIndexKeys";

export type CheckRegistrationKeyType = "phone" | "email" | "username";

export type CheckRegistrationKeyInput = {
  /** «phone» / «email» / «username». */
  type?: unknown;
  /** Сырой ввод пользователя — нормализация на сервере. */
  value?: unknown;
  /**
   * Если ключ уже принадлежит мне — считать как доступный. Тип uid строкой
   * — нет нужды доверять: server проверит, что (а) uid существует
   * в Firebase Auth и (б) клиент авторизован под ним. На pre-auth этапе
   * клиент не передаёт `exceptUid`.
   */
  exceptUid?: unknown;
};

export type CheckRegistrationKeyResult = {
  available: boolean;
};

/** Чистое ядро для тестов и для onCall-обёртки. */
export async function runCheckRegistrationKeyAvailable(
  db: admin.firestore.Firestore,
  data: CheckRegistrationKeyInput
): Promise<CheckRegistrationKeyResult> {
  const type = String(data?.type ?? "").trim().toLowerCase();
  const value = String(data?.value ?? "");
  const exceptUid =
    typeof data?.exceptUid === "string" && data.exceptUid.trim().length > 0 ?
      data.exceptUid.trim() :
      null;

  let key: string | null = null;
  if (type === "phone") {
    key = registrationPhoneKey(value);
  } else if (type === "email") {
    key = registrationEmailKey(value);
  } else if (type === "username") {
    key = registrationUsernameKey(value);
  } else {
    throw new HttpsError(
      "invalid-argument",
      "Unsupported `type` (expected one of phone/email/username)."
    );
  }

  // Невалидный ввод (пустой телефон, пустой username и т.п.) — считаем
  // «доступным», как и старый клиентский код: дальше форма сама отклонит.
  if (!key) return { available: true };

  const snap = await db.doc(`registrationIndex/${key}`).get();
  if (!snap.exists) return { available: true };

  const ownerUid = snap.get("uid");
  if (typeof ownerUid !== "string" || ownerUid.length === 0) {
    return { available: true };
  }
  if (exceptUid && ownerUid === exceptUid) return { available: true };
  return { available: false };
}

export const checkRegistrationKeyAvailable = onCall(
  { region: "us-central1", cors: true },
  async (request) => {
    const rl = await consumeRateLimit(admin.firestore(), {
      key: `checkRegKey:${callerIpKey(request.rawRequest)}`,
      limit: 60,
      windowSec: 60,
    });
    if (!rl.allowed) {
      throw new HttpsError("resource-exhausted", "RATE_LIMITED");
    }

    /**
     * `exceptUid` имеет смысл только когда вызывающий уже авторизован
     * (правка собственного профиля). Принимаем только если совпадает с
     * `request.auth.uid` — иначе игнорируем (атакующий не может назначить
     * чужой uid, чтобы пробить чужую регистрацию).
     */
    const rawInput = (request.data ?? {}) as CheckRegistrationKeyInput;
    const exceptUid =
      typeof rawInput.exceptUid === "string" ?
        rawInput.exceptUid.trim() :
        "";
    const safeExceptUid =
      exceptUid && request.auth?.uid && exceptUid === request.auth.uid ?
        exceptUid :
        undefined;

    try {
      return await runCheckRegistrationKeyAvailable(admin.firestore(), {
        type: rawInput.type,
        value: rawInput.value,
        exceptUid: safeExceptUid,
      });
    } catch (e) {
      if (e instanceof HttpsError) throw e;
      logger.error("checkRegistrationKeyAvailable: unexpected failure", e);
      throw new HttpsError("internal", "Could not check key availability.");
    }
  }
);
