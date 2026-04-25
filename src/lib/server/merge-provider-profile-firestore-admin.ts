/**
 * Admin SDK: дозаполнение `users/{uid}` данными провайдера (телефон/аватар),
 * если в ответе API они есть и не конфликтуют с `registrationIndex`.
 */

import { adminDb } from "@/firebase/admin";
import { registrationPhoneKey } from "@/lib/registration-index-keys";
import {
  applyPhoneMask,
  normalizePhoneDigits,
} from "@/lib/phone-utils";

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

async function isRegistrationPhoneTakenForUidAdmin(
  phone: string,
  exceptUid: string,
): Promise<boolean | "error"> {
  const key = registrationPhoneKey(phone);
  if (!key) return false;
  try {
    const snap = await adminDb.doc(`registrationIndex/${key}`).get();
    if (!snap.exists) return false;
    const owner = snap.get("uid") as string | undefined;
    if (owner === exceptUid) return false;
    return true;
  } catch (e) {
    console.warn(
      "[merge-provider-profile-firestore-admin] registrationIndex read failed; skip phone write",
      e,
    );
    return "error";
  }
}

function formatStoredPhoneFromProviderDigits(digits: string): string {
  const d = normalizePhoneDigits(digits);
  if (d.length < 10) return "";
  if (d.length === 11 && d.startsWith("7")) {
    return applyPhoneMask(`+${d}`);
  }
  return `+${d.slice(0, 32)}`;
}

export async function mergeProviderPhoneAndAvatarIntoUserDocAdmin(opts: {
  uid: string;
  providerPhoneRaw?: string | undefined;
  providerPhotoUrl?: string | undefined;
}): Promise<void> {
  const { uid, providerPhoneRaw, providerPhotoUrl } = opts;
  if (!uid) return;

  const userRef = adminDb.doc(`users/${uid}`);

  for (let attempt = 0; attempt < 6; attempt++) {
    const snap = await userRef.get();
    if (snap.exists) break;
    if (attempt === 5) {
      console.info(
        "[merge-provider-profile-firestore-admin] users/%s not ready yet; skip merge",
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
      const taken = await isRegistrationPhoneTakenForUidAdmin(stored, uid);
      if (taken === false) patch.phone = stored;
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
      /* ignore invalid avatar URL */
    }
  }

  if (Object.keys(patch).length === 0) return;

  try {
    await userRef.set(patch, { merge: true });
  } catch (e) {
    console.error(
      `[merge-provider-profile-firestore-admin] users/${uid} merge failed`,
      e,
    );
  }
}
