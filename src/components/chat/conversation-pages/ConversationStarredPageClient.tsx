'use client';

import { ConversationUtilityRouteSheet } from '@/components/chat/conversation-pages/ConversationUtilityRouteSheet';
import { ConversationStarredPanel } from '@/components/chat/conversation-pages/ConversationStarredPanel';

export function ConversationStarredPageClient({
  conversationId,
  userId,
}: {
  conversationId: string;
  userId: string;
}) {
  return (
    <ConversationUtilityRouteSheet title="Избранное" conversationId={conversationId}>
      <ConversationStarredPanel conversationId={conversationId} userId={userId} />
    </ConversationUtilityRouteSheet>
  );
}
