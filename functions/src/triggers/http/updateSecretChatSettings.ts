import { onCall, HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

import { isSecretChatTtlPresetSec } from "../../lib/secret-chat-presets";

type RequestData = {
  conversationId?: unknown;
  ttlPresetSec?: unknown;
  grantTtlSec?: unknown;
  restrictions?: unknown;
  mediaViewPolicy?: unknown;
};

function asNonEmptyString(v: unknown): string | null {
  if (typeof v !== "string") return null;
  const t = v.trim();
  return t ? t : null;
}

function asBoolOrNull(v: unknown): boolean | null {
  return typeof v === "boolean" ? v : null;
}

function asPosIntOrNull(v: unknown): number | null {
  if (typeof v !== "number") return null;
  if (!Number.isFinite(v)) return null;
  const n = Math.floor(v);
  return n > 0 ? n : null;
}

function asPlainObject(v: unknown): Record<string, unknown> | null {
  if (typeof v !== "object" || v == null) return null;
  if (Array.isArray(v)) return null;
  return v as Record<string, unknown>;
}

export const updateSecretChatSettings = onCall(
  { region: "us-central1" },
  async (request: CallableRequest<RequestData>): Promise<{ ok: true }> => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "AUTH_REQUIRED");

    const conversationId = asNonEmptyString(request.data?.conversationId);
    if (!conversationId) throw new HttpsError("invalid-argument", "BAD_INPUT");

    const db = admin.firestore();
    const convRef = db.doc(`conversations/${conversationId}`);
    const snap = await convRef.get();
    if (!snap.exists) throw new HttpsError("not-found", "CONVERSATION_NOT_FOUND");
    const conv = snap.data() || {};

    const ids = Array.isArray(conv.participantIds) ? conv.participantIds : [];
    if (!ids.includes(uid)) throw new HttpsError("permission-denied", "NOT_A_MEMBER");

    const rawSecret = (conv as Record<string, unknown>).secretChat;
    const secret = asPlainObject(rawSecret);
    if (!secret || secret.enabled !== true) {
      throw new HttpsError("failed-precondition", "NOT_A_SECRET_CHAT");
    }

    const now = new Date();
    const nowIso = now.toISOString();
    const expiresAtIso = typeof secret.expiresAt === "string" ? secret.expiresAt : null;
    if (expiresAtIso && expiresAtIso <= nowIso) {
      throw new HttpsError("failed-precondition", "SECRET_CHAT_EXPIRED");
    }

    const patch: Record<string, unknown> = {};

    // TTL preset → expiresAt recalculated from "now".
    if (request.data?.ttlPresetSec !== undefined) {
      const ttlRaw = request.data.ttlPresetSec;
      const ttl = typeof ttlRaw === "number" ? Math.floor(ttlRaw) : null;
      if (ttl == null || !isSecretChatTtlPresetSec(ttl)) {
        throw new HttpsError("invalid-argument", "BAD_TTL_PRESET");
      }
      patch.ttlPresetSec = ttl;
      patch.expiresAt = new Date(now.getTime() + ttl * 1000).toISOString();
    }

    // Grant TTL.
    if (request.data?.grantTtlSec !== undefined) {
      const gRaw = request.data.grantTtlSec;
      const g = typeof gRaw === "number" ? Math.floor(gRaw) : null;
      if (g == null || g <= 0 || g > 3600) {
        throw new HttpsError("invalid-argument", "BAD_GRANT_TTL");
      }
      patch.lockPolicy = { required: true, grantTtlSec: g };
    }

    // Restrictions.
    if (request.data?.restrictions !== undefined) {
      const r = asPlainObject(request.data.restrictions);
      if (!r) throw new HttpsError("invalid-argument", "BAD_RESTRICTIONS");
      const noForward = asBoolOrNull(r.noForward);
      const noCopy = asBoolOrNull(r.noCopy);
      const noSave = asBoolOrNull(r.noSave);
      const screenshotProtection = asBoolOrNull(r.screenshotProtection);
      if (noForward == null || noCopy == null || noSave == null || screenshotProtection == null) {
        throw new HttpsError("invalid-argument", "BAD_RESTRICTIONS");
      }
      patch.restrictions = {
        noForward,
        noCopy,
        noSave,
        screenshotProtection,
      };
    }

    // Media view policy. Special sentinel to clear.
    if (request.data?.mediaViewPolicy !== undefined) {
      const m = asPlainObject(request.data.mediaViewPolicy);
      if (!m) throw new HttpsError("invalid-argument", "BAD_MEDIA_POLICY");
      if (m.__clear === true) {
        patch.mediaViewPolicy = null;
      } else {
        const image = asPosIntOrNull(m.image);
        const video = asPosIntOrNull(m.video);
        const voice = asPosIntOrNull(m.voice);
        const file = asPosIntOrNull(m.file);
        const location = asPosIntOrNull(m.location);
        patch.mediaViewPolicy = {
          image,
          video,
          voice,
          file,
          location,
        };
      }
    }

    if (Object.keys(patch).length === 0) {
      throw new HttpsError("invalid-argument", "NO_CHANGES");
    }

    await convRef.set(
      {
        secretChat: {
          ...patch,
          updatedAt: nowIso,
          updatedBy: uid,
        },
      },
      { merge: true }
    );

    logger.info("[updateSecretChatSettings] updated", {
      uid,
      conversationId,
      keys: Object.keys(patch),
    });

    return { ok: true };
  }
);

