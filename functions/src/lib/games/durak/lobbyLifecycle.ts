import * as admin from "firebase-admin";
import { HttpsError } from "firebase-functions/v2/https";

import { normalizeDurakSettings } from "../gameSettings";
import { buildInitialState, buildLegalMovesForUid, buildPublicView } from "./engine";

export const DURAK_READY_TIMEOUT_MS = 30_000;

export function readyDeadlineFrom(nowMs: number): string {
  return new Date(nowMs + DURAK_READY_TIMEOUT_MS).toISOString();
}

export function pruneReadyLobby({
  playerIds,
  players,
  readyUids,
  readyDeadlineAt,
  nowMs,
}: {
  playerIds: string[];
  players: any[];
  readyUids: string[];
  readyDeadlineAt?: string;
  nowMs: number;
}): { playerIds: string[]; players: any[]; readyUids: string[]; prunedUids: string[] } {
  const deadlineMs = readyDeadlineAt ? Date.parse(readyDeadlineAt) : Number.NaN;
  if (!Number.isFinite(deadlineMs) || nowMs < deadlineMs) {
    return { playerIds, players, readyUids, prunedUids: [] };
  }
  const ready = new Set(readyUids);
  const prunedUids = playerIds.filter((uid) => !ready.has(uid));
  return {
    playerIds: playerIds.filter((uid) => ready.has(uid)),
    players: players.filter((p) => ready.has(String(p?.uid ?? ""))),
    readyUids: readyUids.filter((uid) => playerIds.includes(uid)),
    prunedUids,
  };
}

export function canAutoStartReadyLobby(playerIds: string[], readyUids: string[]): boolean {
  if (playerIds.length < 2) return false;
  const ready = new Set(readyUids);
  return playerIds.every((uid) => ready.has(uid));
}

export function cryptoRandInt(maxExclusive: number): number {
  if (maxExclusive <= 1) return 0;
  const buf = new Uint32Array(1);
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const crypto = require("crypto") as typeof import("crypto");
  crypto.randomFillSync(buf);
  return buf[0] % maxExclusive;
}

export function startDurakRoundInTransaction({
  tx,
  db,
  gameRef,
  gameId,
  game,
  playerIds,
  settings,
  nowIso,
}: {
  tx: admin.firestore.Transaction;
  db: admin.firestore.Firestore;
  gameRef: admin.firestore.DocumentReference;
  gameId: string;
  game: admin.firestore.DocumentData;
  playerIds: string[];
  settings: ReturnType<typeof normalizeDurakSettings>;
  nowIso: string;
}): void {
  if (playerIds.length < 2) throw new HttpsError("failed-precondition", "NEED_AT_LEAST_2_PLAYERS");
  const conversationId = typeof game.conversationId === "string" ? game.conversationId : "";
  if (!conversationId) throw new HttpsError("internal", "GAME_MISSING_CONVERSATION");

  const { state, handsByUid } = buildInitialState({
    playerIds,
    settings,
    nowIso,
    randInt: cryptoRandInt,
  });
  const publicView = buildPublicView({
    state,
    handsByUid,
    playerIds,
    settings,
    nowIso,
    result: null,
  });

  tx.update(gameRef, {
    status: "active",
    startedAt: nowIso,
    settings,
    playerIds,
    readyUids: admin.firestore.FieldValue.delete(),
    readyDeadlineAt: admin.firestore.FieldValue.delete(),
    serverState: state,
    publicView,
    result: null,
    lastUpdatedAt: nowIso,
  });

  for (const [u, cards] of Object.entries(handsByUid)) {
    tx.set(db.doc(`games/${gameId}/privateHands/${u}`), {
      uid: u,
      cards,
      legalMoves: buildLegalMovesForUid({ state, handsByUid, uid: u, settings }),
      updatedAt: nowIso,
    });
  }

  tx.set(
    db.doc(`conversations/${conversationId}/gameLobbies/${gameId}`),
    {
      status: "active",
      playerCount: playerIds.length,
      readyUids: admin.firestore.FieldValue.delete(),
      readyDeadlineAt: admin.firestore.FieldValue.delete(),
      lastUpdatedAt: nowIso,
    },
    { merge: true },
  );

  const tournamentId = typeof (game as any).tournamentId === "string" ? ((game as any).tournamentId as string) : "";
  if (tournamentId) {
    tx.set(
      db.doc(`tournaments/${tournamentId}/games/${gameId}`),
      {
        status: "active",
        playerIds,
        playerCount: playerIds.length,
        lastUpdatedAt: nowIso,
      },
      { merge: true },
    );
  }

  const msgRef = db.doc(`conversations/${conversationId}/messages/sys_game_started_${gameId}`);
  tx.set(
    msgRef,
    {
      id: `sys_game_started_${gameId}`,
      senderId: "__system__",
      createdAt: nowIso,
      text: "🎮 Партия «Дурак» началась.",
      systemEvent: {
        type: "gameStarted",
        data: { gameId, gameType: "durak" },
      },
    },
    { merge: true },
  );
}
