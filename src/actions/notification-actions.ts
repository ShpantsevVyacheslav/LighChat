
'use server';

import { adminDb, adminMessaging } from '@/firebase/admin';
import type { UserRole, Notification } from '@/lib/types';
import type { MulticastMessage } from 'firebase-admin/messaging';

// Helper function to save notifications to Firestore
async function saveNotificationsForUsers(userIds: string[], title: string, body: string, link: string) {
  if (userIds.length === 0) {
    return;
  }
  const batch = adminDb.batch();
  const now = new Date().toISOString();

  for (const userId of userIds) {
    const notificationRef = adminDb.collection('users').doc(userId).collection('notifications').doc();
    const newNotification: Notification = {
      id: notificationRef.id,
      userId,
      title,
      body,
      link,
      createdAt: now,
      isRead: false,
    };
    batch.set(notificationRef, newNotification);
  }
  await batch.commit();
}


async function getTokensForRoles(roles: UserRole[]): Promise<{ tokens: string[], userIds: string[] }> {
  if (roles.length === 0) {
      return { tokens: [], userIds: [] };
  }
  const usersRef = adminDb.collection('users');
  const q = usersRef.where('role', 'in', roles);
  
  try {
    const querySnapshot = await q.get();
    
    if (querySnapshot.empty) {
      console.log('No users found for roles:', roles);
      return { tokens: [], userIds: [] };
    }
    
    const tokens: string[] = [];
    const userIds: string[] = [];
    querySnapshot.docs.forEach(doc => {
      const user = doc.data();
      // Ensure user is not deleted
      if (!user.deletedAt) {
          userIds.push(doc.id);
          if (Array.isArray(user.fcmTokens)) {
            tokens.push(...user.fcmTokens.filter(Boolean));
          }
      }
    });
    
    return { tokens: [...new Set(tokens)], userIds: [...new Set(userIds)] };
  } catch (error) {
    console.error('Error fetching user tokens for notifications:', error);
    return { tokens: [], userIds: [] };
  }
}

async function getTokensForUserIds(userIds: string[]): Promise<string[]> {
    if (userIds.length === 0) {
        return [];
    }
    try {
        // Firestore 'in' queries are limited to 30 items. We need to batch the requests.
        const userChunks: string[][] = [];
        for (let i = 0; i < userIds.length; i += 30) {
            userChunks.push(userIds.slice(i, i + 30));
        }

        const allTokens: string[] = [];

        for (const chunk of userChunks) {
            const usersRef = adminDb.collection('users');
            const q = usersRef.where('id', 'in', chunk);
            const querySnapshot = await q.get();
            
            if (!querySnapshot.empty) {
                const tokens = querySnapshot.docs.flatMap(doc => {
                    const user = doc.data();
                    // Ensure user is not deleted and has tokens
                    return (!user.deletedAt && Array.isArray(user.fcmTokens)) ? user.fcmTokens.filter(Boolean) : [];
                });
                allTokens.push(...tokens);
            }
        }
        
        return [...new Set(allTokens)];
    } catch (error) {
        console.error('Error fetching user tokens by ID for notifications:', error);
        return [];
    }
}


async function sendNotifications(
  tokens: string[],
  title: string,
  body: string,
  link?: string,
  isDataOnly: boolean = false
): Promise<{ success: boolean; error?: string }> {
  if (tokens.length === 0) {
    console.log('No FCM tokens found. No notifications sent.');
    return { success: true };
  }

  const finalLink = link || '/dashboard';

  const message: MulticastMessage & {
    data: Record<string, string>;
    notification?: { title: string; body: string };
    tokens: string[];
  } = {
    data: {
        title,
        body,
        link: finalLink,
        icon: '/pwa/icon-192.png',
    },
    tokens: tokens,
  };

  // Add the 'notification' payload for non-chat messages to ensure delivery when app is in background
  if (!isDataOnly) {
      message.notification = {
          title,
          body,
      };
  }

  try {
    const response = await adminMessaging.sendEachForMulticast(message);
    const successCount = response.successCount;
    console.log(`Successfully sent ${successCount} notifications.`);

    if (response.failureCount > 0) {
      const failedTokens: string[] = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          failedTokens.push(tokens[idx]);
          console.warn(`Failed to send to token ${tokens[idx]}: ${resp.error?.message}`);
        }
      });
    }

    return { success: true };
  } catch (error: unknown) {
    console.error('Error sending push notification:', error);
    return { success: false, error: 'Failed to send notifications' };
  }
}

export async function sendNotificationToRoles(
  roles: UserRole[],
  title: string,
  body: string,
  link?: string
): Promise<{ success: boolean; error?: string }> {
  const { tokens, userIds } = await getTokensForRoles(roles);
  
  const finalLink = link || '/dashboard';
  
  try {
    await saveNotificationsForUsers(userIds, title, body, finalLink);
  } catch (e) {
    console.error('Failed to save notifications for roles:', e);
  }

  return sendNotifications(tokens, title, body, finalLink, false);
}

export async function sendNotificationToUsers(
  userIds: string[],
  title: string,
  body: string,
  link?: string,
  saveToDb: boolean = true
): Promise<{ success: boolean; error?: string }> {

  const uniqueUserIds = [...new Set(userIds)];
  
  const finalLink = link || '/dashboard';
  
  if (saveToDb) {
    try {
      await saveNotificationsForUsers(uniqueUserIds, title, body, finalLink);
    } catch (e) {
      console.error('Failed to save notifications for users:', e);
    }
  }
  
  const isDataOnly = !saveToDb;
  const tokens = await getTokensForUserIds(uniqueUserIds);
  return sendNotifications(tokens, title, body, finalLink, isDataOnly);
}

export async function sendTestNotificationAction(userId: string) {
    return sendNotificationToUsers(
        [userId], 
        "Проверка связи", 
        "Это тестовое уведомление. Если вы его видите, значит LighChat настроен правильно!", 
        "/dashboard/profile",
        true
    );
}
