import { HttpsError } from "firebase-functions/v2/https";
import type { DurakGameSettings } from "../gameSettings";
import {
  beats,
  buildDeck36,
  cardKey,
  isJoker,
  shuffleInPlace,
  type Card,
} from "./cards";
import type { DurakServerState, DurakTable } from "./state";

function rankValue(c: Card): number {
  if (isJoker(c)) return 100;
  return c.r;
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

  const deckObj = buildDeck36(settings.withJokers);
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
  // Deal 6 cards each, round-robin from attacker seat 0 initially.
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
    revision: 1,
    trumpSuit,
    deck,
    discard: [],
    attackerUid,
    defenderUid,
    table,
    seats,
    lastMoveAt: nowIso,
  };

  return { state, handsByUid };
}

export function nextUid(seats: string[], uid: string): string {
  const i = seats.indexOf(uid);
  if (i < 0) return seats[0];
  return seats[(i + 1) % seats.length];
}

export function canThrowIn({ state, defenderHandSize }: { state: DurakServerState; defenderHandSize: number }): boolean {
  return state.table.attacks.length < defenderHandSize && state.table.attacks.length < 6;
}

export function allowedAttackRanks(state: DurakServerState): Set<number | "JOKER"> {
  const s = new Set<number | "JOKER">();
  for (const a of state.table.attacks) s.add(isJoker(a) ? "JOKER" : a.r);
  for (const d of state.table.defenses) if (d) s.add(isJoker(d) ? "JOKER" : d.r);
  return s;
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
  const defenderHandSize = handsByUid[state.defenderUid]?.length ?? 0;
  if (!canThrowIn({ state, defenderHandSize })) throw new HttpsError("failed-precondition", "CANNOT_THROW_IN");

  const hand = handsByUid[uid] ?? [];
  const idx = hand.findIndex((x) => cardKey(x) === cardKey(card));
  if (idx < 0) throw new HttpsError("failed-precondition", "CARD_NOT_IN_HAND");

  if (state.table.attacks.length > 0) {
    const allowed = allowedAttackRanks(state);
    const r = isJoker(card) ? "JOKER" : card.r;
    if (!allowed.has(r)) throw new HttpsError("failed-precondition", "RANK_NOT_ALLOWED");
  }

  hand.splice(idx, 1);
  state.table.attacks.push(card);
  state.table.defenses.push(null);
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

  const defenderHandSize = handsByUid[state.defenderUid]?.length ?? 0;
  if (!canThrowIn({ state, defenderHandSize })) throw new HttpsError("failed-precondition", "CANNOT_THROW_IN");

  hand.splice(idx, 1);
  state.table.attacks.push(card);
  state.table.defenses.push(null);

  // Pass defense to next player.
  state.defenderUid = nextUid(state.seats, state.defenderUid);
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
}

export function rotateAfterTake(state: DurakServerState): void {
  // attacker stays the same; defender becomes next after the (taking) defender
  state.defenderUid = nextUid(state.seats, state.defenderUid);
}

export function discardTable({ state }: { state: DurakServerState }): void {
  for (const c of state.table.attacks) state.discard.push(c);
  for (const d of state.table.defenses) if (d) state.discard.push(d);
  state.table.attacks = [];
  state.table.defenses = [];
}

export function drawUpToSix({
  state,
  handsByUid,
}: {
  state: DurakServerState;
  handsByUid: Record<string, Card[]>;
}): void {
  // Draw order: attacker, then next seats, defender last (durak-ish simplification).
  const seats = state.seats;
  const attackerIdx = seats.indexOf(state.attackerUid);
  const order = [...seats.slice(attackerIdx), ...seats.slice(0, attackerIdx)];
  // move defender to end
  const order2 = order.filter((u) => u !== state.defenderUid).concat([state.defenderUid]);

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
}

