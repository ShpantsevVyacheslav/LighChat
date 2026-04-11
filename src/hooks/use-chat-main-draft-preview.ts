'use client';

import { useEffect, useMemo, useState } from 'react';
import {
  CHAT_MESSAGE_DRAFT_CHANGED_EVENT,
  chatDraftPlainFromHtml,
  chatDraftStorageKey,
  getMainChatDraftForList,
} from '@/lib/chat-message-draft-storage';

export type ChatMainDraftPreview = {
  hasDraft: boolean;
  /** Короткая строка для подписи в списке чатов */
  preview: string;
};

/**
 * Превью черновика основного чата (не тред) для строки в списке бесед.
 * Обновляется при сохранении/очистке черновика в этой беседе.
 */
export function useChatMainDraftPreview(
  userId: string | undefined,
  conversationId: string
): ChatMainDraftPreview {
  const [version, setVersion] = useState(0);

  useEffect(() => {
    const onChanged = (e: Event) => {
      const detail = (e as CustomEvent<{ conversationId?: string }>).detail;
      if (detail?.conversationId === conversationId) {
        setVersion((v) => v + 1);
      }
    };
    window.addEventListener(CHAT_MESSAGE_DRAFT_CHANGED_EVENT, onChanged as EventListener);
    return () => window.removeEventListener(CHAT_MESSAGE_DRAFT_CHANGED_EVENT, onChanged as EventListener);
  }, [conversationId]);

  useEffect(() => {
    if (!userId) return;
    const storageKey = chatDraftStorageKey(userId);
    const onStorage = (e: StorageEvent) => {
      if (e.key === storageKey) setVersion((v) => v + 1);
    };
    window.addEventListener('storage', onStorage);
    return () => window.removeEventListener('storage', onStorage);
  }, [userId]);

  return useMemo(() => {
    if (!userId) return { hasDraft: false, preview: '' };
    const d = getMainChatDraftForList(userId, conversationId);
    if (!d) return { hasDraft: false, preview: '' };
    const plain = chatDraftPlainFromHtml(d.html);
    const hasReply = !!d.replyTo;
    if (!plain && !hasReply) return { hasDraft: false, preview: '' };
    const preview =
      plain.length > 0
        ? plain.length > 72
          ? `${plain.slice(0, 72)}…`
          : plain
        : d.replyTo?.text
          ? chatDraftPlainFromHtml(d.replyTo.text).slice(0, 72)
          : 'Ответ';
    return { hasDraft: true, preview };
  }, [userId, conversationId, version]);
}
