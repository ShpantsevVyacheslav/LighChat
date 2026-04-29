import { onCall, HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

import { constantTimeEqualsB64, derivePinHashB64, isValidFourDigitPin } from "../../lib/secret-chat-lock";

type RequestData = {
  conversationId?: unknown;
  pin?: unknown;
  deviceId?: unknown;
  method?: unknown;
};

type ResponseData = {
  ok: true;
  expiresAt: string;
};

/** Fixed server-side TTL for secretAccess grants (Unlock Duration removed from product). */
const SECRET_ACCESS_GRANT_TTL_SEC = 600;

const MAX_FAILED_ATTEMPTS = 5;
const LOCK_MINUTES_AFTER_MAX = 15;

function asNonEmptyString(v: unknown): string | null {
  if (typeof v !== "string") return null;
  const t = v.trim();
  return t ? t : null;
}

export const unlockSecretChat = onCall(
  { region: "us-central1" },
  async (request: CallableRequest<RequestData>): Promise<ResponseData> => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "AUTH_REQUIRED");

    const conversationId = asNonEmptyString(request.data?.conversationId);
    const pinRaw = asNonEmptyString(request.data?.pin) ?? "";
    const deviceId = asNonEmptyString(request.data?.deviceId);
    const methodRaw = asNonEmptyString(request.data?.method) ?? "pin";
    const method = methodRaw === "biometric" ? "biometric" : "pin";
    if (!conversationId) throw new HttpsError("invalid-argument", "BAD_INPUT");

    const db = admin.firestore();
    const convRef = db.doc(`conversations/${conversationId}`);
    const convSnap = await convRef.get();
    if (!convSnap.exists) throw new HttpsError("not-found", "CONVERSATION_NOT_FOUND");
    const conv = convSnap.data() || {};

    const ids = Array.isArray(conv.participantIds) ? conv.participantIds : [];
    if (!ids.includes(uid)) throw new HttpsError("permission-denied", "NOT_A_MEMBER");

    const rawSecret = (conv as Record<string, unknown>).secretChat;
    let secret: Record<string, unknown> | null = null;
    if (typeof rawSecret === "object" && rawSecret != null) {
      secret = rawSecret as Record<string, unknown>;
    }
    if (!secret || secret.enabled !== true) {
      throw new HttpsError("failed-precondition", "NOT_A_SECRET_CHAT");
    }

    const now = new Date();
    const nowIso = now.toISOString();
    const expiresAtIso = typeof secret.expiresAt === "string" ? secret.expiresAt : null;
    if (expiresAtIso && expiresAtIso <= nowIso) {
      throw new HttpsError("failed-precondition", "SECRET_CHAT_EXPIRED");
    }

    const grantTtlSec = SECRET_ACCESS_GRANT_TTL_SEC;

    const lockRef = db.doc(`users/${uid}/secretChatLock/main`);
    const lockSnap = await lockRef.get();
    const lock = lockSnap.exists ? (lockSnap.data() || {}) : {};
    const saltB64 = typeof lock.pinSaltB64 === "string" ? lock.pinSaltB64 : "";
    const hashB64 = typeof lock.pinHashB64 === "string" ? lock.pinHashB64 : "";
    const hasPin = Boolean(lockSnap.exists && saltB64.length > 0 && hashB64.length > 0);

    if (hasPin) {
      if (!isValidFourDigitPin(pinRaw)) throw new HttpsError("invalid-argument", "BAD_PIN");

      const lockedUntil = typeof lock.lockedUntil === "string" ? lock.lockedUntil : null;
      if (lockedUntil && lockedUntil > nowIso) {
        throw new HttpsError("resource-exhausted", "PIN_LOCKED");
      }

      const derived = derivePinHashB64(pinRaw, saltB64);
      const ok = constantTimeEqualsB64(derived, hashB64);

      const failedAttempts = typeof lock.failedAttempts === "number" ? lock.failedAttempts : 0;
      if (!ok) {
        const nextFailed = failedAttempts + 1;
        const shouldLock = nextFailed >= MAX_FAILED_ATTEMPTS;
        let nextLockedUntil: string | null = null;
        if (shouldLock) {
          nextLockedUntil = new Date(now.getTime() + LOCK_MINUTES_AFTER_MAX * 60_000).toISOString();
        }
        await lockRef.set(
          {
            failedAttempts: nextFailed,
            lockedUntil: nextLockedUntil,
            updatedAt: nowIso,
          },
          { merge: true }
        );
        throw new HttpsError("permission-denied", "PIN_INVALID");
      }

      if (failedAttempts !== 0 || lockedUntil != null) {
        await lockRef.set(
          {
            failedAttempts: 0,
            lockedUntil: null,
            updatedAt: nowIso,
          },
          { merge: true }
        );
      }
    }

    const grantExpiresAt = new Date(now.getTime() + grantTtlSec * 1000).toISOString();
    const grantRef = db.doc(`conversations/${conversationId}/secretAccess/${uid}`);
    await grantRef.set(
      {
        userId: uid,
        conversationId,
        unlockedAt: nowIso,
        expiresAt: grantExpiresAt,
        unlockedAtTs: admin.firestore.Timestamp.fromDate(now),
        expiresAtTs: admin.firestore.Timestamp.fromDate(new Date(now.getTime() + grantTtlSec * 1000)),
        method,
        ...(deviceId ? { deviceId } : {}),
      },
      { merge: true }
    );

    logger.info("[unlockSecretChat] grant issued", {
      uid,
      conversationId,
      expiresAt: grantExpiresAt,
      method,
      hasPin,
    });

    return { ok: true, expiresAt: grantExpiresAt };
  }
);
