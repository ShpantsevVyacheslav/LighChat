import { HttpsError } from "firebase-functions/v2/https";

import { computeSportPoints, type TournamentPlacementGroup } from "./tournamentScoring";

export type TournamentDoc = {
  id: string;
  type: "durak";
  status: "active" | "finished";
  conversationId: string;
  gameIds: string[];
  finishedGameIds?: string[];
  pointsByUid: Record<string, number>;
  gamesPlayedByUid: Record<string, number>;
  totalGames?: number;
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

  const nextGameIds = tournament.gameIds.includes(gameId) ?
    tournament.gameIds :
    [...tournament.gameIds, gameId];

  const prevFinished = tournament.finishedGameIds ?? [];
  const nextFinishedGameIds = prevFinished.includes(gameId) ? prevFinished : [...prevFinished, gameId];

  const totalGames = tournament.totalGames ?? 0;
  const nextStatus: TournamentDoc["status"] =
    totalGames > 0 && nextFinishedGameIds.length >= totalGames ? "finished" : tournament.status;

  return {
    ...tournament,
    gameIds: nextGameIds,
    finishedGameIds: nextFinishedGameIds,
    pointsByUid: nextPoints,
    gamesPlayedByUid: nextPlayed,
    status: nextStatus,
  };
}

