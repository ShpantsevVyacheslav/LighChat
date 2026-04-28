import { onCall, HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import { logger } from "firebase-functions";
import * as admin from "firebase-admin";

type RequestData = {
  conversationId?: unknown;
  title?: unknown;
};

type ResponseData = {
  tournamentId: string;
};

function asNonEmptyString(v: unknown): string | null {
  if (typeof v !== "string") return null;
  const t = v.trim();
  return t ? t : null;
}

export const createDurakTournament = onCall(
  { region: "us-central1" },
  async (request: CallableRequest<RequestData>): Promise<ResponseData> => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "AUTH_REQUIRED");

    const conversationId = asNonEmptyString(request.data?.conversationId);
    if (!conversationId) throw new HttpsError("invalid-argument", "BAD_INPUT");

    const title = asNonEmptyString(request.data?.title) ?? "Durak tournament";

    const db = admin.firestore();
    const convRef = db.doc(`conversations/${conversationId}`);
    const convSnap = await convRef.get();
    if (!convSnap.exists) throw new HttpsError("not-found", "CONVERSATION_NOT_FOUND");
    const conv = convSnap.data() || {};
    const participantIds = Array.isArray(conv.participantIds) ? conv.participantIds : [];
    if (!participantIds.includes(uid)) throw new HttpsError("permission-denied", "NOT_A_MEMBER");

    const nowIso = new Date().toISOString();
    const tournamentRef = db.collection("tournaments").doc();
    const tournamentId = tournamentRef.id;

    const tournamentDoc: Record<string, unknown> = {
      id: tournamentId,
      type: "durak",
      title,
      status: "active",
      createdAt: nowIso,
      createdBy: uid,
      conversationId,
      gameIds: [],
      pointsByUid: {},
      gamesPlayedByUid: {},
      lastUpdatedAt: nowIso,
    };

    const convIndexRef = db.doc(`conversations/${conversationId}/tournaments/${tournamentId}`);
    const convIndexDoc: Record<string, unknown> = {
      tournamentId,
      type: "durak",
      title,
      status: "active",
      createdAt: nowIso,
      createdBy: uid,
      lastUpdatedAt: nowIso,
    };

    await db.runTransaction(async (tx) => {
      // Enforce: at most one active tournament per conversation.
      const existingQuery = db
        .collection(`conversations/${conversationId}/tournaments`)
        .where("status", "==", "active")
        .limit(1);
      const existing = await tx.get(existingQuery);
      if (!existing.empty) throw new HttpsError("failed-precondition", "ACTIVE_TOURNAMENT_ALREADY_EXISTS");

      tx.create(tournamentRef, tournamentDoc);
      tx.create(convIndexRef, convIndexDoc);
    });

    logger.info("[createDurakTournament] created", { tournamentId, conversationId, uid });
    return { tournamentId };
  },
);

