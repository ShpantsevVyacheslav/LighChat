import { onCall, HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";
import * as admin from "firebase-admin";

import { normalizeDurakSettings } from "../../lib/games/gameSettings";

type RequestData = {
  tournamentId?: unknown;
  settings?: unknown;
};

type ResponseData = {
  tournamentId: string;
  gameId: string;
};

function asNonEmptyString(v: unknown): string | null {
  if (typeof v !== "string") return null;
  const t = v.trim();
  return t ? t : null;
}

export const createTournamentGameLobby = onCall(
  { region: "us-central1" },
  async (request: CallableRequest<RequestData>): Promise<ResponseData> => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "AUTH_REQUIRED");

    const tournamentId = asNonEmptyString(request.data?.tournamentId);
    if (!tournamentId) throw new HttpsError("invalid-argument", "BAD_INPUT");

    const db = admin.firestore();
    const tRef = db.doc(`tournaments/${tournamentId}`);
    const tSnap = await tRef.get();
    if (!tSnap.exists) throw new HttpsError("not-found", "TOURNAMENT_NOT_FOUND");
    const t = tSnap.data() || {};
    if (t.type !== "durak") throw new HttpsError("failed-precondition", "TOURNAMENT_TYPE_UNSUPPORTED");

    const conversationId = typeof t.conversationId === "string" ? t.conversationId : "";
    if (!conversationId) throw new HttpsError("internal", "TOURNAMENT_MISSING_CONVERSATION");

    const convRef = db.doc(`conversations/${conversationId}`);
    const convSnap = await convRef.get();
    if (!convSnap.exists) throw new HttpsError("not-found", "CONVERSATION_NOT_FOUND");
    const conv = convSnap.data() || {};
    const participantIds = Array.isArray(conv.participantIds) ? conv.participantIds : [];
    if (!participantIds.includes(uid)) throw new HttpsError("permission-denied", "NOT_A_MEMBER");

    const isGroup = conv.isGroup === true;
    const normalized = normalizeDurakSettings(request.data?.settings);
    const settings = isGroup ? normalized : { ...normalized, maxPlayers: 2 };

    const nowIso = new Date().toISOString();
    const gameRef = db.collection("games").doc();
    const gameId = gameRef.id;

    const gameDoc: Record<string, unknown> = {
      id: gameId,
      type: "durak",
      status: "lobby",
      createdAt: nowIso,
      createdBy: uid,
      conversationId,
      isGroup,
      playerIds: [uid],
      players: [{ uid, joinedAt: nowIso, isOwner: true }],
      settings,
      tournamentId,
      lastUpdatedAt: nowIso,
    };

    const lobbyRef = db.doc(`conversations/${conversationId}/gameLobbies/${gameId}`);
    const lobbyDoc: Record<string, unknown> = {
      gameId,
      type: "durak",
      status: "lobby",
      conversationId,
      createdAt: nowIso,
      createdBy: uid,
      maxPlayers: settings.maxPlayers,
      playerCount: 1,
      tournamentId,
      lastUpdatedAt: nowIso,
    };

    await db.runTransaction(async (tx) => {
      // Enforce: at most one active game per conversation (including tournament games).
      const existingLobbyQuery = db
        .collection(`conversations/${conversationId}/gameLobbies`)
        .where("status", "in", ["lobby", "active"])
        .limit(1);
      const existing = await tx.get(existingLobbyQuery);
      if (!existing.empty) throw new HttpsError("failed-precondition", "ACTIVE_GAME_ALREADY_EXISTS");

      tx.create(gameRef, gameDoc);
      tx.create(lobbyRef, lobbyDoc);

      const prevGameIds = Array.isArray(t.gameIds) ? t.gameIds : [];
      tx.set(
        tRef,
        {
          gameIds: [...prevGameIds, gameId],
          lastUpdatedAt: nowIso,
        },
        { merge: true },
      );

      tx.set(
        db.doc(`tournaments/${tournamentId}/games/${gameId}`),
        {
          gameId,
          type: "durak",
          status: "lobby",
          createdAt: nowIso,
          createdBy: uid,
          playerIds: [uid],
          playerCount: 1,
          lastUpdatedAt: nowIso,
        },
        { merge: true },
      );
    });

    logger.info("[createTournamentGameLobby] created", { tournamentId, gameId, conversationId, uid });
    return { tournamentId, gameId };
  },
);

