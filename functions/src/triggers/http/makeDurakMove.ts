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
import { applyFinishedGameToTournament } from "../../lib/games/tournamentEngine";

type RequestData = {
  gameId?: unknown;
  clientMoveId?: unknown;
  actionType?: unknown; // "attack" | "defend" | "take" | "finishTurn" | "transfer" | "pass" | "foul" | "resolve"
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

      if (state.pendingResolution && actionType !== "foul" && actionType !== "resolve") {
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
                prevRoundDefenderHandLimit,
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
        default:
          throw new HttpsError("invalid-argument", "UNKNOWN_ACTION");
      }

      // Canon: if defender is taking, allow throw-ins to continue until resolved,
      // then move table to defender, draw, and rotate.
      if (shouldResolveTakingRound({ state, handsByUid: handsByUid as any })) {
        takeTable({ state, handsByUid: handsByUid as any });
        drawUpToSix({ state, handsByUid: handsByUid as any });
        rotateAfterTake(state);
      }

      state.revision = (typeof state.revision === "number" ? state.revision : 0) + 1;
      state.lastMoveAt = nowIso;

      const result = computeAndApplyGameResult({
        state,
        handsByUid: handsByUid as any,
        nowIso,
      });

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
          { uid: u, cards, updatedAt: nowIso },
          { merge: true },
        );
      }

      const handCounts = Object.fromEntries(
        Object.entries(handsByUid).map(([u, cards]) => [u, cards.length]),
      );

      const phase = derivePhase(state);
      const isFinished = result != null && result.kind === "finished";
      tx.update(gameRef, {
        status: isFinished ? "finished" : "active",
        result: result ?? null,
        serverState: state,
        publicView: {
          revision: state.revision,
          phase,
          trumpSuit: state.trumpSuit,
          deckCount: Array.isArray(state.deck) ? state.deck.length : 0,
          discardCount: Array.isArray(state.discard) ? state.discard.length : 0,
          seats: Array.isArray(state.seats) ? state.seats : playerIds,
          attackerUid: state.attackerUid,
          defenderUid: state.defenderUid,
          table: state.table,
          handCounts,
          lastMoveAt: nowIso,
          throwerUids: state.throwerUids ?? [],
          passedUids: state.passedUids ?? [],
          shuler: {
            enabled: settings.shulerEnabled === true,
            lastCheatUid: state.lastCheat ? state.lastCheat.uid : null,
            lastCheatAt: state.lastCheat ? state.lastCheat.at : undefined,
            foulEvent: state.foulEvent ?? undefined,
            pendingResolution: state.pendingResolution ?? undefined,
          },
          result: result ?? null,
        },
        lastUpdatedAt: nowIso,
        finishedAt: isFinished ? nowIso : admin.firestore.FieldValue.delete(),
      });

      if (isFinished) {
        const conversationId = typeof g.conversationId === "string" ? g.conversationId : "";
        if (conversationId) {
          tx.set(
            db.doc(`conversations/${conversationId}/gameLobbies/${gameId}`),
            { status: "finished", lastUpdatedAt: nowIso },
            { merge: true },
          );
        }

        const tournamentId = typeof (g as any).tournamentId === "string" ? ((g as any).tournamentId as string) : "";
        if (tournamentId) {
          const tRef = db.doc(`tournaments/${tournamentId}`);
          const tgRef = db.doc(`tournaments/${tournamentId}/games/${gameId}`);
          const tSnap = await tx.get(tRef);
          if (tSnap.exists) {
            const t = tSnap.data() as any;
            const tgSnap = await tx.get(tgRef);
            const tg = tgSnap.exists ? (tgSnap.data() as any) : null;
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

    logger.info("[makeDurakMove] accepted", { gameId, uid, clientMoveId, actionType });
    return { gameId, accepted: true };
  },
);

