import { adminDb } from "@/firebase/admin";

const USERNAME_ALLOWED = /^[a-zA-Z0-9_]+$/u;

function normalizeUsernameCandidate(raw: string): string {
  const base = String(raw ?? "")
    .trim()
    .replace(/^@/, "")
    .toLowerCase()
    .replace(/[^a-zA-Z0-9_]+/gu, "_")
    .replace(/^_+|_+$/gu, "");
  return base.slice(0, 30);
}

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
    console.warn(
      "[generate-unique-username-admin] registrationIndex read failed",
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
    if (!USERNAME_ALLOWED.test(base)) continue;

    for (let i = 0; i < 20; i++) {
      const candidate = i === 0 ? base : `${base}_${i + 1}`;
      const normalized = normalizeUsernameCandidate(candidate);
      if (normalized.length < 3) continue;
      if (!USERNAME_ALLOWED.test(normalized)) continue;

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

