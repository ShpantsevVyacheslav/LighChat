'use client';
import { useI18n } from '@/hooks/use-i18n';

import { useMemo } from 'react';
import { useRouter } from 'next/navigation';
import { collection, query, where } from 'firebase/firestore';
import { Star } from 'lucide-react';
import { useCollection, useFirestore, useMemoFirebase } from '@/firebase';
import type { StarredChatMessageDoc } from '@/lib/types';
import { buildDashboardChatOpenUrl } from '@/lib/dashboard-conversation-url';

export function ConversationStarredPanel({
  conversationId,
  userId,
  onOpenStarredMessage,
}: {
  conversationId: string;
  userId: string;
  /** Из профиля: закрыть шторку и перейти к сообщению (иначе — только переход). */
  onOpenStarredMessage?: (messageId: string) => void;
}) {
  const { t } = useI18n();
  const router = useRouter();
  const firestore = useFirestore();

  const starredQuery = useMemoFirebase(
    () =>
      firestore && userId
        ? query(
            collection(firestore, 'users', userId, 'starredChatMessages'),
            where('conversationId', '==', conversationId)
          )
        : null,
    [firestore, userId, conversationId]
  );

  const { data, isLoading } = useCollection<StarredChatMessageDoc>(starredQuery);

  const sorted = useMemo(() => {
    const rows = data ?? [];
    return [...rows].sort((a, b) => (a.createdAt < b.createdAt ? 1 : -1));
  }, [data]);

  const openMessage = (messageId: string) => {
    if (onOpenStarredMessage) {
      onOpenStarredMessage(messageId);
    } else {
      router.push(buildDashboardChatOpenUrl(conversationId, { focusMessageId: messageId }));
    }
  };

  return (
    <>
      {isLoading && !data ? (
        <p className="text-sm text-zinc-500">{t('chat.starredPanel.loading')}</p>
      ) : sorted.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-16 text-zinc-500">
          <Star className="mb-2 h-10 w-10 opacity-60" />
          <p className="text-xs font-medium">{t('chat.starredPanel.noStarredMessages')}</p>
          <p className="mt-2 max-w-sm text-center text-[11px] leading-snug text-zinc-500">
            {t('chat.starredPanel.addFromContextMenu')}
          </p>
        </div>
      ) : (
        <ul className="space-y-2">
          {sorted.map((row) => (
            <li key={row.messageId}>
              <button
                type="button"
                className="w-full rounded-2xl border border-zinc-800/80 bg-zinc-900/50 px-4 py-3 text-left text-zinc-100 transition-colors hover:bg-zinc-900"
                onClick={() => openMessage(row.messageId)}
              >
                <p className="line-clamp-3 text-sm leading-snug">
                  {row.previewText?.trim() || t('chat.messageGeneric')}
                </p>
                <p className="mt-1 text-[10px] font-bold uppercase text-zinc-500">
                  {t('chat.starredPanel.goToMessage')}
                </p>
              </button>
            </li>
          ))}
        </ul>
      )}
    </>
  );
}
