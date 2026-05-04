import { HttpsError } from "firebase-functions/v2/https";
import type { DurakGameSettings } from "../gameSettings";
import {
  beats,
  buildDeck,
  cardKey,
  isJoker,
  shuffleInPlace,
  type Card,
} from "./cards";
import type { DurakLegalMoves, DurakPhase, DurakPublicView, DurakServerState, DurakTable, DurakTurnKind } from "./state";
import type { DurakGameResult } from "./state";

function rankValue(c: Card): number {
  if (isJoker(c)) return 100;
  return c.r;
}

function computeThrowerUids({
  seats,
  defenderUid,
  policy,
}: {
  seats: string[];
  defenderUid: string;
  policy?: "all" | "neighbors";
}): string[] {
  const p = policy ?? "all";
  if (p === "neighbors") {
    if (seats.length <= 2) return seats.filter((u) => u !== defenderUid);
    const i = seats.indexOf(defenderUid);
    if (i < 0) return seats.filter((u) => u !== defenderUid);
    const left = seats[(i - 1 + seats.length) % seats.length];
    const right = seats[(i + 1) % seats.length];
    const out = [left, right].filter((u) => u !== defenderUid);
    // ensure unique
    return Array.from(new Set(out));
  }
  return seats.filter((u) => u !== defenderUid);
}

export function derivePhase(state: DurakServerState): DurakPhase {
  if (state.phase === "finished") return "finished";
  if (state.table.attacks.length === 0) return "attack";
  if (state.taking === true) return "throwIn";
  const hasUndefended = state.table.defenses.some((d) => d == null);
  if (hasUndefended) return "defense";
  return "throwIn";
}

export function resetRoundTracking(state: DurakServerState): void {
  state.phase = "attack";
  state.throwerUids = computeThrowerUids({
    seats: state.seats,
    defenderUid: state.defenderUid,
    policy: state.throwInPolicy,
  });
  state.passedUids = [];
  delete state.roundDefenderHandLimit;
  state.taking = false;
}

function clampInt(v: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, Math.floor(v)));
}

function ensureRoundHandLimit(state: DurakServerState, handsByUid: Record<string, Card[]>): void {
  if (typeof state.roundDefenderHandLimit === "number") return;
  const size = handsByUid[state.defenderUid]?.length ?? 0;
  state.roundDefenderHandLimit = clampInt(size, 0, 6);
}

function removeFromArray(xs: string[], x: string): string[] {
  return xs.filter((v) => v !== x);
}

function hasCards(handsByUid: Record<string, Card[]>, uid: string): boolean {
  return (handsByUid[uid]?.length ?? 0) > 0;
}

function throwInTurnOrder(state: DurakServerState): string[] {
  const seats = state.seats ?? [];
  const attackerIdx = seats.indexOf(state.attackerUid);
  const base = attackerIdx < 0 ? [...seats] : [...seats.slice(attackerIdx), ...seats.slice(0, attackerIdx)];
  const throwers =
    state.throwerUids ??
    computeThrowerUids({
      seats,
      defenderUid: state.defenderUid,
      policy: state.throwInPolicy,
    });
  const allowed = new Set(throwers.filter((u) => u !== state.defenderUid));
  return base.filter((u) => allowed.has(u));
}

function currentThrowerUid(state: DurakServerState, handsByUid: Record<string, Card[]>): string | null {
  const passed = new Set(state.passedUids ?? []);
  for (const u of throwInTurnOrder(state)) {
    if (!hasCards(handsByUid, u)) continue;
    if (passed.has(u)) continue;
    return u;
  }
  return null;
}

export function getCurrentThrowerUid({
  state,
  handsByUid,
}: {
  state: DurakServerState;
  handsByUid: Record<string, Card[]>;
}): string | null {
  if (state.phase === "finished") return null;
  if ((state.table?.attacks?.length ?? 0) === 0) return null;
  return currentThrowerUid(state, handsByUid);
}

export function canFinishTurn({
  state,
  handsByUid,
}: {
  state: DurakServerState;
  handsByUid: Record<string, Card[]>;
}): boolean {
  if (state.phase === "finished") return false;
  return allDefended(state) && allThrowersPassed({ state, handsByUid });
}

export function getTrumpCard(state: DurakServerState): Card | null {
  return Array.isArray(state.deck) && state.deck.length > 0 ? state.deck[0] : null;
}

