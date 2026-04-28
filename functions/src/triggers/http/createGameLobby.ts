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
    const settings = normalizeDurakSettings(request.data?.settings);

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

    const batch = db.batch();
    batch.create(gameRef, gameDoc);
    batch.create(lobbyRef, lobbyDoc);
    await batch.commit();

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

