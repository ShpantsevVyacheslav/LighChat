import { HttpsError } from "firebase-functions/v2/https";

export type Suit = "S" | "H" | "D" | "C";
export type Rank = 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14; // J=11, Q=12, K=13, A=14

export type Card =
  | { r: Rank; s: Suit }
  | { r: "JOKER"; s: null };

export type DurakDeck = {
  cards: Card[]; // top is at end
  trumpSuit: Suit;
  withJokers: boolean;
};

export function isJoker(c: Card): c is { r: "JOKER"; s: null } {
  return (c as any)?.r === "JOKER";
}

export function parseSuit(v: unknown): Suit | null {
  if (v === "S" || v === "H" || v === "D" || v === "C") return v;
  return null;
}

export function parseRank(v: unknown): Rank | "JOKER" | null {
  if (v === "JOKER") return "JOKER";
  if (typeof v !== "number") return null;
  if ([6, 7, 8, 9, 10, 11, 12, 13, 14].includes(v)) return v as Rank;
  return null;
}

export function parseCard(v: unknown): Card {
  const obj = v && typeof v === "object" ? (v as Record<string, unknown>) : null;
  if (!obj) throw new HttpsError("invalid-argument", "BAD_CARD");
  const r = parseRank(obj.r);
  if (!r) throw new HttpsError("invalid-argument", "BAD_CARD");
  if (r === "JOKER") return { r: "JOKER", s: null };
  const s = parseSuit(obj.s);
  if (!s) throw new HttpsError("invalid-argument", "BAD_CARD");
  return { r, s };
}

export function cardKey(c: Card): string {
  return isJoker(c) ? "JOKER" : `${c.s}:${c.r}`;
}

export function buildDeck36(withJokers: boolean): DurakDeck {
  const suits: Suit[] = ["S", "H", "D", "C"];
  const ranks: Rank[] = [6, 7, 8, 9, 10, 11, 12, 13, 14];
  const cards: Card[] = [];
  for (const s of suits) for (const r of ranks) cards.push({ s, r });
  if (withJokers) {
    // Assumption: 2 jokers.
    cards.push({ r: "JOKER", s: null }, { r: "JOKER", s: null });
  }
  // trumpSuit will be set after shuffle (by the bottom card)
  return { cards, trumpSuit: "S", withJokers };
}

export function shuffleInPlace(cards: Card[], randInt: (maxExclusive: number) => number): void {
  for (let i = cards.length - 1; i > 0; i--) {
    const j = randInt(i + 1);
    const t = cards[i];
    cards[i] = cards[j];
    cards[j] = t;
  }
}

export function beats({
  attack,
  defense,
  trumpSuit,
}: {
  attack: Card;
  defense: Card;
  trumpSuit: Suit;
}): boolean {
  // Jokers (assumption): joker beats anything, cannot be beaten.
  if (isJoker(defense)) return true;
  if (isJoker(attack)) return false;
  if (defense.s === attack.s) return defense.r > attack.r;
  if (defense.s === trumpSuit && attack.s !== trumpSuit) return true;
  return false;
}