export function getTurnInfo({
  state,
  handsByUid,
}: {
  state: DurakServerState;
  handsByUid: Record<string, Card[]>;
}): { turnUid: string | null; turnKind: DurakTurnKind } {
  if (state.phase === "finished") return { turnUid: null, turnKind: "finished" };
  const attacks = state.table?.attacks ?? [];
  if (attacks.length === 0) return { turnUid: state.attackerUid ?? null, turnKind: "attack" };
  const thrower = currentThrowerUid(state, handsByUid);
  if (state.taking === true) {
    return thrower ? { turnUid: thrower, turnKind: "throwIn" } : { turnUid: null, turnKind: "wait" };
  }
  if (state.table.defenses.some((d) => d == null)) {
    return { turnUid: state.defenderUid ?? null, turnKind: "takeOrDefend" };
  }
  return thrower ? { turnUid: thrower, turnKind: "throwIn" } : { turnUid: null, turnKind: "wait" };
}

function canTransferCard({
  state,
  uid,
  card,
  settings,
  handsByUid,
}: {
  state: DurakServerState;
  uid: string;
  card: Card;
  settings: DurakGameSettings;
  handsByUid: Record<string, Card[]>;
}): boolean {
  if ((settings.mode ?? "podkidnoy") !== "perevodnoy") return false;
  if (!canTransfer({ state, defenderUid: uid, transferCard: card })) return false;
  const defenderHandSize = handsByUid[state.defenderUid]?.length ?? 0;
  return canThrowIn({ state, defenderHandSize });
}

function canAttackCard({
  state,
  uid,
  card,
  handsByUid,
  shulerEnabled,
}: {
  state: DurakServerState;
  uid: string;
  card: Card;
  handsByUid: Record<string, Card[]>;
  shulerEnabled?: boolean;
}): boolean {
  if (state.table.attacks.length >= 6) return false;
  if (uid === state.defenderUid) return false;
  const throwers = new Set(
    state.throwerUids ??
      computeThrowerUids({
        seats: state.seats,
        defenderUid: state.defenderUid,
        policy: state.throwInPolicy,
      }),
  );
  if (!throwers.has(uid)) return false;
  if ((state.passedUids ?? []).includes(uid)) return false;
  if (state.table.attacks.length === 0) {
    if (uid !== state.attackerUid) return false;
  } else {
    const cur = currentThrowerUid(state, handsByUid);
    if (cur !== uid) return false;
    if (!shulerEnabled && !isJoker(card) && !allowedAttackRanks(state).has(card.r)) return false;
  }
  const defenderHandSize = handsByUid[state.defenderUid]?.length ?? 0;
  return canThrowIn({ state, defenderHandSize });
}

export function buildLegalMovesForUid({
  state,
  handsByUid,
  uid,
  settings,
}: {
  state: DurakServerState;
  handsByUid: Record<string, Card[]>;
  uid: string;
  settings: DurakGameSettings;
}): DurakLegalMoves {
  const hand = handsByUid[uid] ?? [];
  const revision = typeof state.revision === "number" ? state.revision : 0;
  const attackCardKeys: string[] = [];
  const transferCardKeys: string[] = [];
  const defenseTargets: { attackIndex: number; cardKeys: string[] }[] = [];

  const shulerEnabled = settings.shulerEnabled === true;

  if (state.phase !== "finished") {
    for (const c of hand) {
      const key = cardKey(c);
      if (canAttackCard({ state, uid, card: c, handsByUid, shulerEnabled })) attackCardKeys.push(key);
      if (canTransferCard({ state, uid, card: c, settings, handsByUid })) transferCardKeys.push(key);
    }
    if (uid === state.defenderUid && state.taking !== true) {
      for (let i = 0; i < state.table.attacks.length; i++) {
        if (state.table.defenses[i] != null) continue;
        const attack = state.table.attacks[i];
        const cardKeys = hand
          .filter((c) => shulerEnabled || beats({ attack, defense: c, trumpSuit: state.trumpSuit }))
          .map((c) => cardKey(c));
        if (cardKeys.length > 0) defenseTargets.push({ attackIndex: i, cardKeys });
      }
    }
  }

  const canTakeMove =
    state.phase !== "finished" &&
    uid === state.defenderUid &&
    state.table.attacks.length > 0 &&
    !(allDefended(state) && state.taking !== true);
  const canPassMove =
    state.phase !== "finished" &&
    uid !== state.defenderUid &&
    state.table.attacks.length > 0 &&
    currentThrowerUid(state, handsByUid) === uid &&
    !(state.passedUids ?? []).includes(uid);
  const canFinishTurnMove = false;

  return {
    revision,
    canTake: canTakeMove,
    canPass: canPassMove,
    canFinishTurn: canFinishTurnMove,
    attackCardKeys: Array.from(new Set(attackCardKeys)),
    transferCardKeys: Array.from(new Set(transferCardKeys)),
    defenseTargets: defenseTargets.map((t) => ({
      attackIndex: t.attackIndex,
      cardKeys: Array.from(new Set(t.cardKeys)),
    })),
  };
}

