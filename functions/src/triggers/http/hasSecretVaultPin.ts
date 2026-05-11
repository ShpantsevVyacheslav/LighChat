import { onCall, HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

/**
 * Returns whether the user has configured a global vault PIN (secretChatLock/main).
 */
export const hasSecretVaultPin = onCall(
  { region: "us-central1", enforceAppCheck: false },
  async (request: CallableRequest<Record<string, unknown>>): Promise<{ hasPin: boolean }> => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "AUTH_REQUIRED");

    const snap = await admin.firestore().doc(`users/${uid}/secretChatLock/main`).get();
    if (!snap.exists) return { hasPin: false };
    const d = snap.data() || {};
    const hash = typeof d.pinHashB64 === "string" ? d.pinHashB64 : "";
    const salt = typeof d.pinSaltB64 === "string" ? d.pinSaltB64 : "";
    return { hasPin: hash.length > 0 && salt.length > 0 };
  },
);
