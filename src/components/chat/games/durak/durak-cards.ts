export type Suit = 'S' | 'H' | 'D' | 'C';
export type Rank = number | 'JOKER';

export type Card = {
  r: Rank;
  s: Suit | null;
};

export function isJoker(c: Card): boolean {
  return c?.r === 'JOKER';
}

export function cardLabel(c: Card): string {
  if (!c) return '';
  if (isJoker(c)) return 'JOKER';
  const rr = String(c.r ?? '');
  const rank =
    ({ '11': 'J', '12': 'Q', '13': 'K', '14': 'A' } as Record<string, string>)[rr] ??
    rr;
  const suit = String(c.s ?? '');
  const suitSym =
    ({ S: '♠', H: '♥', D: '♦', C: '♣' } as Record<string, string>)[suit] ?? suit;
  return `${rank}${suitSym}`;
}

