import { describe, expect, it } from "vitest";

import { applyFinishedGameToTournament } from "./tournamentEngine";

describe("tournament engine", () => {
  it("applies surrender placements to points once per game application", () => {
    const updated = applyFinishedGameToTournament({
      tournament: {
        id: "t1",
        type: "durak",
        status: "active",
        conversationId: "c1",
        gameIds: [],
        pointsByUid: {},
        gamesPlayedByUid: {},
      },
      gameId: "g1",
      playerIds: ["a", "b", "c"],
      placements: [{ uids: ["a", "c"] }, { uids: ["b"] }],
    });

    expect(updated.gameIds).toEqual(["g1"]);
    expect(updated.gamesPlayedByUid).toEqual({ a: 1, b: 1, c: 1 });
    expect(updated.pointsByUid).toEqual({ a: 2.5, c: 2.5, b: 1 });
  });
});
