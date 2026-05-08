'use client';

import { ConversationUtilityRouteSheet } from '@/components/chat/conversation-pages/ConversationUtilityRouteSheet';
import { ConversationNotificationsPanel } from '@/components/chat/conversation-pages/ConversationNotificationsPanel';
import { useI18n } from '@/hooks/use-i18n';

export function ConversationNotificationsPageClient({
  conversationId,
  userId,
}: {
  conversationId: string;
  userId: string;
}) {
  const { t } = useI18n();
  return (
    <ConversationUtilityRouteSheet title={t('chat.pages.notifications')} conversationId={conversationId}>
      <ConversationNotificationsPanel conversationId={conversationId} userId={userId} />
    </ConversationUtilityRouteSheet>
  );
}