export function buildPublicView({
  state,
  handsByUid,
  playerIds,
  settings,
  nowIso,
  result,
}: {
  state: DurakServerState;
  handsByUid: Record<string, Card[]>;
  playerIds: string[];
  settings: DurakGameSettings;
  nowIso: string;
  result?: DurakGameResult;
}): DurakPublicView {
  const turn = getTurnInfo({ state, handsByUid });
  const handCounts = Object.fromEntries(
    Object.entries(handsByUid).map(([u, cards]) => [u, cards.length]),
  );
  const shulerEnabled = settings.shulerEnabled === true;
  const turnTimeSec = typeof settings.turnTimeSec === "number" ? settings.turnTimeSec : null;
  const turnStartedAt = state.lastMoveAt || nowIso;
  const turnDeadlineAt =
    turn.turnUid && turn.turnKind !== "wait" && turn.turnKind !== "finished" && turnTimeSec != null ?
      new Date(Date.parse(turnStartedAt) + turnTimeSec * 1000).toISOString() :
      null;
  return {
    revision: state.revision,
    phase: derivePhase(state),
    trumpSuit: state.trumpSuit,
    trumpCard: getTrumpCard(state),
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
    currentThrowerUid: getCurrentThrowerUid({ state, handsByUid }),
    turnUid: turn.turnUid,
    turnKind: result?.kind === "finished" ? "finished" : turn.turnKind,
    turnStartedAt,
    turnDeadlineAt,
    turnTimeSec,
    roundDefenderHandLimit: typeof state.roundDefenderHandLimit === "number" ? state.roundDefenderHandLimit : null,
    canFinishTurn: canFinishTurn({ state, handsByUid }),
    shuler: {
      enabled: shulerEnabled,
      ...(state.foulEvent ? { foulEvent: state.foulEvent } : {}),
      ...(state.cheatPassedUid ? { cheatPassedUid: state.cheatPassedUid } : {}),
    },
    result: result ?? null,
  };
}

export function buildSurrenderResult({
  playerIds,
  loserUid,
  nowIso,
}: {
  playerIds: string[];
  loserUid: string;
  nowIso: string;
}): DurakGameResult {
  const winners = playerIds.filter((u) => u !== loserUid);
  return {
    kind: "finished",
    finishedAt: nowIso,
    winners,
    loserUid,
    placements: [
      { uids: winners },
      { uids: [loserUid] },
    ].filter((g) => g.uids.length > 0),
  };
}

function markTakingIfJokerOnTable(state: DurakServerState, handsByUid: Record<string, Card[]>): void {
  if (!state.table.attacks.some((c) => isJoker(c))) return;
  ensureRoundHandLimit(state, handsByUid);
  state.taking = true;
  state.phase = derivePhase(state);
}

export function computeAndApplyGameResult({
  state,
  handsByUid,
  nowIso,
}: {
  state: DurakServerState;
  handsByUid: Record<string, Card[]>;
  nowIso: string;
}): DurakGameResult {
  // End conditions for this product:
  // - The deck is empty
  // - The table is empty (resolve the round first)
  // - Placements are based on who "went out" first; ties are grouped.
  if ((state.deck?.length ?? 0) > 0) return null;
  if ((state.table?.attacks?.length ?? 0) > 0) return null;

  const seats = state.seats ?? [];
  const anyCardsLeft = seats.some((u) => (handsByUid[u]?.length ?? 0) > 0);
  const outUids = seats.filter((u) => (handsByUid[u]?.length ?? 0) === 0);

  const finishGroups: string[][] = Array.isArray(state.finishGroups) ? state.finishGroups : [];
  const already = new Set(finishGroups.flat());
  const newGroup = outUids.filter((u) => !already.has(u));
  if (newGroup.length > 0) finishGroups.push(newGroup);
  state.finishGroups = finishGroups;

  if (newGroup.length === 0 && anyCardsLeft) return null;

  // Remove out players from seats.
  let newSeats = [...seats];
  for (const u of outUids) newSeats = removeFromArray(newSeats, u);
  state.seats = newSeats;

  // If game ended (0 or 1 seat left), finalize.
  if (newSeats.length <= 1) {
    const loserUid = newSeats.length === 1 ? newSeats[0] : null;
    const winners = finishGroups.flat();
    const placements = finishGroups.map((uids) => ({ uids }));
    if (loserUid) placements.push({ uids: [loserUid] });
    state.phase = "finished";
    return {
      kind: "finished",
      finishedAt: nowIso,
      winners,
      loserUid,
      placements,
    };
  }

  // Ensure attacker/defender are still valid after pruning.
  if (!newSeats.includes(state.attackerUid)) {
    state.attackerUid = newSeats[0];
  }
  if (!newSeats.includes(state.defenderUid) || state.defenderUid === state.attackerUid) {
    state.defenderUid = nextUid(newSeats, state.attackerUid);
  }
  resetRoundTracking(state);
  return null;
}

