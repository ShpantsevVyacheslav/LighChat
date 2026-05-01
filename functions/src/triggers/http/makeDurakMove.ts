import { onCall, HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";
import * as admin from "firebase-admin";

import { cardKey, parseCard } from "../../lib/games/durak/cards";
import {
  applyAttack,
  applyAttackRelaxed,
  applyDefense,
  applyDefenseRelaxed,
  applyTransfer,
  applyTransferRelaxed,
  buildLegalMovesForUid,
  buildPublicView,
  buildSurrenderResult,
  computeAndApplyGameResult,
  derivePhase,
  drawUpToSix,
  markTaking,
  passThrowIn,
  rotateAfterTake,
  shouldResolveTakingRound,
  takeTable,
} from "../../lib/games/durak/engine";
import { applyFoul, applyFinishTurn, applyResolve } from "../../lib/games/durak/moves";
import type { DurakGameResult } from "../../lib/games/durak/state";
import { applyFinishedGameToTournament } from "../../lib/games/tournamentEngine";

type RequestData = {
  gameId?: unknown;
  clientMoveId?: unknown;
  actionType?: unknown; // "attack" | "defend" | "take" | "finishTurn" | "transfer" | "pass" | "foul" | "resolve" | "surrender"
  payload?: unknown;
};

type ResponseData = {
  gameId: string;
  accepted: boolean;
};

function asNonEmptyString(v: unknown): string | null {
  if (typeof v !== "string") return null;
  const t = v.trim();
  return t ? t : null;
}

export const makeDurakMove = onCall(
  { region: "us-central1" },
  async (request: CallableRequest<RequestData>): Promise<ResponseData> => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "AUTH_REQUIRED");

    const gameId = asNonEmptyString(request.data?.gameId);
    const clientMoveId = asNonEmptyString(request.data?.clientMoveId);
    const actionType = asNonEmptyString(request.data?.actionType);
    if (!gameId || !clientMoveId || !actionType) {
      throw new HttpsError("invalid-argument", "BAD_INPUT");
    }

    const db = admin.firestore();
    const gameRef = db.doc(`games/${gameId}`);
    const moveRef = gameRef.collection("moves").doc(clientMoveId);
    const nowIso = new Date().toISOString();

    try {
      await db.runTransaction(async (tx) => {
      const gameSnap = await tx.get(gameRef);
      if (!gameSnap.exists) throw new HttpsError("not-found", "GAME_NOT_FOUND");
      const g = gameSnap.data() || {};
      if (g.type !== "durak") throw new HttpsError("failed-precondition", "GAME_TYPE_UNSUPPORTED");
      if (g.status !== "active") throw new HttpsError("failed-precondition", "GAME_NOT_ACTIVE");

      const playerIds = Array.isArray(g.playerIds) ? g.playerIds : [];
      if (!playerIds.includes(uid)) throw new HttpsError("permission-denied", "NOT_A_PLAYER");

      const state = (g.serverState && typeof g.serverState === "object") ? (g.serverState as any) : null;
      if (!state) throw new HttpsError("failed-precondition", "GAME_STATE_MISSING");
      const settings = (g.settings && typeof g.settings === "object") ? (g.settings as any) : {};

      const existingMove = await tx.get(moveRef);
      if (existingMove.exists) {
        return; // idempotent
      }

      // Load all hands (server-side authoritative).
      const handsByUid: Record<string, any[]> = {};
      for (const u of playerIds) {
        const hSnap = await tx.get(db.doc(`games/${gameId}/privateHands/${u}`));
        const d = hSnap.data() || {};
        const cards = Array.isArray(d.cards) ? d.cards : [];
        handsByUid[u] = cards;
      }

      let payloadObj: Record<string, unknown> = {};
      const rawPayload = request.data?.payload;
      if (rawPayload && typeof rawPayload === "object") {
        payloadObj = rawPayload as Record<string, unknown>;
      }

      let payloadNormalized: Record<string, unknown> = {};
      let cheated: Record<string, unknown> | null = null;
      let forcedResult: DurakGameResult = null;

      if (state.pendingResolution && actionType !== "foul" && actionType !== "resolve" && actionType !== "surrender") {
        throw new HttpsError("failed-precondition", "ROUND_RESOLUTION_PENDING");
      }

      switch (actionType) {
        case "attack": {
          const c = parseCard(payloadObj.card);
          if (settings.shulerEnabled === true) {
            // Determine if this would fail canon rules.
            try {
              // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
              const stateCopy = structuredClone(state);
              const handsCopy = structuredClone(handsByUid);
              applyAttack({ state: stateCopy as any, uid, card: c, handsByUid: handsCopy as any });
            } catch (e) {
              cheated = { kind: "attack" };
            }
            applyAttackRelaxed({ state, uid, card: c, handsByUid: handsByUid as any });
            if (cheated) {
              state.shulerEnabled = true;
              state.lastCheat = { uid, actionType: "attack", card: c, at: nowIso };
            }
          } else {
            applyAttack({ state, uid, card: c, handsByUid: handsByUid as any });
          }
          payloadNormalized = { card: c, cardKey: cardKey(c) };
          break;
        }
        case "defend": {
          const idxRaw = payloadObj.attackIndex;
          const attackIndex = typeof idxRaw === "number" ? Math.floor(idxRaw) : -1;
          const dCard = parseCard(payloadObj.card);
          if (settings.shulerEnabled === true) {
            try {
              const stateCopy = structuredClone(state);
              const handsCopy = structuredClone(handsByUid);
              applyDefense({
                state: stateCopy as any,
                uid,
                attackIndex,
                defense: dCard,
                handsByUid: handsCopy as any,
              });
            } catch (e) {
              cheated = { kind: "defend" };
            }
            applyDefenseRelaxed({
              state,
              uid,
              attackIndex,
              defense: dCard,
              handsByUid: handsByUid as any,
            });
            if (cheated) {
              state.shulerEnabled = true;
              state.lastCheat = { uid, actionType: "defend", card: dCard, attackIndex, at: nowIso };
            }
          } else {
            applyDefense({
              state,
              uid,
              attackIndex,
              defense: dCard,
              handsByUid: handsByUid as any,
            });
          }
          payloadNormalized = { attackIndex, card: dCard, cardKey: cardKey(dCard) };
          break;
        }
        case "transfer": {
          const mode = typeof settings.mode === "string" ? settings.mode : "podkidnoy";
          if (mode !== "perevodnoy") throw new HttpsError("failed-precondition", "TRANSFER_MODE_DISABLED");
          const c = parseCard(payloadObj.card);
          if (settings.shulerEnabled === true) {
            try {
              const stateCopy = structuredClone(state);
              const handsCopy = structuredClone(handsByUid);
              applyTransfer({ state: stateCopy as any, uid, card: c, handsByUid: handsCopy as any });
            } catch (e) {
              cheated = { kind: "transfer" };
            }
            const prevDefenderUid = typeof state.defenderUid === "string" ? state.defenderUid : "";
            const prevThrowerUids = Array.isArray(state.throwerUids) ? [...state.throwerUids] : [];
            const prevPassedUids = Array.isArray(state.passedUids) ? [...state.passedUids] : [];
            const prevRoundDefenderHandLimit = typeof state.roundDefenderHandLimit === "number" ? state.roundDefenderHandLimit : undefined;
            applyTransferRelaxed({ state, uid, card: c, handsByUid: handsByUid as any });
            if (cheated) {
              state.shulerEnabled = true;
              state.lastCheat = {
                uid,
                actionType: "transfer",
                card: c,
                prevDefenderUid,
                prevThrowerUids,
                prevPassedUids,
                ...(typeof prevRoundDefenderHandLimit === "number" ? { prevRoundDefenderHandLimit } : {}),
                at: nowIso,
              };
            }
          } else {
            applyTransfer({ state, uid, card: c, handsByUid: handsByUid as any });
          }
          payloadNormalized = { card: c, cardKey: cardKey(c) };
          break;
        }
        case "pass": {
          passThrowIn({ state, uid, handsByUid: handsByUid as any });
          payloadNormalized = {};
          break;
        }
        case "take": {
          markTaking({ state, uid, handsByUid: handsByUid as any });
          payloadNormalized = {};
          break;
        }
        case "foul": {
          applyFoul({ state, handsByUid: handsByUid as any, uid, nowIso });
          payloadNormalized = {};
          break;
        }
        case "resolve": {
          applyResolve({ state, handsByUid: handsByUid as any, uid });
          payloadNormalized = {};
          break;
        }
        case "finishTurn": {
          applyFinishTurn({
            state,
            handsByUid: handsByUid as any,
            uid,
            nowIso,
            shulerEnabled: settings.shulerEnabled === true,
          });
          payloadNormalized = {};
          break;
        }
        case "surrender": {
          const activeSeats = Array.isArray(state.seats) ? state.seats : playerIds;
          if (!activeSeats.includes(uid)) throw new HttpsError("permission-denied", "NOT_ACTIVE_PLAYER");
          forcedResult = buildSurrenderResult({ playerIds, loserUid: uid, nowIso });
          state.phase = "finished";
          payloadNormalized = { loserUid: uid };
          break;
        }
        default:
          throw new HttpsError("invalid-argument", "UNKNOWN_ACTION");
      }

      // Canon: if defender is taking, allow throw-ins to continue until resolved,
      // then move table to defender, draw, and rotate.
      if (!forcedResult && shouldResolveTakingRound({ state, handsByUid: handsByUid as any })) {
        takeTable({ state, handsByUid: handsByUid as any });
        drawUpToSix({ state, handsByUid: handsByUid as any });
        rotateAfterTake(state);
      }

      state.revision = (typeof state.revision === "number" ? state.revision : 0) + 1;
      state.lastMoveAt = nowIso;

      const result = forcedResult ?? computeAndApplyGameResult({
        state,
        handsByUid: handsByUid as any,
        nowIso,
      });
      const isFinished = result != null && result.kind === "finished";
      const conversationId = typeof g.conversationId === "string" ? g.conversationId : "";
      const tournamentId = typeof (g as any).tournamentId === "string" ? ((g as any).tournamentId as string) : "";
      const tRef = isFinished && tournamentId ? db.doc(`tournaments/${tournamentId}`) : null;
      const tgRef = isFinished && tournamentId ? db.doc(`tournaments/${tournamentId}/games/${gameId}`) : null;
      const tSnap = tRef ? await tx.get(tRef) : null;
      const tgSnap = tgRef ? await tx.get(tgRef) : null;

      tx.create(moveRef, {
        id: clientMoveId,
        gameId,
        uid,
        actionType,
        payload: request.data?.payload ?? null,
        payloadNormalized,
        createdAt: nowIso,
        revision: state.revision,
        phase: derivePhase(state),
        result: result ?? null,
        cheated: cheated ?? null,
      });

      // Persist hands
      for (const [u, cards] of Object.entries(handsByUid)) {
        tx.set(
          db.doc(`games/${gameId}/privateHands/${u}`),
          {
            uid: u,
            cards,
            legalMoves: buildLegalMovesForUid({ state, handsByUid: handsByUid as any, uid: u, settings }),
            updatedAt: nowIso,
          },
          { merge: true },
        );
      }

      tx.update(gameRef, {
        status: isFinished ? "finished" : "active",
        result: result ?? null,
        serverState: state,
        publicView: buildPublicView({
          state,
          handsByUid: handsByUid as any,
          playerIds,
          settings,
          nowIso,
          result,
        }),
        lastUpdatedAt: nowIso,
        finishedAt: isFinished ? nowIso : admin.firestore.FieldValue.delete(),
      });

      if (isFinished) {
        if (conversationId) {
          tx.set(
            db.doc(`conversations/${conversationId}/gameLobbies/${gameId}`),
            { status: "finished", lastUpdatedAt: nowIso },
            { merge: true },
          );
        }

        if (tRef && tgRef && tSnap) {
          if (tSnap.exists) {
            const t = tSnap.data() as any;
            const tg = tgSnap?.exists ? (tgSnap.data() as any) : null;
            const alreadyApplied =
              tg != null &&
              (typeof tg.appliedAt === "string" || tg.appliedAtTs != null || tg.applied === true);
            if (alreadyApplied) {
              // Idempotency: CF transactions can retry; do not double-apply points.
              tx.set(
                tgRef,
                {
                  status: "finished",
                  finishedAt: nowIso,
                  placements: (result as any)?.placements ?? null,
                  lastUpdatedAt: nowIso,
                },
                { merge: true },
              );
              return;
            }
            const placementsRaw = (result as any)?.placements;
            const placements =
              Array.isArray(placementsRaw) ?
                placementsRaw
                  .map((g0: any) => ({ uids: Array.isArray(g0?.uids) ? g0.uids.map((x: any) => String(x)) : [] }))
                  .filter((g0: any) => g0.uids.length > 0) :
                [];
            const updated = applyFinishedGameToTournament({
              tournament: {
                id: String(t.id ?? tournamentId),
                type: "durak",
                status: (t.status === "finished" ? "finished" : "active") as any,
                conversationId: String(t.conversationId ?? ""),
                gameIds: Array.isArray(t.gameIds) ? t.gameIds.map((x: any) => String(x)) : [],
                pointsByUid: (t.pointsByUid && typeof t.pointsByUid === "object") ? t.pointsByUid : {},
                gamesPlayedByUid: (t.gamesPlayedByUid && typeof t.gamesPlayedByUid === "object") ? t.gamesPlayedByUid : {},
                lastUpdatedAt: String(t.lastUpdatedAt ?? ""),
              },
              gameId,
              playerIds,
              placements,
            });
            tx.set(
              tRef,
              {
                gameIds: updated.gameIds,
                pointsByUid: updated.pointsByUid,
                gamesPlayedByUid: updated.gamesPlayedByUid,
                lastUpdatedAt: nowIso,
              },
              { merge: true },
            );
            tx.set(
              tgRef,
              {
                status: "finished",
                finishedAt: nowIso,
                placements: (result as any)?.placements ?? null,
                playerIds,
                loserUid: (result as any)?.loserUid ?? null,
                winners: (result as any)?.winners ?? null,
                applied: true,
                appliedAt: nowIso,
                lastUpdatedAt: nowIso,
              },
              { merge: true },
            );
          }
        }
      }
      });
    } catch (error) {
      if (error instanceof HttpsError) {
        throw error;
      }
      logger.error("[makeDurakMove] unexpected failure", {
        gameId,
        uid,
        actionType,
        clientMoveId,
        error: (error as Error)?.message ?? String(error),
      });
      throw new HttpsError("failed-precondition", "MOVE_REJECTED_RETRY");
    }

    logger.info("[makeDurakMove] accepted", { gameId, uid, clientMoveId, actionType });
    return { gameId, accepted: true };
  },
);
