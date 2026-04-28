import { describe, expect, it } from "vitest";

import type { DurakServerState } from "./state";
import { applyFoul, applyFinishTurn, applyResolve } from "./moves";
import { parseCard } from "./cards";
import { resetRoundTracking } from "./engine";

function baseState(): DurakServerState {
  const s: DurakServerState = {
    revision: 0,
    trumpSuit: "H",
    deck: [],
    discard: [],
    attackerUid: "a",
    defenderUid: "b",
    table: { attacks: [], defenses: [] },
    seats: ["a", "b", "c"],
    lastMoveAt: new Date(0).toISOString(),
  };
  resetRoundTracking(s);
  return s;
}

describe("durak moves (shuler resolution)", () => {
  it("finishTurn with shuler+lastCheat sets pendingResolution and does not discard", () => {
    const state = baseState();
    const handsByUid: Record<string, any[]> = { a: [], b: [], c: [] };

    // Table is fully defended, throw-in finished.
    state.table.attacks = [parseCard({ r: 6, s: "S" })];
    state.table.defenses = [parseCard({ r: 7, s: "S" })];
    state.throwerUids = ["a", "c"];
    state.passedUids = ["a", "c"];
    state.lastCheat = { uid: "a", actionType: "attack", card: parseCard({ r: 6, s: "S" }), at: new Date(0).toISOString() };

    applyFinishTurn({ state, handsByUid, uid: "a", nowIso: new Date(1).toISOString(), shulerEnabled: true });
    expect(state.pendingResolution).not.toBeNull();
    expect(state.table.attacks.length).toBe(1); // not discarded yet
  });

  it("resolve clears pendingResolution and discards the table", () => {
    const state = baseState();
    const handsByUid: Record<string, any[]> = { a: [], b: [], c: [] };

    state.table.attacks = [parseCard({ r: 6, s: "S" })];
    state.table.defenses = [parseCard({ r: 7, s: "S" })];
    state.throwerUids = ["a", "c"];
    state.passedUids = ["a", "c"];
    state.pendingResolution = { kind: "discard", at: new Date(0).toISOString(), byUid: "a" };
    state.lastCheat = { uid: "a", actionType: "attack", card: parseCard({ r: 6, s: "S" }), at: new Date(0).toISOString() };

    applyResolve({ state, handsByUid, uid: "a" });
    expect(state.pendingResolution).toBeNull();
    expect(state.table.attacks.length).toBe(0);
    expect(state.discard.length).toBeGreaterThan(0);
  });

  it("foul clears pendingResolution and creates foulEvent", () => {
    const state = baseState();
    const handsByUid: Record<string, any[]> = {
      a: [parseCard({ r: 6, s: "S" })],
      b: [],
      c: [],
    };

    state.table.attacks = [parseCard({ r: 7, s: "D" })];
    state.table.defenses = [parseCard({ r: 8, s: "D" })];
    state.pendingResolution = { kind: "discard", at: new Date(0).toISOString(), byUid: "a" };
    // Pretend lastCheat was illegal defend; rollback logic will run.
    state.lastCheat = { uid: "a", actionType: "attack", card: parseCard({ r: 6, s: "S" }), at: new Date(0).toISOString() };

    applyFoul({ state, handsByUid, uid: "b", nowIso: new Date(2).toISOString() });
    expect(state.pendingResolution).toBeNull();
    expect(state.foulEvent).not.toBeNull();
    expect(state.foulEvent?.byUid).toBe("b");
  });
});

