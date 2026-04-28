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
}: {
  state: DurakServerState;
  handsByUid: Record<string, unknown[]>;
  uid: string;
  nowIso: string;
}): void {
  if (!state.pendingResolution) throw new HttpsError("failed-precondition", "FOUL_NOT_ALLOWED_YET");
  if (!state.lastCheat) throw new HttpsError("failed-precondition", "NO_CHEAT_TO_FOUL");
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

