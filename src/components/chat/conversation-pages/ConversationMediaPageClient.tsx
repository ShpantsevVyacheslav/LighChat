'use client';

import type { User } from '@/lib/types';
import { ConversationUtilityRouteSheet } from '@/components/chat/conversation-pages/ConversationUtilityRouteSheet';
import { ConversationMediaPanel } from '@/components/chat/conversation-pages/ConversationMediaPanel';

export function ConversationMediaPageClient({
  conversationId,
  currentUser,
  allUsers = [],
}: {
  conversationId: string;
  currentUser: User;
  allUsers?: User[];
}) {
  return (
    <ConversationUtilityRouteSheet title="Медиа, ссылки и файлы" conversationId={conversationId}>
      <ConversationMediaPanel
        conversationId={conversationId}
        currentUser={currentUser}
        allUsers={allUsers}
        edgeToEdge
      />
    </ConversationUtilityRouteSheet>
  );
}
