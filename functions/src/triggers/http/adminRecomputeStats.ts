import {
  onCall,
  HttpsError,
  type CallableRequest,
} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

import { assertCallerIsAdmin } from "../../lib/admin-claims";

/**
 * Пересчитывает агрегированную статистику для AdminOverviewScreen:
 *
 *   - `totalUsers` — count users collection
 *   - `dau` — distinct users with `lastSeen` > now - 24h
 *   - `mau` — distinct users with `lastSeen` > now - 30d
 *   - `activeConversations` — conversations с `lastMessageAt` > now - 7d
 *   - `totalMessages` — приблизительная сумма `conversations.messagesCount`
 *     (если поле есть), иначе пропуск
 *
 * Запись в `admin/stats` document. Клиент (`AdminOverviewScreen`) уже
 * слушает этот doc через snapshots() и сам обновится.
 *
 * Безопасность: только admin/worker роль.
 *
 * Вызов:
 *   - Manual (admin кнопка «Пересчитать»): через callable.
 *   - Scheduled: см. `triggers/scheduled/recomputeStatsDaily.ts`
 *     (запускается ежедневно в 03:00 UTC).
 */

const db = admin.firestore();
const DAY_MS = 24 * 60 * 60 * 1000;
const MONTH_MS = 30 * DAY_MS;
const WEEK_MS = 7 * DAY_MS;

type Result = {
  totalUsers: number;
  dau: number;
  mau: number;
  activeConversations: number;
  totalMessages: number | null;
  recomputedAt: string;
};

/** Внутренняя функция — переиспользуется callable + scheduled. */
export async function recomputeAdminStats(): Promise<Result> {
  const now = Date.now();
  const dayAgo = admin.firestore.Timestamp.fromMillis(now - DAY_MS);
  const monthAgo = admin.firestore.Timestamp.fromMillis(now - MONTH_MS);
  const weekAgo = admin.firestore.Timestamp.fromMillis(now - WEEK_MS);

  const usersColl = db.collection("users");
  const conversationsColl = db.collection("conversations");

  // Параллельные count() aggregation-запросы — дешёво (1 read за запрос).
  const [
    totalUsersAgg,
    dauAgg,
    mauAgg,
    activeConvAgg,
  ] = await Promise.all([
    usersColl.count().get(),
    usersColl.where("lastSeen", ">=", dayAgo).count().get(),
    usersColl.where("lastSeen", ">=", monthAgo).count().get(),
    conversationsColl
      .where("lastMessageAt", ">=", weekAgo)
      .count()
      .get(),
  ]);

  // totalMessages — best-effort: суммируем `messagesCount` field у конверсий,
  // если он есть. Если нет — null.
  let totalMessages: number | null = null;
  try {
    const sample = await conversationsColl
      .where("messagesCount", ">", 0)
      .limit(1)
      .get();
    if (!sample.empty) {
      let acc = 0;
      // Стримим страницами по 500 чтобы не упереться в память.
      let cursor: FirebaseFirestore.QueryDocumentSnapshot | null = null;
      for (;;) {
        let q: FirebaseFirestore.Query = conversationsColl
          .orderBy("__name__")
          .limit(500);
        if (cursor) q = q.startAfter(cursor);
        const snap = await q.get();
        if (snap.empty) break;
        for (const d of snap.docs) {
          acc += Number(d.get("messagesCount") ?? 0);
        }
        cursor = snap.docs[snap.docs.length - 1];
        if (snap.size < 500) break;
      }
      totalMessages = acc;
    }
  } catch (e) {
    logger.warn("totalMessages aggregation failed (non-critical)", e);
  }

  const result: Result = {
    totalUsers: totalUsersAgg.data().count,
    dau: dauAgg.data().count,
    mau: mauAgg.data().count,
    activeConversations: activeConvAgg.data().count,
    totalMessages,
    recomputedAt: new Date().toISOString(),
  };

  await db.doc("admin/stats").set(
    {
      ...result,
      recomputedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  logger.log("[admin-stats] recomputed", result);
  return result;
}

export const adminRecomputeStats = onCall(
  {
    region: "us-central1",
    enforceAppCheck: false,
    timeoutSeconds: 540,
    memory: "512MiB",
  },
  async (request: CallableRequest<void>): Promise<Result> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign-in required");
    }
    await assertCallerIsAdmin(request.auth.token, db);
    return recomputeAdminStats();
  },
);