export function buildInitialState({
  playerIds,
  settings,
  nowIso,
  randInt,
}: {
  playerIds: string[];
  settings: DurakGameSettings;
  nowIso: string;
  randInt: (maxExclusive: number) => number;
}): { state: DurakServerState; handsByUid: Record<string, Card[]> } {
  if (playerIds.length < 2) throw new HttpsError("failed-precondition", "NEED_AT_LEAST_2_PLAYERS");
  const seats = [...playerIds];

  const deckObj = buildDeck({ deckSize: settings.deckSize, withJokers: settings.withJokers });
  const deck = [...deckObj.cards];
  shuffleInPlace(deck, randInt);
  const bottom = deck[0];
  if (isJoker(bottom)) {
    // Avoid joker as trump marker: rotate until bottom non-joker.
    let guard = 0;
    while (guard++ < deck.length && isJoker(deck[0])) {
      const c = deck.shift()!;
      deck.push(c);
    }
  }
  const bottom2 = deck[0];
  if (isJoker(bottom2)) throw new HttpsError("internal", "TRUMP_CARD_INVALID");
  const trumpSuit = bottom2.s;

  const handsByUid: Record<string, Card[]> = Object.fromEntries(seats.map((u) => [u, []]));
  // First deal: 6 cards each (classic Durak opening hand).
  for (let i = 0; i < 6; i++) {
    for (const uid of seats) {
      const c = deck.pop();
      if (!c) break;
      handsByUid[uid].push(c);
    }
  }

  // Determine first attacker: lowest trump, else lowest card.
  let bestUid = seats[0];
  let bestScore = Number.POSITIVE_INFINITY;
  for (const uid of seats) {
    const hand = handsByUid[uid];
    for (const c of hand) {
      const isTrump = !isJoker(c) && c.s === trumpSuit;
      const score = (isTrump ? 0 : 1) * 100 + rankValue(c) + (isTrump ? 0 : 50) + (isJoker(c) ? 1000 : 0);
      if (score < bestScore) {
        bestScore = score;
        bestUid = uid;
      }
    }
  }

  const attackerUid = bestUid;
  const defenderUid = nextUid(seats, attackerUid);

  const table: DurakTable = { attacks: [], defenses: [] };

  const state: DurakServerState = {
    schemaVersion: 1,
    revision: 1,
    trumpSuit,
    deck,
    discard: [],
    attackerUid,
    defenderUid,
    table,
    seats,
    lastMoveAt: nowIso,
    phase: "attack",
    throwInPolicy: settings.throwInPolicy,
    throwerUids: computeThrowerUids({
      seats,
      defenderUid,
      policy: settings.throwInPolicy,
    }),
    passedUids: [],
  };

  return { state, handsByUid };
}

export function nextUid(seats: string[], uid: string): string {
  const i = seats.indexOf(uid);
  if (i < 0) return seats[0];
  return seats[(i + 1) % seats.length];
}

export function canThrowIn({ state, defenderHandSize }: { state: DurakServerState; defenderHandSize: number }): boolean {
  const limit = typeof state.roundDefenderHandLimit === "number" ?
    state.roundDefenderHandLimit :
    defenderHandSize;
  return state.table.attacks.length < limit && state.table.attacks.length < 6;
}

export function allowedAttackRanks(state: DurakServerState): Set<number | "JOKER"> {
  const s = new Set<number | "JOKER">();
  for (const a of state.table.attacks) s.add(isJoker(a) ? "JOKER" : a.r);
  for (const d of state.table.defenses) if (d) s.add(isJoker(d) ? "JOKER" : d.r);
  return s;
}

export function passThrowIn({
  state,
  uid,
  handsByUid,
}: {
  state: DurakServerState;
  uid: string;
  handsByUid: Record<string, Card[]>;
}): void {
  if (uid === state.defenderUid) throw new HttpsError("permission-denied", "DEFENDER_CANNOT_PASS_THROWIN");
  const throwers = new Set(
    state.throwerUids ??
      computeThrowerUids({
        seats: state.seats,
        defenderUid: state.defenderUid,
        policy: state.throwInPolicy,
      }),
  );
  if (!throwers.has(uid)) throw new HttpsError("permission-denied", "NOT_ALLOWED_TO_THROWIN");
  const passed = new Set(state.passedUids ?? []);
  passed.add(uid);
  state.passedUids = [...passed];
  state.phase = derivePhase(state);
}

