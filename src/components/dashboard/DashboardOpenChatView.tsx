'use client';

import * as React from 'react';
import { usePathname, useRouter, useSearchParams } from 'next/navigation';
import { useAuth } from '@/hooks/use-auth';
import {
  useDoc,
  useFirestore,
  useMemoFirebase,
  useCollection,
  useUser as useFirebaseAuthUser,
} from '@/firebase';
import { collection, doc } from 'firebase/firestore';
import type { User, Conversation } from '@/lib/types';
import { ChatWindow } from '@/components/chat/ChatWindow';
import { Loader2 } from 'lucide-react';
import { Button } from '@/components/ui/button';
import {
  DASHBOARD_OPEN_PROFILE_QUERY,
  DASHBOARD_PROFILE_SOURCE_QUERY,
  DASHBOARD_PROFILE_USER_QUERY,
} from '@/lib/dashboard-conversation-url';
import { FirestorePermissionError } from '@/firebase/errors';
import { useI18n } from '@/hooks/use-i18n';

type DashboardOpenChatViewProps = {
  conversationId: string;
  onBack: () => void;
  onSelectConversation: (id: string) => void;
  messageSearchBlurInsetLeftPx: number;
};

/**
 * Правая колонка: активный чат по id из URL (Firestore + `ChatWindow`).
 * Редактирование группы — внутри sheet профиля (`ChatParticipantProfile`), не отдельным диалогом.
 */
export function DashboardOpenChatView({
  conversationId,
  onBack,
  onSelectConversation,
  messageSearchBlurInsetLeftPx,
}: DashboardOpenChatViewProps) {
  const searchParams = useSearchParams();
  const router = useRouter();
  const pathname = usePathname();
  const focusMessageId = searchParams.get('focusMessageId');
  const threadRootMessageId = searchParams.get('threadRootMessageId');
  const openProfile = searchParams.get(DASHBOARD_OPEN_PROFILE_QUERY) === '1';
  const profileUserId = searchParams.get(DASHBOARD_PROFILE_USER_QUERY);
  const rawProfileSource = searchParams.get(DASHBOARD_PROFILE_SOURCE_QUERY);
  const initialProfileSource =
    rawProfileSource === 'contacts' ||
    rawProfileSource === 'mention' ||
    rawProfileSource === 'sender' ||
    rawProfileSource === 'chat'
      ? rawProfileSource
      : null;

  const clearFocusMessageFromUrl = React.useCallback(() => {
    const p = new URLSearchParams(searchParams.toString());
    p.delete('focusMessageId');
    const qs = p.toString();
    router.replace(qs ? `${pathname}?${qs}` : pathname, { scroll: false });
  }, [searchParams, router, pathname]);

  const clearThreadRootMessageFromUrl = React.useCallback(() => {
    const p = new URLSearchParams(searchParams.toString());
    p.delete('threadRootMessageId');
    const qs = p.toString();
    router.replace(qs ? `${pathname}?${qs}` : pathname, { scroll: false });
  }, [searchParams, router, pathname]);

  const clearInitialProfileFromUrl = React.useCallback(() => {
    const p = new URLSearchParams(searchParams.toString());
    p.delete(DASHBOARD_OPEN_PROFILE_QUERY);
    p.delete(DASHBOARD_PROFILE_USER_QUERY);
    p.delete(DASHBOARD_PROFILE_SOURCE_QUERY);
    const qs = p.toString();
    router.replace(qs ? `${pathname}?${qs}` : pathname, { scroll: false });
  }, [searchParams, router, pathname]);

  const { user: currentUser } = useAuth();
  const { t } = useI18n();
  const { user: firebaseAuthUser } = useFirebaseAuthUser();
  const authUid = firebaseAuthUser?.uid ?? currentUser?.id ?? null;
  const currentUserForFirestore = React.useMemo((): User | null => {
    if (!currentUser) return null;
    if (!authUid) return currentUser;
    if (currentUser.id === authUid) return currentUser;
    return { ...currentUser, id: authUid };
  }, [currentUser, authUid]);

  const firestore = useFirestore();

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
  const { data: conversation, isLoading, error } = useDoc<Conversation>(conversationRef);

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

  if (error && !conversation) {
    const isPermissionDenied = error instanceof FirestorePermissionError;
    if (!isPermissionDenied) {
      return (
        <div className="flex flex-1 flex-col items-center justify-center gap-3 p-6 text-center text-muted-foreground text-sm">
          <p>{t('openChat.transientError')}</p>
          <Button
            variant="outline"
            size="sm"
            onClick={() => onSelectConversation(conversationId)}
          >
            {t('openChat.retry')}
          </Button>
        </div>
      );
    }
  }

  if (!conversation) {
    return (
      <div className="flex flex-1 flex-col items-center justify-center p-6 text-center text-muted-foreground text-sm">
        {t('openChat.notFound')}
      </div>
    );
  }

  return (
    <ChatWindow
      key={conversation.id}
      conversation={conversation}
      currentUser={currentUserForFirestore}
      allUsers={allUsers}
      onBack={onBack}
      onSelectConversation={onSelectConversation}
      messageSearchBlurInsetLeftPx={messageSearchBlurInsetLeftPx}
      focusMessageId={focusMessageId}
      onFocusMessageConsumed={clearFocusMessageFromUrl}
      threadRootMessageId={threadRootMessageId}
      onThreadRootMessageConsumed={clearThreadRootMessageFromUrl}
      initialProfileOpen={openProfile}
      initialProfileFocusUserId={profileUserId}
      initialProfileSource={initialProfileSource}
      onInitialProfileConsumed={clearInitialProfileFromUrl}
    />
  );
}
