/**
 * Admin SDK (Functions): дозаполнение `users/{uid}` телефоном/аватаром из внешнего провайдера,
 * если поля пустые/плейсхолдер и телефон не занят в `registrationIndex` другим uid.
 */

import * as admin from "firebase-admin";
import {
  normalizePhoneDigits,
  registrationPhoneKey,
} from "./registrationIndexKeys";

const DICEBEAR_AVATAR_HOST = "api.dicebear.com";

function isDicebearPlaceholderAvatar(avatar: string | undefined): boolean {
  const u = String(avatar ?? "").trim().toLowerCase();
  if (!u) return true;
  try {
    return new URL(u).hostname === DICEBEAR_AVATAR_HOST;
  } catch {
    return false;
  }
}

/** Маска как на web (`PhoneInput`): +7 (___) ___-__-__ для RU 11 цифр с leading 7. */
export function applyPhoneMaskRuFromDigits11(digits11WithLeading7: string): string {
  const d = normalizePhoneDigits(digits11WithLeading7);
  if (!(d.length === 11 && d.startsWith("7"))) return "";
  const tail = d.slice(1, 11);
  const a = tail.slice(0, 3);
  const b = tail.slice(3, 6);
  const c = tail.slice(6, 8);
  const e = tail.slice(8, 10);
  return `+7 (${a}) ${b}-${c}-${e}`;
}

function formatStoredPhoneFromProviderDigits(digits: string): string {
  const d = normalizePhoneDigits(digits);
  if (d.length < 10) return "";
  if (d.length === 11 && d.startsWith("7")) {
    return applyPhoneMaskRuFromDigits11(d);
  }
  return `+${d.slice(0, 32)}`;
}

async function isRegistrationPhoneTakenForUid(
  db: admin.firestore.Firestore,
  phone: string,
  exceptUid: string,
): Promise<boolean | "error"> {
  const key = registrationPhoneKey(phone);
  if (!key) return false;
  try {
    const snap = await db.doc(`registrationIndex/${key}`).get();
    if (!snap.exists) return false;
    const owner = snap.get("uid") as string | undefined;
    if (owner === exceptUid) return false;
    return true;
  } catch {
    return "error";
  }
}

export async function mergeProviderPhoneAndAvatarIntoUserDoc(opts: {
  db: admin.firestore.Firestore;
  uid: string;
  providerPhoneRaw?: string | undefined;
  providerPhotoUrl?: string | undefined;
  log?: { info: (...args: unknown[]) => void; warn: (...args: unknown[]) => void };
}): Promise<void> {
  const { db, uid, providerPhoneRaw, providerPhotoUrl, log } = opts;
  if (!uid) return;
  const userRef = db.doc(`users/${uid}`);

  for (let attempt = 0; attempt < 6; attempt++) {
    const snap = await userRef.get();
    if (snap.exists) break;
    if (attempt === 5) {
      log?.info?.(
        "[merge-provider-profile-firestore] users/%s not ready yet; skip merge",
        uid,
      );
      return;
    }
    await new Promise((r) => setTimeout(r, 150));
  }

  const snap = await userRef.get();
  if (!snap.exists) return;
  const data = snap.data() ?? {};
  if (data.deletedAt) return;

  const patch: Record<string, unknown> = {};

  const existingPhone = String(data.phone ?? "").trim();
  const digits = normalizePhoneDigits(String(providerPhoneRaw ?? ""));
  if (
    existingPhone.length === 0 &&
    digits.length >= 10 &&
    providerPhoneRaw &&
    String(providerPhoneRaw).trim().length > 0
  ) {
    const stored = formatStoredPhoneFromProviderDigits(digits);
    if (stored) {
      const taken = await isRegistrationPhoneTakenForUid(db, stored, uid);
      if (taken === false) patch.phone = stored;
      else if (taken === "error") {
        log?.warn?.(
          "[merge-provider-profile-firestore] registrationIndex read failed; skip phone",
          { uid },
        );
      }
    }
  }

  const existingAvatar = String(data.avatar ?? "").trim();
  const photo = String(providerPhotoUrl ?? "").trim();
  if (
    photo.length > 0 &&
    (existingAvatar.length === 0 || isDicebearPlaceholderAvatar(existingAvatar))
  ) {
    try {
      const url = new URL(photo);
      if (url.protocol === "https:") patch.avatar = photo.slice(0, 2048);
    } catch {
      /* ignore */
    }
  }

  if (Object.keys(patch).length === 0) return;
  await userRef.set(patch, { merge: true });
}
