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

      const settings = normalizeDurakSettings(g.settings);
      const maxPlayers = typeof settings.maxPlayers === "number" ? settings.maxPlayers : 6;
      if (playerIds.length >= maxPlayers) {
        throw new HttpsError("failed-precondition", "LOBBY_FULL");
      }

      const players = Array.isArray(g.players) ? g.players : [];
      const newPlayers = [
        ...players,
        { uid, joinedAt: nowIso, isOwner: false },
      ];
      const newPlayerIds = [...playerIds, uid];

      // Auto-start for DM (maxPlayers=2) once the second player joins.
      const shouldAutoStart = maxPlayers === 2 && newPlayerIds.length === 2;
      if (shouldAutoStart) {
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
          playerIds: newPlayerIds,
          settings,
          nowIso,
          randInt,
        });

        tx.update(gameRef, {
          status: "active",
          startedAt: nowIso,
          settings,
          playerIds: newPlayerIds,
          players: newPlayers,
          serverState: state,
          publicView: {
            revision: state.revision,
            phase: derivePhase(state),
            trumpSuit: state.trumpSuit,
            deckCount: state.deck.length,
            discardCount: state.discard.length,
            seats: state.seats ?? newPlayerIds,
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
      } else {
        tx.update(gameRef, {
          playerIds: newPlayerIds,
          players: newPlayers,
          lastUpdatedAt: nowIso,
        });
      }

      const lobbyRef = db.doc(`conversations/${conversationId}/gameLobbies/${gameId}`);
      tx.set(
        lobbyRef,
        {
          gameId,
          type: "durak",
          status: shouldAutoStart ? "active" : "lobby",
          conversationId,
          playerCount: playerIds.length + 1,
          maxPlayers,
          lastUpdatedAt: nowIso,
        },
        { merge: true },
      );

      const tournamentId = typeof (g as any).tournamentId === "string" ? ((g as any).tournamentId as string) : "";
      if (tournamentId) {
        tx.set(
          db.doc(`tournaments/${tournamentId}/games/${gameId}`),
          {
            status: shouldAutoStart ? "active" : "lobby",
            playerIds: newPlayerIds,
            playerCount: playerIds.length + 1,
            lastUpdatedAt: nowIso,
          },
          { merge: true },
        );
      }

      if (shouldAutoStart) {
        // Idempotent system message to notify both participants (and push).
        const msgRef = db.doc(`conversations/${conversationId}/messages/sys_game_started_${gameId}`);
        tx.set(
          msgRef,
          {
            id: `sys_game_started_${gameId}`,
            senderId: "__system__",
            createdAt: nowIso,
            text: "🎮 Партия «Дурак» началась.",
            systemEvent: {
              type: "gameStarted",
              data: { gameId, gameType: "durak" },
            },
          },
          { merge: true },
        );
      }
    });

    logger.info("[joinGameLobby] joined", { gameId, uid });
    return { gameId };
  },
);
