import { onCall, HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";
import * as admin from "firebase-admin";

import { normalizeDurakSettings } from "../../lib/games/gameSettings";
import { readyDeadlineFrom } from "../../lib/games/durak/lobbyLifecycle";

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

export const createDurakRematch = onCall(
  { region: "us-central1" },
  async (request: CallableRequest<RequestData>): Promise<ResponseData> => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "AUTH_REQUIRED");
    const previousGameId = asNonEmptyString(request.data?.gameId);
    if (!previousGameId) throw new HttpsError("invalid-argument", "BAD_INPUT");

    const db = admin.firestore();
    const gameRef = db.doc(`games/${previousGameId}`);
    const gameId = previousGameId;
    let responseGameId = gameId;
    const nowIso = new Date().toISOString();
    const deadline = readyDeadlineFrom(Date.now());
    let conversationId = "";

    await db.runTransaction(async (tx) => {
      const prevSnap = await tx.get(gameRef);
      if (!prevSnap.exists) throw new HttpsError("not-found", "GAME_NOT_FOUND");
      const prev = prevSnap.data() || {};
      if (prev.type !== "durak") throw new HttpsError("failed-precondition", "GAME_TYPE_UNSUPPORTED");
      if (typeof (prev as any).tournamentId === "string" && ((prev as any).tournamentId as string).trim()) {
        throw new HttpsError("failed-precondition", "TOURNAMENT_REMATCH_UNSUPPORTED");
      }

      const status = typeof prev.status === "string" ? prev.status : "";
      if (status === "active" || status === "lobby") {
        responseGameId = gameId;
        return;
      }
      if (status !== "finished" && status !== "lobby") {
        throw new HttpsError("failed-precondition", "GAME_NOT_FINISHED");
      }

      const previousPlayerIds = Array.isArray(prev.playerIds) ? prev.playerIds.map((x: any) => String(x)) : [];
      if (!previousPlayerIds.includes(uid)) throw new HttpsError("permission-denied", "NOT_A_PLAYER");
      conversationId = typeof prev.conversationId === "string" ? prev.conversationId : "";
      if (!conversationId) throw new HttpsError("internal", "GAME_MISSING_CONVERSATION");

      const convRef = db.doc(`conversations/${conversationId}`);
      const convSnap = await tx.get(convRef);
      if (!convSnap.exists) throw new HttpsError("not-found", "CONVERSATION_NOT_FOUND");
      const conv = convSnap.data() || {};
      const participantIds = Array.isArray(conv.participantIds) ? new Set(conv.participantIds.map((x: any) => String(x))) : new Set<string>();
      if (!participantIds.has(uid)) throw new HttpsError("permission-denied", "NOT_A_MEMBER");

      const settings = normalizeDurakSettings(prev.settings);
      const nextPlayerIds = previousPlayerIds.filter((id) => participantIds.has(id)).slice(0, settings.maxPlayers);
      if (nextPlayerIds.length < 2) throw new HttpsError("failed-precondition", "NEED_AT_LEAST_2_PLAYERS");

      const existing = await tx.get(
        db
          .collection(`conversations/${conversationId}/gameLobbies`)
          .where("status", "in", ["lobby", "active"])
          .limit(10),
      );
      const hasAnotherActiveGame = existing.docs.some((docSnap) => docSnap.id !== gameId);
      if (hasAnotherActiveGame) {
        const existingDurakLobby = existing.docs.find((docSnap) => {
          if (docSnap.id === gameId) return false;
          const data = docSnap.data() || {};
          return String(data.type ?? "durak") === "durak";
        });
        if (existingDurakLobby) {
          responseGameId = existingDurakLobby.id;
          return;
        }
        throw new HttpsError("failed-precondition", "ACTIVE_GAME_ALREADY_EXISTS");
      }

      const privateHands = await tx.get(db.collection(`games/${gameId}/privateHands`));
      for (const hand of privateHands.docs) tx.delete(hand.ref);

      const moves = await tx.get(db.collection(`games/${gameId}/moves`));
      for (const move of moves.docs) tx.delete(move.ref);

      tx.update(gameRef, {
        status: "lobby",
        createdBy: uid,
        playerIds: nextPlayerIds,
        players: nextPlayerIds.map((puid) => ({
          uid: puid,
          joinedAt: nowIso,
          isOwner: puid === uid,
        })),
        settings,
        readyUids: [],
        readyDeadlineAt: deadline,
        result: admin.firestore.FieldValue.delete(),
        startedAt: admin.firestore.FieldValue.delete(),
        finishedAt: admin.firestore.FieldValue.delete(),
        serverState: admin.firestore.FieldValue.delete(),
        publicView: admin.firestore.FieldValue.delete(),
        spectatorIds: admin.firestore.FieldValue.delete(),
        rematchOfGameId: gameId,
        rematchRequestedAt: nowIso,
        lastUpdatedAt: nowIso,
      });

      tx.set(
        db.doc(`conversations/${conversationId}/gameLobbies/${gameId}`),
        {
          gameId,
          type: "durak",
          status: "lobby",
          conversationId,
          createdAt: nowIso,
          createdBy: uid,
          maxPlayers: settings.maxPlayers,
          playerCount: nextPlayerIds.length,
          readyUids: [],
          readyDeadlineAt: deadline,
          rematchOfGameId: gameId,
          lastUpdatedAt: nowIso,
        },
        { merge: true },
      );
    });

    logger.info("[createDurakRematch] completed", {
      requestedGameId: gameId,
      responseGameId,
      conversationId,
      uid,
    });
    return { gameId: responseGameId };
  },
);
