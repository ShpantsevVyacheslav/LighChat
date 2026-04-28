import { onCall, HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

type RequestData = {
  conversationId?: unknown;
  requestId?: unknown;
  wrappedFileKeyForDevice?: unknown;
};

type ResponseData = {
  ok: true;
  grantId: string;
  expiresAt: string;
};

function asNonEmptyString(v: unknown): string | null {
  if (typeof v !== "string") return null;
  const t = v.trim();
  return t ? t : null;
}

function asPlainObject(v: unknown): Record<string, unknown> | null {
  if (typeof v !== "object" || v == null) return null;
  if (Array.isArray(v)) return null;
  return v as Record<string, unknown>;
}

function buildGrantId(recipientUid: string, messageId: string, fileId: string): string {
  return `${recipientUid}__${messageId}__${fileId}`;
}

export const fulfillSecretMediaViewRequest = onCall(
  { region: "us-central1" },
  async (request: CallableRequest<RequestData>): Promise<ResponseData> => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "AUTH_REQUIRED");

    const conversationId = asNonEmptyString(request.data?.conversationId);
    const requestId = asNonEmptyString(request.data?.requestId);
    const wrappedFileKeyForDevice = asNonEmptyString(request.data?.wrappedFileKeyForDevice);
    if (!conversationId || !requestId || !wrappedFileKeyForDevice) {
      throw new HttpsError("invalid-argument", "BAD_INPUT");
    }

    const db = admin.firestore();
    const convRef = db.doc(`conversations/${conversationId}`);
    const convSnap = await convRef.get();
    if (!convSnap.exists) throw new HttpsError("not-found", "CONVERSATION_NOT_FOUND");
    const conv = (convSnap.data() || {}) as Record<string, unknown>;

    const ids = Array.isArray(conv.participantIds) ? conv.participantIds : [];
    if (!ids.includes(uid)) throw new HttpsError("permission-denied", "NOT_A_MEMBER");

    const secret = asPlainObject(conv.secretChat);
    if (!secret || secret.enabled !== true) {
      throw new HttpsError("failed-precondition", "NOT_A_SECRET_CHAT");
    }

    const now = new Date();
    const nowIso = now.toISOString();
    const expiresAtIso = typeof secret.expiresAt === "string" ? secret.expiresAt : null;
    if (expiresAtIso && expiresAtIso <= nowIso) {
      throw new HttpsError("failed-precondition", "SECRET_CHAT_EXPIRED");
    }

    // Issuer must be unlocked too (same enforcement as read-path).
    const accessRef = db.doc(`conversations/${conversationId}/secretAccess/${uid}`);
    const accessSnap = await accessRef.get();
    const access = (accessSnap.data() || {}) as Record<string, unknown>;
    const accessExpiresAtTs = access.expiresAtTs as admin.firestore.Timestamp | undefined;
    if (!accessSnap.exists || !(accessExpiresAtTs instanceof admin.firestore.Timestamp) || accessExpiresAtTs.toDate() <= now) {
      throw new HttpsError("permission-denied", "SECRET_CHAT_LOCKED");
    }

    const reqRef = db.doc(`conversations/${conversationId}/secretMediaViewRequests/${requestId}`);
    const grantsCol = db.collection(`conversations/${conversationId}/secretMediaKeyGrants`);

    const { grantId, grantExpiresAtIso } = await db.runTransaction(async (tx) => {
      const reqSnap = await tx.get(reqRef);
      if (!reqSnap.exists) throw new HttpsError("not-found", "REQUEST_NOT_FOUND");
      const req = (reqSnap.data() || {}) as Record<string, unknown>;
      if (req.status !== "pending") {
        throw new HttpsError("failed-precondition", "REQUEST_NOT_PENDING");
      }

      const expiresAtTs = req.expiresAtTs as admin.firestore.Timestamp | undefined;
      if (!(expiresAtTs instanceof admin.firestore.Timestamp) || expiresAtTs.toDate() <= now) {
        tx.set(reqRef, { status: "expired", updatedAt: nowIso }, { merge: true });
        throw new HttpsError("failed-precondition", "REQUEST_EXPIRED");
      }

      const recipientUid = typeof req.recipientUid === "string" ? req.recipientUid : null;
      const recipientDeviceId =
        typeof req.recipientDeviceId === "string" ? req.recipientDeviceId : null;
      const messageId = typeof req.messageId === "string" ? req.messageId : null;
      const fileId = typeof req.fileId === "string" ? req.fileId : null;
      if (!recipientUid || !recipientDeviceId || !messageId || !fileId) {
        throw new HttpsError("failed-precondition", "REQUEST_MALFORMED");
      }

      const grantId = buildGrantId(recipientUid, messageId, fileId);
      const grantExpiresAt = new Date(now.getTime() + 30_000);
      tx.set(grantsCol.doc(grantId), {
        conversationId,
        messageId,
        fileId,
        recipientUid,
        recipientDeviceId,
        wrappedFileKeyForDevice,
        expiresAt: grantExpiresAt.toISOString(),
        expiresAtTs: admin.firestore.Timestamp.fromDate(grantExpiresAt),
        issuedByUid: uid,
        oneTime: true,
      });

      tx.set(reqRef, { status: "fulfilled", fulfilledAt: nowIso, grantId }, { merge: true });

      return { grantId, grantExpiresAtIso: grantExpiresAt.toISOString() };
    });

    logger.info("[fulfillSecretMediaViewRequest] granted", {
      uid,
      conversationId,
      requestId,
      grantId,
      expiresAt: grantExpiresAtIso,
    });

    return { ok: true, grantId, expiresAt: grantExpiresAtIso };
  }
);

