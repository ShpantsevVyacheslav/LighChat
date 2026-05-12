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
import { incrementChatPerfCounter } from '@/components/chat/chat-performance-metrics';
import { logger } from '@/lib/logger';

/** Ref на DOM-скроллер Virtuoso (см. prop scrollerRef) — root для IntersectionObserver. */
export const ChatViewportScrollerRefContext = createContext<MutableRefObject<HTMLElement | null> | null>(
  null
);

export function useChatViewportScrollerRef(): MutableRefObject<HTMLElement | null> | null {
  return useContext(ChatViewportScrollerRefContext);
}

type ObserverCallback = (entry: IntersectionObserverEntry) => void;

type ObserverPool = {
  observer: IntersectionObserver;
  callbacksByElement: Map<Element, ObserverCallback>;
};

const observerPoolByRoot = new WeakMap<HTMLElement, ObserverPool>();

function getOrCreateObserverPool(root: HTMLElement): ObserverPool {
  const existing = observerPoolByRoot.get(root);
  if (existing) return existing;

  const callbacksByElement = new Map<Element, ObserverCallback>();
  const observer = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        const cb = callbacksByElement.get(entry.target);
        if (cb) cb(entry);
      }
    },
    { root, rootMargin: '0px', threshold: [0, 0.12, 0.35, 0.6] }
  );

  const pool: ObserverPool = { observer, callbacksByElement };
  observerPoolByRoot.set(root, pool);
  incrementChatPerfCounter('message-read-observer-created');
  return pool;
}

function observeWithPool(root: HTMLElement, element: Element, cb: ObserverCallback): () => void {
  const pool = getOrCreateObserverPool(root);
  pool.callbacksByElement.set(element, cb);
  pool.observer.observe(element);

  return () => {
    pool.observer.unobserve(element);
    pool.callbacksByElement.delete(element);
    if (pool.callbacksByElement.size === 0) {
      pool.observer.disconnect();
      observerPoolByRoot.delete(root);
      incrementChatPerfCounter('message-read-observer-disposed');
    }
  };
}

export type MessageReadOnViewportProps = {
  messageId: string;
  message: Pick<ChatMessage, 'senderId' | 'readAt' | 'readByUid'>;
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
  /** Скрытые read-receipts: пишем личную метку readByUid.{me} вместо публичного readAt. */
  suppressReadReceipts?: boolean;
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
  suppressReadReceipts = false,
  children,
}: MessageReadOnViewportProps) {
  const scrollerRef = useChatViewportScrollerRef();
  const wrapRef = useRef<HTMLDivElement>(null);
  const senderId = message.senderId;
  const readAt = message.readAt;
  const personalReadAt = message.readByUid?.[currentUserId] ?? null;

  useEffect(() => {
    const root = scrollerRef?.current ?? null;
    const el = wrapRef.current;
    if (!canMarkReadByViewport || !root || !el || !firestore) return;
    const probe = { senderId, readAt, readByUid: personalReadAt ? { [currentUserId]: personalReadAt } : undefined };
    if (!isIncomingUnreadForViewer(probe, currentUserId)) return;

    const tryMark = () => {
      if (!firestore) return;
      if (!isIncomingUnreadForViewer(probe, currentUserId)) return;
      if (sessionReadIds.current.has(messageId)) return;
      sessionReadIds.current.add(messageId);
      void markMessagesAsRead(
        firestore,
        conversationId,
        currentUserId,
        [messageId],
        isThread,
        threadParentId,
        suppressReadReceipts,
      ).catch((e) => {
        logger.error('msg-read', 'mark read failed', e);
        sessionReadIds.current.delete(messageId);
      });
    };

    try {
      return observeWithPool(root, el, (entry) => {
        if (entry.isIntersecting && entry.intersectionRatio >= 0.12) {
          tryMark();
        }
      });
    } catch (e) {
      logger.warn('msg-read', 'IntersectionObserver unsupported or invalid root (iOS/WebKit)', e);
      return;
    }
  }, [
    scrollerRef,
    messageId,
    senderId,
    readAt,
    personalReadAt,
    currentUserId,
    canMarkReadByViewport,
    viewportLayoutKey,
    firestore,
    conversationId,
    isThread,
    threadParentId,
    sessionReadIds,
    suppressReadReceipts,
  ]);

  return (
    <div ref={wrapRef} className="min-w-0 w-full">
      {children}
    </div>
  );
}
