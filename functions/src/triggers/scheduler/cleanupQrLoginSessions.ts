import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

const db = admin.firestore();

/**
 * Чистит устаревшие QR-login сессии (`qrLoginSessions/{sessionId}`).
 * TTL у сессии 90 секунд; чистим раз в 5 минут — приемлемый компромисс между
 * мусором в коллекции и квотой запросов.
 */
export const cleanupQrLoginSessions = onSchedule(
  {
    schedule: "every 5 minutes",
    timeZone: "Europe/Moscow",
  },
  async () => {
    const nowIso = new Date().toISOString();
    try {
      const snap = await db
        .collection("qrLoginSessions")
        .where("expiresAt", "<", nowIso)
        .limit(200)
        .get();
      if (snap.empty) return;
      const batch = db.batch();
      snap.docs.forEach((d) => batch.delete(d.ref));
      await batch.commit();
      logger.log(
        `[cleanupQrLoginSessions] Deleted ${snap.size} expired QR login sessions.`
      );
    } catch (err) {
      logger.error("[cleanupQrLoginSessions] Cleanup failed:", err);
    }
  }
);