export function markTaking({
  state,
  uid,
  handsByUid,
}: {
  state: DurakServerState;
  uid: string;
  handsByUid: Record<string, Card[]>;
}): void {
  if (uid !== state.defenderUid) throw new HttpsError("permission-denied", "ONLY_DEFENDER_CAN_TAKE");
  if (state.table.attacks.length === 0) throw new HttpsError("failed-precondition", "NOTHING_TO_TAKE");
  // Cannot take if already fully defended (must finish/throw-in+finish).
  if (allDefended(state) && state.taking !== true) {
    throw new HttpsError("failed-precondition", "ALREADY_DEFENDED");
  }
  ensureRoundHandLimit(state, handsByUid);
  state.taking = true;
  state.phase = derivePhase(state);
}

export function shouldResolveTakingRound({
  state,
  handsByUid,
}: {
  state: DurakServerState;
  handsByUid: Record<string, Card[]>;
}): boolean {
  if (state.taking !== true) return false;
  const defenderHandSize = handsByUid[state.defenderUid]?.length ?? 0;
  // If throw-in is impossible due to limit, or everyone passed, resolve.
  if (!canThrowIn({ state, defenderHandSize })) return true;
  return allThrowersPassed({ state, handsByUid });
}

export function allThrowersPassed({
  state,
  handsByUid,
}: {
  state: DurakServerState;
  handsByUid: Record<string, Card[]>;
}): boolean {
  const throwers =
    state.throwerUids ??
    computeThrowerUids({
      seats: state.seats,
      defenderUid: state.defenderUid,
      policy: state.throwInPolicy,
    });
  const passed = new Set(state.passedUids ?? []);
  for (const u of throwers) {
    if (u === state.defenderUid) continue;
    const hasCards = (handsByUid[u]?.length ?? 0) > 0;
    if (hasCards && !passed.has(u)) return false;
  }
  return true;
}

export function applyAttack({
  state,
  uid,
  card,
  handsByUid,
}: {
  state: DurakServerState;
  uid: string;
  card: Card;
  handsByUid: Record<string, Card[]>;
}): void {
  if (state.table.attacks.length >= 6) throw new HttpsError("failed-precondition", "TABLE_FULL");

  // Only attacker can start the attack; later any non-defender can throw in.
  if (state.table.attacks.length === 0 && uid !== state.attackerUid) {
    throw new HttpsError("permission-denied", "ONLY_ATTACKER_CAN_ATTACK_FIRST");
  }
  // Attacker or any non-defender can throw in during defense.
  if (uid === state.defenderUid) throw new HttpsError("permission-denied", "DEFENDER_CANNOT_ATTACK");
  const throwers = new Set(
    state.throwerUids ??
      computeThrowerUids({
        seats: state.seats,
        defenderUid: state.defenderUid,
        policy: state.throwInPolicy,
      }),
  );
  if (!throwers.has(uid)) throw new HttpsError("permission-denied", "NOT_ALLOWED_TO_THROWIN");
  const passed = new Set(state.passedUids ?? []);
  if (passed.has(uid)) throw new HttpsError("failed-precondition", "ALREADY_PASSED_THROWIN");
  if (state.table.attacks.length === 0) {
    // Canon: limit throw-ins by defender hand size at the start of the round.
    ensureRoundHandLimit(state, handsByUid);
  } else {
    const cur = currentThrowerUid(state, handsByUid);
    if (cur && uid !== cur) throw new HttpsError("failed-precondition", "THROWIN_NOT_YOUR_TURN");
  }
  const defenderHandSize = handsByUid[state.defenderUid]?.length ?? 0;
  if (!canThrowIn({ state, defenderHandSize })) throw new HttpsError("failed-precondition", "CANNOT_THROW_IN");

  const hand = handsByUid[uid] ?? [];
  const idx = hand.findIndex((x) => cardKey(x) === cardKey(card));
  if (idx < 0) throw new HttpsError("failed-precondition", "CARD_NOT_IN_HAND");

  if (state.table.attacks.length > 0) {
    // Product rule: jokers can be thrown-in anytime.
    if (!isJoker(card)) {
      const allowed = allowedAttackRanks(state);
      const r = card.r;
      if (!allowed.has(r)) throw new HttpsError("failed-precondition", "RANK_NOT_ALLOWED");
    }
  }

  const wasThrowIn = state.table.attacks.length > 0;
  hand.splice(idx, 1);
  state.table.attacks.push(card);
  state.table.defenses.push(null);
  if (wasThrowIn) state.passedUids = [];
  state.phase = derivePhase(state);
  // Joker rule: if joker is thrown in, defender must take (cannot defend).
  markTakingIfJokerOnTable(state, handsByUid);
}

