'use client';

import { ConversationUtilityRouteSheet } from '@/components/chat/conversation-pages/ConversationUtilityRouteSheet';
import { ConversationNotificationsPanel } from '@/components/chat/conversation-pages/ConversationNotificationsPanel';

export function ConversationNotificationsPageClient({
  conversationId,
  userId,
}: {
  conversationId: string;
  userId: string;
}) {
  return (
    <ConversationUtilityRouteSheet title="Уведомления в этом чате" conversationId={conversationId}>
      <ConversationNotificationsPanel conversationId={conversationId} userId={userId} />
    </ConversationUtilityRouteSheet>
  );
}
