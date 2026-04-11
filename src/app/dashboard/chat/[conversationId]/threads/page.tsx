'use client';

import { useParams } from 'next/navigation';
import { Loader2 } from 'lucide-react';
import { collection } from 'firebase/firestore';
import { useAuth } from '@/hooks/use-auth';
import { useCollection, useFirestore, useMemoFirebase, useUser as useFirebaseAuthUser } from '@/firebase';
import type { User } from '@/lib/types';
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

  const usersQuery = useMemoFirebase(
    () => (firestore && firebaseAuthUser ? collection(firestore, 'users') : null),
    [firestore, firebaseAuthUser]
  );
  const { data: usersData } = useCollection<User>(usersQuery);
  const allUsers = React.useMemo(() => usersData || [], [usersData]);

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
