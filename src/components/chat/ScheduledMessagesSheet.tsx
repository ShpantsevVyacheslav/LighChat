'use client';

import React, { useMemo, useState } from 'react';
import { format, formatDistanceToNow, parseISO } from 'date-fns';
import { ru } from 'date-fns/locale';
import {
  collection,
  deleteDoc,
  doc,
  orderBy,
  query,
  updateDoc,
  where,
} from 'firebase/firestore';
import { useCollection, useFirestore, useMemoFirebase } from '@/firebase';
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
} from '@/components/ui/sheet';
import { Button } from '@/components/ui/button';
import { ScrollArea } from '@/components/ui/scroll-area';
import { useToast } from '@/hooks/use-toast';
import {
  CalendarClock,
  Loader2,
  Pencil,
  Trash2,
  Paperclip,
  Reply,
  ShieldAlert,
} from 'lucide-react';
import type { ScheduledChatMessage } from '@/lib/types';
import { ChatScheduleMessageDialog } from '@/components/chat/ChatScheduleMessageDialog';

function previewText(msg: ScheduledChatMessage): string {
  if (msg.pendingPoll) return '📊 Опрос: ' + msg.pendingPoll.question;
  if (msg.locationShare) return '📍 Локация';
  if (msg.text) {
    const stripped = msg.text.replace(/<[^>]*>/g, '').replace(/&nbsp;/g, ' ').trim();
    if (stripped.length > 0) return stripped;
  }
  if (msg.attachments && msg.attachments.length > 0) {
    return `📎 Вложение${msg.attachments.length > 1 ? ` (×${msg.attachments.length})` : ''}`;
  }
  return 'Сообщение';
}

interface Props {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  conversationId: string;
  currentUserId: string;
  e2eeEnabled?: boolean;
}

