import { describe, expect, it } from "vitest";

import { buildDeck, cardKey } from "./cards";

describe("durak cards", () => {
  it("buildDeck(52,false) builds 52 unique suit/rank cards", () => {
    const d = buildDeck({ deckSize: 52, withJokers: false });
    expect(d.cards.length).toBe(52);
    const keys = d.cards.map(cardKey);
    expect(new Set(keys).size).toBe(52);
  });

  it("buildDeck(52,true) adds exactly 2 jokers", () => {
    const d = buildDeck({ deckSize: 52, withJokers: true });
    expect(d.cards.length).toBe(54);
    const jokers = d.cards.filter((c) => (c as any).r === "JOKER");
    expect(jokers.length).toBe(2);
  });

  it("buildDeck(36,false) builds 36 unique suit/rank cards", () => {
    const d = buildDeck({ deckSize: 36, withJokers: false });
    expect(d.cards.length).toBe(36);
    const keys = d.cards.map(cardKey);
    expect(new Set(keys).size).toBe(36);
  });
});

