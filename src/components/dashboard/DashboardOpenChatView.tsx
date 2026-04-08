'use client';

import * as React from 'react';
import { useAuth } from '@/hooks/use-auth';
import {
  useDoc,
  useFirestore,
  useMemoFirebase,
  useCollection,
  useUser as useFirebaseAuthUser,
} from '@/firebase';
import { collection, doc } from 'firebase/firestore';
import type { User, Conversation, UserContactsIndex } from '@/lib/types';
import { ChatWindow } from '@/components/chat/ChatWindow';
import { GroupChatFormDialog } from '@/components/chat/GroupChatFormDialog';
import { Loader2 } from 'lucide-react';

type DashboardOpenChatViewProps = {
  conversationId: string;
  onBack: () => void;
  onSelectConversation: (id: string) => void;
  messageSearchBlurInsetLeftPx: number;
};

/**
 * Правая колонка: активный чат по id из URL (Firestore + `ChatWindow`).
 */
export function DashboardOpenChatView({
  conversationId,
  onBack,
  onSelectConversation,
  messageSearchBlurInsetLeftPx,
}: DashboardOpenChatViewProps) {
  const { user: currentUser } = useAuth();
  const { user: firebaseAuthUser } = useFirebaseAuthUser();
  const authUid = firebaseAuthUser?.uid ?? currentUser?.id ?? null;
  const currentUserForFirestore = React.useMemo((): User | null => {
    if (!currentUser) return null;
    if (!authUid) return currentUser;
    if (currentUser.id === authUid) return currentUser;
    return { ...currentUser, id: authUid };
  }, [currentUser, authUid]);

  const firestore = useFirestore();
  const [editingGroup, setEditingGroup] = React.useState<Conversation | null>(null);

  const userContactsRef = useMemoFirebase(
    () => (firestore && authUid ? doc(firestore, 'userContacts', authUid) : null),
    [firestore, authUid]
  );
  const { data: userContactsIndex } = useDoc<UserContactsIndex>(userContactsRef);
  const contactIdsForSearch = React.useMemo(
    () => userContactsIndex?.contactIds ?? [],
    [userContactsIndex?.contactIds]
  );

  const { data: usersData } = useCollection<User>(
    useMemoFirebase(
      () => (firestore && firebaseAuthUser ? collection(firestore, 'users') : null),
      [firestore, firebaseAuthUser]
    )
  );
  const allUsers = React.useMemo(() => usersData || [], [usersData]);

  const conversationRef = useMemoFirebase(
    () => (firestore && conversationId ? doc(firestore, 'conversations', conversationId) : null),
    [firestore, conversationId]
  );
  const { data: conversation, isLoading } = useDoc<Conversation>(conversationRef);

  if (!currentUserForFirestore || !authUid) {
    return (
      <div className="flex flex-1 items-center justify-center text-muted-foreground">
        <Loader2 className="h-8 w-8 animate-spin" aria-hidden />
      </div>
    );
  }

  if (isLoading && !conversation) {
    return (
      <div className="flex flex-1 items-center justify-center text-muted-foreground">
        <Loader2 className="h-8 w-8 animate-spin" aria-hidden />
      </div>
    );
  }

  if (!conversation) {
    return (
      <div className="flex flex-1 flex-col items-center justify-center p-6 text-center text-muted-foreground text-sm">
        Чат не найден или нет доступа.
      </div>
    );
  }

  return (
    <>
      <ChatWindow
        key={conversation.id}
        conversation={conversation}
        currentUser={currentUserForFirestore}
        allUsers={allUsers}
        onBack={onBack}
        onSelectConversation={onSelectConversation}
        onEditGroup={(c) => {
          setEditingGroup(c);
        }}
        messageSearchBlurInsetLeftPx={messageSearchBlurInsetLeftPx}
      />
      <GroupChatFormDialog
        open={!!editingGroup}
        onOpenChange={(open) => {
          if (!open) setEditingGroup(null);
        }}
        allUsers={allUsers.filter((u) => u.id !== authUid && !u.deletedAt)}
        contactIds={contactIdsForSearch}
        currentUser={currentUserForFirestore}
        onGroupCreated={(id) => {
          setEditingGroup(null);
          onSelectConversation(id);
        }}
        initialData={editingGroup}
      />
    </>
  );
}
