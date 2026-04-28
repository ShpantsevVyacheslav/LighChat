import { onCall, HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";
import * as admin from "firebase-admin";

import { parseCard } from "../../lib/games/durak/cards";
import {
  allDefended,
  applyAttack,
  applyDefense,
  applyTransfer,
  discardTable,
  drawUpToSix,
  rotateAfterSuccessfulDefense,
  rotateAfterTake,
  takeTable,
} from "../../lib/games/durak/engine";

type RequestData = {
  gameId?: unknown;
  clientMoveId?: unknown;
  actionType?: unknown; // "attack" | "defend" | "take" | "finishTurn" | "transfer"
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

      switch (actionType) {
        case "attack": {
          const c = parseCard(payloadObj.card);
          applyAttack({ state, uid, card: c, handsByUid: handsByUid as any });
          break;
        }
        case "defend": {
          const idxRaw = payloadObj.attackIndex;
          const attackIndex = typeof idxRaw === "number" ? Math.floor(idxRaw) : -1;
          const dCard = parseCard(payloadObj.card);
          applyDefense({
            state,
            uid,
            attackIndex,
            defense: dCard,
            handsByUid: handsByUid as any,
          });
          break;
        }
        case "transfer": {
          const mode = typeof settings.mode === "string" ? settings.mode : "podkidnoy";
          if (mode !== "perevodnoy") throw new HttpsError("failed-precondition", "TRANSFER_MODE_DISABLED");
          const c = parseCard(payloadObj.card);
          applyTransfer({ state, uid, card: c, handsByUid: handsByUid as any });
          break;
        }
        case "take": {
          if (uid !== state.defenderUid) throw new HttpsError("permission-denied", "ONLY_DEFENDER_CAN_TAKE");
          takeTable({ state, handsByUid: handsByUid as any });
          drawUpToSix({ state, handsByUid: handsByUid as any });
          rotateAfterTake(state);
          break;
        }
        case "finishTurn": {
          // Only attacker can finish, and only when fully defended.
          if (uid !== state.attackerUid) throw new HttpsError("permission-denied", "ONLY_ATTACKER_CAN_FINISH");
          if (!allDefended(state)) throw new HttpsError("failed-precondition", "NOT_FULLY_DEFENDED");
          discardTable({ state });
          drawUpToSix({ state, handsByUid: handsByUid as any });
          rotateAfterSuccessfulDefense(state);
          break;
        }
        default:
          throw new HttpsError("invalid-argument", "UNKNOWN_ACTION");
      }

      state.revision = (typeof state.revision === "number" ? state.revision : 0) + 1;
      state.lastMoveAt = nowIso;

      tx.create(moveRef, {
        id: clientMoveId,
        gameId,
        uid,
        actionType,
        payload: request.data?.payload ?? null,
        createdAt: nowIso,
        revision: state.revision,
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

      tx.update(gameRef, {
        serverState: state,
        publicView: {
          revision: state.revision,
          phase: "defense",
          trumpSuit: state.trumpSuit,
          deckCount: Array.isArray(state.deck) ? state.deck.length : 0,
          discardCount: Array.isArray(state.discard) ? state.discard.length : 0,
          attackerUid: state.attackerUid,
          defenderUid: state.defenderUid,
          table: state.table,
          handCounts,
          lastMoveAt: nowIso,
        },
        lastUpdatedAt: nowIso,
      });
    });

    logger.info("[makeDurakMove] accepted", { gameId, uid, clientMoveId, actionType });
    return { gameId, accepted: true };
  },
);

