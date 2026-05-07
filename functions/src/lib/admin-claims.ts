// SECURITY: admin authorization via Firebase Custom Claims, with a backward-
// compatible Firestore role fallback. Custom Claims live inside the signed
// ID token, so:
//   - Cheap to verify (no extra Firestore read on every call)
//   - Tamper-proof (only a service account can call setCustomUserClaims)
//   - Unaffected by future regressions in firestore.rules that might let a
//     malicious user mutate users/{uid}.role
//
// Migration: existing admins still have role:'admin' in Firestore but no
// claim. assertCallerIsAdmin() therefore checks BOTH; new admin promotions
// (see ensureAdminClaim below) write both at once. Once `syncAdminClaims`
// has run for every existing admin, the Firestore fallback becomes dead
// code and can be removed.

import * as admin from "firebase-admin";

export const ADMIN_CLAIM_KEY = "admin";

export type AdminCheck = {
  uid: string;
  name: string;
  /** True if authorization came from a JWT custom claim (preferred). */
  fromClaim: boolean;
};

/**
 * Verify that the caller of a Cloud Function is an administrator.
 *
 * Preference order:
 *   1. Decoded ID token has `admin: true` (Custom Claim — cheap, signed).
 *   2. users/{uid}.role === 'admin' (legacy Firestore-side, requires a read).
 *
 * On success returns the trusted identity. On failure throws Error with
 * one of: 'UNAUTHENTICATED', 'FORBIDDEN'.
 */
export async function assertCallerIsAdmin(
  decodedToken: admin.auth.DecodedIdToken | undefined | null,
  db: admin.firestore.Firestore,
): Promise<AdminCheck> {
  if (!decodedToken?.uid) throw new Error("UNAUTHENTICATED");

  const claimAdmin = decodedToken[ADMIN_CLAIM_KEY] === true;
  if (claimAdmin) {
    // Even with a valid claim, fetch the profile name for audit logging.
    // Best effort — don't fail the auth check if Firestore is slow.
    let name = "Admin";
    try {
      const snap = await db.collection("users").doc(decodedToken.uid).get();
      const n = snap.data()?.name;
      if (typeof n === "string" && n) name = n;
    } catch {
      /* ignore */
    }
    return { uid: decodedToken.uid, name, fromClaim: true };
  }

  const snap = await db.collection("users").doc(decodedToken.uid).get();
  const data = snap.data();
  if (data?.role !== "admin") throw new Error("FORBIDDEN");
  return {
    uid: decodedToken.uid,
    name: typeof data.name === "string" && data.name ? data.name : "Admin",
    fromClaim: false,
  };
}

/**
 * Set or remove the `admin` custom claim. Idempotent — only writes if the
 * claim actually changes (saves a token-refresh round-trip on the client).
 *
 * IMPORTANT: after writing, the affected user must re-fetch their ID token
 * (force refresh) before the new claim is visible to other Cloud Functions.
 * Most clients do this automatically within an hour; admins promoting
 * themselves should call `getIdToken(true)` to make the claim available
 * immediately.
 */
export async function ensureAdminClaim(
  uid: string,
  isAdmin: boolean,
): Promise<{ changed: boolean }> {
  const existing = await admin.auth().getUser(uid);
  const current = (existing.customClaims ?? {}) as Record<string, unknown>;
  const currentAdmin = current[ADMIN_CLAIM_KEY] === true;
  if (currentAdmin === isAdmin) return { changed: false };

  const next = { ...current };
  if (isAdmin) next[ADMIN_CLAIM_KEY] = true;
  else delete next[ADMIN_CLAIM_KEY];

  await admin.auth().setCustomUserClaims(uid, next);
  return { changed: true };
}