export function applyAttackRelaxed({
  state,
  uid,
  card,
  handsByUid,
}: {
  state: DurakServerState;
  uid: string;
  card: Card;
  handsByUid: Record<string, Card[]>;
}): void {
  // Same as applyAttack but without rank restriction (Shuler).
  if (state.table.attacks.length >= 6) throw new HttpsError("failed-precondition", "TABLE_FULL");
  if (state.table.attacks.length === 0 && uid !== state.attackerUid) {
    throw new HttpsError("permission-denied", "ONLY_ATTACKER_CAN_ATTACK_FIRST");
  }
  if (uid === state.defenderUid) throw new HttpsError("permission-denied", "DEFENDER_CANNOT_ATTACK");
  const throwers = new Set(
    state.throwerUids ??
      computeThrowerUids({
        seats: state.seats,
        defenderUid: state.defenderUid,
        policy: state.throwInPolicy,
      }),
  );
  if (!throwers.has(uid)) throw new HttpsError("permission-denied", "NOT_ALLOWED_TO_THROWIN");
  const passed = new Set(state.passedUids ?? []);
  if (passed.has(uid)) throw new HttpsError("failed-precondition", "ALREADY_PASSED_THROWIN");
  if (state.table.attacks.length === 0) {
    ensureRoundHandLimit(state, handsByUid);
  } else {
    const cur = currentThrowerUid(state, handsByUid);
    if (cur && uid !== cur) throw new HttpsError("failed-precondition", "THROWIN_NOT_YOUR_TURN");
  }
  const defenderHandSize = handsByUid[state.defenderUid]?.length ?? 0;
  if (!canThrowIn({ state, defenderHandSize })) throw new HttpsError("failed-precondition", "CANNOT_THROW_IN");

  const hand = handsByUid[uid] ?? [];
  const idx = hand.findIndex((x) => cardKey(x) === cardKey(card));
  if (idx < 0) throw new HttpsError("failed-precondition", "CARD_NOT_IN_HAND");

  const wasThrowIn = state.table.attacks.length > 0;
  hand.splice(idx, 1);
  state.table.attacks.push(card);
  state.table.defenses.push(null);
  if (wasThrowIn) state.passedUids = [];
  state.phase = derivePhase(state);
  markTakingIfJokerOnTable(state, handsByUid);
}

export function canTransfer({
  state,
  defenderUid,
  transferCard,
}: {
  state: DurakServerState;
  defenderUid: string;
  transferCard: Card;
}): boolean {
  if (defenderUid !== state.defenderUid) return false;
  if (state.table.attacks.length === 0) return false;
  // Canon: transfer is only allowed before any defense card is placed.
  if (state.table.defenses.some((d) => d != null)) return false;
  // Product rule: joker can transfer anytime (before any defense is placed).
  if (isJoker(transferCard)) return true;
  // Must match rank of at least one attack card (common rule).
  const r = isJoker(transferCard) ? "JOKER" : transferCard.r;
  for (const a of state.table.attacks) {
    const ar = isJoker(a) ? "JOKER" : a.r;
    if (ar === r) return true;
  }
  return false;
}

export function applyTransfer({
  state,
  uid,
  card,
  handsByUid,
}: {
  state: DurakServerState;
  uid: string;
  card: Card;
  handsByUid: Record<string, Card[]>;
}): void {
  if (!canTransfer({ state, defenderUid: uid, transferCard: card })) {
    throw new HttpsError("failed-precondition", "TRANSFER_NOT_ALLOWED");
  }

  const hand = handsByUid[uid] ?? [];
  const idx = hand.findIndex((x) => cardKey(x) === cardKey(card));
  if (idx < 0) throw new HttpsError("failed-precondition", "CARD_NOT_IN_HAND");

  // Recompute round hand limit for the current defender seat (before changing defender).
  ensureRoundHandLimit(state, handsByUid);
  const defenderHandSize = handsByUid[state.defenderUid]?.length ?? 0;
  if (!canThrowIn({ state, defenderHandSize })) throw new HttpsError("failed-precondition", "CANNOT_THROW_IN");

  hand.splice(idx, 1);
  state.table.attacks.push(card);
  state.table.defenses.push(null);

  // Pass defense to next player.
  state.defenderUid = nextUid(state.seats, state.defenderUid);
  if (state.defenderUid === state.attackerUid) {
    state.attackerUid = uid;
  }
  state.throwerUids = computeThrowerUids({
    seats: state.seats,
    defenderUid: state.defenderUid,
    policy: state.throwInPolicy,
  });
  state.passedUids = [];
  // New defender => new round limit based on new defender's current hand size.
  delete state.roundDefenderHandLimit;
  ensureRoundHandLimit(state, handsByUid);
  state.phase = derivePhase(state);
  markTakingIfJokerOnTable(state, handsByUid);
}

