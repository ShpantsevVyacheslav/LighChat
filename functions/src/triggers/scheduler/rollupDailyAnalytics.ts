import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v1";
import { logger } from "firebase-functions/v1";

/**
 * Ежесуточный rollup `analyticsEvents` → `platformStats/daily/entries/{YYYY-MM-DD}`.
 *
 * Зачем:
 *   - admin-дашборд (`src/actions/analytics-actions.ts`) уже читает
 *     `platformStats/daily/entries`, но прежде источников записи не было.
 *   - GA4/BigQuery — внешние системы; внутренний дашборд должен работать
 *     даже когда BigQuery export не настроен.
 *
 * Что считает:
 *   - activeUsers (distinct uid за сутки)
 *   - newRegistrations (event = sign_up_success)
 *   - messagesSent (event = message_sent)
 *   - chatsCreated (event = chat_created)
 *   - callsStarted (event = call_started)
 *   - meetingsHeld (event = meeting_created)
 *   - breakdownByPlatform: { web, pwa, ios, android, macos, windows, linux }
 *   - breakdownByCountry: top-20 ISO-кодов
 *   - breakdownBySignupMethod: для sign_up_success
 *
 * TTL: ивенты старше 90 дней удаляются батчами (агрегаты остаются в
 * platformStats навсегда + есть BigQuery export для архивного анализа).
 */

const TZ = "Etc/UTC";

function pad(n: number): string {
  return n < 10 ? `0${n}` : `${n}`;
}

function ymd(d: Date): string {
  return `${d.getUTCFullYear()}-${pad(d.getUTCMonth() + 1)}-${pad(d.getUTCDate())}`;
}

async function rollup(targetDate: Date): Promise<void> {
  const db = admin.firestore();
  const dayKey = ymd(targetDate);
  const dayStart = new Date(Date.UTC(targetDate.getUTCFullYear(), targetDate.getUTCMonth(), targetDate.getUTCDate())).toISOString();
  const dayEnd = new Date(Date.UTC(targetDate.getUTCFullYear(), targetDate.getUTCMonth(), targetDate.getUTCDate(), 23, 59, 59, 999)).toISOString();

  const snap = await db
    .collection("analyticsEvents")
    .where("ts", ">=", dayStart)
    .where("ts", "<=", dayEnd)
    .get();

  const activeUsers = new Set<string>();
  let newRegistrations = 0;
  let messagesSent = 0;
  let chatsCreated = 0;
  let callsStarted = 0;
  let meetingsHeld = 0;

  const platformCounts: Record<string, number> = {};
  const countryCounts: Record<string, number> = {};
  const signupMethodCounts: Record<string, number> = {};

  snap.docs.forEach((doc) => {
    const d = doc.data() as {
      event?: string;
      uid?: string | null;
      platform?: string;
      params?: Record<string, unknown>;
    };
    if (d.uid) activeUsers.add(d.uid);
    if (d.platform) platformCounts[d.platform] = (platformCounts[d.platform] ?? 0) + 1;

    switch (d.event) {
      case "sign_up_success":
        newRegistrations++;
        {
          const method = String(d.params?.method ?? "unknown");
          signupMethodCounts[method] = (signupMethodCounts[method] ?? 0) + 1;
          const country = String(d.params?.country ?? "").toUpperCase();
          if (country) countryCounts[country] = (countryCounts[country] ?? 0) + 1;
        }
        break;
      case "message_sent":
        messagesSent++;
        break;
      case "chat_created":
        chatsCreated++;
        break;
      case "call_started":
        callsStarted++;
        break;
      case "meeting_created":
        meetingsHeld++;
        break;
    }
  });

  const topCountries = Object.entries(countryCounts)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 20)
    .map(([code, count]) => ({ code, count }));

  await db
    .collection("platformStats")
    .doc("daily")
    .collection("entries")
    .doc(dayKey)
    .set(
      {
        date: dayKey,
        activeUsers: activeUsers.size,
        newRegistrations,
        messagesSent,
        chatsCreated,
        callsStarted,
        meetingsHeld,
        breakdownByPlatform: platformCounts,
        breakdownByCountry: topCountries,
        breakdownBySignupMethod: signupMethodCounts,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

  logger.log(
    `rollupDailyAnalytics: ${dayKey} events=${snap.size} dau=${activeUsers.size} ` +
      `signups=${newRegistrations} msgs=${messagesSent} chats=${chatsCreated} calls=${callsStarted}`,
  );
}

async function pruneOldEvents(): Promise<void> {
  const db = admin.firestore();
  const cutoff = new Date(Date.now() - 90 * 24 * 60 * 60 * 1000).toISOString();
  const snap = await db
    .collection("analyticsEvents")
    .where("ts", "<", cutoff)
    .limit(500)
    .get();
  if (snap.empty) return;
  const batch = db.batch();
  snap.docs.forEach((d) => batch.delete(d.ref));
  await batch.commit();
  logger.log(`rollupDailyAnalytics: pruned ${snap.size} old events`);
}

export const rollupDailyAnalytics = functions.pubsub
  .schedule("every day 03:00")
  .timeZone(TZ)
  .onRun(async () => {
    const yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000);
    try {
      await rollup(yesterday);
    } catch (e) {
      logger.error("rollupDailyAnalytics: rollup failed", e);
    }
    try {
      await pruneOldEvents();
    } catch (e) {
      logger.error("rollupDailyAnalytics: prune failed", e);
    }
  });
