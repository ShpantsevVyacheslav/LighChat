import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { MulticastMessage } from "firebase-admin/messaging";
import type { UserRole } from "./types";

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Sends notifications to users with specific roles.
 * This is a helper for use within Cloud Functions.
 * Uses 'data' only to prevent doubling if user has the app open.
 */
export async function sendNotificationToRoles_CF(roles: UserRole[], title: string, body: string, link: string, tag?: string): Promise<void> {
  if (roles.length === 0) {
    return;
  }

  const usersRef = db.collection("users");
  const q = usersRef.where("role", "in", roles);

  try {
    const querySnapshot = await q.get();
    if (querySnapshot.empty) {
      logger.log("No users found for roles to notify:", roles);
      return;
    }

    const tokens: string[] = [];
    const userIds: string[] = [];
    querySnapshot.docs.forEach((doc) => {
      const user = doc.data();
      if (!user.deletedAt) {
        userIds.push(doc.id);
        if (Array.isArray(user.fcmTokens)) {
          tokens.push(...user.fcmTokens.filter(Boolean));
        }
      }
    });

    const uniqueTokens = [...new Set(tokens)];

    if (uniqueTokens.length > 0) {
      // Use data-only message here as well to maintain consistency and prevent doubling
      const message: MulticastMessage = {
        data: { 
          title: title, 
          body: body, 
          link: link, 
          icon: "/pwa/icon-192.png",
          tag: tag || "system_notification" 
        },
        tokens: uniqueTokens,
      };
      await messaging.sendEachForMulticast(message);
    }

    const batch = db.batch();
    const now = new Date().toISOString();
    userIds.forEach((userId) => {
      const notificationRef = db.collection("users").doc(userId).collection("notifications").doc();
      batch.set(notificationRef, { id: notificationRef.id, userId, title, body, link, createdAt: now, isRead: false });
    });
    await batch.commit();
  } catch (error: unknown) {
    logger.error("Error sending notifications to roles:", error);
  }
}
