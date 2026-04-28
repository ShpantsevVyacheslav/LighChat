export type TournamentPlacementGroup = {
  uids: string[]; // tied players
};

export type TournamentPointsResult = {
  pointsByUid: Record<string, number>;
};

/**
 * "Sport" scoring: for N players, places award N, N-1, ..., 1 points.
 * Ties split points equally across the occupied place range.
 *
 * Example N=4:
 * - place1: 4, place2: 3, place3: 2, place4: 1
 * If two players tie for 2nd/3rd: each gets (3+2)/2 = 2.5
 */
export function computeSportPoints({
  playerCount,
  placements,
}: {
  playerCount: number;
  placements: TournamentPlacementGroup[];
}): TournamentPointsResult {
  const n = Math.max(2, Math.min(64, Math.floor(playerCount)));
  const pointsByUid: Record<string, number> = {};

  let place = 1;
  for (const group of placements) {
    const uids = Array.from(new Set((group.uids ?? []).filter((s) => typeof s === "string" && s.trim())));
    if (uids.length === 0) continue;

    const startPlace = place;
    const endPlace = Math.min(n, place + uids.length - 1);
    const occupied = endPlace - startPlace + 1;

    // Sum points for occupied places: points(place)= n - place + 1
    let sum = 0;
    for (let p = startPlace; p <= endPlace; p++) sum += n - p + 1;
    const each = sum / occupied;

    for (const uid of uids) pointsByUid[uid] = (pointsByUid[uid] ?? 0) + each;
    place += uids.length;
    if (place > n) break;
  }

  return { pointsByUid };
}

