'use client';

import { useParams } from 'next/navigation';
import { Loader2 } from 'lucide-react';
import { doc } from 'firebase/firestore';
import { useAuth } from '@/hooks/use-auth';
import {
  useDoc,
  useFirestore,
  useMemoFirebase,
  useUser as useFirebaseAuthUser,
  useUsersByDocumentIds,
} from '@/firebase';
import type { Conversation, User } from '@/lib/types';
import { ConversationThreadsPageClient } from '@/components/chat/conversation-pages/ConversationThreadsPageClient';
import * as React from 'react';

export default function ConversationThreadsPage() {
  const { user: currentUser, isLoading } = useAuth();
  const { user: firebaseAuthUser } = useFirebaseAuthUser();
  const params = useParams();
  const firestore = useFirestore();
  const conversationId = typeof params.conversationId === 'string' ? params.conversationId : '';

  const authUid = firebaseAuthUser?.uid ?? currentUser?.id ?? null;
  const userForUi = React.useMemo((): User | null => {
    if (!currentUser) return null;
    if (!authUid) return currentUser;
    if (currentUser.id === authUid) return currentUser;
    return { ...currentUser, id: authUid };
  }, [currentUser, authUid]);

  const conversationRef = useMemoFirebase(
    () =>
      firestore && firebaseAuthUser && conversationId
        ? doc(firestore, 'conversations', conversationId)
        : null,
    [firestore, firebaseAuthUser, conversationId]
  );
  const { data: conversation } = useDoc<Conversation>(conversationRef);

  const userIds = React.useMemo(() => {
    const ids = new Set<string>(conversation?.participantIds ?? []);
    if (authUid) ids.add(authUid);
    return [...ids];
  }, [conversation?.participantIds, authUid]);
  const { usersById } = useUsersByDocumentIds(firestore, userIds);
  const allUsers = React.useMemo(() => [...usersById.values()] as User[], [usersById]);

  if (isLoading || !userForUi) {
    return (
      <div className="flex flex-1 items-center justify-center p-8">
        <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" aria-hidden />
      </div>
    );
  }

  if (!conversationId) return null;

  return (
    <ConversationThreadsPageClient
      conversationId={conversationId}
      currentUser={userForUi}
      allUsers={allUsers}
    />
  );
}
