import { onCall, HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";
import * as admin from "firebase-admin";

type RequestData = {
  gameId?: unknown;
};

type ResponseData = {
  gameId: string;
};

function asNonEmptyString(v: unknown): string | null {
  if (typeof v !== "string") return null;
  const t = v.trim();
  return t ? t : null;
}

export const joinGameLobby = onCall(
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
      const gameSnap = await tx.get(gameRef);
      if (!gameSnap.exists) throw new HttpsError("not-found", "GAME_NOT_FOUND");
      const g = gameSnap.data() || {};
      if (g.type !== "durak") throw new HttpsError("failed-precondition", "GAME_TYPE_UNSUPPORTED");
      if (g.status !== "lobby") throw new HttpsError("failed-precondition", "NOT_IN_LOBBY");

      const conversationId = typeof g.conversationId === "string" ? g.conversationId : "";
      if (!conversationId) throw new HttpsError("internal", "GAME_MISSING_CONVERSATION");

      const convSnap = await tx.get(db.doc(`conversations/${conversationId}`));
      if (!convSnap.exists) throw new HttpsError("not-found", "CONVERSATION_NOT_FOUND");
      const conv = convSnap.data() || {};
      const participantIds = Array.isArray(conv.participantIds) ? conv.participantIds : [];
      if (!participantIds.includes(uid)) {
        throw new HttpsError("permission-denied", "NOT_A_MEMBER");
      }

      const playerIds = Array.isArray(g.playerIds) ? g.playerIds : [];
      if (playerIds.includes(uid)) {
        return; // idempotent join
      }

      const settings = (g.settings && typeof g.settings === "object") ? (g.settings as any) : {};
      const maxPlayers = typeof settings.maxPlayers === "number" ? settings.maxPlayers : 6;
      if (playerIds.length >= maxPlayers) {
        throw new HttpsError("failed-precondition", "LOBBY_FULL");
      }

      const players = Array.isArray(g.players) ? g.players : [];
      const newPlayers = [
        ...players,
        { uid, joinedAt: nowIso, isOwner: false },
      ];

      tx.update(gameRef, {
        playerIds: [...playerIds, uid],
        players: newPlayers,
        lastUpdatedAt: nowIso,
      });

      const lobbyRef = db.doc(`conversations/${conversationId}/gameLobbies/${gameId}`);
      tx.set(
        lobbyRef,
        {
          gameId,
          type: "durak",
          status: "lobby",
          conversationId,
          playerCount: playerIds.length + 1,
          maxPlayers,
          lastUpdatedAt: nowIso,
        },
        { merge: true },
      );
    });

    logger.info("[joinGameLobby] joined", { gameId, uid });
    return { gameId };
  },
);

