import { onCall, HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

import { derivePinHashB64, isValidFourDigitPin, newPinSaltB64 } from "../../lib/secret-chat-lock";

type RequestData = {
  pin?: unknown;
};

type ResponseData = {
  ok: true;
  updatedAt: string;
};

export const setSecretChatPin = onCall(
  { region: "us-central1", enforceAppCheck: false },
  async (request: CallableRequest<RequestData>): Promise<ResponseData> => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "AUTH_REQUIRED");

    const pin = typeof request.data?.pin === "string" ? request.data.pin.trim() : "";
    if (!isValidFourDigitPin(pin)) throw new HttpsError("invalid-argument", "BAD_PIN");

    const saltB64 = newPinSaltB64();
    const hashB64 = derivePinHashB64(pin, saltB64);
    const updatedAt = new Date().toISOString();

    const db = admin.firestore();
    const ref = db.doc(`users/${uid}/secretChatLock/main`);
    await ref.set(
      {
        pinSaltB64: saltB64,
        pinHashB64: hashB64,
        failedAttempts: 0,
        lockedUntil: null,
        updatedAt,
      },
      { merge: true }
    );

    logger.info("[setSecretChatPin] updated", { uid });
    return { ok: true, updatedAt };
  }
);

