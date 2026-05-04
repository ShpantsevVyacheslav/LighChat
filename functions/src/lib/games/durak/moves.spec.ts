import { describe, expect, it } from "vitest";

import type { DurakServerState } from "./state";
import { applyFoul } from "./moves";
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

describe("durak moves (shuler)", () => {
  it("foul with correct card undoes cheat and creates foulEvent", () => {
    const state = baseState();
    const cheatCard = parseCard({ r: 6, s: "S" });
    const handsByUid: Record<string, any[]> = {
      a: [cheatCard],
      b: [],
      c: [],
    };

    state.table.attacks = [parseCard({ r: 7, s: "D" }), cheatCard];
    state.table.defenses = [parseCard({ r: 8, s: "D" }), null];
    state.lastCheat = { uid: "a", actionType: "attack", card: cheatCard, at: new Date(0).toISOString() };

    applyFoul({ state, handsByUid, uid: "b", nowIso: new Date(2).toISOString(), suspectedCard: { r: 6, s: "S" } });
    expect(state.foulEvent).not.toBeNull();
    expect(state.foulEvent?.byUid).toBe("b");
    expect(state.table.attacks.length).toBe(1);
  });

  it("foul with wrong card throws WRONG_CARD", () => {
    const state = baseState();
    const handsByUid: Record<string, any[]> = { a: [], b: [], c: [] };

    state.table.attacks = [parseCard({ r: 6, s: "S" })];
    state.table.defenses = [null];
    state.lastCheat = { uid: "a", actionType: "attack", card: parseCard({ r: 6, s: "S" }), at: new Date(0).toISOString() };

    expect(() =>
      applyFoul({ state, handsByUid, uid: "b", nowIso: new Date(2).toISOString(), suspectedCard: { r: 7, s: "H" } }),
    ).toThrow("WRONG_CARD");
  });

  it("cheater cannot foul own cheat", () => {
    const state = baseState();
    const handsByUid: Record<string, any[]> = { a: [], b: [], c: [] };

    state.table.attacks = [parseCard({ r: 6, s: "S" })];
    state.table.defenses = [null];
    state.lastCheat = { uid: "a", actionType: "attack", card: parseCard({ r: 6, s: "S" }), at: new Date(0).toISOString() };

    expect(() =>
      applyFoul({ state, handsByUid, uid: "a", nowIso: new Date(2).toISOString(), suspectedCard: { r: 6, s: "S" } }),
    ).toThrow("CANNOT_FOUL_OWN_CHEAT");
  });
});
