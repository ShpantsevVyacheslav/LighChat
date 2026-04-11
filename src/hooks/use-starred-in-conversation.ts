'use client';

import { useMemo } from 'react';
import { collection, query, where } from 'firebase/firestore';
import { useCollection, useFirestore, useMemoFirebase } from '@/firebase';
import type { StarredChatMessageDoc } from '@/lib/types';

/**
 * Подписка на избранные сообщения пользователя в одной беседе.
 */
export function useStarredInConversation(userId: string | undefined, conversationId: string | undefined) {
  const firestore = useFirestore();

  const starredQuery = useMemoFirebase(
    () =>
      firestore && userId && conversationId
        ? query(
            collection(firestore, 'users', userId, 'starredChatMessages'),
            where('conversationId', '==', conversationId)
          )
        : null,
    [firestore, userId, conversationId]
  );

  const { data, isLoading, error } = useCollection<StarredChatMessageDoc>(starredQuery);

  const starredMessageIds = useMemo(() => new Set((data ?? []).map((d) => d.messageId)), [data]);

  const starredCount = starredMessageIds.size;

  return { starredDocs: data ?? [], starredMessageIds, starredCount, isLoading, error };
}
