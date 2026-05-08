'use client';

import type { User } from '@/lib/types';
import { ConversationUtilityRouteSheet } from '@/components/chat/conversation-pages/ConversationUtilityRouteSheet';
import { ConversationMediaPanel } from '@/components/chat/conversation-pages/ConversationMediaPanel';
import { useI18n } from '@/hooks/use-i18n';

export function ConversationMediaPageClient({
  conversationId,
  currentUser,
  allUsers = [],
}: {
  conversationId: string;
  currentUser: User;
  allUsers?: User[];
}) {
  const { t } = useI18n();
  return (
    <ConversationUtilityRouteSheet title={t('chat.pages.media')} conversationId={conversationId}>
      <ConversationMediaPanel
        conversationId={conversationId}
        currentUser={currentUser}
        allUsers={allUsers}
        edgeToEdge
      />
    </ConversationUtilityRouteSheet>
  );
}
