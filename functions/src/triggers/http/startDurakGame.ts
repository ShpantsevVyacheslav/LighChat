import { onCall, HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";
import * as admin from "firebase-admin";

import { normalizeDurakSettings } from "../../lib/games/gameSettings";
import {
  buildInitialState,
  canFinishTurn,
  derivePhase,
  getCurrentThrowerUid,
} from "../../lib/games/durak/engine";

type RequestData = {
  gameId?: unknown;
};

type ResponseData = {
  gameId: string;
  status: "active";
};

function asNonEmptyString(v: unknown): string | null {
  if (typeof v !== "string") return null;
  const t = v.trim();
  return t ? t : null;
}

export const startDurakGame = onCall(
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
      if (g.status !== "lobby") throw new HttpsError("failed-precondition", "NOT_IN_LOBBY");

      const createdBy = typeof g.createdBy === "string" ? g.createdBy : "";
      if (createdBy !== uid) throw new HttpsError("permission-denied", "ONLY_OWNER_CAN_START");

      const playerIds = Array.isArray(g.playerIds) ? g.playerIds : [];
      if (playerIds.length < 2) throw new HttpsError("failed-precondition", "NEED_AT_LEAST_2_PLAYERS");

      const conversationId = typeof g.conversationId === "string" ? g.conversationId : "";
      if (!conversationId) throw new HttpsError("internal", "GAME_MISSING_CONVERSATION");

      const settings = normalizeDurakSettings(g.settings);

      // randInt with crypto, deterministic-free.
      const randInt = (maxExclusive: number): number => {
        if (maxExclusive <= 1) return 0;
        const buf = new Uint32Array(1);
        // eslint-disable-next-line @typescript-eslint/no-var-requires
        const crypto = require("crypto") as typeof import("crypto");
        crypto.randomFillSync(buf);
        return buf[0] % maxExclusive;
      };

      const { state, handsByUid } = buildInitialState({
        playerIds,
        settings,
        nowIso,
        randInt,
      });

      tx.update(gameRef, {
        status: "active",
        startedAt: nowIso,
        settings,
        serverState: state,
        publicView: {
          revision: state.revision,
          phase: derivePhase(state),
          trumpSuit: state.trumpSuit,
          deckCount: state.deck.length,
          discardCount: state.discard.length,
          seats: state.seats ?? playerIds,
          attackerUid: state.attackerUid,
          defenderUid: state.defenderUid,
          table: state.table,
          handCounts: Object.fromEntries(
            Object.entries(handsByUid).map(([u, cards]) => [u, cards.length]),
          ),
          lastMoveAt: nowIso,
          throwerUids: state.throwerUids ?? [],
          passedUids: state.passedUids ?? [],
          currentThrowerUid: getCurrentThrowerUid({ state, handsByUid }),
          roundDefenderHandLimit: typeof state.roundDefenderHandLimit === "number" ? state.roundDefenderHandLimit : null,
          canFinishTurn: canFinishTurn({ state, handsByUid }),
          shuler: {
            enabled: settings.shulerEnabled === true,
            lastCheatUid: null,
          },
        },
        lastUpdatedAt: nowIso,
      });

      for (const [u, cards] of Object.entries(handsByUid)) {
        tx.set(db.doc(`games/${gameId}/privateHands/${u}`), {
          uid: u,
          cards,
          updatedAt: nowIso,
        });
      }

      tx.set(
        db.doc(`conversations/${conversationId}/gameLobbies/${gameId}`),
        {
          status: "active",
          lastUpdatedAt: nowIso,
        },
        { merge: true },
      );
    });

    logger.info("[startDurakGame] started", { gameId, uid });
    return { gameId, status: "active" };
  },
);
