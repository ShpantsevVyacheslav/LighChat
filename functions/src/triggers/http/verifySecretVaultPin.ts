import { onCall, HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

import { constantTimeEqualsB64, derivePinHashB64, isValidFourDigitPin } from "../../lib/secret-chat-lock";

type Payload = { pin?: unknown };

/**
 * Verifies the user's global secret PIN (users/{uid}/secretChatLock/main) without issuing grants.
 * Used to unlock the secret-chat inbox UI.
 *
 * SECURITY: previously we only READ `lockedUntil` but never INCREMENTED
 * `failedAttempts` on a wrong PIN. The companion `unlockSecretChat` is the
 * only thing that wrote the counter — meaning a caller could brute-force the
 * 4-digit PIN through `verifySecretVaultPin` essentially for free (10000
 * attempts in seconds). The vault PIN gates *every* secret chat for the user,
 * so this is a high-impact bypass. The counter logic mirrors the version in
 * `unlockSecretChat` and is kept atomic via a transaction so concurrent
 * requests cannot race past the lock.
 */
const MAX_FAILED_ATTEMPTS = 5;
const LOCK_MINUTES_AFTER_MAX = 15;

export const verifySecretVaultPin = onCall(
  { region: "us-central1", enforceAppCheck: false },
  async (request: CallableRequest<Payload>): Promise<{ ok: true }> => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "AUTH_REQUIRED");

    const pinRaw = typeof request.data?.pin === "string" ? request.data.pin.trim() : "";
    if (!isValidFourDigitPin(pinRaw)) throw new HttpsError("invalid-argument", "BAD_PIN");

    const db = admin.firestore();
    const lockRef = db.doc(`users/${uid}/secretChatLock/main`);

    // Run check-and-record under a transaction so two parallel verifies cannot
    // both observe `failedAttempts == 4` and race past the auto-lock threshold.
    type TxResult = "ok" | "not-set" | "locked" | "invalid";
    const result = await db.runTransaction<TxResult>(async (tx) => {
      const lockSnap = await tx.get(lockRef);
      if (!lockSnap.exists) return "not-set";

      const lock = lockSnap.data() || {};
      const saltB64 = typeof lock.pinSaltB64 === "string" ? lock.pinSaltB64 : "";
      const hashB64 = typeof lock.pinHashB64 === "string" ? lock.pinHashB64 : "";
      if (!saltB64 || !hashB64) return "not-set";

      const now = new Date();
      const nowIso = now.toISOString();
      const lockedUntil = typeof lock.lockedUntil === "string" ? lock.lockedUntil : null;
      if (lockedUntil && lockedUntil > nowIso) return "locked";

      const derived = derivePinHashB64(pinRaw, saltB64);
      const ok = constantTimeEqualsB64(derived, hashB64);

      const failedAttempts = typeof lock.failedAttempts === "number" ? lock.failedAttempts : 0;
      if (!ok) {
        const nextFailed = failedAttempts + 1;
        const shouldLock = nextFailed >= MAX_FAILED_ATTEMPTS;
        const nextLockedUntil = shouldLock ?
          new Date(now.getTime() + LOCK_MINUTES_AFTER_MAX * 60_000).toISOString() :
          null;
        tx.set(
          lockRef,
          { failedAttempts: nextFailed, lockedUntil: nextLockedUntil, updatedAt: nowIso },
          { merge: true }
        );
        return "invalid";
      }

      // On success, reset the counter (only if it was non-zero) so we don't
      // generate spurious writes on every successful unlock.
      if (failedAttempts !== 0 || lockedUntil != null) {
        tx.set(
          lockRef,
          { failedAttempts: 0, lockedUntil: null, updatedAt: nowIso },
          { merge: true }
        );
      }
      return "ok";
    });

    if (result === "not-set") throw new HttpsError("failed-precondition", "PIN_NOT_SET");
    if (result === "locked") throw new HttpsError("resource-exhausted", "PIN_LOCKED");
    if (result === "invalid") throw new HttpsError("permission-denied", "PIN_INVALID");
    return { ok: true };
  },
);
