import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions";
import * as admin from "firebase-admin";

import { normalizeDurakSettings } from "../../lib/games/gameSettings";
import {
  buildLegalMovesForUid,
  buildPublicView,
  buildSurrenderResult,
  computeAndApplyGameResult,
  discardTable,
  drawUpToSix,
  nextUid,
  resetRoundTracking,
} from "../../lib/games/durak/engine";
import type { Card } from "../../lib/games/durak/cards";
import type { DurakGameResult, DurakServerState } from "../../lib/games/durak/state";

function stripUndefined<T>(input: T): T {
  try {
    return JSON.parse(
      JSON.stringify(input, (_key, value) => {
        if (value === undefined) return null;
        if (typeof value === "number" && !Number.isFinite(value)) return null;
        if (typeof value === "bigint") return Number(value);
        if (typeof value === "function" || typeof value === "symbol") return undefined;
        return value;
      }),
    );
  } catch {
    return input;
  }
}

/**
 * Auto-handles expired Durak turn timers.
 *
 * Rules:
 * - 2 players: timed-out player immediately loses (game finished).
 * - 3+ players: timed-out player is eliminated from this hand:
 *   all their cards go to discard, table is discarded, game continues.
 */
export const cleanupDurakTurnTimeouts = onSchedule({
  schedule: "every 1 minutes",
  timeZone: "Europe/Moscow",
}, async () => {
  const db = admin.firestore();
  const nowIso = new Date().toISOString();

  const timedOut = await db
    .collection("games")
    .where("status", "==", "active")
    .where("publicView.turnDeadlineAt", "<=", nowIso)
    .limit(100)
    .get();

  if (timedOut.empty) return;

  for (const doc of timedOut.docs) {
    try {
      await db.runTransaction(async (tx) => {
        const gameRef = doc.ref;
        const gameSnap = await tx.get(gameRef);
        if (!gameSnap.exists) return;
        const g = gameSnap.data() || {};
        if (g.type !== "durak" || g.status !== "active") return;

        const publicView = (g.publicView && typeof g.publicView === "object") ? (g.publicView as any) : null;
        const turnDeadlineAt = typeof publicView?.turnDeadlineAt === "string" ? publicView.turnDeadlineAt : "";
        const turnUid = typeof publicView?.turnUid === "string" ? publicView.turnUid : "";
        if (!turnDeadlineAt || !turnUid || turnDeadlineAt > nowIso) return;

        const conversationId = typeof g.conversationId === "string" ? g.conversationId : "";
        if (!conversationId) return;

        const state = (g.serverState && typeof g.serverState === "object") ? (g.serverState as DurakServerState) : null;
        if (!state) return;

        const settings = normalizeDurakSettings(g.settings);
        const playerIds = Array.isArray(g.playerIds) ? g.playerIds.map((x: any) => String(x)) : [];
        if (!playerIds.includes(turnUid) || playerIds.length < 2) return;

        const allKnownUids = Array.from(new Set([
          ...playerIds,
          ...(Array.isArray(state.seats) ? state.seats.map((x) => String(x)) : []),
        ]));
        const handsByUid: Record<string, Card[]> = {};
        for (const uid of allKnownUids) {
          const handSnap = await tx.get(db.doc(`games/${doc.id}/privateHands/${uid}`));
          const d = handSnap.data() || {};
          const cards = Array.isArray(d.cards) ? (d.cards as Card[]) : [];
          handsByUid[uid] = cards;
        }

        let nextPlayerIds = [...playerIds];
        let result: DurakGameResult = null;
        let nextStatus: "active" | "finished" = "active";

        if (playerIds.length <= 2) {
          // Two-player timeout => immediate loss.
          result = buildSurrenderResult({ playerIds, loserUid: turnUid, nowIso });
          state.phase = "finished";
          state.lastMoveAt = nowIso;
          state.revision = (typeof state.revision === "number" ? state.revision : 0) + 1;
          nextStatus = "finished";
        } else {
          // 3+ players => eliminate timed-out player and continue.
          handsByUid[turnUid] = handsByUid[turnUid] ?? [];
          for (const c of handsByUid[turnUid]) state.discard.push(c);
          handsByUid[turnUid] = [];

          // Discard current table to move on cleanly.
          discardTable({ state });

          nextPlayerIds = playerIds.filter((uid) => uid !== turnUid);
          state.seats = (state.seats ?? nextPlayerIds).filter((uid) => uid !== turnUid);

          if (nextPlayerIds.length <= 1) {
            const winners = nextPlayerIds;
            result = {
              kind: "finished",
              finishedAt: nowIso,
              winners,
              loserUid: turnUid,
              placements: [
                ...(winners.length > 0 ? [{ uids: winners }] : []),
                { uids: [turnUid] },
              ],
            };
            state.phase = "finished";
            nextStatus = "finished";
          } else {
            if (!nextPlayerIds.includes(state.attackerUid)) {
              state.attackerUid = nextPlayerIds[0];
            }
            if (!nextPlayerIds.includes(state.defenderUid) || state.defenderUid === state.attackerUid) {
              state.defenderUid = nextUid(nextPlayerIds, state.attackerUid);
            }
            resetRoundTracking(state);
            drawUpToSix({ state, handsByUid });

            state.lastMoveAt = nowIso;
            state.revision = (typeof state.revision === "number" ? state.revision : 0) + 1;
            result = computeAndApplyGameResult({ state, handsByUid, nowIso });
            nextStatus = result ? "finished" : "active";
          }
        }

        // Persist hands for all participants known to this game.
        for (const uid of allKnownUids) {
          const cards = handsByUid[uid] ?? [];
          const legalMoves = nextStatus === "active" && nextPlayerIds.includes(uid) ?
            buildLegalMovesForUid({ state, handsByUid, uid, settings }) :
            {
              revision: typeof state.revision === "number" ? state.revision : 0,
              canTake: false,
              canPass: false,
              canFinishTurn: false,
              attackCardKeys: [],
              transferCardKeys: [],
              defenseTargets: [],
            };
          tx.set(
            db.doc(`games/${doc.id}/privateHands/${uid}`),
            {
              uid,
              cards,
              legalMoves,
              updatedAt: nowIso,
            },
            { merge: true },
          );
        }

        tx.update(gameRef, {
          status: nextStatus,
          playerIds: nextPlayerIds,
          serverState: stripUndefined(state),
          publicView: stripUndefined(
            buildPublicView({
              state,
              handsByUid,
              playerIds: nextPlayerIds,
              settings,
              nowIso,
              result,
            }),
          ),
          result: result ?? null,
          lastUpdatedAt: nowIso,
          finishedAt: nextStatus === "finished" ? nowIso : admin.firestore.FieldValue.delete(),
        });

        tx.set(
          db.doc(`conversations/${conversationId}/gameLobbies/${doc.id}`),
          {
            status: nextStatus,
            playerCount: nextPlayerIds.length,
            lastUpdatedAt: nowIso,
          },
          { merge: true },
        );

        logger.info("[cleanupDurakTurnTimeouts] handled timeout", {
          gameId: doc.id,
          turnUid,
          status: nextStatus,
          playerCountBefore: playerIds.length,
          playerCountAfter: nextPlayerIds.length,
        });
      });
    } catch (e) {
      logger.error("[cleanupDurakTurnTimeouts] transaction failed", {
        gameId: doc.id,
        error: (e as Error)?.message ?? String(e),
      });
    }
  }
});
