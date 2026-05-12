import { onCall, HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";
import * as admin from "firebase-admin";

import { normalizeDurakSettings } from "../../lib/games/gameSettings";
import {
  canAutoStartReadyLobby,
  pruneReadyLobby,
  readyDeadlineFrom,
  startDurakRoundInTransaction,
} from "../../lib/games/durak/lobbyLifecycle";
import { recordAnalyticsEvent } from "../../analytics/recordEvent";
import { AnalyticsEvents } from "../../analytics/events";

type RequestData = {
  gameId?: unknown;
};

type ResponseData = {
  gameId: string;
  status: "lobby" | "active";
};

function asNonEmptyString(v: unknown): string | null {
  if (typeof v !== "string") return null;
  const t = v.trim();
  return t ? t : null;
}

export const startDurakGame = onCall(
  { region: "us-central1", enforceAppCheck: false },
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
      if (g.status !== "lobby") throw new HttpsError("failed-precondition", "NOT_IN_LOBBY");

      const playerIds = Array.isArray(g.playerIds) ? g.playerIds : [];
      if (!playerIds.includes(uid)) throw new HttpsError("permission-denied", "NOT_A_PLAYER");

      const conversationId = typeof g.conversationId === "string" ? g.conversationId : "";
      if (!conversationId) throw new HttpsError("internal", "GAME_MISSING_CONVERSATION");

      const settings = normalizeDurakSettings(g.settings);
      const players = Array.isArray(g.players) ? g.players : playerIds.map((u: string) => ({ uid: u }));
      const readyBefore = Array.isArray(g.readyUids) ? g.readyUids.map((x: any) => String(x)) : [];
      const pruned = pruneReadyLobby({
        playerIds,
        players,
        readyUids: readyBefore,
        readyDeadlineAt: typeof g.readyDeadlineAt === "string" ? g.readyDeadlineAt : undefined,
        nowMs: Date.now(),
      });
      const nextPlayerIds = pruned.playerIds.includes(uid) ? pruned.playerIds : [...pruned.playerIds, uid];
      const nextPlayers = pruned.players.some((p) => String(p?.uid ?? "") === uid) ?
        pruned.players :
        [...pruned.players, { uid, joinedAt: nowIso, isOwner: uid === g.createdBy }];
      const nextReadyUids = Array.from(new Set([...pruned.readyUids, uid])).filter((u) => nextPlayerIds.includes(u));

      if (canAutoStartReadyLobby(nextPlayerIds, nextReadyUids)) {
        startDurakRoundInTransaction({
          tx,
          db,
          gameRef,
          gameId,
          game: g,
          playerIds: nextPlayerIds,
          settings,
          nowIso,
        });
        return;
      }

      const deadline = typeof g.readyDeadlineAt === "string" ? g.readyDeadlineAt : readyDeadlineFrom(Date.now());
      tx.update(gameRef, {
        playerIds: nextPlayerIds,
        players: nextPlayers,
        readyUids: nextReadyUids,
        readyDeadlineAt: deadline,
        lastUpdatedAt: nowIso,
      });
      tx.set(
        db.doc(`conversations/${conversationId}/gameLobbies/${gameId}`),
        {
          status: "lobby",
          playerCount: nextPlayerIds.length,
          readyUids: nextReadyUids,
          readyDeadlineAt: deadline,
          lastUpdatedAt: nowIso,
        },
        { merge: true },
      );
    });

    logger.info("[startDurakGame] started", { gameId, uid });
    void recordAnalyticsEvent({
      event: AnalyticsEvents.gameStarted,
      uid,
      params: { game_id: "durak", mode: "vs_human" },
      source: "callable",
    });
    return { gameId, status: "lobby" };
  },
);
