import { onCall, HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { isSecretConversation } from "../../lib/secret-chat-index";

const db = admin.firestore();
const PAGE = 40;

type MigratePayload = { cursor?: string | null };

/**
 * One-time/backfill: move secret DM ids from userChats to userSecretChats and ensure secretChats/* docs exist.
 * Admin-only.
 */
export const migrateSecretChatIndexes = onCall(
  { region: "us-central1", enforceAppCheck: false, timeoutSeconds: 540, memory: "512MiB" },
  async (request: CallableRequest<MigratePayload>) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "AUTH_REQUIRED");
    }

    const callerDoc = await db.collection("users").doc(request.auth.uid).get();
    if (callerDoc.data()?.role !== "admin") {
      throw new HttpsError("permission-denied", "ADMIN_ONLY");
    }

    let q = db
      .collection("conversations")
      .where("secretChat.enabled", "==", true)
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(PAGE);

    const cursor = request.data?.cursor?.trim();
    if (cursor) {
      const cursorDoc = await db.collection("conversations").doc(cursor).get();
      if (cursorDoc.exists) {
        q = q.startAfter(cursorDoc);
      }
    }

    const snap = await q.get();
    let migrated = 0;

    for (const doc of snap.docs) {
      const conversationId = doc.id;
      const convData = (doc.data() || {}) as Record<string, unknown>;
      if (!isSecretConversation(conversationId, convData)) continue;

      const rawParticipantIds = convData.participantIds;
      const participantIds = Array.isArray(rawParticipantIds) ?
        rawParticipantIds.filter((x): x is string => typeof x === "string") :
        [];

      const sc = (convData.secretChat ?? {}) as Record<string, unknown>;
      const batch = db.batch();

      batch.set(
        db.doc(`secretChats/${conversationId}`),
        {
          conversationId,
          participantIds,
          createdAt: typeof sc.createdAt === "string" ?
            sc.createdAt :
            admin.firestore.FieldValue.serverTimestamp(),
          expiresAt: typeof sc.expiresAt === "string" ? sc.expiresAt : null,
          ttlPresetSec: typeof sc.ttlPresetSec === "number" ? sc.ttlPresetSec : null,
        },
        { merge: true },
      );

      const rm = admin.firestore.FieldValue.arrayRemove(conversationId);
      const un = admin.firestore.FieldValue.arrayUnion(conversationId);

      for (const uid of participantIds) {
        batch.set(db.doc(`userChats/${uid}`), { conversationIds: rm }, { merge: true });
        batch.set(db.doc(`userSecretChats/${uid}`), { conversationIds: un }, { merge: true });
      }

      try {
        await batch.commit();
        migrated += 1;
      } catch (e) {
        logger.error("[migrateSecretChatIndexes] batch failed", { conversationId, err: String(e) });
      }
    }

    const lastId = snap.empty ? null : snap.docs[snap.docs.length - 1].id;
    const hasMore = snap.size === PAGE;

    return {
      ok: true,
      migrated,
      nextCursor: hasMore ? lastId : null,
      scanned: snap.size,
    };
  },
);
