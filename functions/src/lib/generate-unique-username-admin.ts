/**
 * Admin SDK (Functions): уникальный `users.username` по `registrationIndex`,
 * с приоритетным кандидатом (например `@username` из Telegram Login Widget).
 */

import * as admin from "firebase-admin";
import { registrationUsernameKey } from "./registrationIndexKeys";

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

async function isUsernameTakenInRegistrationIndex(opts: {
  db: admin.firestore.Firestore;
  normalizedUsername: string;
  exceptUid: string;
}): Promise<boolean | "error"> {
  const key = registrationUsernameKey(opts.normalizedUsername);
  if (!key) return false;
  try {
    const snap = await opts.db.doc(`registrationIndex/${key}`).get();
    if (!snap.exists) return false;
    const owner = snap.get("uid") as string | undefined;
    if (owner === opts.exceptUid) return false;
    return true;
  } catch {
    return "error";
  }
}

export async function generateUniqueUsernameAdmin(opts: {
  db: admin.firestore.Firestore;
  uid: string;
  preferredCandidate?: string | undefined;
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

      const taken = await isUsernameTakenInRegistrationIndex({
        db: opts.db,
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
