'use client';

import { useMemo } from 'react';
import { useRouter } from 'next/navigation';
import { collection, limit, orderBy, query } from 'firebase/firestore';
import { MessageSquare } from 'lucide-react';
import { useCollection, useFirestore, useMemoFirebase } from '@/firebase';
import type { ChatMessage, User } from '@/lib/types';
import { categorizeAttachmentsFromMessages } from '@/lib/chat-attachments-from-messages';
import { sanitizeMessageHtml } from '@/lib/sanitize-message-html';
import { Badge } from '@/components/ui/badge';
import { format, isToday, isYesterday, parseISO } from 'date-fns';
import { buildDashboardChatOpenUrl } from '@/lib/dashboard-conversation-url';

function formatLastThreadTime(dateStr?: string) {
  if (!dateStr) return '';
  const date = parseISO(dateStr);
  if (isToday(date)) return format(date, 'HH:mm');
  if (isYesterday(date)) return 'Вчера';
  return format(date, 'dd.MM.yy');
}

export function ConversationThreadsPanel({
  conversationId,
  currentUser,
  allUsers,
  onAfterThreadNavigate,
}: {
  conversationId: string;
  currentUser: User;
  allUsers: User[];
  onAfterThreadNavigate?: () => void;
}) {
  const router = useRouter();
  const firestore = useFirestore();

  const messagesQuery = useMemoFirebase(
    () =>
      firestore && conversationId
        ? query(
            collection(firestore, `conversations/${conversationId}/messages`),
            orderBy('createdAt', 'desc'),
            limit(500)
          )
        : null,
    [firestore, conversationId]
  );

  const { data: rows, isLoading } = useCollection<ChatMessage>(messagesQuery);
  const messages = useMemo(() => {
    const r = rows ?? [];
    return [...r].reverse();
  }, [rows]);

  const { threadMessages } = useMemo(() => categorizeAttachmentsFromMessages(messages), [messages]);

  const openThread = (msg: ChatMessage) => {
    router.push(
      buildDashboardChatOpenUrl(conversationId, { threadRootMessageId: msg.id })
    );
    onAfterThreadNavigate?.();
  };

  return (
    <>
      {isLoading && !rows ? (
        <p className="text-sm text-zinc-500">Загрузка…</p>
      ) : threadMessages.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-16 text-zinc-500">
          <MessageSquare className="mb-2 h-10 w-10 opacity-60" />
          <p className="text-xs font-medium">Обсуждений пока нет</p>
        </div>
      ) : (
        <div className="space-y-2">
          {threadMessages.map((msg) => {
            const unreadCount = msg.unreadThreadCounts?.[currentUser.id] || 0;
            const lastSender = allUsers.find((u) => u.id === msg.lastThreadMessageSenderId);
            const lastSenderName = lastSender
              ? lastSender.id === currentUser.id
                ? 'Вы'
                : lastSender.name.split(' ')[0]
              : 'Участник';

            return (
              <button
                key={msg.id}
                type="button"
                onClick={() => openThread(msg)}
                className="flex w-full min-w-0 items-start gap-3 rounded-3xl border border-zinc-800/60 bg-zinc-900/40 p-4 text-left shadow-sm transition-all hover:border-zinc-700 hover:bg-zinc-900/70 active:scale-[0.98]"
              >
                <div className="shrink-0 rounded-2xl bg-emerald-600/15 p-3">
                  <MessageSquare className="h-5 w-5 text-emerald-400" />
                </div>
                <div className="min-w-0 flex-1">
                  <div
                    className="mb-1 break-words text-sm font-bold leading-tight break-all text-zinc-100 [&_p]:m-0 [&_p]:inline"
                    dangerouslySetInnerHTML={{
                      __html: msg.text ? sanitizeMessageHtml(msg.text) : 'Вложение',
                    }}
                  />
                  {msg.lastThreadMessageText && (
                    <p className="mb-2 line-clamp-2 break-all text-xs text-zinc-500">
                      <span className="font-semibold text-zinc-400">{lastSenderName}:</span>{' '}
                      {msg.lastThreadMessageText}
                    </p>
                  )}
                  <div className="flex flex-wrap items-center justify-between gap-2">
                    <div className="flex flex-wrap items-center gap-2">
                      <Badge
                        variant="secondary"
                        className="h-5 rounded-full border-none bg-emerald-600 px-2 text-[10px] font-bold uppercase tracking-tight text-white shadow-none"
                      >
                        {msg.threadCount ?? 0}{' '}
                        {(msg.threadCount ?? 0) === 1
                          ? 'ответ'
                          : [2, 3, 4].includes((msg.threadCount ?? 0) % 10)
                            ? 'ответа'
                            : 'ответов'}
                      </Badge>
                      {unreadCount > 0 && (
                        <Badge className="h-5 animate-in zoom-in-50 rounded-full border-none bg-red-500 px-2 text-[10px] font-bold text-white shadow-none">
                          +{unreadCount}
                        </Badge>
                      )}
                    </div>
                    <span className="text-[10px] font-bold uppercase text-zinc-500">
                      {formatLastThreadTime(msg.lastThreadMessageTimestamp || msg.createdAt)}
                    </span>
                  </div>
                </div>
              </button>
            );
          })}
        </div>
      )}
    </>
  );
}
