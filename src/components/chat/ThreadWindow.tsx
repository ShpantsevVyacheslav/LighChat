
'use client';

import React, { useState, useMemo, useEffect, useLayoutEffect, useRef, useCallback } from 'react';
import { useFirestore, useMemoFirebase, useStorage, useCollection } from '@/firebase';
import { collection, query, doc, updateDoc, increment, orderBy, setDoc, getDocs, where, limit, documentId, writeBatch, onSnapshot, deleteDoc, serverTimestamp } from 'firebase/firestore';
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
} from '@/lib/types';
import type { ChatPollCreateInput } from '@/components/chat/ChatAttachPollDialog';
import { Button } from '@/components/ui/button';
import { Separator } from '@/components/ui/separator';
import { ChatMessageItem } from './ChatMessageItem';
import { ChatMessageInput } from './ChatMessageInput';
import { ChatWallpaperLayer } from './ChatWallpaperLayer';
import { SelectionHeader } from './SelectionHeader';
import { ChatAnchor } from './ChatAnchor';
import { X, MessageSquare, Loader2, ChevronDown } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import { parseISO, isToday, isYesterday, format } from 'date-fns';
import { ru } from 'date-fns/locale';
import { useRouter } from 'next/navigation';
import { MediaViewer, type MediaViewerItem } from '@/components/chat/media-viewer';
import { getReplyPreview } from '@/lib/chat-utils';
import { HISTORY_PAGE_SIZE, INITIAL_MESSAGE_LIMIT } from '@/components/chat/chat-message-limits';
import { ChatDateListAnchor } from '@/components/chat/ChatDateListAnchor';
import { ChatFloatingDateLabel } from '@/components/chat/ChatFloatingDateLabel';
import { firstCalendarDayInViewport } from '@/components/chat/visible-range-date';
import { isGridGalleryAttachment } from '@/components/chat/attachment-visual';
import { VIRTUOSO_CHAT_INCREASE_VIEWPORT, VIRTUOSO_CHAT_MIN_OVERSCAN } from '@/components/chat/virtuoso-chat-config';
import { VideoCircleTailProvider } from '@/components/chat/video-circle-tail-context';
import { cn } from '@/lib/utils';
import { useSettings } from '@/hooks/use-settings';
import { GEOLOCATION_FIRESTORE_LOG } from '@/lib/geolocation-client';
import { scheduleFirestoreListen } from '@/firebase/schedule-firestore-listen';
import {
    ChatViewportScrollerRefContext,
    MessageReadOnViewport,
} from '@/components/chat/message-read-on-viewport';
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
    /** Прокрутка к сообщению в треде (например, по якорю «реакция» из основного чата). */
    highlightThreadMessageId?: string | null;
    onHighlightThreadMessageConsumed?: () => void;
    /** Клик по @ в тексте сообщения ветки — открыть профиль (родительский `ChatWindow`). */
    onMentionProfileOpen?: (userId: string) => void;
    /** Группа: меню отправителя — личный чат (родительский `ChatWindow`). */
    onGroupSenderWritePrivate?: (userId: string) => void | Promise<void>;
    /** Сохранить стикер/GIF из сообщения в пак текущего пользователя. */
    onSaveStickerGif?: (attachment: ChatAttachment) => void;
    /** Скрыть плавающий якорь (оверлей профиля родителя — тот же высокий z-index). */
    suppressFloatingAnchor?: boolean;
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
    highlightThreadMessageId = null,
    onHighlightThreadMessageConsumed,
    onMentionProfileOpen,
    onGroupSenderWritePrivate,
    onSaveStickerGif,
    suppressFloatingAnchor = false,
}: ThreadWindowProps) {
    const firestore = useFirestore();
    const storage = useStorage();
    const { toast } = useToast();
    const router = useRouter();
    const { chatSettings } = useSettings();
    
    const [messages, setMessages] = useState<ChatMessage[]>([]);
    const [displayLimit, setDisplayLimit] = useState(INITIAL_MESSAGE_LIMIT);
    const [hasMore, setHasMore] = useState(true);
    const [isLoadingOlder, setIsLoadingOlder] = useState(false);
    const [isFullyReady, setIsFullyReady] = useState(false);
    const [optimisticMessages, setOptimisticMessages] = useState<ChatMessage[]>([]);
    const [editingMessage, setEditingMessage] = useState<{ id: string; text: string; attachments?: ChatAttachment[] } | null>(null);
    const [replyingTo, setReplyingTo] = useState<ReplyContext | null>(null);
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

    const handleLoadMore = useCallback(() => {
        if (!hasMore || isLoadingOlder) return;
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

    const allMessages = useMemo(() => {
        const remoteMessageIds = new Set(messages.map(rm => rm.id));
        const uniqueOptimistic = optimisticMessages.filter(om => !remoteMessageIds.has(om.id));
        const combined = [...messages, ...uniqueOptimistic];
        
        const clearedAt = conversation.clearedAt?.[currentUser.id];
        return clearedAt 
            ? combined.filter(m => new Date(m.createdAt) > new Date(clearedAt))
            : combined;
    }, [messages, optimisticMessages, conversation.clearedAt, currentUser.id]);

    const unreadCount = useMemo(() => {
        return allMessages.filter(m => m.senderId !== currentUser.id && !m.readAt).length;
    }, [allMessages, currentUser.id]);

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
            const oldestUnread = allMessages.find(m => m.senderId !== currentUser.id && !m.readAt);
            if (oldestUnread) {
                setUnreadSeparatorId(oldestUnread.id);
            }
        }
    }, [isFullyReady, unreadCount, unreadSeparatorId, allMessages, currentUser.id]);

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
            const len = flatItemsRef.current.length;
            if (len > 0) {
                requestAnimationFrame(() => {
                    requestAnimationFrame(() => {
                        virtuosoRef.current?.scrollToIndex({ index: len - 1, align: 'end', behavior: 'auto' });
                    });
                });
            }
        } else if (atBottomRef.current) {
            v.scrollBy({ top: delta, behavior: 'auto' });
        }
    }, [videoCircleTailReservePx]);

    const pendingScrollToBottomAfterSendRef = useRef(false);
    const pendingPrependAdjustRef = useRef<{ scrollTop: number; scrollHeight: number } | null>(null);
    const loadMoreCooldownUntilRef = useRef(0);

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
        const now = Date.now();
        if (now < loadMoreCooldownUntilRef.current) return;
        if (!isFullyReady || !hasMore || isLoadingOlder) return;
        const scroller = viewportScrollerRef.current;
        if (!scroller) return;
        if (scroller.scrollTop > TOP_LOAD_THRESHOLD_PX) return;
        loadMoreCooldownUntilRef.current = now + LOAD_MORE_COOLDOWN_MS;
        handleLoadMore();
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
        tryLoadMoreByTopPosition();
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
    }, [tryLoadMoreByTopPosition, isFullyReady, firestore, conversation.id, currentUser.id, parentMessage.id, syncViewportCalendarDay]);

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
            const uploadedAttachments: ChatAttachment[] = [...prebuilt];
            if (files.length > 0) {
                const { uploadFile: internalUpload } = await import('./ChatMessageInput');
                for (const file of files) {
                    const path = `chat-attachments/${conversation.id}/threads/${parentMessage.id}/${Date.now()}-${file.name.replace(/\s+/g, '_')}`;
                    const uploaded = await internalUpload(file, path, storage);
                    uploadedAttachments.push(uploaded);
                }
            }

            const messageData: Partial<ChatMessage> = {
                id: messageId,
                senderId: currentUser.id,
                createdAt: now,
                readAt: null,
                attachments: uploadedAttachments,
                ...(text && { text: text }),
                ...(replyContext && { replyTo: replyContext })
            };

            await setDoc(newDocRef, messageData);

            const parentMessageRef = doc(firestore, `conversations/${conversation.id}/messages`, parentMessage.id);
            const convRef = doc(firestore, 'conversations', conversation.id);
            const otherParticipantIds = conversation.participantIds.filter(id => id !== currentUser.id);
            
            const threadUnreadUpdates: Record<string, any> = {};
            otherParticipantIds.forEach(id => {
                threadUnreadUpdates[`unreadThreadCounts.${id}`] = increment(1);
            });

            const strip = text ? text.replace(/<[^>]*>/g, '') : '';
            let threadLastText = strip;
            if (!threadLastText) {
                if (prebuilt.some((a) => a.name.startsWith('gif_'))) threadLastText = 'GIF';
                else if (prebuilt.some((a) => a.name.startsWith('sticker_'))) threadLastText = 'Стикер';
                else if (files.length === 1 && files[0].name.startsWith('sticker_')) threadLastText = 'Стикер';
                else if (files.length > 0 || prebuilt.length > 0) threadLastText = 'Вложение';
                else threadLastText = 'Сообщение';
            }

            updateDoc(parentMessageRef, {
                threadCount: increment(1),
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
        }
    };

    const handleSendLocationShare = useCallback(
        async (share: ChatLocationShare, replyContext: ReplyContext | null, meta: ChatLocationSendMeta) => {
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
        [firestore, currentUser, conversation.id, conversation.participantIds, parentMessage.id]
    );

    const handleSendPoll = useCallback(
        async (input: ChatPollCreateInput, replyContext: ReplyContext | null) => {
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
                    id: pollId,
                    question: input.question,
                    options: input.options,
                    creatorId: currentUser.id,
                    status: 'active',
                    isAnonymous: input.isAnonymous,
                    createdAt: serverTimestamp(),
                    votes: {},
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
        [firestore, currentUser, conversation.id, conversation.participantIds, parentMessage.id]
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

    const formatDateLabel = (dateStr: string) => {
        const date = parseISO(dateStr);
        if (isToday(date)) return 'Сегодня';
        if (isYesterday(date)) return 'Вчера';
        return format(date, 'd MMMM', { locale: ru });
    };

    return (
        <div 
            className="absolute inset-0 z-50 bg-background flex flex-col animate-in slide-in-from-right duration-300 touch-pan-y"
            onTouchStart={handleTouchStart}
            onTouchEnd={handleTouchEnd}
        >
            <ChatWallpaperLayer wallpaper={chatSettings.chatWallpaper} />

            <div className="relative z-10 flex min-h-0 min-w-0 flex-1 flex-col">
            <div
                className={cn(
                    'flex shrink-0 items-center justify-between gap-2 px-4 pb-2 pt-[max(0.35rem,env(safe-area-inset-top))]',
                    CHAT_HEADER_SAFE_AREA_STRIP
                )}
            >
                <div className="flex min-w-0 flex-1 items-center justify-between gap-2">
                    {!selection.active ? (
                        <div className="flex min-w-0 items-center gap-3">
                            <MessageSquare className="h-5 w-5 shrink-0 text-primary" />
                            <h3 className="truncate text-sm font-bold">Обсуждение</h3>
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
                        <Button variant="ghost" size="icon" className="h-9 w-9 shrink-0 rounded-full" onClick={onClose}>
                            <X className="h-5 w-5" />
                        </Button>
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
                    startReached={handleLoadMore}
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
                    increaseViewportBy={VIRTUOSO_CHAT_INCREASE_VIEWPORT}
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
                            return (
                                <div className="p-2 rounded-2xl bg-muted/50 mb-4 mx-4 mt-2">
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
                                        onGroupSenderWritePrivate={onGroupSenderWritePrivate}
                                    />
                                    <div className="flex items-center gap-2 px-4 py-2 mt-2">
                                        <span className="text-[10px] font-bold uppercase tracking-widest text-muted-foreground opacity-60">
                                            {allMessages.length} {allMessages.length === 1 ? 'ответ' : [2,3,4].includes(allMessages.length % 10) ? 'ответа' : 'ответов'}
                                        </span>
                                        <Separator className="flex-1 opacity-20" />
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
                        const isLastInChat = index === flatItems.length - 1;
                        return (
                            <MessageReadOnViewport
                                messageId={msg.id}
                                message={msg}
                                currentUserId={currentUser.id}
                                conversationId={conversation.id}
                                firestore={firestore}
                                canMarkReadByViewport={isFullyReady && hasScrolledToUnread}
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
                                        onUpdateMessage={onUpdateMessage}
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
                                        onGroupSenderWritePrivate={onGroupSenderWritePrivate}
                                        onSaveStickerGif={onSaveStickerGif}
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
                        isPartnerDeleted={isPartnerDeleted}
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
