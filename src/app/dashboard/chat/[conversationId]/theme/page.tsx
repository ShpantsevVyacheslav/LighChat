'use client';

import { useParams } from 'next/navigation';
import { Loader2 } from 'lucide-react';
import { useAuth } from '@/hooks/use-auth';
import { ConversationThemePageClient } from '@/components/chat/conversation-pages/ConversationThemePageClient';

export default function ConversationThemePage() {
  const { user, isLoading } = useAuth();
  const params = useParams();
  const conversationId = typeof params.conversationId === 'string' ? params.conversationId : '';

  if (isLoading || !user) {
    return (
      <div className="flex flex-1 items-center justify-center p-8">
        <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" aria-hidden />
      </div>
    );
  }

  if (!conversationId) return null;

  return <ConversationThemePageClient conversationId={conversationId} userId={user.id} />;
}
