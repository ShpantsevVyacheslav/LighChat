'use client';

/**
 * Reactive подписка на persistent IndexedDB-кеш последнего расшифрованного
 * текста для конкретного чата. Используется в `ConversationItem`, чтобы в
 * списке чатов вместо плейсхолдера «Зашифрованное сообщение» (которое
 * Firestore хранит специально, чтобы сервер не видел plaintext) показать
 * настоящий текст — но только на тех устройствах, где сообщение уже было
 * расшифровано (открывали чат / сами отправляли).
 *
 * Hook следит за `lighchat:e2ee-preview-changed` (диспатчится из
 * `putCachedConversationPreview`), чтобы при отправке нового сообщения
 * сайдбар обновился без перерендера всей конвы.
 */

import { useEffect, useState } from 'react';
import {
  getCachedConversationPreview,
  subscribeConversationPreviewChanges,
  type ConversationPreviewRecord,
} from '@/lib/e2ee/plaintext-cache';

export function useCachedConversationPreview(
  conversationId: string | null | undefined
): ConversationPreviewRecord | null {
  const [record, setRecord] = useState<ConversationPreviewRecord | null>(null);

  useEffect(() => {
    if (!conversationId) {
      setRecord(null);
      return;
    }
    let cancelled = false;
    void getCachedConversationPreview(conversationId).then((value) => {
      if (!cancelled) setRecord(value ?? null);
    });
    const unsubscribe = subscribeConversationPreviewChanges((cid, next) => {
      if (cid !== conversationId) return;
      setRecord(next);
    });
    return () => {
      cancelled = true;
      unsubscribe();
    };
  }, [conversationId]);

  return record;
}
