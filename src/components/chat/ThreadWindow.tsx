
'use client';

import React, { useState, useMemo, useEffect, useLayoutEffect, useRef, useCallback } from 'react';
import { getAuth } from 'firebase/auth';
import { getFunctions, httpsCallable } from 'firebase/functions';
import { useFirestore, useMemoFirebase, useStorage, useCollection } from '@/firebase';
import { collection, query, doc, updateDoc, increment, orderBy, setDoc, getDocs, where, limit, documentId, writeBatch, onSnapshot, deleteDoc, serverTimestamp, deleteField, arrayUnion } from 'firebase/firestore';
import { E2EE_LAST_MESSAGE_PREVIEW } from '@/lib/e2ee';
import { useE2eeConversation } from '@/hooks/use-e2ee-conversation';
import { useE2eeMediaAttachments } from '@/hooks/use-e2ee-media-attachments';
import { useE2eeHydratedMessages } from '@/hooks/use-e2ee-hydrated-messages';
import { isEncryptableMimeV2 } from '@/lib/e2ee';
import { inferKindHintFromFileName } from '@/lib/e2ee/infer-kind-hint';
import { Virtuoso, type VirtuosoHandle } from 'react-virtuoso';
import type {
    User,
    Conversation,
    ChatMessage,
    ChatAttachment,
    ReplyContext,
    ReactionDetail,
    ChatLocationShare,
    ChatLocationSendMeta,
    UserContactLocalProfile,
} from '@/lib/types';
import type { ChatPollCreateInput } from '@/components/chat/ChatAttachPollDialog';
import { chatPollFirestoreFields } from '@/lib/chat-poll-create';
import { Button } from '@/components/ui/button';
import { ChatMessageItem } from './ChatMessageItem';
import { ChatSystemEventDivider } from './ChatSystemEventDivider';
import { ChatMessageInput } from './ChatMessageInput';
import { ChatWallpaperLayer } from './ChatWallpaperLayer';
import { SelectionHeader } from './SelectionHeader';
import { ChatAnchor } from './ChatAnchor';
import { X, MessageSquare, Loader2, ChevronDown, Maximize2, Minimize2 } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import { parseISO, isToday, isYesterday, format } from 'date-fns';
import { ru } from 'date-fns/locale';
import { useRouter } from 'next/navigation';
import { MediaViewer, type MediaViewerItem } from '@/components/chat/media-viewer';
import { getReplyPreview, markThreadMessagesSeenWithoutReadReceipt } from '@/lib/chat-utils';
import { HISTORY_PAGE_SIZE, INITIAL_MESSAGE_LIMIT } from '@/components/chat/chat-message-limits';
import { ChatDateListAnchor } from '@/components/chat/ChatDateListAnchor';
import { ChatFloatingDateLabel } from '@/components/chat/ChatFloatingDateLabel';
import { firstCalendarDayInViewport } from '@/components/chat/visible-range-date';
import { isGridGalleryAttachment } from '@/components/chat/attachment-visual';
import { getVirtuosoChatIncreaseViewport, VIRTUOSO_CHAT_MIN_OVERSCAN } from '@/components/chat/virtuoso-chat-config';
import {
    isFirestorePermissionDeniedError,
    logFirestorePermissionDenied,
} from '@/lib/firestore-permission-debug';
import { VideoCircleTailProvider } from '@/components/chat/video-circle-tail-context';
import { cn } from '@/lib/utils';
import { useSettings } from '@/hooks/use-settings';
import { GEOLOCATION_FIRESTORE_LOG } from '@/lib/geolocation-client';
import { scheduleFirestoreListen } from '@/firebase/schedule-firestore-listen';
import {
    ChatViewportScrollerRefContext,
    MessageReadOnViewport,
} from '@/components/chat/message-read-on-viewport';
import {
    incrementChatPerfCounter,
    markChatPerf,
    measureChatPerf,
} from '@/components/chat/chat-performance-metrics';
import { CHAT_HEADER_SAFE_AREA_STRIP } from '@/lib/chat-glass-styles';

interface ThreadWindowProps {
    parentMessage: ChatMessage;
    conversation: Conversation;
    currentUser: User;
    allUsers: User[];
    onClose: () => void;
    onOpenImageViewer: (image: ChatAttachment) => void;
    onOpenVideoViewer: (video: ChatAttachment) => void;
    onNavigateToMessage: (messageId: string) => void;
    onUpdateMessage: (id: string, text: string, attachments?: ChatAttachment[]) => Promise<void>;
    onDeleteMessage: (id: string) => Promise<void>;
    onReplyTo: (context: ReplyContext) => void;
    onForwardMessage: (msg: ChatMessage) => void;
    onForwardToThread?: (messages: ChatMessage[]) => void;
    onReactTo: (messageId: string, emoji: string, threadParentId?: string) => void;
    isPartnerDeleted?: boolean;
    composerLocked?: boolean;
    composerLockedHint?: string;
    /** Прокрутка к сообщению в треде (например, по якорю «реакция» из основного чата). */
    highlightThreadMessageId?: string | null;
    onHighlightThreadMessageConsumed?: () => void;
    /** Клик по @ в тексте сообщения ветки — открыть профиль (родительский `ChatWindow`). */
    onMentionProfileOpen?: (userId: string) => void;
    /** Группа: клик по имени/аватару отправителя (родительский `ChatWindow`). */
    onGroupSenderProfileOpen?: (userId: string) => void;
    /** Группа: меню отправителя — личный чат (родительский `ChatWindow`). */
    onGroupSenderWritePrivate?: (userId: string) => void | Promise<void>;
    /** Локальные имена контактов текущего пользователя. */
    contactProfiles?: Record<string, UserContactLocalProfile>;
    /** Сохранить стикер/GIF из сообщения в пак текущего пользователя. */
    onSaveStickerGif?: (attachment: ChatAttachment, mode?: 'copy' | 'normalize_sticker') => void;
    /** Скрыть плавающий якорь (оверлей профиля родителя — тот же высокий z-index). */
    suppressFloatingAnchor?: boolean;
    /** Расшифровка родительского сообщения (из основного чата). */
    parentE2eeDecryptedByMessageId?: Record<string, string>;
    /** Фон ветки: совпадает с основным чатом (например персональный фон беседы). */
    chatWallpaper?: string | null;
    /** На desktop — показывать как правую колонку (Mattermost-like), на mobile оставить overlay. */
    asSidebarOnDesktop?: boolean;
    /** Текущая ширина sidebar в desktop-режиме (для resize). */
    desktopWidthPx?: number;
    /** Развернуть/свернуть sidebar до максимально допустимой ширины. */
    isExpandedDesktop?: boolean;
    onToggleExpandDesktop?: () => void;
}

type FlatThreadItem = 
    | { type: 'parent' } 
    | { type: 'date'; date: string } 
    | { type: 'message'; message: ChatMessage }
    | { type: 'unread-separator' };

const TOP_LOAD_THRESHOLD_PX = 40;
const LOAD_MORE_COOLDOWN_MS = 600;

