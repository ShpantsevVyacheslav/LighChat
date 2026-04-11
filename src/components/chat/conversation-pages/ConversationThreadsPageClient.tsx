'use client';

import type { User } from '@/lib/types';
import { ConversationUtilityRouteSheet } from '@/components/chat/conversation-pages/ConversationUtilityRouteSheet';
import { ConversationThreadsPanel } from '@/components/chat/conversation-pages/ConversationThreadsPanel';

export function ConversationThreadsPageClient({
  conversationId,
  currentUser,
  allUsers,
}: {
  conversationId: string;
  currentUser: User;
  allUsers: User[];
}) {
  return (
    <ConversationUtilityRouteSheet title="Обсуждения" conversationId={conversationId}>
      <ConversationThreadsPanel conversationId={conversationId} currentUser={currentUser} allUsers={allUsers} />
    </ConversationUtilityRouteSheet>
  );
}
