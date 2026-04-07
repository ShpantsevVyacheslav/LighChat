
'use client';

import { useMemo } from 'react';
import { useFirestore, useCollection, useMemoFirebase, useDoc, useConversationsByDocumentIds } from '@/firebase';
import { collection, query, where, doc } from 'firebase/firestore';
import type { Conversation, Notification, UserChatIndex } from '@/lib/types';

/**
 * Centralized hook to fetch total unread messages across all active conversations.
 * Чаты подгружаются по `userChats/{userId}.conversationIds` (без list-query по `conversations`).
 */
export function useTotalUnreadCount(userId: string | undefined): number {
  return useTotalUnreadCountWithOptions(userId, true);
}

export function useTotalUnreadCountWithOptions(
  userId: string | undefined,
  enabled: boolean
): number {
  const firestore = useFirestore();

  const userChatIndexRef = useMemoFirebase(
    () => (enabled && firestore && userId ? doc(firestore, 'userChats', userId) : null),
    [enabled, firestore, userId]
  );
  const { data: userChatIndex } = useDoc<UserChatIndex>(userChatIndexRef);
  const conversationIds = useMemo(
    () => userChatIndex?.conversationIds || [],
    [userChatIndex?.conversationIds]
  );

  const { data: conversations } = useConversationsByDocumentIds(enabled ? firestore : null, conversationIds);

  /** Сумма непрочитанных (основная лента + треды). */
  return useMemo(() => {
    if (!conversations || !userId) return 0;
    return conversations.reduce((total, conv) => {
      if (!conv.participantIds?.includes(userId)) return total;

      const mainUnreads = conv.unreadCounts?.[userId] || 0;
      const threadUnreads = conv.unreadThreadCounts?.[userId] || 0;

      return total + mainUnreads + threadUnreads;
    }, 0);
  }, [conversations, userId]);
}

/**
 * Hook to fetch total unread system notifications.
 */
export function useUnreadNotificationsCount(userId: string | undefined): number {
  const firestore = useFirestore();

  const notificationsQuery = useMemoFirebase(
    () => (userId && firestore ? query(
        collection(firestore, `users/${userId}/notifications`),
        where('isRead', '==', false)
    ) : null),
    [userId, firestore]
  );

  const { data: notifications } = useCollection<Notification>(notificationsQuery);

  return useMemo(() => notifications?.length || 0, [notifications]);
}
