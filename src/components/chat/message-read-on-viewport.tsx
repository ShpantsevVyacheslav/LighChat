'use client';

import React, {
  createContext,
  useContext,
  useEffect,
  useRef,
  type MutableRefObject,
  type ReactNode,
} from 'react';
import type { Firestore } from 'firebase/firestore';
import type { ChatMessage } from '@/lib/types';
import { markMessagesAsRead } from '@/lib/chat-utils';
import { isIncomingUnreadForViewer } from '@/lib/message-read-status';

/** Ref на DOM-скроллер Virtuoso (см. prop scrollerRef) — root для IntersectionObserver. */
export const ChatViewportScrollerRefContext = createContext<MutableRefObject<HTMLElement | null> | null>(
  null
);

export function useChatViewportScrollerRef(): MutableRefObject<HTMLElement | null> | null {
  return useContext(ChatViewportScrollerRefContext);
}

export type MessageReadOnViewportProps = {
  messageId: string;
  message: Pick<ChatMessage, 'senderId' | 'readAt'>;
  currentUserId: string;
  conversationId: string;
  firestore: Firestore | null;
  /** До завершения стартового скролла к непрочитанным — не помечать (как hasScrolledToUnread). */
  canMarkReadByViewport: boolean;
  /** Увеличивается при первом/monтировании scrollerRef Virtuoso — пересоздаёт Observer, т.к. ref.current не триггерит рендер. */
  viewportLayoutKey: number;
  sessionReadIds: MutableRefObject<Set<string>>;
  isThread?: boolean;
  threadParentId?: string;
  children: ReactNode;
};

/**
 * Помечает входящее сообщение прочитанным, когда строка реально пересекает видимую область скроллера.
 * Не зависит от overscan / increaseViewportBy у Virtuoso (в отличие от slice по rangeChanged).
 */
export function MessageReadOnViewport({
  messageId,
  message,
  currentUserId,
  conversationId,
  firestore,
  canMarkReadByViewport,
  viewportLayoutKey,
  sessionReadIds,
  isThread = false,
  threadParentId,
  children,
}: MessageReadOnViewportProps) {
  const scrollerRef = useChatViewportScrollerRef();
  const wrapRef = useRef<HTMLDivElement>(null);
  useEffect(() => {
    const root = scrollerRef?.current ?? null;
    const el = wrapRef.current;
    if (!canMarkReadByViewport || !root || !el || !firestore) return;
    if (!isIncomingUnreadForViewer(message, currentUserId)) return;

    const tryMark = () => {
      if (!firestore) return;
      if (!isIncomingUnreadForViewer(message, currentUserId)) return;
      if (sessionReadIds.current.has(messageId)) return;
      sessionReadIds.current.add(messageId);
      void markMessagesAsRead(
        firestore,
        conversationId,
        currentUserId,
        [messageId],
        isThread,
        threadParentId
      ).catch((e) => {
        console.error('[MessageReadOnViewport] mark read failed', e);
        sessionReadIds.current.delete(messageId);
      });
    };

    let observer: IntersectionObserver;
    try {
      observer = new IntersectionObserver(
        (entries) => {
          const visible = entries.some((e) => e.isIntersecting && e.intersectionRatio >= 0.12);
          if (visible) tryMark();
        },
        { root, rootMargin: '0px', threshold: [0, 0.12, 0.35, 0.6] }
      );
      observer.observe(el);
    } catch (e) {
      console.warn('[MessageReadOnViewport] IntersectionObserver unsupported or invalid root (iOS/WebKit)', e);
      return;
    }
    return () => observer.disconnect();
  }, [
    scrollerRef,
    messageId,
    message,
    currentUserId,
    canMarkReadByViewport,
    viewportLayoutKey,
    firestore,
    conversationId,
    isThread,
    threadParentId,
    sessionReadIds,
  ]);

  return (
    <div ref={wrapRef} className="min-w-0 w-full">
      {children}
    </div>
  );
}
