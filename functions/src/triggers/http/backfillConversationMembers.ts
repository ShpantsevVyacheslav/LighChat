import { onCall, HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import {
  participantIdsFromConversationData,
  syncMemberDocsForConversation,
} from "../../lib/sync-conversation-members";

const db = admin.firestore();

const PAGE = 200;

/**
 * Одноразовая/периодическая синхронизация `conversations/{id}/members/*` с participantIds.
 * Только admin (поле role в users/{uid}). После деплоя правил Firestore вызвать из клиента админки или Firebase Console.
 */
export const backfillConversationMembers = onCall(
  { region: "us-central1", enforceAppCheck: false, timeoutSeconds: 540, memory: "512MiB" },
  async (request: CallableRequest<{ cursor?: string | null }>) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Требуется вход.");
    }

    const callerDoc = await db.collection("users").doc(request.auth.uid).get();
    if (callerDoc.data()?.role !== "admin") {
      throw new HttpsError("permission-denied", "Только администратор.");
    }

    const startAfterId = request.data?.cursor ?? null;
    let q = db.collection("conversations").orderBy(admin.firestore.FieldPath.documentId()).limit(PAGE);
    if (startAfterId) {
      const cursorDoc = await db.collection("conversations").doc(startAfterId).get();
      if (cursorDoc.exists) {
        q = q.startAfter(cursorDoc);
      }
    }

    const snap = await q.get();
    let synced = 0;
    for (const doc of snap.docs) {
      const ids = participantIdsFromConversationData(doc.data());
      if (ids.length > 0) {
        try {
          await syncMemberDocsForConversation(doc.id, ids);
          synced += 1;
        } catch (e) {
          logger.error(`backfillConversationMembers failed for ${doc.id}`, e);
        }
      }
    }

    const lastId = snap.empty ? null : snap.docs[snap.docs.length - 1].id;
    const hasMore = snap.size === PAGE;

    return {
      ok: true,
      syncedConversations: synced,
      scanned: snap.size,
      nextCursor: hasMore ? lastId : null,
      done: !hasMore,
    };
  },
);
