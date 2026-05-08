'use client';

import { ConversationUtilityRouteSheet } from '@/components/chat/conversation-pages/ConversationUtilityRouteSheet';
import { ConversationThemePanel } from '@/components/chat/conversation-pages/ConversationThemePanel';
import { useI18n } from '@/hooks/use-i18n';

export function ConversationThemePageClient({
  conversationId,
  userId,
}: {
  conversationId: string;
  userId: string;
}) {
  const { t } = useI18n();
  return (
    <ConversationUtilityRouteSheet title={t('chat.pages.theme')} conversationId={conversationId}>
      <ConversationThemePanel conversationId={conversationId} userId={userId} />
    </ConversationUtilityRouteSheet>
  );
}