export function applyTransferRelaxed({
  state,
  uid,
  card,
  handsByUid,
}: {
  state: DurakServerState;
  uid: string;
  card: Card;
  handsByUid: Record<string, Card[]>;
}): void {
  // Relaxed transfer: defender may transfer with any card while attacks exist.
  if (uid !== state.defenderUid) throw new HttpsError("permission-denied", "ONLY_DEFENDER_CAN_TRANSFER");
  if (state.table.attacks.length === 0) throw new HttpsError("failed-precondition", "TRANSFER_NOT_ALLOWED");

  const hand = handsByUid[uid] ?? [];
  const idx = hand.findIndex((x) => cardKey(x) === cardKey(card));
  if (idx < 0) throw new HttpsError("failed-precondition", "CARD_NOT_IN_HAND");

  ensureRoundHandLimit(state, handsByUid);
  const defenderHandSize = handsByUid[state.defenderUid]?.length ?? 0;
  if (!canThrowIn({ state, defenderHandSize })) throw new HttpsError("failed-precondition", "CANNOT_THROW_IN");

  hand.splice(idx, 1);
  state.table.attacks.push(card);
  state.table.defenses.push(null);

  state.defenderUid = nextUid(state.seats, state.defenderUid);
  if (state.defenderUid === state.attackerUid) {
    state.attackerUid = uid;
  }
  state.throwerUids = computeThrowerUids({
    seats: state.seats,
    defenderUid: state.defenderUid,
    policy: state.throwInPolicy,
  });
  state.passedUids = [];
  delete state.roundDefenderHandLimit;
  ensureRoundHandLimit(state, handsByUid);
  state.phase = derivePhase(state);
  markTakingIfJokerOnTable(state, handsByUid);
}

export function applyDefense({
  state,
  uid,
  attackIndex,
  defense,
  handsByUid,
}: {
  state: DurakServerState;
  uid: string;
  attackIndex: number;
  defense: Card;
  handsByUid: Record<string, Card[]>;
}): void {
  if (uid !== state.defenderUid) throw new HttpsError("permission-denied", "ONLY_DEFENDER_CAN_DEFEND");
  if (state.taking === true) throw new HttpsError("failed-precondition", "DEFENDER_ALREADY_TAKING");
  if (attackIndex < 0 || attackIndex >= state.table.attacks.length) {
    throw new HttpsError("invalid-argument", "BAD_ATTACK_INDEX");
  }
  if (state.table.defenses[attackIndex] != null) {
    throw new HttpsError("failed-precondition", "ALREADY_DEFENDED");
  }
  const attack = state.table.attacks[attackIndex];
  if (!beats({ attack, defense, trumpSuit: state.trumpSuit })) {
    throw new HttpsError("failed-precondition", "DEFENSE_DOES_NOT_BEAT");
  }

  const hand = handsByUid[uid] ?? [];
  const idx = hand.findIndex((x) => cardKey(x) === cardKey(defense));
  if (idx < 0) throw new HttpsError("failed-precondition", "CARD_NOT_IN_HAND");
  hand.splice(idx, 1);
  state.table.defenses[attackIndex] = defense;
  state.phase = derivePhase(state);
}

export function applyDefenseRelaxed({
  state,
  uid,
  attackIndex,
  defense,
  handsByUid,
}: {
  state: DurakServerState;
  uid: string;
  attackIndex: number;
  defense: Card;
  handsByUid: Record<string, Card[]>;
}): void {
  // Relaxed defense: any card can be used to defend (Shuler), still must be defender and slot open.
  if (uid !== state.defenderUid) throw new HttpsError("permission-denied", "ONLY_DEFENDER_CAN_DEFEND");
  if (state.taking === true) throw new HttpsError("failed-precondition", "DEFENDER_ALREADY_TAKING");
  if (attackIndex < 0 || attackIndex >= state.table.attacks.length) {
    throw new HttpsError("invalid-argument", "BAD_ATTACK_INDEX");
  }
  if (state.table.defenses[attackIndex] != null) {
    throw new HttpsError("failed-precondition", "ALREADY_DEFENDED");
  }
  const hand = handsByUid[uid] ?? [];
  const idx = hand.findIndex((x) => cardKey(x) === cardKey(defense));
  if (idx < 0) throw new HttpsError("failed-precondition", "CARD_NOT_IN_HAND");
  hand.splice(idx, 1);
  state.table.defenses[attackIndex] = defense;
  state.phase = derivePhase(state);
}

