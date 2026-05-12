'use client';

/**
 * [audit M-009] Извлечён из `ChatWindow.tsx` — самое крупное скопление
 * thread-panel state'а:
 *  - 4 useState'а (selectedMessage / panelWidth / isExpanded / reactionScrollToId)
 *  - useRef для guarding drag-resize'а
 *  - 2 useEffect'а на load/save localStorage (width + expanded)
 *  - 1 useEffect на URL-init (open thread by `threadRootMessageId`)
 *  - 30-строчный startResize callback
 *  - resetForConversationSwitch для outer'ного «конверсация переключилась» effect'а
 *  - openByMessageId для navigate-to-reaction (fetch parent + open)
 *
 * ChatWindow дальше:
 *  - читает `threadPanel.selectedMessage` для рендера ThreadWindow и для
 *    «есть ли поверх контента модалка/панель» проверок
 *  - вызывает `threadPanel.open(msg)` из onOpenThread (клик в bubble)
 *  - вызывает `threadPanel.resetForConversationSwitch()` из своего switch-эффекта
 *  - пробрасывает `startResize`, `toggleExpanded`, `panelWidth`, `isExpanded`,
 *    `selectedMessage`, `reactionScrollToId` в JSX
 */

import { useCallback, useEffect, useRef, useState } from 'react';
import { doc, getDoc, type Firestore } from 'firebase/firestore';
import type { ChatMessage } from '@/lib/types';
import { logger } from '@/lib/logger';

const PANEL_WIDTH_DEFAULT = 520;
const PANEL_WIDTH_MIN = 420;
const PANEL_WIDTH_MAX_FALLBACK = 1180;
const PANEL_WIDTH_MAX_RATIO = 0.78;
const STORAGE_KEY_WIDTH = 'chat_thread_panel_width';
const STORAGE_KEY_EXPANDED = 'chat_thread_panel_expanded';

type ToastFn = (opts: {
  title: string;
  description?: string;
  variant?: 'default' | 'destructive';
}) => void;
type TFn = (key: string, params?: Record<string, string | number>) => string;

export type ChatThreadPanel = {
  selectedMessage: ChatMessage | null;
  panelWidth: number;
  isExpanded: boolean;
  reactionScrollToId: string | null;
  /** Открыть thread по уже загруженному ChatMessage (клик «Reply in thread»). */
  open: (message: ChatMessage) => void;
  /** Открыть thread по messageId — fetch parent doc, тост на not-found. */
  openByMessageId: (messageId: string, scrollToReactionMessageId?: string | null) => Promise<void>;
  /** Закрыть панель (сбрасывает scroll-target тоже). */
  close: () => void;
  /** Установить highlight для конкретного сообщения внутри thread. */
  setReactionScrollTarget: (messageId: string) => void;
  /** Сбросить highlight (после consume в ThreadWindow). */
  clearReactionScrollTarget: () => void;
  /** Resize handle: drag mouse/touch на левой границе панели. */
  startResize: (startX: number) => void;
  /** Toggle expanded (full-width) режима. */
  toggleExpanded: () => void;
  /** Очистить все state thread-panel — для outer'ного «convo switch» effect'а. */
  resetForConversationSwitch: () => void;
};

