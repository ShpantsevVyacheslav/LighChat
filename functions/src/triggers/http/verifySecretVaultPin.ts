import { onCall, HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

import { constantTimeEqualsB64, derivePinHashB64, isValidFourDigitPin } from "../../lib/secret-chat-lock";

type Payload = { pin?: unknown };

/**
 * Verifies the user's global secret PIN (users/{uid}/secretChatLock/main) without issuing grants.
 * Used to unlock the secret-chat inbox UI.
 */
export const verifySecretVaultPin = onCall(
  { region: "us-central1" },
  async (request: CallableRequest<Payload>): Promise<{ ok: true }> => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "AUTH_REQUIRED");

    const pinRaw = typeof request.data?.pin === "string" ? request.data.pin.trim() : "";
    if (!isValidFourDigitPin(pinRaw)) throw new HttpsError("invalid-argument", "BAD_PIN");

    const db = admin.firestore();
    const lockRef = db.doc(`users/${uid}/secretChatLock/main`);
    const lockSnap = await lockRef.get();
    if (!lockSnap.exists) throw new HttpsError("failed-precondition", "PIN_NOT_SET");

    const lock = lockSnap.data() || {};
    const saltB64 = typeof lock.pinSaltB64 === "string" ? lock.pinSaltB64 : "";
    const hashB64 = typeof lock.pinHashB64 === "string" ? lock.pinHashB64 : "";
    if (!saltB64 || !hashB64) throw new HttpsError("failed-precondition", "PIN_NOT_SET");

    const nowIso = new Date().toISOString();
    const lockedUntil = typeof lock.lockedUntil === "string" ? lock.lockedUntil : null;
    if (lockedUntil && lockedUntil > nowIso) {
      throw new HttpsError("resource-exhausted", "PIN_LOCKED");
    }

    const derived = derivePinHashB64(pinRaw, saltB64);
    const ok = constantTimeEqualsB64(derived, hashB64);
    if (!ok) throw new HttpsError("permission-denied", "PIN_INVALID");

    return { ok: true };
  },
);
