'use client';

/**
 * [audit M-009] Извлечён из `ChatWindow.tsx`. Раньше:
 *  - useMemoFirebase + useCollection для pending-count (4 строки)
 *  - 60-строчный `handleScheduleMessage` useCallback с upload + Firestore
 *    setDoc + toast.
 *
 * Теперь хук возвращает `{ pendingCount, scheduleSend(args) }` — UI
 * чат-окна цепляет к badge и `<ChatScheduleMessageDialog onScheduleMessage>`.
 *
 * Pending-count: Firestore listener на
 * `conversations/{cid}/scheduledMessages` where senderId == me, status ==
 * pending. Реалтайм — после `sendAt` сервер меняет статус и счётчик
 * автоматически уменьшается.
 */

import { useCallback } from 'react';
import {
  collection,
  doc,
  query,
  setDoc,
  where,
  type Firestore,
} from 'firebase/firestore';
import type { FirebaseStorage } from 'firebase/storage';
import { format } from 'date-fns';
import { ru } from 'date-fns/locale';
import { useCollection, useMemoFirebase } from '@/firebase';
import type { ChatAttachment, ReplyContext } from '@/lib/types';
import { logger } from '@/lib/logger';

type ToastFn = (opts: {
  title: string;
  description?: string;
  variant?: 'default' | 'destructive';
}) => void;

type TFn = (key: string, params?: Record<string, string | number>) => string;

export type ScheduleSendArgs = {
  text: string | undefined;
  files: File[];
  replyContext: ReplyContext | null;
  prebuilt: ChatAttachment[] | undefined;
  sendAt: Date;
};

export type ScheduledMessages = {
  /** Количество pending-сообщений у текущего юзера в этом чате. */
  pendingCount: number;
  /** Создать запись в `scheduledMessages` (с upload вложений если нужно). */
  scheduleSend: (args: ScheduleSendArgs) => Promise<void>;
};

export function useScheduledMessages(opts: {
  firestore: Firestore | null;
  storage: FirebaseStorage | null;
  conversationId: string;
  currentUserId: string | null;
  toast: ToastFn;
  t: TFn;
}): ScheduledMessages {
  const { firestore, storage, conversationId, currentUserId, toast, t } = opts;

  const pendingQuery = useMemoFirebase(
    () =>
      firestore && currentUserId
        ? query(
            collection(firestore, `conversations/${conversationId}/scheduledMessages`),
            where('senderId', '==', currentUserId),
            where('status', '==', 'pending'),
          )
        : null,
    [firestore, conversationId, currentUserId],
  );
  const { data: pendingDocs } = useCollection(pendingQuery);
  const pendingCount = pendingDocs?.length ?? 0;

  const scheduleSend = useCallback(
    async (args: ScheduleSendArgs) => {
      const { text, files, replyContext, prebuilt, sendAt } = args;
      if (!firestore || !currentUserId) return;
      const trimmedText = typeof text === 'string' ? text : undefined;
      const hasText =
        !!trimmedText
        && trimmedText.replace(/<[^>]*>/g, '').replace(/&nbsp;/g, ' ').trim().length > 0;
      if (!hasText && (!files || files.length === 0) && (!prebuilt || prebuilt.length === 0)) {
        return;
      }

      const scheduledCollection = collection(
        firestore,
        `conversations/${conversationId}/scheduledMessages`,
      );
      const newDocRef = doc(scheduledCollection);
      const nowIso = new Date().toISOString();
      const sendAtIso = sendAt.toISOString();

      try {
        const uploadedAttachments: ChatAttachment[] = [...(prebuilt ?? [])];
        if (files && files.length > 0) {
          if (!storage) {
            // Без storage не может быть аплоада — но текстовый payload ниже
            // спокойно сохранится. Сообщим toast'ом, чтобы юзер не молча
            // потерял вложения.
            toast({
              variant: 'destructive',
              title: t('chat.scheduleMessageFailed'),
              description: 'Storage unavailable',
            });
            throw new Error('NO_STORAGE');
          }
          // Динамический импорт — чтобы хук не зависел жёстко от
          // ChatMessageInput.tsx (циклы импортов в ChatWindow chain).
          const { uploadFile: internalUpload } = await import(
            '@/components/chat/ChatMessageInput'
          );
          for (const file of files) {
            const path = `chat-attachments/${conversationId}/scheduled-${Date.now()}-${file.name.replace(/\s+/g, '_')}`;
            const uploaded = await internalUpload(file, path, storage);
            uploadedAttachments.push(uploaded);
          }
        }

        const payload: Record<string, unknown> = {
          senderId: currentUserId,
          status: 'pending',
          scheduledAt: nowIso,
          sendAt: sendAtIso,
          createdAt: nowIso,
        };
        if (hasText && trimmedText) payload.text = trimmedText;
        if (uploadedAttachments.length > 0) payload.attachments = uploadedAttachments;
        if (replyContext) payload.replyTo = replyContext;

        await setDoc(newDocRef, payload as Parameters<typeof setDoc>[1]);

        toast({
          title: t('chat.messageScheduled'),
          description: format(sendAt, 'd MMMM yyyy, HH:mm', { locale: ru }),
        });
      } catch (e) {
        logger.error('scheduled-msgs', 'schedule failed', e);
        toast({
          variant: 'destructive',
          title: t('chat.scheduleMessageFailed'),
          description: e instanceof Error ? e.message : String(e),
        });
        throw e;
      }
    },
    [firestore, currentUserId, conversationId, storage, toast, t],
  );

  return { pendingCount, scheduleSend };
}
