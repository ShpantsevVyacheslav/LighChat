import { onCall, HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";
import * as admin from "firebase-admin";

type RequestData = {
  gameId?: unknown;
};

type ResponseData = {
  gameId: string;
  cancelled: boolean;
};

function asNonEmptyString(v: unknown): string | null {
  if (typeof v !== "string") return null;
  const t = v.trim();
  return t ? t : null;
}

export const cancelGameLobby = onCall(
  { region: "us-central1" },
  async (request: CallableRequest<RequestData>): Promise<ResponseData> => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "AUTH_REQUIRED");

    const gameId = asNonEmptyString(request.data?.gameId);
    if (!gameId) throw new HttpsError("invalid-argument", "BAD_INPUT");

    const db = admin.firestore();
    const gameRef = db.doc(`games/${gameId}`);
    const nowIso = new Date().toISOString();

    await db.runTransaction(async (tx) => {
      const snap = await tx.get(gameRef);
      if (!snap.exists) throw new HttpsError("not-found", "GAME_NOT_FOUND");
      const g = snap.data() || {};
      if (g.type !== "durak") throw new HttpsError("failed-precondition", "GAME_TYPE_UNSUPPORTED");

      const status = typeof g.status === "string" ? g.status : "";
      if (status !== "lobby") {
        throw new HttpsError("failed-precondition", "NOT_IN_LOBBY");
      }
      const createdBy = typeof g.createdBy === "string" ? g.createdBy : "";
      if (createdBy !== uid) throw new HttpsError("permission-denied", "ONLY_OWNER_CAN_CANCEL");

      const conversationId = typeof g.conversationId === "string" ? g.conversationId : "";
      if (!conversationId) throw new HttpsError("internal", "GAME_MISSING_CONVERSATION");

      // Ensure caller is still a conversation participant.
      const convSnap = await tx.get(db.doc(`conversations/${conversationId}`));
      if (!convSnap.exists) throw new HttpsError("not-found", "CONVERSATION_NOT_FOUND");
      const conv = convSnap.data() || {};
      const participantIds = Array.isArray(conv.participantIds) ? conv.participantIds : [];
      if (!participantIds.includes(uid)) throw new HttpsError("permission-denied", "NOT_A_MEMBER");

      tx.update(gameRef, {
        status: "cancelled",
        lastUpdatedAt: nowIso,
      });
      tx.set(
        db.doc(`conversations/${conversationId}/gameLobbies/${gameId}`),
        { status: "cancelled", lastUpdatedAt: nowIso },
        { merge: true },
      );
    });

    logger.info("[cancelGameLobby] cancelled", { gameId, uid });
    return { gameId, cancelled: true };
  },
);