export function useChatThreadPanel(opts: {
  firestore: Firestore | null;
  conversationId: string;
  /** URL-init: открыть thread с этим parent-id один раз. */
  threadRootMessageId?: string | null;
  onThreadRootMessageConsumed?: () => void;
  toast: ToastFn;
  t: TFn;
}): ChatThreadPanel {
  const { firestore, conversationId, threadRootMessageId, onThreadRootMessageConsumed, toast, t } =
    opts;

  const [selectedMessage, setSelectedMessage] = useState<ChatMessage | null>(null);
  const [panelWidth, setPanelWidth] = useState<number>(PANEL_WIDTH_DEFAULT);
  const [isExpanded, setIsExpanded] = useState(false);
  const [reactionScrollToId, setReactionScrollToId] = useState<string | null>(null);
  const resizingRef = useRef(false);

  // localStorage: load on mount.
  useEffect(() => {
    if (typeof window === 'undefined') return;
    const storedWidth = Number(window.localStorage.getItem(STORAGE_KEY_WIDTH) ?? '');
    if (
      Number.isFinite(storedWidth)
      && storedWidth >= PANEL_WIDTH_MIN
      && storedWidth <= 1280
    ) {
      setPanelWidth(storedWidth);
    }
    const storedExpanded = window.localStorage.getItem(STORAGE_KEY_EXPANDED);
    if (storedExpanded === '1') setIsExpanded(true);
  }, []);

  // localStorage: persist width + expanded.
  useEffect(() => {
    if (typeof window === 'undefined') return;
    window.localStorage.setItem(STORAGE_KEY_WIDTH, String(Math.round(panelWidth)));
  }, [panelWidth]);
  useEffect(() => {
    if (typeof window === 'undefined') return;
    window.localStorage.setItem(STORAGE_KEY_EXPANDED, isExpanded ? '1' : '0');
  }, [isExpanded]);

  // URL-init: открыть thread по threadRootMessageId. Идемпотентно через handled-ref.
  const handledThreadRootRef = useRef<string | null>(null);
  useEffect(() => {
    handledThreadRootRef.current = null;
  }, [threadRootMessageId, conversationId]);

  useEffect(() => {
    if (!firestore || !conversationId || !threadRootMessageId) return;
    if (handledThreadRootRef.current === threadRootMessageId) return;
    handledThreadRootRef.current = threadRootMessageId;
    const convId = conversationId;
    const rootId = threadRootMessageId;
    let cancelled = false;
    void getDoc(doc(firestore, `conversations/${convId}/messages`, rootId))
      .then((snap) => {
        if (cancelled) return;
        if (!snap.exists()) {
          toast({ title: t('chat.threadNotFound') });
          onThreadRootMessageConsumed?.();
          return;
        }
        setSelectedMessage({ ...snap.data(), id: snap.id } as ChatMessage);
        onThreadRootMessageConsumed?.();
      })
      .catch((e) => {
        logger.warn('thread-panel', 'open thread from URL failed', e);
        if (!cancelled) {
          toast({ title: t('chat.threadOpenError'), variant: 'destructive' });
          onThreadRootMessageConsumed?.();
        }
      });
    return () => {
      cancelled = true;
      if (handledThreadRootRef.current === rootId) handledThreadRootRef.current = null;
    };
  }, [firestore, conversationId, threadRootMessageId, toast, t, onThreadRootMessageConsumed]);

  const open = useCallback((message: ChatMessage) => {
    setSelectedMessage(message);
  }, []);

  const openByMessageId = useCallback(
    async (messageId: string, scrollToReactionMessageId: string | null = null) => {
      if (!firestore) return;
      const parentRef = doc(firestore, `conversations/${conversationId}/messages`, messageId);
      const snap = await getDoc(parentRef);
      if (!snap.exists()) {
        toast({ title: t('chat.threadNotFound') });
        return;
      }
      if (scrollToReactionMessageId) setReactionScrollToId(scrollToReactionMessageId);
      setSelectedMessage({ ...snap.data(), id: snap.id } as ChatMessage);
    },
    [firestore, conversationId, toast, t],
  );

  const close = useCallback(() => {
    setSelectedMessage(null);
    setReactionScrollToId(null);
  }, []);

  const setReactionScrollTarget = useCallback((messageId: string) => {
    setReactionScrollToId(messageId);
  }, []);
  const clearReactionScrollTarget = useCallback(() => setReactionScrollToId(null), []);

  const toggleExpanded = useCallback(() => setIsExpanded((v) => !v), []);

  const startResize = useCallback(
    (startX: number) => {
      if (typeof window === 'undefined') return;
      resizingRef.current = true;
      const startWidth = panelWidth;
      document.body.style.cursor = 'col-resize';
      document.body.style.userSelect = 'none';
      const minWidth = PANEL_WIDTH_MIN;
      const maxWidth = Math.min(
        Math.floor(window.innerWidth * PANEL_WIDTH_MAX_RATIO),
        PANEL_WIDTH_MAX_FALLBACK,
      );

      const onMove = (clientX: number) => {
        if (!resizingRef.current) return;
        // Ручка на левой границе панели: тянем влево => панель шире.
        const delta = startX - clientX;
        setIsExpanded(false);
        setPanelWidth(Math.max(minWidth, Math.min(maxWidth, startWidth + delta)));
      };

      const onEnd = () => {
        resizingRef.current = false;
        document.body.style.cursor = '';
        document.body.style.userSelect = '';
        document.removeEventListener('mousemove', onMouseMove);
        document.removeEventListener('mouseup', onEnd);
        document.removeEventListener('touchmove', onTouchMove);
        document.removeEventListener('touchend', onEnd);
      };

      const onMouseMove = (e: MouseEvent) => onMove(e.clientX);
      const onTouchMove = (e: TouchEvent) => onMove(e.touches[0].clientX);

      document.addEventListener('mousemove', onMouseMove);
      document.addEventListener('mouseup', onEnd);
      document.addEventListener('touchmove', onTouchMove, { passive: true });
      document.addEventListener('touchend', onEnd);
    },
    [panelWidth],
  );

  const resetForConversationSwitch = useCallback(() => {
    setSelectedMessage(null);
    setReactionScrollToId(null);
    handledThreadRootRef.current = null;
  }, []);

  return {
    selectedMessage,
    panelWidth,
    isExpanded,
    reactionScrollToId,
    open,
    openByMessageId,
    close,
    setReactionScrollTarget,
    clearReactionScrollTarget,
    startResize,
    toggleExpanded,
    resetForConversationSwitch,
  };
}
