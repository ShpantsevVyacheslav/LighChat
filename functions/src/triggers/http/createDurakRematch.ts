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
    const prevRef = db.doc(`games/${previousGameId}`);
    const prevSnap = await prevRef.get();
    if (!prevSnap.exists) throw new HttpsError("not-found", "GAME_NOT_FOUND");
    const prev = prevSnap.data() || {};
    if (prev.type !== "durak") throw new HttpsError("failed-precondition", "GAME_TYPE_UNSUPPORTED");
    const previousPlayerIds = Array.isArray(prev.playerIds) ? prev.playerIds.map((x: any) => String(x)) : [];
    if (!previousPlayerIds.includes(uid)) throw new HttpsError("permission-denied", "NOT_A_PLAYER");
    const conversationId = typeof prev.conversationId === "string" ? prev.conversationId : "";
    if (!conversationId) throw new HttpsError("internal", "GAME_MISSING_CONVERSATION");

    const convSnap = await db.doc(`conversations/${conversationId}`).get();
    if (!convSnap.exists) throw new HttpsError("not-found", "CONVERSATION_NOT_FOUND");
    const conv = convSnap.data() || {};
    const participantIds = Array.isArray(conv.participantIds) ? new Set(conv.participantIds.map((x: any) => String(x))) : new Set<string>();
    if (!participantIds.has(uid)) throw new HttpsError("permission-denied", "NOT_A_MEMBER");

    const settings = normalizeDurakSettings(prev.settings);
    const nextPlayerIds = previousPlayerIds.filter((id) => participantIds.has(id)).slice(0, settings.maxPlayers);
    if (nextPlayerIds.length < 2) throw new HttpsError("failed-precondition", "NEED_AT_LEAST_2_PLAYERS");

    const nowIso = new Date().toISOString();
    const deadline = readyDeadlineFrom(Date.now());
    const gameRef = db.collection("games").doc();
    const gameId = gameRef.id;
    const isGroup = conv.isGroup === true;
    const gameDoc: Record<string, unknown> = {
      id: gameId,
      type: "durak",
      status: "lobby",
      createdAt: nowIso,
      createdBy: uid,
      conversationId,
      isGroup,
      playerIds: nextPlayerIds,
      readyUids: [],
      readyDeadlineAt: deadline,
      players: nextPlayerIds.map((puid) => ({
        uid: puid,
        joinedAt: nowIso,
        isOwner: puid === uid,
      })),
      settings,
      rematchOfGameId: previousGameId,
      lastUpdatedAt: nowIso,
    };

    await db.runTransaction(async (tx) => {
      const existing = await tx.get(
        db
          .collection(`conversations/${conversationId}/gameLobbies`)
          .where("status", "in", ["lobby", "active"])
          .limit(1),
      );
      if (!existing.empty) throw new HttpsError("failed-precondition", "ACTIVE_GAME_ALREADY_EXISTS");
      tx.create(gameRef, gameDoc);
      tx.create(db.doc(`conversations/${conversationId}/gameLobbies/${gameId}`), {
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
        rematchOfGameId: previousGameId,
        lastUpdatedAt: nowIso,
      });
    });

    logger.info("[createDurakRematch] created", { previousGameId, gameId, conversationId, uid });
    return { gameId };
  },
);