export function ScheduledMessagesSheet({
  open,
  onOpenChange,
  conversationId,
  currentUserId,
  e2eeEnabled,
}: Props) {
  const firestore = useFirestore();
  const { toast } = useToast();
  const [editing, setEditing] = useState<ScheduledChatMessage | null>(null);
  const [pendingDeleteId, setPendingDeleteId] = useState<string | null>(null);

  const scheduledQuery = useMemoFirebase(
    () =>
      firestore && currentUserId && open
        ? query(
            collection(firestore, `conversations/${conversationId}/scheduledMessages`),
            where('senderId', '==', currentUserId),
            where('status', '==', 'pending'),
            orderBy('sendAt', 'asc'),
          )
        : null,
    [firestore, conversationId, currentUserId, open],
  );
  const { data: scheduledRaw, isLoading } = useCollection<ScheduledChatMessage>(scheduledQuery);

  const items: ScheduledChatMessage[] = useMemo(
    () =>
      (scheduledRaw ?? []).map((d) => ({
        ...d,
        id: (d as ScheduledChatMessage).id ?? '',
      })),
    [scheduledRaw],
  );

  const handleDelete = async (id: string) => {
    if (!firestore) return;
    setPendingDeleteId(id);
    try {
      await deleteDoc(doc(firestore, `conversations/${conversationId}/scheduledMessages`, id));
      toast({ title: 'Запланированное сообщение отменено' });
    } catch (e) {
      toast({
        variant: 'destructive',
        title: 'Не удалось отменить',
        description: e instanceof Error ? e.message : String(e),
      });
    } finally {
      setPendingDeleteId(null);
    }
  };

  const handleReschedule = async (sendAt: Date) => {
    if (!firestore || !editing) return;
    try {
      await updateDoc(doc(firestore, `conversations/${conversationId}/scheduledMessages`, editing.id), {
        sendAt: sendAt.toISOString(),
        updatedAt: new Date().toISOString(),
      });
      toast({
        title: 'Время отправки изменено',
        description: format(sendAt, 'd MMMM yyyy, HH:mm', { locale: ru }),
      });
    } catch (e) {
      toast({
        variant: 'destructive',
        title: 'Не удалось перенести',
        description: e instanceof Error ? e.message : String(e),
      });
    }
  };

  return (
    <>
      <Sheet open={open} onOpenChange={onOpenChange}>
        <SheetContent side="right" className="w-full sm:max-w-md p-0">
          <SheetHeader className="px-4 py-3 border-b">
            <SheetTitle className="flex items-center gap-2">
              <CalendarClock className="h-5 w-5 text-primary" />
              Запланированные сообщения
              {items.length > 0 && (
                <span className="ml-1 inline-flex h-5 min-w-5 items-center justify-center rounded-full bg-primary/15 px-1.5 text-xs font-semibold text-primary">
                  {items.length}
                </span>
              )}
            </SheetTitle>
          </SheetHeader>

          <ScrollArea className="h-[calc(100vh-64px)] px-4 py-3">
            {isLoading && (
              <div className="flex justify-center py-10 text-muted-foreground">
                <Loader2 className="h-5 w-5 animate-spin" />
              </div>
            )}
            {!isLoading && items.length === 0 && (
              <div className="text-center text-sm text-muted-foreground py-10">
                Нет запланированных сообщений в этом чате.
                <br />
                <span className="text-xs">
                  Удерживайте кнопку «Отправить», чтобы запланировать.
                </span>
              </div>
            )}

            <ul className="space-y-2">
              {items.map((m) => {
                let sendAtDate: Date | null = null;
                try {
                  sendAtDate = typeof m.sendAt === 'string' ? parseISO(m.sendAt) : null;
                } catch {
                  sendAtDate = null;
                }
                const sendAtFormatted = sendAtDate
                  ? format(sendAtDate, 'd MMMM yyyy, HH:mm', { locale: ru })
                  : '—';
                const distanceText = sendAtDate
                  ? formatDistanceToNow(sendAtDate, { locale: ru, addSuffix: true })
                  : '';

                return (
                  <li
                    key={m.id}
                    className="rounded-xl border bg-card p-3 shadow-sm"
                  >
                    <div className="flex items-start justify-between gap-2">
                      <div className="min-w-0 flex-1">
                        <div className="text-xs text-primary font-medium flex items-center gap-1">
                          <CalendarClock className="h-3.5 w-3.5" />
                          {sendAtFormatted}
                          <span className="text-muted-foreground font-normal">
                            · {distanceText}
                          </span>
                        </div>
                        <div className="mt-1.5 text-sm text-foreground line-clamp-3 break-words">
                          {previewText(m)}
                        </div>
                        <div className="mt-1.5 flex flex-wrap items-center gap-2 text-[11px] text-muted-foreground">
                          {m.replyTo && (
                            <span className="inline-flex items-center gap-1">
                              <Reply className="h-3 w-3" />
                              ответ {m.replyTo.senderName ? `«${m.replyTo.senderName}»` : ''}
                            </span>
                          )}
                          {m.attachments && m.attachments.length > 0 && (
                            <span className="inline-flex items-center gap-1">
                              <Paperclip className="h-3 w-3" />
                              {m.attachments.length}
                            </span>
                          )}
                        </div>
                      </div>
                      <div className="flex shrink-0 flex-col gap-1">
                        <Button
                          variant="ghost"
                          size="icon"
                          className="h-8 w-8"
                          onClick={() => setEditing(m)}
                          title="Изменить время"
                        >
                          <Pencil className="h-4 w-4" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          className="h-8 w-8 text-destructive hover:text-destructive"
                          onClick={() => handleDelete(m.id)}
                          disabled={pendingDeleteId === m.id}
                          title="Отменить"
                        >
                          {pendingDeleteId === m.id ? (
                            <Loader2 className="h-4 w-4 animate-spin" />
                          ) : (
                            <Trash2 className="h-4 w-4" />
                          )}
                        </Button>
                      </div>
                    </div>
                  </li>
                );
              })}
            </ul>

            {e2eeEnabled && items.length > 0 && (
              <div className="mt-4 rounded-lg border border-amber-500/40 bg-amber-500/10 p-3 text-[11px] text-amber-900 dark:text-amber-200 flex gap-2">
                <ShieldAlert className="h-4 w-4 mt-0.5 shrink-0" />
                <span>
                  В E2EE-чате запланированные сообщения хранятся и публикуются
                  в открытом виде.
                </span>
              </div>
            )}
          </ScrollArea>
        </SheetContent>
      </Sheet>

      {editing && (
        <ChatScheduleMessageDialog
          open={!!editing}
          onOpenChange={(o) => !o && setEditing(null)}
          initialSendAt={(() => {
            try {
              return typeof editing.sendAt === 'string' ? parseISO(editing.sendAt) : null;
            } catch {
              return null;
            }
          })()}
          showE2eeWarning={e2eeEnabled}
          confirmLabel="Сохранить"
          onConfirm={handleReschedule}
        />
      )}
    </>
  );
}
