import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

import { normalizeDurakSettings } from "../../lib/games/gameSettings";
import {
  canAutoStartReadyLobby,
  pruneReadyLobby,
  readyDeadlineFrom,
  startDurakRoundInTransaction,
} from "../../lib/games/durak/lobbyLifecycle";

const db = admin.firestore();

export const cleanupDurakReadyRooms = onSchedule({
  schedule: "every 1 minutes",
  timeZone: "Europe/Moscow",
}, async () => {
  const now = new Date();
  const nowIso = now.toISOString();
  const snap = await db
    .collection("games")
    .where("readyDeadlineAt", "<=", nowIso)
    .limit(50)
    .get();

  let started = 0;
  let pruned = 0;
  for (const doc of snap.docs) {
    await db.runTransaction(async (tx) => {
      const ref = doc.ref;
      const fresh = await tx.get(ref);
      if (!fresh.exists) return;
      const g = fresh.data() || {};
      if (g.type !== "durak" || g.status !== "lobby") return;
      const playerIds = Array.isArray(g.playerIds) ? g.playerIds.map((x: any) => String(x)) : [];
      const players = Array.isArray(g.players) ? g.players : playerIds.map((uid) => ({ uid }));
      const readyUids = Array.isArray(g.readyUids) ? g.readyUids.map((x: any) => String(x)) : [];
      const prunedState = pruneReadyLobby({
        playerIds,
        players,
        readyUids,
        readyDeadlineAt: typeof g.readyDeadlineAt === "string" ? g.readyDeadlineAt : undefined,
        nowMs: now.getTime(),
      });
      const settings = normalizeDurakSettings(g.settings);
      const conversationId = typeof g.conversationId === "string" ? g.conversationId : "";
      if (canAutoStartReadyLobby(prunedState.playerIds, prunedState.readyUids)) {
        startDurakRoundInTransaction({
          tx,
          db,
          gameRef: ref,
          gameId: doc.id,
          game: g,
          playerIds: prunedState.playerIds,
          settings,
          nowIso,
        });
        started++;
        pruned += prunedState.prunedUids.length;
        return;
      }
      const nextDeadline = readyDeadlineFrom(now.getTime());
      tx.update(ref, {
        playerIds: prunedState.playerIds,
        players: prunedState.players,
        readyUids: prunedState.readyUids,
        readyDeadlineAt: nextDeadline,
        lastUpdatedAt: nowIso,
      });
      if (conversationId) {
        tx.set(
          db.doc(`conversations/${conversationId}/gameLobbies/${doc.id}`),
          {
            playerCount: prunedState.playerIds.length,
            readyUids: prunedState.readyUids,
            readyDeadlineAt: nextDeadline,
            lastUpdatedAt: nowIso,
          },
          { merge: true },
        );
      }
      pruned += prunedState.prunedUids.length;
    });
  }
  logger.info("[cleanupDurakReadyRooms] done", { scanned: snap.size, started, pruned });
});
