import { describe, expect, it } from "vitest";

import { computeSportPoints } from "./tournamentScoring";

describe("tournament scoring", () => {
  it("awards N..1 for unique placements", () => {
    const r = computeSportPoints({
      playerCount: 4,
      placements: [{ uids: ["a"] }, { uids: ["b"] }, { uids: ["c"] }, { uids: ["d"] }],
    });
    expect(r.pointsByUid).toEqual({ a: 4, b: 3, c: 2, d: 1 });
  });

  it("splits points equally for ties across occupied places", () => {
    const r = computeSportPoints({
      playerCount: 4,
      placements: [{ uids: ["a"] }, { uids: ["b", "c"] }, { uids: ["d"] }],
    });
    // b/c tie for places 2-3 => (3+2)/2=2.5
    expect(r.pointsByUid.a).toBe(4);
    expect(r.pointsByUid.b).toBe(2.5);
    expect(r.pointsByUid.c).toBe(2.5);
    expect(r.pointsByUid.d).toBe(1);
  });
});

