'use client';

import { ConversationUtilityRouteSheet } from '@/components/chat/conversation-pages/ConversationUtilityRouteSheet';
import { ConversationThemePanel } from '@/components/chat/conversation-pages/ConversationThemePanel';

export function ConversationThemePageClient({
  conversationId,
  userId,
}: {
  conversationId: string;
  userId: string;
}) {
  return (
    <ConversationUtilityRouteSheet title="Тема этого чата" conversationId={conversationId}>
      <ConversationThemePanel conversationId={conversationId} userId={userId} />
    </ConversationUtilityRouteSheet>
  );
}
