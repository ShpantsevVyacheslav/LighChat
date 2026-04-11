'use client';

import { useParams, useRouter } from 'next/navigation';
import { Loader2 } from 'lucide-react';
import { useAuth } from '@/hooks/use-auth';
import { buildDashboardChatOpenUrl } from '@/lib/dashboard-conversation-url';
import { ConversationUtilityRouteSheet } from '@/components/chat/conversation-pages/ConversationUtilityRouteSheet';
import { LeaveGroupPanel } from '@/components/chat/conversation-pages/LeaveGroupPanel';

export default function LeaveConversationPage() {
  const router = useRouter();
  const params = useParams();
  const { user: currentUser, isLoading } = useAuth();
  const conversationId = typeof params.conversationId === 'string' ? params.conversationId : '';

  const handleCancel = () => {
    router.push(buildDashboardChatOpenUrl(conversationId));
  };

  if (isLoading || !currentUser) {
    return (
      <div className="flex flex-1 items-center justify-center p-8">
        <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" aria-hidden />
      </div>
    );
  }

  if (!conversationId) return null;

  return (
    <ConversationUtilityRouteSheet title="Покинуть группу" conversationId={conversationId}>
      <LeaveGroupPanel conversationId={conversationId} currentUser={currentUser} onCancel={handleCancel} />
    </ConversationUtilityRouteSheet>
  );
}
