
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

const db = admin.firestore();

/**
 * Scheduled function that checks for users marked as 'online' but who haven't
 * updated their 'lastSeen' timestamp recently.
 * Also cleans up stale meeting participants and join requests.
 * 
 * Frequency: Every 1 minute
 * Threshold: 60 seconds
 */
export const checkUserPresence = onSchedule({
  schedule: "every 1 minutes",
  timeZone: "Europe/Moscow",
}, async () => {
  const now = new Date();
  // Threshold: If lastSeen is older than 1 minute, consider them offline.
  const threshold = new Date(now.getTime() - 60 * 1000);
  const thresholdIso = threshold.toISOString();

  try {
    // 1. GLOBAL PRESENCE CLEANUP
    logger.log("[checkUserPresence] Step 1: Cleaning up global user presence...");
    const onlineUsersSnapshot = await db.collection("users")
      .where("online", "==", true)
      .where("lastSeen", "<", thresholdIso)
      .get();

    if (!onlineUsersSnapshot.empty) {
      const batch = db.batch();
      onlineUsersSnapshot.docs.forEach((doc) => {
        batch.update(doc.ref, { online: false });
      });
      await batch.commit();
      logger.log(`[checkUserPresence] Successfully marked ${onlineUsersSnapshot.size} inactive users as offline.`);
    }

    // 2. MEETING PARTICIPANTS CLEANUP
    logger.log("[checkUserPresence] Step 2: Cleaning up stale meeting participants...");
    // Uses collectionGroup index: participants (lastSeen ASC, id ASC)
    const staleParticipantsSnapshot = await db.collectionGroup('participants')
      .where('lastSeen', '<', thresholdIso)
      .orderBy('lastSeen', 'asc')
      .orderBy('id', 'asc')
      .get();

    if (!staleParticipantsSnapshot.empty) {
      const batch = db.batch();
      let count = 0;
      staleParticipantsSnapshot.docs.forEach((doc) => {
        // Double check it's actually in a meeting path
        if (doc.ref.path.includes('/meetings/')) {
            batch.delete(doc.ref);
            count++;
        }
      });
      if (count > 0) {
        await batch.commit();
        logger.log(`[checkUserPresence] Removed ${count} stale participants from meetings.`);
      }
    }

    // 3. JOIN REQUESTS CLEANUP
    logger.log("[checkUserPresence] Step 3: Cleaning up stale lobby requests...");
    // Uses collectionGroup index: requests (status ASC, lastSeen ASC)
    const staleRequestsSnapshot = await db.collectionGroup('requests')
      .where('status', '==', 'pending')
      .where('lastSeen', '<', thresholdIso)
      .get();

    if (!staleRequestsSnapshot.empty) {
      const batch = db.batch();
      let count = 0;
      staleRequestsSnapshot.docs.forEach((doc) => {
        if (doc.ref.path.includes('/meetings/')) {
            batch.delete(doc.ref);
            count++;
        }
      });
      if (count > 0) {
        await batch.commit();
        logger.log(`[checkUserPresence] Removed ${count} stale requests from lobby.`);
      }
    }
    
    logger.log("[checkUserPresence] Cleanup completed successfully.");
  } catch (error) {
    logger.error("[checkUserPresence] Critical error during presence cleanup:", error);
  }
});
