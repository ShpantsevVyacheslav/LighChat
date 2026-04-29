import { onCall, HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

type RequestData = {
  conversationId?: unknown;
  messageId?: unknown;
  fileId?: unknown;
  recipientDeviceId?: unknown;
};

type ResponseData = {
  ok: true;
  requestId: string;
  grantId: string;
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

function envKindToPolicyKey(kind: unknown): "image" | "video" | "voice" | "file" | null {
  if (typeof kind !== "string") return null;
  switch (kind) {
    case "image":
      return "image";
    case "video":
      return "video";
    case "voice":
      return "voice";
    case "videoCircle":
      return "video";
    case "file":
      return "file";
    default:
      return null;
  }
}

function buildStateId(recipientUid: string, messageId: string, fileId: string): string {
  return `${recipientUid}__${messageId}__${fileId}`;
}

export const requestSecretMediaView = onCall(
  { region: "us-central1" },
  async (request: CallableRequest<RequestData>): Promise<ResponseData> => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "AUTH_REQUIRED");

    const conversationId = asNonEmptyString(request.data?.conversationId);
    const messageId = asNonEmptyString(request.data?.messageId);
    const fileId = asNonEmptyString(request.data?.fileId);
    const recipientDeviceId = asNonEmptyString(request.data?.recipientDeviceId);
    if (!conversationId || !messageId || !fileId || !recipientDeviceId) {
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

    // Requires active secretAccess grant (server-enforced unlock).
    const grantRef = db.doc(`conversations/${conversationId}/secretAccess/${uid}`);
    const grantSnap = await grantRef.get();
    const grant = (grantSnap.data() || {}) as Record<string, unknown>;
    const expiresAtTs = grant.expiresAtTs as admin.firestore.Timestamp | undefined;
    if (!grantSnap.exists || !(expiresAtTs instanceof admin.firestore.Timestamp) || expiresAtTs.toDate() <= now) {
      throw new HttpsError("permission-denied", "SECRET_CHAT_LOCKED");
    }

    // Resolve attachment kind from the message payload; client cannot lie.
    const msgRef = db.doc(`conversations/${conversationId}/messages/${messageId}`);
    const msgSnap = await msgRef.get();
    if (!msgSnap.exists) throw new HttpsError("not-found", "MESSAGE_NOT_FOUND");
    const msg = (msgSnap.data() || {}) as Record<string, unknown>;
    const e2ee = asPlainObject(msg.e2ee);
    const attachments = Array.isArray(e2ee?.attachments) ? (e2ee!.attachments as unknown[]) : [];
    let envKind: unknown = null;
    for (const one of attachments) {
      const env = asPlainObject(one);
      if (!env) continue;
      if (typeof env.fileId === "string" && env.fileId === fileId) {
        envKind = env.kind;
        break;
      }
    }
    const policyKey = envKindToPolicyKey(envKind);
    if (!policyKey) {
      throw new HttpsError("failed-precondition", "UNSUPPORTED_MEDIA_KIND");
    }

    const mediaPolicy = asPlainObject(secret.mediaViewPolicy);
    const limitRaw = mediaPolicy ? mediaPolicy[policyKey] : null;
    const limit = typeof limitRaw === "number" && Number.isFinite(limitRaw) ? Math.floor(limitRaw) : null;
    if (limit != null && limit <= 0) {
      throw new HttpsError("failed-precondition", "MEDIA_VIEWS_DISABLED");
    }

    const stateId = buildStateId(uid, messageId, fileId);
    const stateRef = db.doc(`conversations/${conversationId}/secretMediaViewState/${stateId}`);
    const requestsCol = db.collection(`conversations/${conversationId}/secretMediaViewRequests`);

    if (limit == null) {
      const expiresAt = new Date(now.getTime() + 60_000);
      const reqRef = requestsCol.doc();
      await reqRef.set({
        conversationId,
        messageId,
        fileId,
        recipientUid: uid,
        recipientDeviceId,
        kind: policyKey === "video" && envKind === "videoCircle" ? "videoCircle" : policyKey,
        createdAt: nowIso,
        expiresAt: expiresAt.toISOString(),
        expiresAtTs: admin.firestore.Timestamp.fromDate(expiresAt),
        status: "pending",
        unlimitedMediaViews: true,
      });

      const grantId = buildStateId(uid, messageId, fileId);
      logger.info("[requestSecretMediaView] created unlimited", {
        uid,
        conversationId,
        messageId,
        fileId,
        policyKey,
        requestId: reqRef.id,
        grantId,
      });

      return { ok: true as const, requestId: reqRef.id, grantId };
    }

    const requestId = await db.runTransaction(async (tx) => {
      const stateSnap = await tx.get(stateRef);
      const state = (stateSnap.data() || {}) as Record<string, unknown>;
      const used = typeof state.used === "number" ? Math.floor(state.used) : 0;
      const locked = state.locked === true;
      if (locked || used >= limit) {
        throw new HttpsError("failed-precondition", "VIEWS_EXHAUSTED");
      }
      const nextUsed = used + 1;
      tx.set(
        stateRef,
        {
          conversationId,
          messageId,
          fileId,
          recipientUid: uid,
          kind: policyKey === "video" && envKind === "videoCircle" ? "videoCircle" : policyKey,
          limit,
          used: nextUsed,
          locked: nextUsed >= limit,
          updatedAt: nowIso,
        },
        { merge: true }
      );

      const expiresAt = new Date(now.getTime() + 60_000);
      const reqRef = requestsCol.doc();
      tx.set(reqRef, {
        conversationId,
        messageId,
        fileId,
        recipientUid: uid,
        recipientDeviceId,
        kind: policyKey === "video" && envKind === "videoCircle" ? "videoCircle" : policyKey,
        createdAt: nowIso,
        expiresAt: expiresAt.toISOString(),
        expiresAtTs: admin.firestore.Timestamp.fromDate(expiresAt),
        status: "pending",
      });
      return reqRef.id;
    });

    const grantId = buildStateId(uid, messageId, fileId);

    logger.info("[requestSecretMediaView] created", {
      uid,
      conversationId,
      messageId,
      fileId,
      recipientDeviceId,
      policyKey,
      limit,
      requestId,
      grantId,
    });

    return { ok: true, requestId, grantId };
  }
);

