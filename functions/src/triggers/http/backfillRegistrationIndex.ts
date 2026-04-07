import { onCall, HttpsError, type CallableRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { registrationEntriesForProfile } from "../../lib/registrationIndexKeys";

const db = admin.firestore();

const PAGE = 200;

/**
 * Заполняет `registrationIndex/*` по существующим `users/*`.
 * Вызывать один раз после деплоя триггера/правил (из админки под учёткой admin).
 */
export const backfillRegistrationIndex = onCall(
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
    let q = db
      .collection("users")
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(PAGE);
    if (startAfterId) {
      const cursorDoc = await db.collection("users").doc(startAfterId).get();
      if (cursorDoc.exists) {
        q = q.startAfter(cursorDoc);
      }
    }

    const snap = await q.get();
    let indexWrites = 0;

    for (const userDoc of snap.docs) {
      const entries = registrationEntriesForProfile(userDoc.data());
      for (const e of entries) {
        try {
          await db
            .collection("registrationIndex")
            .doc(e.id)
            .set({
              uid: userDoc.id,
              field: e.field,
              updatedAt: new Date().toISOString(),
            });
          indexWrites += 1;
        } catch (err) {
          logger.error(`backfillRegistrationIndex: ${e.id}`, err);
        }
      }
    }

    const lastId = snap.empty ? null : snap.docs[snap.docs.length - 1].id;
    const hasMore = snap.size === PAGE;

    return {
      ok: true,
      indexWrites,
      scannedUsers: snap.size,
      nextCursor: hasMore ? lastId : null,
      done: !hasMore,
    };
  },
);