export function ThreadWindow({
    parentMessage, conversation, currentUser, allUsers, onClose,
    onNavigateToMessage,
    onUpdateMessage, onDeleteMessage, onReplyTo, onForwardMessage, onReactTo,
    isPartnerDeleted = false,
    composerLocked = false,
    composerLockedHint,
    highlightThreadMessageId = null,
    onHighlightThreadMessageConsumed,
    onMentionProfileOpen,
    onGroupSenderProfileOpen,
    onGroupSenderWritePrivate,
    contactProfiles,
    onSaveStickerGif,
    suppressFloatingAnchor = false,
    parentE2eeDecryptedByMessageId = {},
    chatWallpaper: chatWallpaperProp = null,
    asSidebarOnDesktop = false,
    desktopWidthPx,
    isExpandedDesktop = false,
    onToggleExpandDesktop,
}: ThreadWindowProps) {
    const firestore = useFirestore();
    const storage = useStorage();
    const { toast } = useToast();
    const router = useRouter();
    const { chatSettings, privacySettings } = useSettings();
    const suppressReadReceipts = privacySettings.showReadReceipts === false;
    const effectiveThreadWallpaper = chatWallpaperProp != null && chatWallpaperProp !== '' ? chatWallpaperProp : chatSettings.chatWallpaper;
    const e2eeConv = useE2eeConversation(firestore, conversation, currentUser.id);
    const e2eeMediaApi = useE2eeMediaAttachments({
        storage,
        conversationId: conversation.id,
        getChatKeyRawV2ForEpoch: e2eeConv.getChatKeyRawV2ForEpoch,
        epoch: e2eeConv.e2eeEpoch,
    });
    const [threadE2eePlaintextByMessageId, setThreadE2eePlaintextByMessageId] = useState<Record<string, string>>({});
    
    const [messages, setMessages] = useState<ChatMessage[]>([]);
    const [displayLimit, setDisplayLimit] = useState(INITIAL_MESSAGE_LIMIT);
    const [hasMore, setHasMore] = useState(true);
    const [isLoadingOlder, setIsLoadingOlder] = useState(false);
    const [isFullyReady, setIsFullyReady] = useState(false);
    const [optimisticMessages, setOptimisticMessages] = useState<ChatMessage[]>([]);
    const [editingMessage, setEditingMessage] = useState<{ id: string; text: string; attachments?: ChatAttachment[] } | null>(null);
    const [replyingTo, setReplyingTo] = useState<ReplyContext | null>(null);
    useEffect(() => {
        setReplyingTo(null);
        setEditingMessage(null);
    }, [parentMessage.id]);
    const [selection, setSelection] = useState({ active: false, ids: new Set<string>() });
    const [mediaViewerState, setMediaViewerState] = useState({ isOpen: false, startIndex: 0 });
    const [hasScrolledToUnread, setHasScrolledToUnread] = useState(false);
    const [showScrollButton, setShowScrollButton] = useState(false);
    const [documentFullscreen, setDocumentFullscreen] = useState(false);
    const [unreadSeparatorId, setUnreadSeparatorId] = useState<string | null>(null);
    const hasClearedSeparatorRef = useRef(false);
    const hasScrolledToUnreadRef = useRef(false);
    const [viewportCalendarDayKey, setViewportCalendarDayKey] = useState<string | null>(null);

    const virtuosoRef = useRef<VirtuosoHandle>(null);
    const viewportScrollerRef = useRef<HTMLElement | null>(null);
    const [viewportScrollerKey, setViewportScrollerKey] = useState(0);
    const onVirtuosoScrollerRef = useCallback((el: HTMLElement | Window | null) => {
        const node = el instanceof HTMLElement ? el : null;
        if (viewportScrollerRef.current !== node) {
            viewportScrollerRef.current = node;
            setViewportScrollerKey((k) => k + 1);
        }
    }, []);
    const isFullyReadyRef = useRef(isFullyReady);
    isFullyReadyRef.current = isFullyReady;
    const sessionReadIds = useRef<Set<string>>(new Set());
    const currentVisibleRange = useRef({ startIndex: 0, endIndex: 0 });
    const atBottomRef = useRef(true);
    const [videoCircleTailReservePx, setVideoCircleTailReservePxState] = useState(0);
    const prevTailReserveRef = useRef(0);

    const setVideoCircleTailReservePx = useCallback((px: number) => {
        setVideoCircleTailReservePxState(Math.max(0, Math.round(px)));
    }, []);

    useEffect(() => {
        hasScrolledToUnreadRef.current = hasScrolledToUnread;
    }, [hasScrolledToUnread]);

    useEffect(() => {
        const sync = () => {
            const docRef = document as Document & { webkitFullscreenElement?: Element | null };
            setDocumentFullscreen(!!(document.fullscreenElement ?? docRef.webkitFullscreenElement));
        };
        sync();
        document.addEventListener('fullscreenchange', sync);
        document.addEventListener('webkitfullscreenchange', sync);
        return () => {
            document.removeEventListener('fullscreenchange', sync);
            document.removeEventListener('webkitfullscreenchange', sync);
        };
    }, []);

    const touchStartX = useRef<number | null>(null);
    const touchStartY = useRef<number | null>(null);

    const prevParentIdRef = useRef(parentMessage.id);

    useEffect(() => {
        if (!firestore || !conversation.id || !parentMessage.id) return;
        
        if (prevParentIdRef.current !== parentMessage.id) {
            setMessages([]);
            setDisplayLimit(INITIAL_MESSAGE_LIMIT);
            setHasMore(true);
            setIsLoadingOlder(false);
            setIsFullyReady(false);
            setHasScrolledToUnread(false);
            hasScrolledToUnreadRef.current = false;
            setUnreadSeparatorId(null);
            hasClearedSeparatorRef.current = false;
            setVideoCircleTailReservePxState(0);
            prevTailReserveRef.current = 0;
            sessionReadIds.current.clear();
            setViewportCalendarDayKey(null);
            setThreadE2eePlaintextByMessageId({});
            prevParentIdRef.current = parentMessage.id;
        }

        const threadCollection = collection(firestore, `conversations/${conversation.id}/messages/${parentMessage.id}/thread`);
        const q = query(threadCollection, orderBy('createdAt', 'desc'), limit(displayLimit));

        return scheduleFirestoreListen(() =>
            onSnapshot(
                q,
                (snap) => {
                    const msgs = snap.docs.map((d) => ({ ...d.data(), id: d.id } as ChatMessage)).reverse();
                    setMessages(msgs);
                    setHasMore(snap.docs.length === displayLimit);
                    setIsLoadingOlder(false);
                    setIsFullyReady(true);
                },
                (err) => {
                    console.error('Thread messages fetch error:', err);
                    setIsLoadingOlder(false);
                    setIsFullyReady(true);
                }
            )
        );
    }, [firestore, conversation.id, parentMessage.id, displayLimit]);

    const handleLoadMore = useCallback((source: 'startReached' | 'scroll-fallback' | 'manual' = 'manual') => {
        incrementChatPerfCounter(`thread-load-more-trigger:${source}`);
        if (!hasMore || isLoadingOlder || loadMoreInFlightRef.current) {
            incrementChatPerfCounter('thread-load-more-skipped');
            return;
        }
        loadMoreInFlightRef.current = true;
        incrementChatPerfCounter('thread-load-more-accepted');
        markChatPerf('thread-load-more-start');
        const scroller = viewportScrollerRef.current;
        if (scroller) {
            pendingPrependAdjustRef.current = {
                scrollTop: scroller.scrollTop,
                scrollHeight: scroller.scrollHeight,
            };
        }
        setIsLoadingOlder(true);
        setDisplayLimit(prev => prev + HISTORY_PAGE_SIZE);
    }, [hasMore, isLoadingOlder]);

    const allMessagesRaw = useMemo(() => {
        const remoteMessageIds = new Set(messages.map(rm => rm.id));
        const uniqueOptimistic = optimisticMessages.filter(om => !remoteMessageIds.has(om.id));
        const combined = [...messages, ...uniqueOptimistic];
        
        const clearedAt = conversation.clearedAt?.[currentUser.id];
        return clearedAt 
            ? combined.filter(m => new Date(m.createdAt) > new Date(clearedAt))
            : combined;
    }, [messages, optimisticMessages, conversation.clearedAt, currentUser.id]);

    // E2EE v2 Phase 9: подмешиваем расшифрованные blob-URL в message.attachments
    // перед тем как сообщения попадут в flatItems/ChatMessageItem.
    const allMessages = useE2eeHydratedMessages(allMessagesRaw, e2eeMediaApi);

    useEffect(() => {
        const hasCiphertext = allMessages.some((m) => m.e2ee?.ciphertext);
        if (!hasCiphertext) {
            setThreadE2eePlaintextByMessageId({});
            return;
        }
        let cancelled = false;
        void (async () => {
            const updates: Record<string, string> = {};
            for (const m of allMessages) {
                if (!m.e2ee?.ciphertext) continue;
                const plain = await e2eeConv.decryptMessagePayload(m.e2ee, m.id);
                updates[m.id] = plain;
            }
            if (!cancelled) {
                setThreadE2eePlaintextByMessageId((prev) => {
                    const merged = { ...prev };
                    let changed = false;
                    for (const [k, v] of Object.entries(updates)) {
                        if (merged[k] !== v) {
                            merged[k] = v;
                            changed = true;
                        }
                    }
                    return changed ? merged : prev;
                });
            }
        })();
        return () => {
            cancelled = true;
        };
    }, [allMessages, e2eeConv.decryptMessagePayload]);

    const threadE2eeMergedMap = useMemo(
        () => ({ ...parentE2eeDecryptedByMessageId, ...threadE2eePlaintextByMessageId }),
        [parentE2eeDecryptedByMessageId, threadE2eePlaintextByMessageId]
    );

    const isIncomingUnreadForViewer = useCallback(
        (m: Pick<ChatMessage, 'senderId' | 'readAt' | 'systemEvent'>) => {
            if (m.senderId === '__system__' || m.systemEvent != null) return false;
            if (m.senderId === currentUser.id) return false;
            return !m.readAt;
        },
        [currentUser.id]
    );

    const unreadCount = useMemo(() => {
        return allMessages.filter((m) => isIncomingUnreadForViewer(m)).length;
    }, [allMessages, isIncomingUnreadForViewer]);

    useEffect(() => {
        if (!suppressReadReceipts) return;
        if (!firestore || !isFullyReady || !hasScrolledToUnread) return;
        const pendingIds = allMessages
            .filter((m) => isIncomingUnreadForViewer(m) && !sessionReadIds.current.has(m.id))
            .map((m) => m.id);
        if (pendingIds.length === 0) return;

        pendingIds.forEach((id) => sessionReadIds.current.add(id));
        void markThreadMessagesSeenWithoutReadReceipt(
            firestore,
            conversation.id,
            currentUser.id,
            parentMessage.id,
            pendingIds.length
        ).catch((e) => {
            console.error('[ThreadWindow] suppress-read-receipts thread reset failed', e);
            pendingIds.forEach((id) => sessionReadIds.current.delete(id));
        });
    }, [
        suppressReadReceipts,
        firestore,
        isFullyReady,
        hasScrolledToUnread,
        allMessages,
        isIncomingUnreadForViewer,
        conversation.id,
        currentUser.id,
        parentMessage.id,
    ]);

    const prevUnreadCount = useRef(unreadCount);
    useEffect(() => {
        if (!isFullyReady) return;

        if (unreadCount > prevUnreadCount.current) {
            hasClearedSeparatorRef.current = false;
        }
        prevUnreadCount.current = unreadCount;

        if (unreadCount === 0) {
            if (unreadSeparatorId) {
                setUnreadSeparatorId(null);
                hasClearedSeparatorRef.current = false;
            }
            return;
        }

        if (!unreadSeparatorId && !hasClearedSeparatorRef.current) {
            const oldestUnread = allMessages.find((m) => isIncomingUnreadForViewer(m));
            if (oldestUnread) {
                setUnreadSeparatorId(oldestUnread.id);
            }
        }
    }, [isFullyReady, unreadCount, unreadSeparatorId, allMessages, isIncomingUnreadForViewer]);

    const flatItems = useMemo(() => {
        const items: FlatThreadItem[] = [{ type: 'parent' }];
        let lastDate = "";
        
        allMessages.forEach((msg) => {
            const date = format(parseISO(msg.createdAt), 'yyyy-MM-dd');
            if (date !== lastDate) {
                items.push({ type: 'date', date });
                lastDate = date;
            }
            
            if (msg.id === unreadSeparatorId) {
                items.push({ type: 'unread-separator' });
            }

            items.push({ type: 'message', message: msg });
        });
        
        return items;
    }, [allMessages, unreadSeparatorId]);

    const flatItemsRef = useRef(flatItems);
    useEffect(() => { flatItemsRef.current = flatItems; }, [flatItems]);
    const increaseViewportBy = useMemo(() => getVirtuosoChatIncreaseViewport(), []);

    const syncViewportCalendarDay = useCallback(
        (startIndex: number, endIndex: number) => {
            if (!isFullyReadyRef.current) return;
            const items = flatItemsRef.current;
            if (items.length === 0) {
                setViewportCalendarDayKey(null);
                return;
            }
            const lo = Math.min(startIndex, endIndex);
            const hi = Math.max(startIndex, endIndex);
            const dayKey = firstCalendarDayInViewport(items, lo, hi, {
                parentCreatedAt: parentMessage.createdAt,
            });
            setViewportCalendarDayKey((prev) => (prev === dayKey ? prev : dayKey));
        },
        [parentMessage.createdAt]
    );

    useLayoutEffect(() => {
        const prev = prevTailReserveRef.current;
        const next = videoCircleTailReservePx;
        const delta = next - prev;
        prevTailReserveRef.current = next;
        if (delta === 0) return;
        const v = virtuosoRef.current;
        if (!v) return;
        if (delta > 0) {
            v.scrollBy({ top: delta, behavior: 'auto' });
        } else if (atBottomRef.current) {
            v.scrollBy({ top: delta, behavior: 'auto' });
        }
    }, [videoCircleTailReservePx]);

    const pendingScrollToBottomAfterSendRef = useRef(false);
    const pendingPrependAdjustRef = useRef<{ scrollTop: number; scrollHeight: number } | null>(null);
    const loadMoreCooldownUntilRef = useRef(0);
    const loadMoreInFlightRef = useRef(false);

    useEffect(() => {
        if (!isLoadingOlder) {
            loadMoreInFlightRef.current = false;
            measureChatPerf('thread-load-more-start', 'thread-load-more-duration');
        }
    }, [isLoadingOlder]);

    useEffect(() => {
        if (!pendingScrollToBottomAfterSendRef.current || !isFullyReady || !virtuosoRef.current) return;
        const items = flatItemsRef.current;
        if (items.length === 0) return;
        pendingScrollToBottomAfterSendRef.current = false;
        const id = requestAnimationFrame(() => {
            virtuosoRef.current?.scrollToIndex({ index: items.length - 1, align: 'end', behavior: 'auto' });
        });
        return () => cancelAnimationFrame(id);
    }, [flatItems, isFullyReady]);

    useLayoutEffect(() => {
        const pending = pendingPrependAdjustRef.current;
        const scroller = viewportScrollerRef.current;
        if (!pending || !scroller) return;
        const delta = scroller.scrollHeight - pending.scrollHeight;
        if (delta > 0) {
            scroller.scrollTop = pending.scrollTop + delta;
        }
        pendingPrependAdjustRef.current = null;
    }, [flatItems]);

    const tryLoadMoreByTopPosition = useCallback(() => {
        incrementChatPerfCounter('thread-load-more-top-check');
        const now = Date.now();
        if (now < loadMoreCooldownUntilRef.current) return;
        if (!isFullyReady || !hasMore || isLoadingOlder) return;
        const scroller = viewportScrollerRef.current;
        if (!scroller) return;
        if (scroller.scrollTop > TOP_LOAD_THRESHOLD_PX) return;
        loadMoreCooldownUntilRef.current = now + LOAD_MORE_COOLDOWN_MS;
        handleLoadMore('scroll-fallback');
    }, [isFullyReady, hasMore, isLoadingOlder, handleLoadMore]);

    useEffect(() => {
        const scroller = viewportScrollerRef.current;
        if (!scroller) return;
        const onScroll = () => {
            tryLoadMoreByTopPosition();
        };
        scroller.addEventListener('scroll', onScroll, { passive: true });
        return () => scroller.removeEventListener('scroll', onScroll);
    }, [viewportScrollerKey, tryLoadMoreByTopPosition]);

    const threadMediaItems = useMemo((): MediaViewerItem[] => {
        const items: MediaViewerItem[] = [];

        if (!parentMessage.isDeleted && parentMessage.attachments) {
            parentMessage.attachments.forEach(att => {
                if (isGridGalleryAttachment(att)) {
                    items.push({ ...att, messageId: parentMessage.id, senderId: parentMessage.senderId, createdAt: parentMessage.createdAt });
                }
            });
        }
        allMessages.forEach(msg => {
            if (msg.isDeleted || !msg.attachments) return;
            msg.attachments.forEach(att => {
                if (isGridGalleryAttachment(att)) {
                    items.push({ ...att, messageId: msg.id, senderId: msg.senderId, createdAt: msg.createdAt });
                }
            });
        });
        return items;
    }, [allMessages, parentMessage]);

    const handleOpenMediaViewer = useCallback((att: ChatAttachment) => {
        const idx = threadMediaItems.findIndex(i => i.url === att.url);
        if (idx >= 0) {
            setMediaViewerState({ isOpen: true, startIndex: idx });
        }
    }, [threadMediaItems]);

    useEffect(() => {
        if (!isFullyReady) return;
        if (highlightThreadMessageId) return;
        if (!hasScrolledToUnread && virtuosoRef.current && flatItems.length > 0) {
            if (unreadCount > 0 && !unreadSeparatorId) return;

            const timer = setTimeout(() => {
                const unreadIdx = flatItems.findIndex(item => item.type === 'unread-separator');
                if (unreadIdx !== -1) {
                    virtuosoRef.current?.scrollToIndex({ index: unreadIdx, align: 'start', behavior: 'auto' });
                } else {
                    virtuosoRef.current?.scrollToIndex({ index: flatItems.length - 1, align: 'end', behavior: 'auto' });
                }
                requestAnimationFrame(() => {
                    requestAnimationFrame(() => {
                        hasScrolledToUnreadRef.current = true;
                        setHasScrolledToUnread(true);
                    });
                });
            }, 200);
            return () => clearTimeout(timer);
        }
    }, [isFullyReady, hasScrolledToUnread, flatItems, unreadCount, unreadSeparatorId, highlightThreadMessageId]);

    useEffect(() => {
        const targetId = highlightThreadMessageId;
        if (!targetId || !isFullyReady) return;
        const idx = flatItems.findIndex(
            (item) => item.type === 'message' && item.message.id === targetId
        );
        if (idx !== -1) {
            virtuosoRef.current?.scrollToIndex({ index: idx, align: 'center', behavior: 'smooth' });
            const runHighlight = () => {
                const el = document.getElementById(`msg-${targetId}`);
                if (el) {
                    el.classList.add('animate-message-highlight');
                    window.setTimeout(() => el.classList.remove('animate-message-highlight'), 2000);
                }
            };
            requestAnimationFrame(() => requestAnimationFrame(runHighlight));
            window.setTimeout(runHighlight, 450);
            onHighlightThreadMessageConsumed?.();
            hasScrolledToUnreadRef.current = true;
            setHasScrolledToUnread(true);
            return;
        }
        if (!hasMore) {
            onHighlightThreadMessageConsumed?.();
            toast({ title: 'Сообщение не найдено' });
            return;
        }
        setIsLoadingOlder(true);
        setDisplayLimit((prev) => prev + HISTORY_PAGE_SIZE);
    }, [highlightThreadMessageId, isFullyReady, flatItems, hasMore, onHighlightThreadMessageConsumed, toast]);

    const handleRangeChanged = useCallback((range: { startIndex: number; endIndex: number }) => {
        currentVisibleRange.current = range;
        syncViewportCalendarDay(range.startIndex, range.endIndex);
        if (!isFullyReady || !firestore || !conversation.id) return;

        const currentItems = flatItemsRef.current;
        if (range.endIndex >= currentItems.length - 1 && hasScrolledToUnreadRef.current) {
            setUnreadSeparatorId((prev) => {
                if (prev !== null) {
                    hasClearedSeparatorRef.current = true;
                    return null;
                }
                return prev;
            });
        }
    }, [isFullyReady, firestore, conversation.id, currentUser.id, parentMessage.id, syncViewportCalendarDay]);

    const handleThreadUpdateMessage = useCallback(
        async (id: string, text: string, attachments?: ChatAttachment[]) => {
            if (!firestore || !conversation.id) return;
            const msgRef = doc(
                firestore,
                `conversations/${conversation.id}/messages/${parentMessage.id}/thread`,
                id
            );
            const now = new Date().toISOString();
            const existing = allMessages.find((m) => m.id === id);
            const hadE2eeEnvelope = !!(existing?.e2ee && (existing.e2ee.ciphertext || (existing.e2ee.attachments && existing.e2ee.attachments.length > 0)));
            try {
                if (e2eeConv.e2eeEnabled && hadE2eeEnvelope) {
                    const e2eePayload = await e2eeConv.encryptOutgoingHtmlV2(text, { messageId: id });
                    if (existing?.e2ee?.attachments && existing.e2ee.attachments.length > 0) {
                        e2eePayload.attachments = existing.e2ee.attachments;
                    }
                    await updateDoc(msgRef, {
                        e2ee: e2eePayload,
                        text: deleteField(),
                        attachments: attachments || [],
                        updatedAt: now,
                    });
                } else {
                    await updateDoc(msgRef, { text, attachments: attachments || [], updatedAt: now });
                }
            } catch {
                toast({ variant: 'destructive', title: 'Ошибка обновления' });
            }
        },
        [firestore, conversation.id, parentMessage.id, allMessages, e2eeConv.e2eeEnabled, e2eeConv.encryptOutgoingHtmlV2, toast]
    );

    const handleSendMessage = async (
        text?: string,
        attachmentsToUpload?: File[],
        replyTo?: ReplyContext | null,
        prebuiltAttachments?: ChatAttachment[]
    ) => {
        if (!firestore || !currentUser) return;
        const replyContext = replyTo ?? null;
        const files = attachmentsToUpload ?? [];
        const prebuilt = prebuiltAttachments ?? [];
        
        const threadCollection = collection(firestore, `conversations/${conversation.id}/messages/${parentMessage.id}/thread`);
        const newDocRef = doc(threadCollection);
        const messageId = newDocRef.id;
        const now = new Date().toISOString();

        const optimisticAttachments: ChatAttachment[] = [
            ...prebuilt.map((a) => ({ ...a })),
            ...files.map((f) => ({ url: URL.createObjectURL(f), name: f.name, type: f.type, size: f.size })),
        ];
        
        const optimisticMessage: ChatMessage = {
            id: messageId,
            senderId: currentUser.id,
            text: text,
            createdAt: now,
            readAt: null,
            deliveryStatus: 'sending',
            attachments: optimisticAttachments,
            ...(replyContext && { replyTo: replyContext }),
        };
        pendingScrollToBottomAfterSendRef.current = true;
        setOptimisticMessages(prev => [...prev, optimisticMessage]);

        try {
            // E2EE v2 Phase 9: плейнтекст (стикеры/GIF) идёт привычным путём,
            // encryptable-файлы шифруются через useE2eeMediaAttachments.
            const encryptAttachments = e2eeConv.e2eeEnabled;
            const plaintextFilesToUpload: File[] = encryptAttachments
                ? files.filter((f) => !isEncryptableMimeV2(f.type))
                : files;
            const filesToEncrypt: File[] = encryptAttachments
                ? files.filter((f) => isEncryptableMimeV2(f.type))
                : [];

            const uploadedAttachments: ChatAttachment[] = [...prebuilt];
            if (plaintextFilesToUpload.length > 0) {
                const { uploadFile: internalUpload } = await import('./ChatMessageInput');
                for (const file of plaintextFilesToUpload) {
                    const path = `chat-attachments/${conversation.id}/threads/${parentMessage.id}/${Date.now()}-${file.name.replace(/\s+/g, '_')}`;
                    const uploaded = await internalUpload(file, path, storage);
                    uploadedAttachments.push(uploaded);
                }
            }

            let e2eeAttachmentEnvelopes:
                | NonNullable<import('@/lib/types').ChatMessageE2eePayload['attachments']>
                | null = null;
            if (filesToEncrypt.length > 0) {
                try {
                    const res = await e2eeMediaApi.encryptAndUploadForSend(
                        messageId,
                        filesToEncrypt.map((file) => ({
                            file,
                            kindHint: inferKindHintFromFileName(file.name),
                        }))
                    );
                    e2eeAttachmentEnvelopes = res.envelopes;
                } catch (encErr) {
                    toast({ variant: 'destructive', title: 'Не удалось зашифровать вложение' });
                    throw encErr;
                }
            }

            const plainBody = text
                ? text.replace(/<[^>]*>/g, '').replace(/&nbsp;/g, ' ').trim()
                : '';
            const useE2eeForText =
                e2eeConv.e2eeEnabled && !!text && plainBody.length > 0;
            const hasEncryptedAttachments =
                !!e2eeAttachmentEnvelopes && e2eeAttachmentEnvelopes.length > 0;
            const useE2eeEnvelope = useE2eeForText || hasEncryptedAttachments;
            const replyForWrite =
                useE2eeEnvelope && replyContext
                    ? (({ text: _omitted, ...rest }) => rest)(replyContext)
                    : replyContext;

            const messageData: Record<string, unknown> = {
                id: messageId,
                senderId: currentUser.id,
                createdAt: now,
                readAt: null,
                attachments: uploadedAttachments,
                ...(replyForWrite && { replyTo: replyForWrite }),
            };
            if (useE2eeEnvelope) {
                const htmlForEncrypt = useE2eeForText ? text! : '';
                const e2eePayload = await e2eeConv.encryptOutgoingHtmlV2(htmlForEncrypt, { messageId });
                if (hasEncryptedAttachments) {
                    e2eePayload.attachments = e2eeAttachmentEnvelopes!;
                }
                messageData.e2ee = e2eePayload;
            } else if (text) {
                messageData.text = text;
            }

            try {
                await setDoc(newDocRef, messageData as Parameters<typeof setDoc>[1]);
            } catch (writeError) {
                if (isFirestorePermissionDeniedError(writeError)) {
                    try {
                        await getAuth(firestore.app).currentUser?.getIdToken(true);
                        await setDoc(newDocRef, messageData as Parameters<typeof setDoc>[1]);
                    } catch (retryError) {
                        logFirestorePermissionDenied({
                            source: 'ThreadWindow.handleSendMessage',
                            operation: 'create',
                            path: `conversations/${conversation.id}/messages/${parentMessage.id}/thread/${messageId}`,
                            firestore,
                            failedStep: 'setDoc',
                            extra: {
                                conversationId: conversation.id,
                                parentMessageId: parentMessage.id,
                                senderId: currentUser.id,
                                useE2eeForText,
                                hasReply: !!replyForWrite,
                                attachmentCount: uploadedAttachments.length,
                            },
                            error: retryError,
                        });
                        throw retryError;
                    }
                } else {
                    throw writeError;
                }
            }

            const parentMessageRef = doc(firestore, `conversations/${conversation.id}/messages`, parentMessage.id);
            const convRef = doc(firestore, 'conversations', conversation.id);
            const otherParticipantIds = conversation.participantIds.filter(id => id !== currentUser.id);
            
            const threadUnreadUpdates: Record<string, any> = {};
            otherParticipantIds.forEach(id => {
                threadUnreadUpdates[`unreadThreadCounts.${id}`] = increment(1);
            });

            const strip = text ? text.replace(/<[^>]*>/g, '') : '';
            let threadLastText = strip;
            if (useE2eeForText) {
                threadLastText = E2EE_LAST_MESSAGE_PREVIEW;
            } else if (!threadLastText) {
                if (prebuilt.some((a) => a.name.startsWith('gif_'))) threadLastText = 'GIF';
                else if (prebuilt.some((a) => a.name.startsWith('sticker_'))) threadLastText = 'Стикер';
                else if (files.length === 1 && files[0].name.startsWith('sticker_')) threadLastText = 'Стикер';
                else if (files.length > 0 || prebuilt.length > 0) threadLastText = 'Вложение';
                else threadLastText = 'Сообщение';
            }

            updateDoc(parentMessageRef, {
                threadCount: increment(1),
                threadParticipantIds: arrayUnion(currentUser.id),
                lastThreadMessageText: threadLastText,
                lastThreadMessageSenderId: currentUser.id,
                lastThreadMessageTimestamp: now,
                ...threadUnreadUpdates
            });

            updateDoc(convRef, {
                lastMessageText: threadLastText,
                lastMessageTimestamp: now,
                lastMessageSenderId: currentUser.id,
                lastMessageIsThread: true,
                ...threadUnreadUpdates
            });

        } catch (error) {
            console.error("Thread send failed:", error);
            setOptimisticMessages(prev => prev.filter(m => m.id !== messageId));
            const msg = error instanceof Error ? error.message : '';
            if (msg === 'E2EE_NO_CHAT_KEY' || msg === 'E2EE_UNWRAP_FAILED') {
                toast({
                    variant: 'destructive',
                    title: 'Не удалось зашифровать сообщение',
                    description:
                        msg === 'E2EE_UNWRAP_FAILED'
                            ? 'Этот браузер не совпадает с ключом, под который включали шифрование (часто: другое устройство/браузер или очистка данных). Откройте профиль чата → «Шифрование» и выключите/включите снова на этом устройстве.'
                            : 'Этот браузер не может открыть ключ чата. Попробуйте тот же браузер, где включали шифрование, или перевключите «Шифрование» в профиле чата.',
                });
            }
        }
    };

    const handleSendLocationShare = useCallback(
        async (share: ChatLocationShare, replyContext: ReplyContext | null, meta: ChatLocationSendMeta) => {
            if (e2eeConv.e2eeEnabled) {
                toast({
                    variant: 'destructive',
                    title: 'Геолокация недоступна',
                    description: 'В чате со сквозным шифрованием отправка геолокации пока не поддерживается.',
                });
                return;
            }
            if (!firestore || !currentUser) {
                console.warn(GEOLOCATION_FIRESTORE_LOG, 'thread.aborted', { reason: 'no firestore or user' });
                return;
            }
            const threadCollection = collection(firestore, `conversations/${conversation.id}/messages/${parentMessage.id}/thread`);
            const newDocRef = doc(threadCollection);
            const messageId = newDocRef.id;
            const now = new Date().toISOString();
            console.log(GEOLOCATION_FIRESTORE_LOG, 'thread.start', {
                conversationId: conversation.id,
                parentMessageId: parentMessage.id,
                messageId,
                reply: !!replyContext,
                lat: share.lat,
                lng: share.lng,
            });
            const optimisticMessage: ChatMessage = {
                id: messageId,
                senderId: currentUser.id,
                createdAt: now,
                readAt: null,
                deliveryStatus: 'sending',
                locationShare: share,
                ...(replyContext && { replyTo: replyContext }),
            };
            pendingScrollToBottomAfterSendRef.current = true;
            setOptimisticMessages((prev) => [...prev, optimisticMessage]);
            if (replyContext) setReplyingTo(null);
            try {
                await setDoc(newDocRef, {
                    id: messageId,
                    senderId: currentUser.id,
                    createdAt: now,
                    readAt: null,
                    locationShare: share,
                    ...(replyContext && { replyTo: replyContext }),
                });
                const parentMessageRef = doc(firestore, `conversations/${conversation.id}/messages`, parentMessage.id);
                const convRef = doc(firestore, 'conversations', conversation.id);
                const otherParticipantIds = conversation.participantIds.filter((id) => id !== currentUser.id);
                const threadUnreadUpdates: Record<string, unknown> = {};
                otherParticipantIds.forEach((id) => {
                    threadUnreadUpdates[`unreadThreadCounts.${id}`] = increment(1);
                });
                const threadLastText = '📍 Геолокация';
                await updateDoc(parentMessageRef, {
                    threadCount: increment(1),
                    threadParticipantIds: arrayUnion(currentUser.id),
                    lastThreadMessageText: threadLastText,
                    lastThreadMessageSenderId: currentUser.id,
                    lastThreadMessageTimestamp: now,
                    ...threadUnreadUpdates,
                });
                await updateDoc(convRef, {
                    lastMessageText: threadLastText,
                    lastMessageTimestamp: now,
                    lastMessageSenderId: currentUser.id,
                    lastMessageIsThread: true,
                    ...threadUnreadUpdates,
                });
                if (meta.kind === 'live') {
                    await updateDoc(doc(firestore, 'users', currentUser.id), {
                        liveLocationShare: {
                            active: true,
                            expiresAt: meta.expiresAt,
                            lat: share.lat,
                            lng: share.lng,
                            accuracyM: share.accuracyM,
                            updatedAt: now,
                            startedAt: now,
                        },
                    });
                }
                console.log(GEOLOCATION_FIRESTORE_LOG, 'thread.success', { messageId });
            } catch (error) {
                console.error(GEOLOCATION_FIRESTORE_LOG, 'thread.failed', { messageId, error });
                setOptimisticMessages((prev) => prev.filter((m) => m.id !== messageId));
            }
        },
        [firestore, currentUser, conversation.id, conversation.participantIds, parentMessage.id, e2eeConv.e2eeEnabled, toast]
    );

    const handleSendPoll = useCallback(
        async (input: ChatPollCreateInput, replyContext: ReplyContext | null) => {
            if (e2eeConv.e2eeEnabled) {
                toast({
                    variant: 'destructive',
                    title: 'Опрос недоступен',
                    description: 'В чате со сквозным шифрованием опросы пока не поддерживаются.',
                });
                return;
            }
            if (!firestore || !currentUser) return;
            const pollId = `chat-poll-${Date.now()}`;
            const pollRef = doc(firestore, `conversations/${conversation.id}/polls`, pollId);
            const threadCollection = collection(firestore, `conversations/${conversation.id}/messages/${parentMessage.id}/thread`);
            const newDocRef = doc(threadCollection);
            const messageId = newDocRef.id;
            const now = new Date().toISOString();
            const pollText = '<p>📊 Опрос</p>';
            const optimisticMessage: ChatMessage = {
                id: messageId,
                senderId: currentUser.id,
                text: pollText,
                createdAt: now,
                readAt: null,
                deliveryStatus: 'sending',
                chatPollId: pollId,
                ...(replyContext && { replyTo: replyContext }),
            };
            pendingScrollToBottomAfterSendRef.current = true;
            setOptimisticMessages((prev) => [...prev, optimisticMessage]);
            if (replyContext) setReplyingTo(null);
            try {
                await setDoc(pollRef, {
                    ...chatPollFirestoreFields(input, pollId, currentUser.id),
                    createdAt: serverTimestamp(),
                });
                await setDoc(newDocRef, {
                    id: messageId,
                    senderId: currentUser.id,
                    createdAt: now,
                    readAt: null,
                    text: pollText,
                    chatPollId: pollId,
                    ...(replyContext && { replyTo: replyContext }),
                });
                const parentMessageRef = doc(firestore, `conversations/${conversation.id}/messages`, parentMessage.id);
                const convRef = doc(firestore, 'conversations', conversation.id);
                const otherParticipantIds = conversation.participantIds.filter((id) => id !== currentUser.id);
                const threadUnreadUpdates: Record<string, unknown> = {};
                otherParticipantIds.forEach((id) => {
                    threadUnreadUpdates[`unreadThreadCounts.${id}`] = increment(1);
                });
                const threadLastText = '📊 Опрос';
                await updateDoc(parentMessageRef, {
                    threadCount: increment(1),
                    threadParticipantIds: arrayUnion(currentUser.id),
                    lastThreadMessageText: threadLastText,
                    lastThreadMessageSenderId: currentUser.id,
                    lastThreadMessageTimestamp: now,
                    ...threadUnreadUpdates,
                });
                await updateDoc(convRef, {
                    lastMessageText: threadLastText,
                    lastMessageTimestamp: now,
                    lastMessageSenderId: currentUser.id,
                    lastMessageIsThread: true,
                    ...threadUnreadUpdates,
                });
            } catch (error) {
                console.error('Thread poll send failed:', error);
                setOptimisticMessages((prev) => prev.filter((m) => m.id !== messageId));
                try {
                    await deleteDoc(pollRef);
                } catch {
                    /* ignore */
                }
            }
        },
        [firestore, currentUser, conversation.id, conversation.participantIds, parentMessage.id, e2eeConv.e2eeEnabled, toast]
    );

    const handleAnchorClick = () => {
        const currentItems = flatItemsRef.current;
        const separatorIdx = currentItems.findIndex(item => item.type === 'unread-separator');
        const currentEnd = currentVisibleRange.current.endIndex;
        const lastIdx = currentItems.length - 1;

        if (separatorIdx !== -1 && currentEnd < separatorIdx + 2) {
            virtuosoRef.current?.scrollToIndex({ index: separatorIdx, align: 'start', behavior: 'smooth' });
        } else {
            virtuosoRef.current?.scrollToIndex({ index: lastIdx, align: 'end', behavior: 'smooth' });
        }
    };

    const handleTouchStart = (e: React.TouchEvent) => {
        e.stopPropagation(); 
        touchStartX.current = e.touches[0].clientX;
        touchStartY.current = e.touches[0].clientY;
    };

    const handleTouchEnd = (e: React.TouchEvent) => {
        e.stopPropagation(); 
        if (touchStartX.current === null || touchStartY.current === null || mediaViewerState.isOpen) return;
        
        const touchEndX = e.changedTouches[0].clientX;
        const touchEndY = e.changedTouches[0].clientY;
        
        const dx = touchEndX - touchStartX.current;
        const dy = Math.abs(touchEndY - touchStartY.current);
        
        if (dx > 100 && dy < 60) {
            onClose();
        }
        
        touchStartX.current = null;
        touchStartY.current = null;
    };

    const handleBulkDelete = () => {
        if (!firestore) return;
        selection.ids.forEach(id => {
            onDeleteMessage(id);
        });
        setSelection({ active: false, ids: new Set() });
    };

    const handleInternalReact = async (mid: string, emoji: string) => {
        onReactTo(mid, emoji, parentMessage.id);
    };

    const handleRetryMediaNorm = useCallback(
        async (message: ChatMessage) => {
            if (!firestore) return;
            try {
                const fn = httpsCallable(
                    getFunctions(firestore.app, 'us-central1'),
                    'retryChatMediaTranscode'
                );
                await fn({
                    conversationId: conversation.id,
                    messageId: message.id,
                    isThread: true,
                    parentMessageId: parentMessage.id,
                });
                toast({ title: 'Повторная обработка запущена' });
            } catch (error) {
                const msg =
                    error instanceof Error
                        ? error.message
                        : 'Не удалось запустить обработку';
                toast({ variant: 'destructive', title: 'Ошибка', description: msg });
            }
        },
        [conversation.id, firestore, parentMessage.id, toast]
    );

    const formatDateLabel = (dateStr: string) => {
        const date = parseISO(dateStr);
        if (isToday(date)) return 'Сегодня';
        if (isYesterday(date)) return 'Вчера';
        return format(date, 'd MMMM', { locale: ru });
    };

    const parentPreviewLabel = useMemo(() => {
        const raw =
            (threadE2eeMergedMap[parentMessage.id] ?? parentMessage.text ?? '')
                .replace(/<[^>]+>/g, ' ')
                .replace(/&nbsp;/g, ' ')
                .replace(/\s+/g, ' ')
                .trim();
        if (raw) return raw;
        if ((parentMessage.chatPollId ?? '').trim()) return 'Опрос';
        if (parentMessage.locationShare) return 'Локация';
        if ((parentMessage.attachments?.length ?? 0) > 0) return 'Вложение';
        return 'Сообщение';
    }, [
        parentMessage.attachments,
        parentMessage.chatPollId,
        parentMessage.id,
        parentMessage.locationShare,
        parentMessage.text,
        threadE2eeMergedMap,
    ]);

    return (
        <div 
            className={cn(
                'absolute inset-0 z-50 bg-background flex flex-col animate-in slide-in-from-right duration-300 touch-pan-y',
                asSidebarOnDesktop &&
                    'lg:relative lg:inset-auto lg:z-20 lg:h-full lg:shrink-0 lg:bg-background/52 lg:backdrop-blur-2xl lg:shadow-[-10px_0_34px_rgba(0,0,0,0.42)] lg:animate-none'
            )}
            style={
                asSidebarOnDesktop && desktopWidthPx
                    ? ({ width: `${desktopWidthPx}px` } as React.CSSProperties)
                    : undefined
            }
            onTouchStart={handleTouchStart}
            onTouchEnd={handleTouchEnd}
        >
            <div className={cn(asSidebarOnDesktop && 'lg:hidden')}>
                <ChatWallpaperLayer wallpaper={effectiveThreadWallpaper} />
            </div>

            <div className="relative z-10 flex min-h-0 min-w-0 flex-1 flex-col">
            <div
                className={cn(
                    'flex shrink-0 items-center justify-between gap-2 px-3 pb-2 pt-[max(0.35rem,env(safe-area-inset-top))]',
                    CHAT_HEADER_SAFE_AREA_STRIP,
                    asSidebarOnDesktop &&
                        'lg:border-b lg:border-white/10 lg:bg-transparent lg:backdrop-blur-none'
                )}
            >
                <div className="flex min-w-0 flex-1 items-center justify-between gap-2">
                    {!selection.active ? (
                        <div className="flex min-w-0 items-center gap-3">
                            <MessageSquare className="h-5 w-5 shrink-0 text-primary" />
                            <div className="min-w-0">
                                <h3 className="truncate text-base font-bold lg:text-lg lg:leading-tight">Обсуждение</h3>
                                <p className="hidden lg:block truncate text-xs text-muted-foreground">{parentPreviewLabel}</p>
                            </div>
                        </div>
                    ) : (
                        <SelectionHeader
                            count={selection.ids.size}
                            onCancel={() => setSelection({ active: false, ids: new Set() })}
                            onForward={() => {
                                const selectedMessages = allMessages.filter((m) => selection.ids.has(m.id));
                                sessionStorage.setItem('forwardMessages', JSON.stringify(selectedMessages));
                                router.push('/dashboard/chat/forward');
                            }}
                            onDelete={handleBulkDelete}
                            isProcessing={false}
                            showDelete={Array.from(selection.ids).every(
                                (id) => allMessages.find((m) => m.id === id)?.senderId === currentUser.id
                            )}
                        />
                    )}
                    {!selection.active && (
                        <div className="flex items-center gap-1">
                            {asSidebarOnDesktop && (
                                <>
                                    <Button
                                        variant="ghost"
                                        size="icon"
                                        className="hidden lg:inline-flex h-8 w-8 rounded-md"
                                        aria-label={isExpandedDesktop ? 'Свернуть панель обсуждения' : 'Развернуть панель обсуждения'}
                                        title={isExpandedDesktop ? 'Свернуть' : 'Развернуть'}
                                        onClick={onToggleExpandDesktop}
                                    >
                                        {isExpandedDesktop ? (
                                          <Minimize2 className="h-4 w-4" />
                                        ) : (
                                          <Maximize2 className="h-4 w-4" />
                                        )}
                                    </Button>
                                </>
                            )}
                            <Button variant="ghost" size="icon" className="h-9 w-9 shrink-0 rounded-full lg:h-8 lg:w-8 lg:rounded-md" onClick={onClose}>
                                <X className="h-5 w-5 lg:h-4 lg:w-4" />
                            </Button>
                        </div>
                    )}
                </div>
            </div>

            <div className="relative flex min-h-0 flex-1 flex-col overflow-hidden bg-transparent">
                {!isFullyReady && (
                    <div className="absolute inset-0 z-50 bg-background/80 backdrop-blur-md flex flex-col items-center justify-center space-y-4">
                        <Loader2 className="h-8 w-8 animate-spin text-primary" />
                        <p className="text-xs font-bold uppercase tracking-widest text-muted-foreground">Загрузка...</p>
                    </div>
                )}
                <div className={cn('relative h-full w-full min-h-0 min-w-0 flex-1 overflow-hidden transition-opacity duration-500', isFullyReady ? 'opacity-100' : 'opacity-0')}>
                <ChatFloatingDateLabel
                    label={viewportCalendarDayKey ? formatDateLabel(viewportCalendarDayKey) : null}
                />
                <VideoCircleTailProvider setTailReservePx={setVideoCircleTailReservePx}>
                <ChatViewportScrollerRefContext.Provider value={viewportScrollerRef}>
                <Virtuoso
                    ref={virtuosoRef}
                    data={flatItems}
                    followOutput="auto"
                    alignToBottom
                    scrollerRef={onVirtuosoScrollerRef}
                    startReached={() => handleLoadMore('startReached')}
                    atBottomStateChange={(atBottom) => {
                        atBottomRef.current = atBottom;
                        setShowScrollButton(!atBottom);
                    }}
                    computeItemKey={(index, item) => {
                        if (item.type === 'parent') return `thr-p-${parentMessage.id}`;
                        if (item.type === 'date') return `thr-d-${parentMessage.id}-${item.date}`;
                        if (item.type === 'unread-separator') return `thr-u-${parentMessage.id}-${unreadSeparatorId ?? index}`;
                        return `thr-m-${item.message.id}`;
                    }}
                    increaseViewportBy={increaseViewportBy}
                    minOverscanItemCount={VIRTUOSO_CHAT_MIN_OVERSCAN}
                    rangeChanged={handleRangeChanged}
                    components={{
                        Header: () => isLoadingOlder ? (
                            <div className="p-4 flex items-center justify-center text-muted-foreground">
                                <Loader2 className="h-5 w-5 animate-spin mr-2" />
                                <span className="text-[10px] font-black uppercase tracking-widest">Загрузка ответов...</span>
                            </div>
                        ) : null,
                        Footer: () => (
                            <div
                                className="w-full shrink-0"
                                style={{ height: 12 + videoCircleTailReservePx }}
                                aria-hidden
                            />
                        ),
                    }}
                    itemContent={(index, item) => {
                        if (item.type === 'parent') {
                            const repliesLabel =
                                allMessages.length === 1
                                    ? '1 ответ'
                                    : [2, 3, 4].includes(allMessages.length % 10) &&
                                      ![12, 13, 14].includes(allMessages.length % 100)
                                      ? `${allMessages.length} ответа`
                                      : `${allMessages.length} ответов`;
                            return (
                                <div className="mx-3 mb-4 mt-2">
                                    <ChatMessageItem 
                                        message={parentMessage}
                                        currentUser={currentUser}
                                        allUsers={allUsers}
                                        conversation={conversation}
                                        isSelected={false}
                                        isSelectionActive={false}
                                        editingMessage={null}
                                        onToggleSelection={() => {}}
                                        onEdit={() => {}}
                                        onUpdateMessage={async () => {}}
                                        onDelete={async () => {}}
                                        onCopy={(txt) => {
                                            const cleanText = txt.replace(/<[^>]*>/g, '').replace(/&nbsp;/g, ' ').trim();
                                            navigator.clipboard.writeText(cleanText);
                                            toast({ title: 'Текст скопирован' });
                                        }}
                                        onPin={() => {}}
                                        onReply={(context) => onReplyTo(context)}
                                        onForward={() => {}}
                                        onReact={handleInternalReact}
                                        onOpenImageViewer={handleOpenMediaViewer}
                                        onOpenVideoViewer={handleOpenMediaViewer}
                                        onNavigateToMessage={() => {}}
                                        isThreadMessage={true}
                                        disableContextMenu={true}
                                        chatSettings={chatSettings}
                                        onMentionProfileOpen={onMentionProfileOpen}
                                        onGroupSenderProfileOpen={onGroupSenderProfileOpen}
                                        onGroupSenderWritePrivate={onGroupSenderWritePrivate}
                                        contactProfiles={contactProfiles}
                                        e2eeDecryptedByMessageId={parentE2eeDecryptedByMessageId}
                                        onRetryMediaNorm={handleRetryMediaNorm}
                                    />
                                    <div className="mt-2 px-2 py-1">
                                        <div className="relative flex items-center justify-center">
                                            <div className="absolute inset-x-0 top-1/2 h-px -translate-y-1/2 bg-white/22" />
                                            <span className="relative z-10 shrink-0 rounded-full border border-white/12 bg-background/65 px-3 py-0.5 text-[12px] font-semibold uppercase tracking-wide text-white/82 backdrop-blur-sm">
                                                {repliesLabel}
                                            </span>
                                        </div>
                                    </div>
                                </div>
                            );
                        }
                        if (item.type === 'date') {
                            return <ChatDateListAnchor />;
                        }
                        if (item.type === 'unread-separator') {
                            return (
                                <div className="flex items-center gap-4 px-6 py-4 animate-in fade-in duration-500">
                                    <div className="h-px bg-primary/30 flex-1" />
                                    <span className="text-[10px] font-black uppercase tracking-widest text-primary bg-primary/5 px-3 py-1 rounded-full border border-primary/20">Непрочитанные сообщения</span>
                                    <div className="h-px bg-primary/30 flex-1" />
                                </div>
                            );
                        }
                        const msg = item.message;
                        if (msg.systemEvent && msg.senderId === '__system__') {
                          return <ChatSystemEventDivider event={msg.systemEvent} />;
                        }
                        const isLastInChat = index === flatItems.length - 1;
                        return (
                            <MessageReadOnViewport
                                messageId={msg.id}
                                message={msg}
                                currentUserId={currentUser.id}
                                conversationId={conversation.id}
                                firestore={firestore}
                                canMarkReadByViewport={isFullyReady && hasScrolledToUnread && !suppressReadReceipts}
                                viewportLayoutKey={viewportScrollerKey}
                                sessionReadIds={sessionReadIds}
                                isThread
                                threadParentId={parentMessage.id}
                            >
                                <div className="px-4 py-1">
                                    <ChatMessageItem 
                                        message={msg}
                                        currentUser={currentUser}
                                        allUsers={allUsers}
                                        conversation={conversation}
                                        isSelected={selection.ids.has(msg.id)}
                                        isSelectionActive={selection.active}
                                        editingMessage={editingMessage?.id === msg.id ? editingMessage : null}
                                        onToggleSelection={(id) => setSelection(prev => {
                                            const next = new Set(prev.ids);
                                            if (next.has(id)) next.delete(id); else next.add(id);
                                            return { active: true, ids: next };
                                        })}
                                        onEdit={(edit) => setEditingMessage(edit)}
                                        onUpdateMessage={handleThreadUpdateMessage}
                                        onDelete={onDeleteMessage}
                                        onCopy={(txt) => {
                                            const cleanText = txt.replace(/<[^>]*>/g, '').replace(/&nbsp;/g, ' ').trim();
                                            navigator.clipboard.writeText(cleanText);
                                            toast({ title: 'Текст скопирован' });
                                        }}
                                        onPin={() => {}}
                                        onReply={(context) => onReplyTo(context)}
                                        onForward={(m) => onForwardMessage(m)}
                                        onReact={handleInternalReact}
                                        onOpenImageViewer={handleOpenMediaViewer}
                                        onOpenVideoViewer={handleOpenMediaViewer}
                                        onNavigateToMessage={() => {}}
                                        isThreadMessage={true}
                                        isLastInChat={isLastInChat}
                                        chatSettings={chatSettings}
                                        onMentionProfileOpen={onMentionProfileOpen}
                                        onGroupSenderProfileOpen={onGroupSenderProfileOpen}
                                        onGroupSenderWritePrivate={onGroupSenderWritePrivate}
                                        onSaveStickerGif={onSaveStickerGif}
                                        contactProfiles={contactProfiles}
                                        e2eeDecryptedByMessageId={threadE2eeMergedMap}
                                        onRetryMediaNorm={handleRetryMediaNorm}
                                    />
                                </div>
                            </MessageReadOnViewport>
                        );
                    }}
                />
                </ChatViewportScrollerRefContext.Provider>
                </VideoCircleTailProvider>

                <ChatAnchor
                    suppressed={suppressFloatingAnchor || mediaViewerState.isOpen || documentFullscreen}
                    isVisible={showScrollButton}
                    unreadCount={unreadCount}
                    lastReaction={null}
                    onClick={handleAnchorClick}
                    onNavigateToReaction={() => {}}
                />
                </div>
            </div>

            {!selection.active && (
                <div className="relative shrink-0 border-t border-transparent bg-transparent p-2">
                    <ChatMessageInput
                        onSendMessage={handleSendMessage}
                        onSendLocationShare={handleSendLocationShare}
                        onSendPoll={handleSendPoll}
                        onUpdateMessage={onUpdateMessage}
                        replyingTo={replyingTo}
                        onCancelReply={() => setReplyingTo(null)}
                        editingMessage={editingMessage}
                        onCancelEdit={() => setEditingMessage(null)}
                        conversation={conversation}
                        currentUser={currentUser}
                        allUsers={allUsers}
                        contactProfiles={contactProfiles}
                        isPartnerDeleted={isPartnerDeleted}
                        composerLocked={composerLocked}
                        composerLockedHint={composerLockedHint}
                        draftScopeKey={`t:${conversation.id}:${parentMessage.id}`}
                        onRestoreDraftReply={(reply) => setReplyingTo(reply)}
                    />
                </div>
            )}
            </div>

            <MediaViewer 
                isOpen={mediaViewerState.isOpen} 
                onOpenChange={(open) => setMediaViewerState(prev => ({ ...prev, isOpen: open }))} 
                media={threadMediaItems} 
                startIndex={mediaViewerState.startIndex} 
                currentUserId={currentUser.id} 
                allUsers={allUsers} 
                onReply={(m) => {
                    const replyContext = getReplyPreview(m, allUsers);
                    onReplyTo(replyContext);
                }} 
                onForward={onForwardMessage} 
                onDelete={onDeleteMessage} 
                navigateToMessage={onNavigateToMessage}
            />
        </div>
    );
}
