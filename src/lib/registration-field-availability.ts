/**
 * Проверка занятости телефона / email / логина до создания Firebase Auth user.
 *
 * [audit H-004] Раньше клиент делал `getDoc(registrationIndex/...)` без auth,
 * что превращало коллекцию в открытую базу phone/email → uid: атакующий
 * подбирал известные номера и получал маппинг на uid аккаунтов LighChat.
 *
 * Теперь идём через серверный callable `checkRegistrationKeyAvailable`,
 * который возвращает только `{ available: boolean }` (без uid), имеет
 * per-IP rate-limit и нормализует ключи на сервере. Pre-auth вызов
 * разрешён через `cors: true` — App Check сузит до App-аутентифицированных
 * клиентов, когда его включат.
 */

import { type Firestore } from "firebase/firestore";
import { getApp } from "firebase/app";
import { getFunctions, httpsCallable } from "firebase/functions";

type CheckPayload = {
  type: "phone" | "email" | "username";
  value: string;
  exceptUid?: string;
};

type CheckResult = {
  available: boolean;
};

function callCheck(payload: CheckPayload): Promise<CheckResult> {
  /** firestore-параметр сохраняется во внешнем API ради совместимости с
   *  существующими call-сайтами в `use-auth.tsx`; реальные RPC идут через
   *  Firebase Functions singleton, привязанный к тому же FirebaseApp. */
  const functions = getFunctions(getApp(), "us-central1");
  const fn = httpsCallable<CheckPayload, CheckResult>(
    functions,
    "checkRegistrationKeyAvailable"
  );
  return fn(payload).then((res) => res.data);
}

function logCallError(err: unknown): void {
  console.warn("[registration-field-availability] callable failed", err);
}

export async function isRegistrationPhoneTaken(
  _firestore: Firestore,
  phone: string,
  options?: { exceptUid?: string }
): Promise<boolean> {
  void _firestore;
  if (!phone) return false;
  try {
    const { available } = await callCheck({
      type: "phone",
      value: phone,
      exceptUid: options?.exceptUid,
    });
    return !available;
  } catch (e) {
    logCallError(e);
    throw e;
  }
}

export async function isRegistrationEmailTakenInIndex(
  _firestore: Firestore,
  email: string,
  options?: { exceptUid?: string }
): Promise<boolean> {
  void _firestore;
  if (!email) return false;
  try {
    const { available } = await callCheck({
      type: "email",
      value: email,
      exceptUid: options?.exceptUid,
    });
    return !available;
  } catch (e) {
    logCallError(e);
    throw e;
  }
}

export async function isRegistrationUsernameTakenInIndex(
  _firestore: Firestore,
  normalizedUsername: string,
  options?: { exceptUid?: string }
): Promise<boolean> {
  void _firestore;
  if (!normalizedUsername) return false;
  try {
    const { available } = await callCheck({
      type: "username",
      value: normalizedUsername,
      exceptUid: options?.exceptUid,
    });
    return !available;
  } catch (e) {
    logCallError(e);
    throw e;
  }
}