export function undoLastCheat({
  state,
  handsByUid,
}: {
  state: DurakServerState;
  handsByUid: Record<string, Card[]>;
}): { cheaterUid: string; penaltyCards: number; missedUids: string[] } {
  const cheat = state.lastCheat;
  if (!cheat) throw new HttpsError("failed-precondition", "NO_CHEAT_TO_FOUL");
  const uid = cheat.uid;
  handsByUid[uid] = handsByUid[uid] ?? [];

  const key = cardKey(cheat.card);
  if (cheat.actionType === "attack") {
    // remove last matching attack and its defense slot
    for (let i = state.table.attacks.length - 1; i >= 0; i--) {
      if (cardKey(state.table.attacks[i]) === key) {
        state.table.attacks.splice(i, 1);
        state.table.defenses.splice(i, 1);
        break;
      }
    }
    handsByUid[uid].push(cheat.card);
  } else if (cheat.actionType === "defend") {
    const idx = cheat.attackIndex ?? -1;
    if (idx >= 0 && idx < state.table.defenses.length) {
      state.table.defenses[idx] = null;
    }
    handsByUid[uid].push(cheat.card);
  } else if (cheat.actionType === "transfer") {
    // remove last matching attack card
    for (let i = state.table.attacks.length - 1; i >= 0; i--) {
      if (cardKey(state.table.attacks[i]) === key) {
        state.table.attacks.splice(i, 1);
        state.table.defenses.splice(i, 1);
        break;
      }
    }
    handsByUid[uid].push(cheat.card);
    if (cheat.prevDefenderUid) {
      state.defenderUid = cheat.prevDefenderUid;
    }
    if (cheat.prevThrowerUids) state.throwerUids = cheat.prevThrowerUids;
    if (cheat.prevPassedUids) state.passedUids = cheat.prevPassedUids;
    if (typeof cheat.prevRoundDefenderHandLimit === "number") {
      state.roundDefenderHandLimit = cheat.prevRoundDefenderHandLimit;
    } else {
      delete state.roundDefenderHandLimit;
    }
  }

  state.lastCheat = null;
  state.phase = derivePhase(state);

  const penaltyCards = 2;
  for (let i = 0; i < penaltyCards; i++) {
    const c = state.deck.pop();
    if (!c) break;
    handsByUid[uid].push(c);
  }

  const missedUids = state.seats.filter((u) => u !== uid);
  return { cheaterUid: uid, penaltyCards, missedUids };
}

export function allDefended(state: DurakServerState): boolean {
  if (state.table.attacks.length === 0) return false;
  return state.table.defenses.length === state.table.attacks.length && state.table.defenses.every((d) => d != null);
}

export function takeTable({ state, handsByUid }: { state: DurakServerState; handsByUid: Record<string, Card[]> }): void {
  const def = state.defenderUid;
  handsByUid[def] = handsByUid[def] ?? [];
  for (const c of state.table.attacks) handsByUid[def].push(c);
  for (const d of state.table.defenses) if (d) handsByUid[def].push(d);
  state.table.attacks = [];
  state.table.defenses = [];
  state.phase = "resolution";
  state.taking = false;
}

export function rotateAfterTake(state: DurakServerState): void {
  // If defender takes, the same attacker starts the next round.
  // In 2-player games this keeps roles as attacker -> defender instead of
  // accidentally making the attacker defend against themself.
  if (!state.seats.includes(state.attackerUid)) {
    state.attackerUid = state.seats[0];
  }
  state.defenderUid = nextUid(state.seats, state.attackerUid);
  resetRoundTracking(state);
}

export function discardTable({ state }: { state: DurakServerState }): void {
  for (const c of state.table.attacks) state.discard.push(c);
  for (const d of state.table.defenses) if (d) state.discard.push(d);
  state.table.attacks = [];
  state.table.defenses = [];
  state.phase = "resolution";
}

export function drawUpToSix({
  state,
  handsByUid,
}: {
  state: DurakServerState;
  handsByUid: Record<string, Card[]>;
}): void {
  // Canonical draw order:
  // Start from attacker seat and go forward; defender always draws last.
  const seats = state.seats;
  const attackerIdx = seats.indexOf(state.attackerUid);
  const baseOrder = attackerIdx < 0 ?
    [...seats] :
    [...seats.slice(attackerIdx), ...seats.slice(0, attackerIdx)];
  const order2 = baseOrder.filter((u) => u !== state.defenderUid).concat([state.defenderUid]);

  for (const uid of order2) {
    const hand = (handsByUid[uid] = handsByUid[uid] ?? []);
    while (hand.length < 6) {
      const c = state.deck.pop();
      if (!c) return;
      hand.push(c);
    }
  }
}

export function rotateAfterSuccessfulDefense(state: DurakServerState): void {
  // defender becomes next attacker; next defender is next after attacker
  const newAttacker = state.defenderUid;
  const newDefender = nextUid(state.seats, newAttacker);
  state.attackerUid = newAttacker;
  state.defenderUid = newDefender;
  resetRoundTracking(state);
}
