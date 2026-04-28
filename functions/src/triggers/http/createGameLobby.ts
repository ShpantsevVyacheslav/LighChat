import { onCall, HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";
import * as admin from "firebase-admin";

import { normalizeDurakSettings } from "../../lib/games/gameSettings";

type RequestData = {
  conversationId?: unknown;
  gameKey?: unknown; // currently: "durak"
  settings?: unknown;
};

type ResponseData = {
  gameId: string;
};

function asNonEmptyString(v: unknown): string | null {
  if (typeof v !== "string") return null;
  const t = v.trim();
  return t ? t : null;
}

export const createGameLobby = onCall(
  { region: "us-central1" },
  async (request: CallableRequest<RequestData>): Promise<ResponseData> => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "AUTH_REQUIRED");

    const conversationId = asNonEmptyString(request.data?.conversationId);
    const gameKey = asNonEmptyString(request.data?.gameKey)?.toLowerCase() ?? "durak";
    if (!conversationId || gameKey !== "durak") {
      throw new HttpsError("invalid-argument", "BAD_INPUT");
    }

    const db = admin.firestore();
    const convRef = db.doc(`conversations/${conversationId}`);
    const convSnap = await convRef.get();
    if (!convSnap.exists) throw new HttpsError("not-found", "CONVERSATION_NOT_FOUND");
    const conv = convSnap.data() || {};
    const participantIds = Array.isArray(conv.participantIds) ? conv.participantIds : [];
    if (!participantIds.includes(uid)) {
      throw new HttpsError("permission-denied", "NOT_A_MEMBER");
    }

    const isGroup = conv.isGroup === true;
    const normalized = normalizeDurakSettings(request.data?.settings);
    // DM is always 2 players by product definition.
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
      players: [
        {
          uid,
          joinedAt: nowIso,
          isOwner: true,
        },
      ],
      settings,
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
      lastUpdatedAt: nowIso,
    };

    await db.runTransaction(async (tx) => {
      // Enforce: at most one active game per conversation.
      const existingLobbyQuery = db
        .collection(`conversations/${conversationId}/gameLobbies`)
        .where("status", "in", ["lobby", "active"])
        .limit(1);
      const existing = await tx.get(existingLobbyQuery);
      if (!existing.empty) throw new HttpsError("failed-precondition", "ACTIVE_GAME_ALREADY_EXISTS");

      tx.create(gameRef, gameDoc);
      tx.create(lobbyRef, lobbyDoc);

      // System message so the other participant sees a banner / gets a push.
      const msgRef = db.collection(`conversations/${conversationId}/messages`).doc();
      tx.create(msgRef, {
        id: msgRef.id,
        senderId: "__system__",
        createdAt: nowIso,
        text: "🎮 Создано лобби «Дурак». Откройте «Игры», чтобы присоединиться.",
        systemEvent: {
          type: "gameLobbyCreated",
          data: { gameId, gameType: "durak" },
        },
      });
    });

    logger.info("[createGameLobby] created", {
      gameId,
      conversationId,
      isGroup,
      uid,
      settings,
    });

    return { gameId };
  },
);

