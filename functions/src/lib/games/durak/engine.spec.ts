import { describe, expect, it } from "vitest";

import { buildInitialState, buildSurrenderResult, canFinishTurn, computeAndApplyGameResult, derivePhase, drawUpToSix, markTaking, rotateAfterTake, shouldResolveTakingRound, takeTable } from "./engine";
import type { DurakGameSettings } from "../gameSettings";
import { parseCard } from "./cards";
import { applyAttack, applyDefense, applyTransfer, allDefended, resetRoundTracking } from "./engine";

const settings: DurakGameSettings = {
  mode: "podkidnoy",
  maxPlayers: 2,
  deckSize: 36,
  withJokers: false,
  turnTimeSec: null,
  throwInPolicy: "all",
  shulerEnabled: false,
};

describe("durak engine", () => {
  it("buildInitialState sets phase attack and deals 6 cards in first deal", () => {
    const { state, handsByUid } = buildInitialState({
      playerIds: ["u1", "u2"],
      settings,
      nowIso: new Date(0).toISOString(),
      randInt: (m) => (m <= 1 ? 0 : 1),
    });

    expect(state.seats).toEqual(["u1", "u2"]);
    expect(state.phase).toBe("attack");
    expect(derivePhase(state)).toBe("attack");
    expect(handsByUid.u1.length).toBe(6);
    expect(handsByUid.u2.length).toBe(6);
  });

  it("buildSurrenderResult makes the surrendering player the loser", () => {
    const result = buildSurrenderResult({
      playerIds: ["u1", "u2", "u3"],
      loserUid: "u2",
      nowIso: new Date(10).toISOString(),
    });

    expect(result?.kind).toBe("finished");
    expect(result?.loserUid).toBe("u2");
    expect(result?.winners).toEqual(["u1", "u3"]);
    expect(result?.placements).toEqual([{ uids: ["u1", "u3"] }, { uids: ["u2"] }]);
  });

  it("joker can be thrown-in anytime and forces defender to take", () => {
    const { state, handsByUid } = buildInitialState({
      playerIds: ["u1", "u2"],
      settings: { ...settings, withJokers: true },
      nowIso: new Date(0).toISOString(),
      randInt: () => 0,
    });
    state.trumpSuit = "H";
    handsByUid[state.attackerUid] = [parseCard({ r: 6, s: "S" }), parseCard({ r: "JOKER", s: null })];
    handsByUid[state.defenderUid] = [parseCard({ r: 7, s: "S" }), parseCard({ r: 8, s: "S" })];

    applyAttack({ state, uid: state.attackerUid, card: parseCard({ r: 6, s: "S" }), handsByUid });
    applyAttack({ state, uid: state.attackerUid, card: parseCard({ r: "JOKER", s: null }), handsByUid });

    expect(state.taking).toBe(true);
    expect(derivePhase(state)).toBe("throwIn");
  });

  it("joker can transfer anytime (before any defense is placed)", () => {
    const { state, handsByUid } = buildInitialState({
      playerIds: ["u1", "u2", "u3"],
      settings: { ...settings, maxPlayers: 3, mode: "perevodnoy", withJokers: true },
      nowIso: new Date(0).toISOString(),
      randInt: () => 0,
    });
    handsByUid[state.attackerUid] = [parseCard({ r: 6, s: "S" })];
    // Defender must have enough cards so canonical throw-in limit doesn't block transfer.
    handsByUid[state.defenderUid] = [
      parseCard({ r: "JOKER", s: null }),
      parseCard({ r: 7, s: "D" }),
    ];
    handsByUid["u3"] = [parseCard({ r: 7, s: "S" })];
    state.trumpSuit = "H";

    applyAttack({ state, uid: state.attackerUid, card: parseCard({ r: 6, s: "S" }), handsByUid });
    applyTransfer({ state, uid: state.defenderUid, card: parseCard({ r: "JOKER", s: null }), handsByUid });

    expect(state.table.attacks.length).toBe(2);
    expect(state.taking).toBe(true);
  });

  it("throw-in is turn-based: attacker first, then next thrower", () => {
    const { state, handsByUid } = buildInitialState({
      playerIds: ["a", "b", "c", "d"],
      settings: { ...settings, maxPlayers: 4 },
      nowIso: new Date(0).toISOString(),
      randInt: () => 0,
    });
    state.seats = ["a", "b", "c", "d"];
    state.attackerUid = "a";
    state.defenderUid = "b";
    resetRoundTracking(state);
    state.trumpSuit = "H";

    handsByUid.a = [parseCard({ r: 6, s: "S" }), parseCard({ r: 6, s: "D" })];
    handsByUid.b = [parseCard({ r: 7, s: "S" }), parseCard({ r: 8, s: "S" })];
    handsByUid.c = [parseCard({ r: 6, s: "H" })];
    handsByUid.d = [parseCard({ r: 6, s: "C" })];

    applyAttack({ state, uid: "a", card: parseCard({ r: 6, s: "S" }), handsByUid });
    expect(() =>
      applyAttack({ state, uid: "c", card: parseCard({ r: 6, s: "H" }), handsByUid }),
    ).toThrow();
  });

  it("canFinishTurn stays false until every thrower passed", () => {
    const { state, handsByUid } = buildInitialState({
      playerIds: ["a", "b", "c"],
      settings: { ...settings, maxPlayers: 3 },
      nowIso: new Date(0).toISOString(),
      randInt: () => 0,
    });
    state.seats = ["a", "b", "c"];
    state.attackerUid = "a";
    state.defenderUid = "b";
    resetRoundTracking(state);
    state.trumpSuit = "H";
    handsByUid.a = [parseCard({ r: 6, s: "S" })];
    handsByUid.b = [parseCard({ r: 7, s: "S" })];
    handsByUid.c = [parseCard({ r: 6, s: "C" })];

    applyAttack({ state, uid: "a", card: parseCard({ r: 6, s: "S" }), handsByUid });
    applyDefense({ state, uid: "b", attackIndex: 0, defense: parseCard({ r: 7, s: "S" }), handsByUid });

    expect(canFinishTurn({ state, handsByUid })).toBe(false);
    state.passedUids = ["a", "c"];
    expect(canFinishTurn({ state, handsByUid })).toBe(true);
  });

  it("defense must beat attack (same suit higher or trump)", () => {
    const { state, handsByUid } = buildInitialState({
      playerIds: ["u1", "u2"],
      settings,
      nowIso: new Date(0).toISOString(),
      randInt: (m) => (m <= 1 ? 0 : 1),
    });

    // Force deterministic hands for the test.
    handsByUid[state.attackerUid] = [parseCard({ r: 6, s: "S" })];
    handsByUid[state.defenderUid] = [parseCard({ r: 7, s: "S" })];
    state.trumpSuit = "H";

    applyAttack({
      state,
      uid: state.attackerUid,
      card: parseCard({ r: 6, s: "S" }),
      handsByUid,
    });

    applyDefense({
      state,
      uid: state.defenderUid,
      attackIndex: 0,
      defense: parseCard({ r: 7, s: "S" }),
      handsByUid,
    });

    expect(allDefended(state)).toBe(true);
    expect(state.table.defenses[0]).not.toBeNull();
  });

  it("transfer is forbidden after any defense card is placed (canon)", () => {
    const { state, handsByUid } = buildInitialState({
      playerIds: ["u1", "u2", "u3"],
      settings: { ...settings, maxPlayers: 3, mode: "perevodnoy" },
      nowIso: new Date(0).toISOString(),
      randInt: (m) => (m <= 1 ? 0 : 1),
    });

    // Force hands.
    handsByUid[state.attackerUid] = [parseCard({ r: 6, s: "S" })];
    handsByUid[state.defenderUid] = [
      parseCard({ r: 6, s: "D" }), // transfer candidate
      parseCard({ r: 7, s: "S" }), // defense
    ];
    state.trumpSuit = "H";

    applyAttack({
      state,
      uid: state.attackerUid,
      card: parseCard({ r: 6, s: "S" }),
      handsByUid,
    });

    applyDefense({
      state,
      uid: state.defenderUid,
      attackIndex: 0,
      defense: parseCard({ r: 7, s: "S" }),
      handsByUid,
    });

    expect(() =>
      applyTransfer({
        state,
        uid: state.defenderUid,
        card: parseCard({ r: 6, s: "D" }),
        handsByUid,
      }),
    ).toThrow();
  });

  it("throw-in count is limited by defender hand size at round start (canon)", () => {
    const { state, handsByUid } = buildInitialState({
      playerIds: ["u1", "u2"],
      settings,
      nowIso: new Date(0).toISOString(),
      randInt: (m) => (m <= 1 ? 0 : 1),
    });

    // Defender starts round with exactly 1 card.
    handsByUid[state.attackerUid] = [
      parseCard({ r: 6, s: "S" }),
      parseCard({ r: 6, s: "D" }),
    ];
    handsByUid[state.defenderUid] = [parseCard({ r: 7, s: "S" })];
    state.trumpSuit = "H";

    applyAttack({
      state,
      uid: state.attackerUid,
      card: parseCard({ r: 6, s: "S" }),
      handsByUid,
    });

    // Second throw-in should fail because limit is 1 (defender had 1 at start).
    expect(() =>
      applyAttack({
        state,
        uid: state.attackerUid,
        card: parseCard({ r: 6, s: "D" }),
        handsByUid,
      }),
    ).toThrow();
  });

  it("drawUpToSix uses canonical order (attacker forward, defender last) for 4 players", () => {
    const { state, handsByUid } = buildInitialState({
      playerIds: ["a", "b", "c", "d"],
      settings: { ...settings, maxPlayers: 4 },
      nowIso: new Date(0).toISOString(),
      randInt: () => 0,
    });

    state.attackerUid = "d";
    state.defenderUid = "a";
    state.seats = ["a", "b", "c", "d"];

    // Hands: everyone needs 1 card to reach 6.
    handsByUid.a = [parseCard({ r: 6, s: "S" }), parseCard({ r: 7, s: "S" }), parseCard({ r: 8, s: "S" }), parseCard({ r: 9, s: "S" }), parseCard({ r: 10, s: "S" })];
    handsByUid.b = [parseCard({ r: 6, s: "H" }), parseCard({ r: 7, s: "H" }), parseCard({ r: 8, s: "H" }), parseCard({ r: 9, s: "H" }), parseCard({ r: 10, s: "H" })];
    handsByUid.c = [parseCard({ r: 6, s: "D" }), parseCard({ r: 7, s: "D" }), parseCard({ r: 8, s: "D" }), parseCard({ r: 9, s: "D" }), parseCard({ r: 10, s: "D" })];
    handsByUid.d = [parseCard({ r: 6, s: "C" }), parseCard({ r: 7, s: "C" }), parseCard({ r: 8, s: "C" }), parseCard({ r: 9, s: "C" }), parseCard({ r: 10, s: "C" })];

    // Deck top is at end; pop() will deal in this sequence:
    // order should be: attacker d, then b, then c, defender a last.
    state.deck = [
      parseCard({ r: 14, s: "S" }), // bottom-ish filler
      parseCard({ r: 11, s: "S" }), // to a (last)
      parseCard({ r: 12, s: "S" }), // to c
      parseCard({ r: 13, s: "S" }), // to b
      parseCard({ r: 6, s: "S" }), // to d (first)
    ];

    drawUpToSix({ state, handsByUid });

    expect(handsByUid.d[handsByUid.d.length - 1]).toEqual(parseCard({ r: 6, s: "S" }));
    expect(handsByUid.b[handsByUid.b.length - 1]).toEqual(parseCard({ r: 13, s: "S" }));
    expect(handsByUid.c[handsByUid.c.length - 1]).toEqual(parseCard({ r: 12, s: "S" }));
    expect(handsByUid.a[handsByUid.a.length - 1]).toEqual(parseCard({ r: 11, s: "S" }));
  });

  it("drawUpToSix handles 6 players and stops when deck ends", () => {
    const { state, handsByUid } = buildInitialState({
      playerIds: ["p1", "p2", "p3", "p4", "p5", "p6"],
      settings: { ...settings, maxPlayers: 6 },
      nowIso: new Date(0).toISOString(),
      randInt: () => 0,
    });

    state.seats = ["p1", "p2", "p3", "p4", "p5", "p6"];
    state.attackerUid = "p3";
    state.defenderUid = "p5";

    // Everyone at 5 cards so each needs 1, but deck has only 3 cards.
    for (const u of state.seats) {
      handsByUid[u] = [
        parseCard({ r: 6, s: "S" }),
        parseCard({ r: 7, s: "S" }),
        parseCard({ r: 8, s: "S" }),
        parseCard({ r: 9, s: "S" }),
        parseCard({ r: 10, s: "S" }),
      ];
    }

    // Order: p3, p4, p6, p1, p2, defender p5 last.
    state.deck = [
      parseCard({ r: 14, s: "H" }),
      parseCard({ r: 13, s: "H" }),
      parseCard({ r: 12, s: "H" }),
    ];

    drawUpToSix({ state, handsByUid });

    expect(handsByUid.p3.length).toBe(6);
    expect(handsByUid.p4.length).toBe(6);
    expect(handsByUid.p6.length).toBe(6);
    // Others should not receive because deck ended.
    expect(handsByUid.p1.length).toBe(5);
    expect(handsByUid.p2.length).toBe(5);
    expect(handsByUid.p5.length).toBe(5);
  });

  it("take is canonical: defender marks taking, throw-in may continue, then resolves", () => {
    const { state, handsByUid } = buildInitialState({
      playerIds: ["u1", "u2"],
      settings,
      nowIso: new Date(0).toISOString(),
      randInt: () => 0,
    });
    state.trumpSuit = "H";
    // Set deterministic hands
    handsByUid[state.attackerUid] = [parseCard({ r: 6, s: "S" }), parseCard({ r: 6, s: "D" })];
    // Defender starts round with 2 cards => canonical throw-in limit = 2.
    handsByUid[state.defenderUid] = [parseCard({ r: 7, s: "S" }), parseCard({ r: 8, s: "S" })];

    applyAttack({
      state,
      uid: state.attackerUid,
      card: parseCard({ r: 6, s: "S" }),
      handsByUid,
    });

    markTaking({ state, uid: state.defenderUid, handsByUid });
    expect(state.taking).toBe(true);
    expect(derivePhase(state)).toBe("throwIn");

    // Attacker can still throw-in (rank matches table).
    applyAttack({
      state,
      uid: state.attackerUid,
      card: parseCard({ r: 6, s: "D" }),
      handsByUid,
    });

    // Now throw-in cannot continue because defender had 2 cards at round start => limit=2 and we placed 2 attacks.
    expect(shouldResolveTakingRound({ state, handsByUid })).toBe(true);
    const before = handsByUid[state.defenderUid].length;
    takeTable({ state, handsByUid });
    expect(handsByUid[state.defenderUid].length).toBeGreaterThan(before);
    expect(state.table.attacks.length).toBe(0);
    expect(state.taking).toBe(false);
  });

  it("after take in a two-player game attacker and defender stay distinct", () => {
    const { state } = buildInitialState({
      playerIds: ["u1", "u2"],
      settings,
      nowIso: new Date(0).toISOString(),
      randInt: () => 0,
    });
    const attacker = state.attackerUid;
    const defender = state.defenderUid;

    rotateAfterTake(state);

    expect(state.attackerUid).toBe(attacker);
    expect(state.defenderUid).toBe(defender);
    expect(state.attackerUid).not.toBe(state.defenderUid);
  });

  it("neighbors throw-in policy allows only defender neighbors", () => {
    const { state, handsByUid } = buildInitialState({
      playerIds: ["a", "b", "c", "d", "e"],
      settings: { ...settings, maxPlayers: 5, throwInPolicy: "neighbors" },
      nowIso: new Date(0).toISOString(),
      randInt: () => 0,
    });

    state.seats = ["a", "b", "c", "d", "e"];
    state.attackerUid = "c";
    state.defenderUid = "d"; // neighbors: c and e
    state.throwInPolicy = "neighbors";
    resetRoundTracking(state);

    handsByUid.c = [parseCard({ r: 6, s: "S" })];
    handsByUid.e = [parseCard({ r: 6, s: "D" })];
    handsByUid.a = [parseCard({ r: 6, s: "H" })];
    handsByUid.b = [parseCard({ r: 6, s: "C" })];
    // Defender starts round with >=2 cards so canonical throw-in limit doesn't block the test.
    handsByUid.d = [parseCard({ r: 7, s: "S" }), parseCard({ r: 8, s: "S" }), parseCard({ r: 9, s: "S" })];
    state.trumpSuit = "H";

    applyAttack({ state, uid: "c", card: parseCard({ r: 6, s: "S" }), handsByUid });
    // e is neighbor => allowed to throw-in rank 6.
    applyAttack({ state, uid: "e", card: parseCard({ r: 6, s: "D" }), handsByUid });
    // a is not neighbor => must fail.
    expect(() =>
      applyAttack({ state, uid: "a", card: parseCard({ r: 6, s: "H" }), handsByUid }),
    ).toThrow();
  });

  it("does not finish when deck is empty but table is not resolved", () => {
    const { state, handsByUid } = buildInitialState({
      playerIds: ["a", "b"],
      settings,
      nowIso: new Date(0).toISOString(),
      randInt: () => 0,
    });
    state.deck = [];
    state.trumpSuit = "H";
    state.table.attacks = [parseCard({ r: 6, s: "S" })];
    state.table.defenses = [null];
    handsByUid.a = [];
    handsByUid.b = [parseCard({ r: 7, s: "S" })];

    const r = computeAndApplyGameResult({ state, handsByUid, nowIso: new Date(1).toISOString() });
    expect(r).toBeNull();
  });

  it("finishes as draw when all players go out together (placements single group)", () => {
    const { state, handsByUid } = buildInitialState({
      playerIds: ["a", "b", "c"],
      settings: { ...settings, maxPlayers: 3 },
      nowIso: new Date(0).toISOString(),
      randInt: () => 0,
    });
    state.deck = [];
    state.table.attacks = [];
    state.table.defenses = [];
    handsByUid.a = [];
    handsByUid.b = [];
    handsByUid.c = [];

    const nowIso = new Date(2).toISOString();
    const r = computeAndApplyGameResult({ state, handsByUid, nowIso });
    expect(r?.kind).toBe("finished");
    expect(r?.loserUid).toBeNull();
    expect(r?.placements).toEqual([{ uids: ["a", "b", "c"] }]);
  });

  it("finishes with loser when one player still has cards; placements include loser last", () => {
    const { state, handsByUid } = buildInitialState({
      playerIds: ["a", "b", "c"],
      settings: { ...settings, maxPlayers: 3 },
      nowIso: new Date(0).toISOString(),
      randInt: () => 0,
    });
    state.seats = ["a", "b", "c"];
    state.attackerUid = "a";
    state.defenderUid = "b";
    state.deck = [];
    state.table.attacks = [];
    state.table.defenses = [];

    handsByUid.a = [];
    handsByUid.b = [];
    handsByUid.c = [parseCard({ r: 6, s: "S" })];

    const nowIso = new Date(3).toISOString();
    const r = computeAndApplyGameResult({ state, handsByUid, nowIso });
    expect(r?.kind).toBe("finished");
    expect(r?.loserUid).toBe("c");
    expect(r?.placements).toEqual([{ uids: ["a", "b"] }, { uids: ["c"] }]);
  });
});
