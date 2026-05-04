import { HttpsError } from "firebase-functions/v2/https";

import type { DurakServerState } from "./state";
import { allDefended, allThrowersPassed, discardTable, drawUpToSix, rotateAfterSuccessfulDefense, undoLastCheat } from "./engine";

export function applyFinishTurn({
  state,
  handsByUid,
  uid,
  nowIso,
  shulerEnabled,
}: {
  state: DurakServerState;
  handsByUid: Record<string, unknown[]>;
  uid: string;
  nowIso: string;
  shulerEnabled: boolean;
}): void {
  if (uid !== state.attackerUid) throw new HttpsError("permission-denied", "ONLY_ATTACKER_CAN_FINISH");
  if (!allDefended(state)) throw new HttpsError("failed-precondition", "NOT_FULLY_DEFENDED");
  if (!allThrowersPassed({ state, handsByUid: handsByUid as any })) {
    throw new HttpsError("failed-precondition", "THROWIN_NOT_FINISHED");
  }
  if (shulerEnabled && state.lastCheat) {
    state.pendingResolution = { kind: "discard", at: nowIso, byUid: uid };
    state.phase = "resolution";
    return;
  }
  discardTable({ state });
  drawUpToSix({ state, handsByUid: handsByUid as any });
  rotateAfterSuccessfulDefense(state);
}

export function applyResolve({
  state,
  handsByUid,
  uid,
}: {
  state: DurakServerState;
  handsByUid: Record<string, unknown[]>;
  uid: string;
}): void {
  if (!state.pendingResolution) throw new HttpsError("failed-precondition", "NO_PENDING_RESOLUTION");
  if (uid !== state.attackerUid) throw new HttpsError("permission-denied", "ONLY_ATTACKER_CAN_RESOLVE");
  if (!allDefended(state)) throw new HttpsError("failed-precondition", "NOT_FULLY_DEFENDED");
  if (!allThrowersPassed({ state, handsByUid: handsByUid as any })) {
    throw new HttpsError("failed-precondition", "THROWIN_NOT_FINISHED");
  }
  state.pendingResolution = null;
  state.lastCheat = null;
  discardTable({ state });
  drawUpToSix({ state, handsByUid: handsByUid as any });
  rotateAfterSuccessfulDefense(state);
}

export function applyFoul({
  state,
  handsByUid,
  uid,
  nowIso,
  suspectedCard,
}: {
  state: DurakServerState;
  handsByUid: Record<string, unknown[]>;
  uid: string;
  nowIso: string;
  suspectedCard: { r: number; s: string };
}): void {
  if (!state.lastCheat) throw new HttpsError("failed-precondition", "NO_CHEAT_TO_FOUL");
  if (state.lastCheat.uid === uid) throw new HttpsError("permission-denied", "CANNOT_FOUL_OWN_CHEAT");
  const cheatCard = state.lastCheat.card;
  if (cheatCard.r !== suspectedCard.r || cheatCard.s !== suspectedCard.s) {
    throw new HttpsError("failed-precondition", "WRONG_CARD");
  }
  const { cheaterUid, penaltyCards, missedUids } = undoLastCheat({
    state,
    handsByUid: handsByUid as any,
  });
  state.foulEvent = {
    at: nowIso,
    byUid: uid,
    cheaterUid,
    missedUids: missedUids.filter((u) => u !== uid && u !== cheaterUid),
    penaltyCards,
  };
  state.pendingResolution = null;
}

