'use client';

import { ConversationUtilityRouteSheet } from '@/components/chat/conversation-pages/ConversationUtilityRouteSheet';
import { ConversationStarredPanel } from '@/components/chat/conversation-pages/ConversationStarredPanel';
import { useI18n } from '@/hooks/use-i18n';

export function ConversationStarredPageClient({
  conversationId,
  userId,
}: {
  conversationId: string;
  userId: string;
}) {
  const { t } = useI18n();
  return (
    <ConversationUtilityRouteSheet title={t('chat.pages.starred')} conversationId={conversationId}>
      <ConversationStarredPanel conversationId={conversationId} userId={userId} />
    </ConversationUtilityRouteSheet>
  );
}
