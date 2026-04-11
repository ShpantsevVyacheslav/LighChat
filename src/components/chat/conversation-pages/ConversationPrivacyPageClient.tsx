'use client';

import { ConversationUtilityRouteSheet } from '@/components/chat/conversation-pages/ConversationUtilityRouteSheet';
import { ConversationPrivacyPanel } from '@/components/chat/conversation-pages/ConversationPrivacyPanel';

export function ConversationPrivacyPageClient({
  conversationId,
  userId,
}: {
  conversationId: string;
  userId: string;
}) {
  return (
    <ConversationUtilityRouteSheet title="Приватность этого чата" conversationId={conversationId}>
      <ConversationPrivacyPanel conversationId={conversationId} userId={userId} />
    </ConversationUtilityRouteSheet>
  );
}
