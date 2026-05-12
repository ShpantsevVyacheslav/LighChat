import { adminDb } from "@/firebase/admin";
import {
  isNormalizedUsernameTokenAllowed,
  normalizeUsernameCandidate,
} from "@/lib/username-candidate";
import { logger } from "@/lib/logger";

async function isUsernameTakenInRegistrationIndexAdmin(opts: {
  normalizedUsername: string;
  exceptUid: string;
}): Promise<boolean | "error"> {
  const key = `u_${opts.normalizedUsername}`;
  try {
    const snap = await adminDb.doc(`registrationIndex/${key}`).get();
    if (!snap.exists) return false;
    const owner = snap.get("uid") as string | undefined;
    if (owner === opts.exceptUid) return false;
    return true;
  } catch (e) {
    logger.warn(
      'gen-unique-username',
      'registrationIndex read failed',
      e,
    );
    return "error";
  }
}

export async function generateUniqueUsernameAdmin(opts: {
  uid: string;
  /** Первый кандидат (например, login Яндекса). */
  preferredCandidate?: string | undefined;
  /** Фоллбек-кандидат (например, displayName). */
  fallbackCandidate?: string | undefined;
}): Promise<string> {
  const seedFromUid = String(opts.uid).replace(/[^a-zA-Z0-9]/gu, "").slice(-8);

  const candidates: string[] = [];
  if (opts.preferredCandidate) candidates.push(opts.preferredCandidate);
  if (opts.fallbackCandidate) candidates.push(opts.fallbackCandidate);
  candidates.push(`user_${seedFromUid || "new"}`);

  for (const rawBase of candidates) {
    const base = normalizeUsernameCandidate(rawBase);
    if (base.length < 3) continue;
    if (!isNormalizedUsernameTokenAllowed(base)) continue;

    for (let i = 0; i < 20; i++) {
      const candidate = i === 0 ? base : `${base}_${i + 1}`;
      const normalized = normalizeUsernameCandidate(candidate);
      if (normalized.length < 3) continue;
      if (!isNormalizedUsernameTokenAllowed(normalized)) continue;

      const taken = await isUsernameTakenInRegistrationIndexAdmin({
        normalizedUsername: normalized,
        exceptUid: opts.uid,
      });
      if (taken === false) return normalized;
      if (taken === "error") break;
    }
  }

  return `user_${seedFromUid || "new"}_${Date.now()
    .toString(36)
    .slice(-4)}`.slice(0, 30);
}

