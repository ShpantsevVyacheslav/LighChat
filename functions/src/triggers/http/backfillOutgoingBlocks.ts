import { onCall, HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { reconcileOutgoingBlocksForUser } from "../../lib/sync-user-outgoing-blocks";

const db = admin.firestore();
const PAGE = 200;

/**
 * Синхронизирует подколлекцию `outgoingBlocks` у каждого документа `users/{uid}` с полем `blockedUserIds`.
 * Вызывать один раз после деплоя правил/триггера (клиент админки или Firebase Console). Только `role == admin`.
 */
export const backfillOutgoingBlocks = onCall(
  { region: "us-central1", timeoutSeconds: 540, memory: "512MiB" },
  async (request: CallableRequest<{ cursor?: string | null }>) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Требуется вход.");
    }

    const callerDoc = await db.collection("users").doc(request.auth.uid).get();
    if (callerDoc.data()?.role !== "admin") {
      throw new HttpsError("permission-denied", "Только администратор.");
    }

    const startAfterId = request.data?.cursor ?? null;
    let q = db.collection("users").orderBy(admin.firestore.FieldPath.documentId()).limit(PAGE);
    if (startAfterId) {
      const cursorDoc = await db.collection("users").doc(startAfterId).get();
      if (cursorDoc.exists) {
        q = q.startAfter(cursorDoc);
      }
    }

    const snap = await q.get();
    let synced = 0;
    for (const doc of snap.docs) {
      try {
        await reconcileOutgoingBlocksForUser(doc.id, doc.data());
        synced += 1;
      } catch (e) {
        logger.error(`backfillOutgoingBlocks failed for ${doc.id}`, e);
      }
    }

    const lastId = snap.empty ? null : snap.docs[snap.docs.length - 1].id;
    const hasMore = snap.size === PAGE;

    return {
      ok: true,
      syncedUsers: synced,
      scanned: snap.size,
      nextCursor: hasMore ? lastId : null,
      done: !hasMore,
    };
  },
);
