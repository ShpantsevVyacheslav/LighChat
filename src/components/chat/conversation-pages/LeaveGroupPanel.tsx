'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useDoc, useFirestore, useMemoFirebase } from '@/firebase';
import { doc, writeBatch, arrayRemove } from 'firebase/firestore';
import type { Conversation, User } from '@/lib/types';
import { logger } from '@/lib/logger';
import { useToast } from '@/hooks/use-toast';
import { useI18n } from '@/hooks/use-i18n';
import { Button } from '@/components/ui/button';
import { Loader2 } from 'lucide-react';

type LeaveGroupPanelProps = {
  conversationId: string;
  currentUser: User;
  /** Профиль чата: вернуться к карточке группы. Маршрут: то же + уход со страницы. */
  onCancel: () => void;
};

export function LeaveGroupPanel({ conversationId, currentUser, onCancel }: LeaveGroupPanelProps) {
  const { t } = useI18n();
  const router = useRouter();
  const firestore = useFirestore();
  const { toast } = useToast();
  const [isLeaving, setIsLeaving] = useState(false);

  const conversationRef = useMemoFirebase(
    () => (firestore && conversationId ? doc(firestore, 'conversations', conversationId) : null),
    [firestore, conversationId]
  );
  const { data: conversation, isLoading } = useDoc<Conversation>(conversationRef);

  const isCreator = conversation?.createdByUserId === currentUser.id;

  const handleConfirmLeave = async () => {
    if (!conversationRef || !conversation) return;

    if (isCreator) {
      toast({
        variant: 'destructive',
        title: t('chat.leaveGroup.forbidden'),
        description: t('chat.leaveGroup.forbiddenHint'),
      });
      onCancel();
      return;
    }

    setIsLeaving(true);

    const newParticipantIds = conversation.participantIds.filter((id) => id !== currentUser.id);
    const newAdminIds = (conversation.adminIds || []).filter((id) => id !== currentUser.id);
    const newParticipantInfo = { ...conversation.participantInfo };
    delete newParticipantInfo[currentUser.id];
    const lastMessageText = `${currentUser.name} ${t('chat.leaveGroup.leftMessage')}`;

    try {
      const batch = writeBatch(firestore);

      batch.update(conversationRef, {
        participantIds: newParticipantIds,
        participantInfo: newParticipantInfo,
        adminIds: newAdminIds,
        lastMessageText,
        lastMessageSenderId: 'system',
        lastMessageTimestamp: new Date().toISOString(),
      });

      const userChatIndexRef = doc(firestore, 'userChats', currentUser.id);
      batch.update(userChatIndexRef, {
        conversationIds: arrayRemove(conversation.id),
      });

      await batch.commit();

      toast({ title: t('chat.leaveGroup.success') });
      router.push('/dashboard/chat');
    } catch (e) {
      logger.error('leave-group', 'failed', e);
      toast({ variant: 'destructive', title: t('common.error'), description: t('chat.leaveGroup.failed') });
      setIsLeaving(false);
    }
  };

  if (isLoading && !conversation) {
    return (
      <div className="flex items-center justify-center py-16">
        <Loader2 className="h-8 w-8 animate-spin text-zinc-500" aria-hidden />
      </div>
    );
  }

  return (
    <div className="space-y-6 text-zinc-100">
      <p className="text-sm text-zinc-400">
        {isCreator ? (
          t('chat.leaveGroup.creatorHint')
        ) : (
          <>
            {t('chat.leaveGroup.confirmPrefix')}{' '}
            <span className="font-semibold text-zinc-100">{conversation?.name}</span>?
          </>
        )}
      </p>
      <div className="flex flex-col gap-2 sm:flex-row sm:justify-end">
        <Button
          type="button"
          variant="ghost"
          className="text-zinc-300 hover:bg-zinc-800 hover:text-zinc-100"
          disabled={isLeaving}
          onClick={onCancel}
        >
          {t('common.cancel')}
        </Button>
        {!isCreator && (
          <Button
            type="button"
            variant="destructive"
            className="rounded-full"
            disabled={isLeaving || isLoading}
            onClick={() => void handleConfirmLeave()}
          >
            {isLeaving ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
            {t('chat.leaveGroup.confirm')}
          </Button>
        )}
      </div>
    </div>
  );
}
