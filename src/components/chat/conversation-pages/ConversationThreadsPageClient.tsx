'use client';

import type { User } from '@/lib/types';
import { ConversationUtilityRouteSheet } from '@/components/chat/conversation-pages/ConversationUtilityRouteSheet';
import { ConversationThreadsPanel } from '@/components/chat/conversation-pages/ConversationThreadsPanel';
import { useI18n } from '@/hooks/use-i18n';

export function ConversationThreadsPageClient({
  conversationId,
  currentUser,
  allUsers,
}: {
  conversationId: string;
  currentUser: User;
  allUsers: User[];
}) {
  const { t } = useI18n();
  return (
    <ConversationUtilityRouteSheet title={t('chat.pages.threads')} conversationId={conversationId}>
      <ConversationThreadsPanel conversationId={conversationId} currentUser={currentUser} allUsers={allUsers} />
    </ConversationUtilityRouteSheet>
  );
}
