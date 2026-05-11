import { onCall, HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

type RequestData = {
  conversationId?: unknown;
  messageId?: unknown;
  fileId?: unknown;
};

type ResponseData = {
  ok: true;
};

function asNonEmptyString(v: unknown): string | null {
  if (typeof v !== "string") return null;
  const t = v.trim();
  return t ? t : null;
}

function buildGrantId(uid: string, messageId: string, fileId: string): string {
  return `${uid}__${messageId}__${fileId}`;
}

export const consumeSecretMediaKeyGrant = onCall(
  { region: "us-central1", enforceAppCheck: false },
  async (request: CallableRequest<RequestData>): Promise<ResponseData> => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "AUTH_REQUIRED");

    const conversationId = asNonEmptyString(request.data?.conversationId);
    const messageId = asNonEmptyString(request.data?.messageId);
    const fileId = asNonEmptyString(request.data?.fileId);
    if (!conversationId || !messageId || !fileId) {
      throw new HttpsError("invalid-argument", "BAD_INPUT");
    }

    const db = admin.firestore();
    const grantId = buildGrantId(uid, messageId, fileId);
    const ref = db.doc(`conversations/${conversationId}/secretMediaKeyGrants/${grantId}`);

    // Idempotent: deleting twice is OK.
    await ref.delete().catch(() => null);

    logger.info("[consumeSecretMediaKeyGrant] consumed", {
      uid,
      conversationId,
      messageId,
      fileId,
      grantId,
    });

    return { ok: true };
  }
);

