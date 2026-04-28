import { HttpsError } from "firebase-functions/v2/https";

import { computeSportPoints, type TournamentPlacementGroup } from "./tournamentScoring";

export type TournamentDoc = {
  id: string;
  type: "durak";
  status: "active" | "finished";
  conversationId: string;
  gameIds: string[];
  pointsByUid: Record<string, number>;
  gamesPlayedByUid: Record<string, number>;
  lastUpdatedAt?: string;
};

export function applyFinishedGameToTournament({
  tournament,
  gameId,
  playerIds,
  placements,
}: {
  tournament: TournamentDoc;
  gameId: string;
  playerIds: string[];
  placements: TournamentPlacementGroup[];
}): TournamentDoc {
  if (tournament.type !== "durak") throw new HttpsError("failed-precondition", "TOURNAMENT_TYPE_UNSUPPORTED");
  if (tournament.status !== "active") return tournament;

  const n = playerIds.length;
  if (n < 2) return tournament;

  const { pointsByUid } = computeSportPoints({
    playerCount: n,
    placements,
  });

  const nextPoints = { ...(tournament.pointsByUid ?? {}) };
  const nextPlayed = { ...(tournament.gamesPlayedByUid ?? {}) };

  for (const uid of playerIds) {
    nextPlayed[uid] = (nextPlayed[uid] ?? 0) + 1;
  }
  for (const [uid, pts] of Object.entries(pointsByUid)) {
    nextPoints[uid] = (nextPoints[uid] ?? 0) + pts;
  }

  return {
    ...tournament,
    gameIds: tournament.gameIds.includes(gameId) ? tournament.gameIds : [...tournament.gameIds, gameId],
    pointsByUid: nextPoints,
    gamesPlayedByUid: nextPlayed,
  };
}

