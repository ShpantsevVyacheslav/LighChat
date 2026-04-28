import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

const db = admin.firestore();

/**
 * Secret Chat hard media view protocol cleanup:
 * - Deletes expired `secretMediaViewRequests` (short-lived, ~60s).
 * - Deletes expired `secretMediaKeyGrants` (short-lived, ~30s).
 *
 * Notes:
 * - Uses collectionGroup queries across all conversations.
 * - Best-effort: failures on one batch do not stop next runs.
 */
export const cleanupSecretMediaRequests = onSchedule({
  schedule: "every 5 minutes",
  timeZone: "Europe/Moscow",
}, async () => {
  const now = new Date();
  const nowIso = now.toISOString();
  const nowTs = admin.firestore.Timestamp.fromDate(now);

  try {
    const reqSnap = await db
      .collectionGroup("secretMediaViewRequests")
      .where("expiresAtTs", "<=", nowTs)
      .limit(200)
      .get();

    if (!reqSnap.empty) {
      const batch = db.batch();
      for (const d of reqSnap.docs) batch.delete(d.ref);
      await batch.commit();
      logger.info("[cleanupSecretMediaRequests] deleted expired requests", { count: reqSnap.size });
    }
  } catch (e) {
    logger.error("[cleanupSecretMediaRequests] requests cleanup failed", { err: String(e) });
  }

  try {
    const grantSnap = await db
      .collectionGroup("secretMediaKeyGrants")
      .where("expiresAtTs", "<=", nowTs)
      .limit(200)
      .get();

    if (!grantSnap.empty) {
      const batch = db.batch();
      for (const d of grantSnap.docs) batch.delete(d.ref);
      await batch.commit();
      logger.info("[cleanupSecretMediaRequests] deleted expired grants", { count: grantSnap.size });
    }
  } catch (e) {
    logger.error("[cleanupSecretMediaRequests] grants cleanup failed", { err: String(e) });
  }

  logger.debug("[cleanupSecretMediaRequests] done", { now: nowIso });
});

