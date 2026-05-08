'use client';

import { ConversationUtilityRouteSheet } from '@/components/chat/conversation-pages/ConversationUtilityRouteSheet';
import { ConversationPrivacyPanel } from '@/components/chat/conversation-pages/ConversationPrivacyPanel';
import { useI18n } from '@/hooks/use-i18n';

export function ConversationPrivacyPageClient({
  conversationId,
  userId,
}: {
  conversationId: string;
  userId: string;
}) {
  const { t } = useI18n();
  return (
    <ConversationUtilityRouteSheet title={t('chat.pages.privacy')} conversationId={conversationId}>
      <ConversationPrivacyPanel conversationId={conversationId} userId={userId} />
    </ConversationUtilityRouteSheet>
  );
}
