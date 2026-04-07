/**
 * Проверка занятости телефона / email / логина до создания Firebase Auth user.
 * Данные — коллекция `registrationIndex` (публичное чтение в firestore.rules).
 */

import { doc, getDoc, type Firestore } from "firebase/firestore";
import {
  registrationEmailKey,
  registrationPhoneKey,
  registrationUsernameKey,
} from "@/lib/registration-index-keys";

function logIndexReadError(err: unknown): void {
  console.warn("[registration-field-availability] getDoc registrationIndex", err);
}

export async function isRegistrationPhoneTaken(
  firestore: Firestore,
  phone: string,
): Promise<boolean> {
  const key = registrationPhoneKey(phone);
  if (!key) return false;
  try {
    const snap = await getDoc(doc(firestore, "registrationIndex", key));
    return snap.exists();
  } catch (e) {
    logIndexReadError(e);
    throw e;
  }
}

export async function isRegistrationEmailTakenInIndex(
  firestore: Firestore,
  email: string,
): Promise<boolean> {
  const key = registrationEmailKey(email);
  if (!key) return false;
  try {
    const snap = await getDoc(doc(firestore, "registrationIndex", key));
    return snap.exists();
  } catch (e) {
    logIndexReadError(e);
    throw e;
  }
}

export async function isRegistrationUsernameTakenInIndex(
  firestore: Firestore,
  normalizedUsername: string,
): Promise<boolean> {
  const key = registrationUsernameKey(normalizedUsername);
  if (!key) return false;
  try {
    const snap = await getDoc(doc(firestore, "registrationIndex", key));
    return snap.exists();
  } catch (e) {
    logIndexReadError(e);
    throw e;
  }
}
