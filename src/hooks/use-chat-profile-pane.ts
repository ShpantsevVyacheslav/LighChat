'use client';

/**
 * [audit M-009] Извлечён из `ChatWindow.tsx` (4 useState'а + 4 callback'а
 * + URL-init useEffect, итого ~50 строк inline-state).
 *
 * Управляет состоянием правой панели профиля чат-собеседника:
 * открыта / какой подменю / на ком фокус / откуда открыта
 * (`'chat' | 'mention' | 'sender' | 'contacts'`).
 *
 * Все «открытия» атомарно сбрасывают остальные поля (так чтобы старая
 * focus/source не утекала в новый контекст). Закрытие через
 * `onOpenChange(false)` чистит focus/subMenu/source за один батч.
 *
 * URL-init: если родитель пробросил `initialProfile{Open,FocusUserId,Source}`,
 * хук разово открывает панель и зовёт `onInitialProfileConsumed?.()` —
 * это сбрасывает query-параметры в URL, чтобы повторный mount не
 * переоткрывал.
 */

import { useCallback, useEffect, useState } from 'react';
import type {
  ChatProfileSource,
  ChatProfileSubMenu,
} from '@/components/chat/ChatParticipantProfile';

export type ChatProfilePane = {
  isOpen: boolean;
  initialSubMenu: ChatProfileSubMenu | null;
  focusUserId: string | null;
  source: ChatProfileSource;
  /** Колбэк для `<Sheet onOpenChange>` — закрытие чистит focus/subMenu/source. */
  onOpenChange: (open: boolean) => void;
  /** Открыть из шапки чата. По умолчанию — без под-меню (общая карточка чата); */
  /** для клика «обсуждения» передать `subMenu = 'threads'`. */
  openFromHeader: (subMenu?: ChatProfileSubMenu | null) => void;
  /** Сахар: `openFromHeader('threads')`. Сохранён для совместимости. */
  openThreadsFromHeader: () => void;
  /** @-mention в сообщении: открыть профиль участника, если он ещё в чате. */
  openMentionProfile: (userId: string) => void;
  /** Аватар отправителя в группе: то же, но с `source = 'sender'`. */
  openGroupSenderProfile: (userId: string) => void;
  /** Сбросить только focus (например, после открытия диалога «написать в личку»). */
  clearFocus: () => void;
  /** Сбросить initialSubMenu (вызывается панелью после `useEffect`-консьюма). */
  clearInitialSubMenu: () => void;
};

export function useChatProfilePane(opts: {
  participantIds: string[];
  initialOpen?: boolean;
  initialFocusUserId?: string | null;
  initialSource?: ChatProfileSource | null;
  onInitialConsumed?: () => void;
}): ChatProfilePane {
  const {
    participantIds,
    initialOpen = false,
    initialFocusUserId = null,
    initialSource = null,
    onInitialConsumed,
  } = opts;

  const [isOpen, setIsOpen] = useState(false);
  const [initialSubMenu, setInitialSubMenu] = useState<ChatProfileSubMenu | null>(null);
  const [focusUserId, setFocusUserId] = useState<string | null>(null);
  const [source, setSource] = useState<ChatProfileSource>('chat');

  const onOpenChange = useCallback((open: boolean) => {
    setIsOpen(open);
    if (!open) {
      setInitialSubMenu(null);
      setFocusUserId(null);
      setSource('chat');
    }
  }, []);

  const openFromHeader = useCallback((subMenu: ChatProfileSubMenu | null = null) => {
    setFocusUserId(null);
    setSource('chat');
    setInitialSubMenu(subMenu);
    setIsOpen(true);
  }, []);
  const openThreadsFromHeader = useCallback(() => openFromHeader('threads'), [openFromHeader]);

  const openMentionProfile = useCallback(
    (userId: string) => {
      if (!participantIds.includes(userId)) return;
      setFocusUserId(userId);
      setSource('mention');
      setIsOpen(true);
    },
    [participantIds],
  );

  const openGroupSenderProfile = useCallback(
    (userId: string) => {
      if (!participantIds.includes(userId)) return;
      setFocusUserId(userId);
      setSource('sender');
      setIsOpen(true);
    },
    [participantIds],
  );

  const clearFocus = useCallback(() => setFocusUserId(null), []);
  const clearInitialSubMenu = useCallback(() => setInitialSubMenu(null), []);

  useEffect(() => {
    if (!initialOpen) return;
    const incomingUserId =
      initialFocusUserId && participantIds.includes(initialFocusUserId)
        ? initialFocusUserId
        : null;
    setFocusUserId(incomingUserId);
    setSource(initialSource ?? 'chat');
    setInitialSubMenu(null);
    setIsOpen(true);
    onInitialConsumed?.();
  }, [initialOpen, initialFocusUserId, initialSource, participantIds, onInitialConsumed]);

  return {
    isOpen,
    initialSubMenu,
    focusUserId,
    source,
    onOpenChange,
    openFromHeader,
    openThreadsFromHeader,
    openMentionProfile,
    openGroupSenderProfile,
    clearFocus,
    clearInitialSubMenu,
  };
}
