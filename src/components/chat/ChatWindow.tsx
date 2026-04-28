
'use client';

import React, { useState, useMemo, useEffect, useLayoutEffect, useRef, useCallback } from 'react';
import { useDoc, useFirestore, useMemoFirebase, useStorage } from '@/firebase';
import { getAuth } from 'firebase/auth';
import { getFunctions, httpsCallable } from 'firebase/functions';
import { collection, query, doc, updateDoc, orderBy, setDoc, getDocs, limit, onSnapshot, increment, documentId, where, getDoc, arrayUnion, arrayRemove, deleteDoc, serverTimestamp, deleteField } from 'firebase/firestore';
import { E2EE_LAST_MESSAGE_PREVIEW, autoEnableE2eeForNewDirectChat, isEncryptableMimeV2 } from '@/lib/e2ee';
import { inferKindHintFromFileName } from '@/lib/e2ee/infer-kind-hint';
import { useE2eeConversation } from '@/hooks/use-e2ee-conversation';
import { useE2eeMediaAttachments } from '@/hooks/use-e2ee-media-attachments';
import { useE2eeHydratedMessages } from '@/hooks/use-e2ee-hydrated-messages';
import { Virtuoso, type VirtuosoHandle } from 'react-virtuoso';

import type {
  User,
  Conversation,
  ChatMessage,
  ChatAttachment,
  ReplyContext,
  ReactionDetail,
  UserChatIndex,
  ChatLocationShare,
  ChatLocationSendMeta,
  PinnedMessage,
  PlatformSettingsDoc,
  UserContactsIndex,
} from '@/lib/types';
import type { ChatPollCreateInput } from '@/components/chat/ChatAttachPollDialog';
import { chatPollFirestoreFields } from '@/lib/chat-poll-create';
import { cn } from '@/lib/utils';
import { format, isToday, isYesterday, parseISO } from 'date-fns';
import { ru } from 'date-fns/locale';
import {
  getUnreadIncrementUpdate,
  markManyMessagesAsRead,
  markConversationAsRead,
  getReplyPreview,
} from '@/lib/chat-utils';
import { isIncomingUnreadForViewer } from '@/lib/message-read-status';
import {
  addChatAttachmentToUserStickerPack,
  addChatImageAsSquareStickerToPack,
  createUserStickerPack,
} from '@/lib/user-sticker-packs-client';
import { USER_STICKER_MAX_FILE_BYTES } from '@/lib/user-sticker-packs';
import { isSavedMessagesChat } from '@/lib/saved-messages-chat';
import { CHAT_GLASS_PANEL, CHAT_HEADER_SAFE_AREA_STRIP } from '@/lib/chat-glass-styles';
import { buildGroupMentionCandidates, extractMentionedUserIdsFromPlainText } from '@/lib/group-mention-utils';
import { createOrOpenDirectChat } from '@/lib/direct-chat';
import { canStartDirectChat } from '@/lib/user-chat-policy';
import {
  directChatComposerBlockedHint,
  isEitherBlockingFromUserIds,
  normalizeBlockedUserIds,
} from '@/lib/user-block-utils';
import { SelectionHeader } from '@/components/chat/SelectionHeader';
import { ChatParticipantProfile } from '@/components/chat/ChatParticipantProfile';
import type { ChatProfileSource, ChatProfileSubMenu } from '@/components/chat/ChatParticipantProfile';
import { DurakWebGameDialog } from '@/components/chat/games/durak/DurakWebGameDialog';
import { ChatMessageItem } from './ChatMessageItem';
import { ChatMessageInput, type ChatMessageInputHandle } from './ChatMessageInput';
import { initiateCall } from './AudioCallOverlay';
import { ChatSearchOverlay } from './ChatSearchOverlay';
import { ChatAnchor } from './ChatAnchor';
import { ThreadWindow } from './ThreadWindow';
import { PinnedMessageBar } from './PinnedMessageBar';
import { ChatWallpaperLayer } from './ChatWallpaperLayer';
import { MediaViewer, type MediaViewerItem } from '@/components/chat/media-viewer';

import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { useToast } from '@/hooks/use-toast';
import { ArrowLeft, Loader2, Search, X, Video, Phone, MessageCircle } from 'lucide-react';
import { Badge } from '@/components/ui/badge';
import { useRouter } from 'next/navigation';
import { useSettings } from '@/hooks/use-settings';
import { DASHBOARD_GAME_ID_QUERY } from '@/lib/dashboard-conversation-url';
import { HISTORY_PAGE_SIZE, INITIAL_MESSAGE_LIMIT } from '@/components/chat/chat-message-limits';
import { ChatDateSeparatorRow } from '@/components/chat/ChatDateSeparatorRow';
import {
  parseE2eeEncryptedDataTypes,
  resolveEffectiveE2eeEncryptedDataTypes,
} from '@/lib/e2ee/e2ee-data-type-policy';
import { ChatSystemEventDivider } from '@/components/chat/ChatSystemEventDivider';
import { buildChatListRows, type ChatListRow } from '@/components/chat/build-chat-message-groups';
import { isGridGalleryAttachment } from '@/components/chat/attachment-visual';
import { getVirtuosoChatIncreaseViewport, VIRTUOSO_CHAT_MIN_OVERSCAN } from '@/components/chat/virtuoso-chat-config';
import { GEOLOCATION_FIRESTORE_LOG } from '@/lib/geolocation-client';
import { VideoCircleTailProvider } from '@/components/chat/video-circle-tail-context';
import { deleteDocumentNonBlocking, setDocumentNonBlocking, updateDocumentNonBlocking } from '@/firebase/non-blocking-updates';
import { useChatConversationPrefs } from '@/hooks/use-chat-conversation-prefs';
import { useStarredInConversation } from '@/hooks/use-starred-in-conversation';
import { buildStarredMessageDocId } from '@/lib/starred-chat-messages';
import { scheduleFirestoreListen } from '@/firebase/schedule-firestore-listen';
import { StickerPackPickerDialog } from '@/components/chat/StickerPackPickerDialog';
import {
  ChatViewportScrollerRefContext,
  MessageReadOnViewport,
} from '@/components/chat/message-read-on-viewport';
import {
  isFirestorePermissionDeniedError,
  logFirestorePermissionDenied,
} from '@/lib/firestore-permission-debug';
import {
  incrementChatPerfCounter,
  markChatPerf,
  measureChatPerf,
} from '@/components/chat/chat-performance-metrics';
import { participantListAvatarUrl } from '@/lib/user-avatar-display';
import { resolveContactDisplayName } from '@/lib/contact-display-name';
import { resolvePresenceLabel } from '@/lib/presence-visibility';
import {
  MAX_PINNED_MESSAGES,
  conversationPinnedList,
  pickPinnedBarIndexForViewport,
  sortPinnedMessagesByTime,
} from '@/lib/chat-pinned-messages';

interface ChatWindowProps {
  conversation: Conversation;
  currentUser: User;
  allUsers: User[];
  onBack: () => void;
  onSelectConversation: (conversationId: string) => void;
  /** Смещение оверлея поиска по сообщениям от левого края viewport (колонка чата на /dashboard/chat). */
  messageSearchBlurInsetLeftPx?: number;
  /** Query `focusMessageId`: открыть чат с прокруткой к сообщению (избранное и т.д.). */
  focusMessageId?: string | null;
  onFocusMessageConsumed?: () => void;
  threadRootMessageId?: string | null;
  onThreadRootMessageConsumed?: () => void;
  /** URL-контракт открытия профиля (например, переход из «Контактов»). */
  initialProfileOpen?: boolean;
  initialProfileFocusUserId?: string | null;
  initialProfileSource?: ChatProfileSource | null;
  onInitialProfileConsumed?: () => void;
}

/** Подложки шапки чата на фоне обоев — без обводки, только лёгкое стекло */
const chatHeaderUserGlass = CHAT_GLASS_PANEL;
const chatHeaderIconGlass =
  'rounded-xl bg-background/28 dark:bg-background/20 backdrop-blur-md shadow-sm';

/** Цвета иконок в духе iOS (SF Symbols): на светлой теме — достаточный контраст на стекле */
const CHAT_HEADER_IOS = {
  threads: 'text-[#007AFF] dark:text-[#64B5FF]',
  /** Тёмная тема: светлая иконка, чтобы не терялась на «стеклянной» подложке шапки */
  search: 'text-neutral-900 dark:text-white',
  callVideo: 'text-[#34C759] dark:text-[#48E074]',
  callAudio: 'text-[#34C759] dark:text-[#48E074]',
} as const;

const TOP_LOAD_THRESHOLD_PX = 40;
const LOAD_MORE_COOLDOWN_MS = 600;

export function ChatWindow({ 
  conversation, 
  currentUser, 
  allUsers, 
  onBack, 
  onSelectConversation, 
  messageSearchBlurInsetLeftPx = 0,
  focusMessageId = null,
  onFocusMessageConsumed,
  threadRootMessageId = null,
  onThreadRootMessageConsumed,
  initialProfileOpen = false,
  initialProfileFocusUserId = null,
  initialProfileSource = null,
  onInitialProfileConsumed,
}: ChatWindowProps) {
  const firestore = useFirestore();
  const storage = useStorage();
  const { toast } = useToast();
  const router = useRouter();
  const [openGameId, setOpenGameId] = useState<string | null>(null);

  useEffect(() => {
    if (typeof window === 'undefined') return;
    const p = new URLSearchParams(window.location.search || '');
    const gid = p.get(DASHBOARD_GAME_ID_QUERY);
    if (gid && gid.trim()) setOpenGameId(gid.trim());
  }, [conversation.id]);

  const closeGameDialog = useCallback(() => {
    setOpenGameId(null);
    if (typeof window === 'undefined') return;
    const p = new URLSearchParams(window.location.search || '');
    p.delete(DASHBOARD_GAME_ID_QUERY);
    const q = p.toString();
    const url = q ? `${window.location.pathname}?${q}` : window.location.pathname;
    router.replace(url);
  }, [router]);
  const { chatSettings, privacySettings } = useSettings();
  const { prefs } = useChatConversationPrefs(currentUser.id, conversation.id);
  const { starredMessageIds } = useStarredInConversation(currentUser.id, conversation.id);
  const suppressReadReceipts =
    prefs?.suppressReadReceipts === true || privacySettings.showReadReceipts === false;
  const globalE2eeTypes = parseE2eeEncryptedDataTypes(privacySettings.e2eeEncryptedDataTypes);
  const effectiveE2eeTypes = resolveEffectiveE2eeEncryptedDataTypes({
    global: globalE2eeTypes,
    override: conversation.e2eeEncryptedDataTypesOverride ?? null,
  });
  const effectiveWallpaper =
    prefs?.chatWallpaper != null && prefs.chatWallpaper !== ''
      ? prefs.chatWallpaper
      : chatSettings.chatWallpaper;
  const e2eeConv = useE2eeConversation(firestore, conversation, currentUser.id);
  const e2eeMediaApi = useE2eeMediaAttachments({
    storage,
    conversationId: conversation.id,
    getChatKeyRawV2ForEpoch: e2eeConv.getChatKeyRawV2ForEpoch,
    epoch: e2eeConv.e2eeEpoch,
  });
  const [e2eePlaintextByMessageId, setE2eePlaintextByMessageId] = useState<Record<string, string>>({});
  const userContactsRef = useMemoFirebase(
    () => (firestore ? doc(firestore, 'userContacts', currentUser.id) : null),
    [firestore, currentUser.id]
  );
  const { data: userContactsIndex } = useDoc<UserContactsIndex>(userContactsRef);
  // E2E enable UI removed from main chat header (kept via auto-enable paths).

  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [displayLimit, setDisplayLimit] = useState(INITIAL_MESSAGE_LIMIT);
  const [hasMore, setHasMore] = useState(true);
  const [isLoadingOlder, setIsLoadingOlder] = useState(false);
  const [optimisticMessages, setOptimisticMessages] = useState<ChatMessage[]>([]);
  const [editingMessage, setEditingMessage] = useState<{ id: string; text: string; attachments?: ChatAttachment[] } | null>(null);
  const [replyingTo, setReplyingTo] = useState<ReplyContext | null>(null);
  const [selection, setSelection] = useState({ active: false, ids: new Set<string>() });
  const [mediaViewerState, setMediaViewerState] = useState({ isOpen: false, startIndex: 0 });
  const [isProfileOpen, setIsProfileOpen] = useState(false);
  const [profileInitialSubMenu, setProfileInitialSubMenu] = useState<ChatProfileSubMenu | null>(null);
  /** Просмотр карточки участника группы (клик по @ в сообщении). */
  const [profileFocusUserId, setProfileFocusUserId] = useState<string | null>(null);
  const [profileSource, setProfileSource] = useState<ChatProfileSource>('chat');
  const [isSearchActive, setIsSearchActive] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  /** Индекс в sortedPins: какой закреп показан в шапке (синхрон с viewport + клик). */
  const [barPinIndex, setBarPinIndex] = useState(0);
  const [showScrollButton, setShowScrollButton] = useState(false);
  const [isFullyReady, setIsFullyReady] = useState(false);
  const [hasScrolledToUnread, setHasScrolledToUnread] = useState(false);
  const [selectedThreadMessage, setSelectedThreadMessage] = useState<ChatMessage | null>(null);
  const [threadPanelWidth, setThreadPanelWidth] = useState(520);
  const [threadPanelExpanded, setThreadPanelExpanded] = useState(false);
  /** После открытия треда по реакции — id ответа в треде для прокрутки и подсветки. */
  const [threadReactionScrollToId, setThreadReactionScrollToId] = useState<string | null>(null);
  const [stickerSaveOpen, setStickerSaveOpen] = useState(false);
  const [stickerSaveAttachment, setStickerSaveAttachment] = useState<ChatAttachment | null>(null);
  const [stickerSaveBusy, setStickerSaveBusy] = useState(false);
  const [stickerSaveMode, setStickerSaveMode] = useState<'copy' | 'normalize_sticker'>('copy');
  /** Якорь с z-[10050] — скрываем при оверлеях и при document fullscreen (видео). */
  const [documentFullscreen, setDocumentFullscreen] = useState(false);
  const [isBulkProcessing, setIsBulkProcessing] = useState(false);
  const [unreadSeparatorId, setUnreadSeparatorId] = useState<string | null>(null);
  const hasClearedSeparatorRef = useRef(false);
  /** Не снимать разделитель по rangeChanged «у низа», пока не выполнен стартовый scroll к непрочитанным (иначе alignToBottom съедает ленту до таймера). */
  const hasScrolledToUnreadRef = useRef(false);
  /** Якорь: 0 — следующий клик ведёт к первому непрочитанному; 1 — к низу и сброс счётчика. */
  const anchorUnreadStepRef = useRef(0);
  const suppressUnreadResetKeyRef = useRef('');

  const messageInputRef = useRef<ChatMessageInputHandle>(null);
  const virtuosoRef = useRef<VirtuosoHandle>(null);
  /** Скроллер Virtuoso для IntersectionObserver (реальная видимость строки, без overscan range). */
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
  const prevConvIdRef = useRef(conversation.id);
  /** Догрузка истории, пока целевое сообщение не попадёт в flatItems (реакция, поиск, закреп). */
  const pendingNavigateMessageIdRef = useRef<string | null>(null);
  const currentVisibleRange = useRef({ startIndex: 0, endIndex: 0 });
  const atBottomRef = useRef(true);
  const [videoCircleTailReservePx, setVideoCircleTailReservePxState] = useState(0);
  const prevTailReserveRef = useRef(0);
  const threadPanelResizingRef = useRef(false);

  const setVideoCircleTailReservePx = useCallback((px: number) => {
    setVideoCircleTailReservePxState(Math.max(0, Math.round(px)));
  }, []);

  useEffect(() => {
    hasScrolledToUnreadRef.current = hasScrolledToUnread;
  }, [hasScrolledToUnread]);

  useEffect(() => {
    if (typeof window === 'undefined') return;
    const storedWidth = Number(
      window.localStorage.getItem('chat_thread_panel_width') ?? ''
    );
    if (Number.isFinite(storedWidth) && storedWidth >= 420 && storedWidth <= 1280) {
      setThreadPanelWidth(storedWidth);
    }
    const storedExpanded = window.localStorage.getItem('chat_thread_panel_expanded');
    if (storedExpanded === '1') setThreadPanelExpanded(true);
  }, []);

  useEffect(() => {
    if (typeof window === 'undefined') return;
    window.localStorage.setItem(
      'chat_thread_panel_width',
      String(Math.round(threadPanelWidth))
    );
  }, [threadPanelWidth]);

  useEffect(() => {
    if (typeof window === 'undefined') return;
    window.localStorage.setItem(
      'chat_thread_panel_expanded',
      threadPanelExpanded ? '1' : '0'
    );
  }, [threadPanelExpanded]);

  const threadRootHandledRef = useRef<string | null>(null);
  useEffect(() => {
    threadRootHandledRef.current = null;
  }, [threadRootMessageId, conversation.id]);

  useEffect(() => {
    if (!firestore || !conversation.id || !threadRootMessageId) return;
    if (threadRootHandledRef.current === threadRootMessageId) return;
    threadRootHandledRef.current = threadRootMessageId;
    const convId = conversation.id;
    const rootId = threadRootMessageId;
    let cancelled = false;
    void getDoc(doc(firestore, `conversations/${convId}/messages`, rootId))
      .then((snap) => {
        if (cancelled) return;
        if (!snap.exists()) {
          toast({ title: 'Обсуждение не найдено' });
          onThreadRootMessageConsumed?.();
          return;
        }
        setSelectedThreadMessage({ ...snap.data(), id: snap.id } as ChatMessage);
        onThreadRootMessageConsumed?.();
      })
      .catch((e) => {
        console.warn('[LighChat] open thread from URL', e);
        if (!cancelled) {
          toast({ title: 'Не удалось открыть обсуждение', variant: 'destructive' });
          onThreadRootMessageConsumed?.();
        }
      });
    return () => {
      cancelled = true;
      if (threadRootHandledRef.current === rootId) threadRootHandledRef.current = null;
    };
  }, [firestore, conversation.id, threadRootMessageId, toast, onThreadRootMessageConsumed]);

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

  // --- Firestore Messages Listener ---
  useEffect(() => {
    if (!firestore || !conversation.id) return;
    
    // Reset internal state on conversation switch
    if (prevConvIdRef.current !== conversation.id) {
        setMessages([]);
        setIsFullyReady(false);
        setHasScrolledToUnread(false);
        hasScrolledToUnreadRef.current = false;
        anchorUnreadStepRef.current = 0;
        setUnreadSeparatorId(null);
        hasClearedSeparatorRef.current = false;
        setDisplayLimit(INITIAL_MESSAGE_LIMIT);
        setHasMore(true);
        setIsLoadingOlder(false);
        setVideoCircleTailReservePxState(0);
        prevTailReserveRef.current = 0;
        sessionReadIds.current.clear();
        pendingNavigateMessageIdRef.current = null;
        setThreadReactionScrollToId(null);
        setSelectedThreadMessage(null);
        setE2eePlaintextByMessageId({});
        setReplyingTo(null);
        setEditingMessage(null);
        suppressUnreadResetKeyRef.current = '';
        prevConvIdRef.current = conversation.id;
    }

    const msgCollection = collection(firestore, `conversations/${conversation.id}/messages`);
    const q = query(msgCollection, orderBy('createdAt', 'desc'), limit(displayLimit));
    
    return scheduleFirestoreListen(() =>
      onSnapshot(
        q,
        (snap) => {
          const msgs = snap.docs.map((d) => ({ ...d.data(), id: d.id } as ChatMessage)).reverse();
        setMessages(msgs);
        setHasMore(snap.docs.length === displayLimit);
        setIsFullyReady(true);
          setIsLoadingOlder(false);
        },
        (err) => {
        console.error("Chat fetch error:", err);
          if (process.env.NODE_ENV === "development" && firestore) {
            console.info(
              "[LighChat] permission-denied → опубликуйте правила: npm run deploy:firestore · Firebase projectId:",
              firestore.app.options.projectId
            );
          }
        setIsFullyReady(true);
          setIsLoadingOlder(false);
        }
      )
    );
  }, [firestore, conversation.id, displayLimit]);

  const handleLoadMore = useCallback((source: 'startReached' | 'scroll-fallback' | 'manual' = 'manual') => {
    incrementChatPerfCounter(`chat-load-more-trigger:${source}`);
    if (!hasMore || isLoadingOlder || loadMoreInFlightRef.current) {
      incrementChatPerfCounter('chat-load-more-skipped');
      return;
    }
    loadMoreInFlightRef.current = true;
    incrementChatPerfCounter('chat-load-more-accepted');
    markChatPerf('chat-load-more-start');
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

  const isSelfSavedChat = useMemo(
    () => isSavedMessagesChat(conversation, currentUser.id),
    [conversation, currentUser.id]
  );
  const otherId = useMemo(() => {
    if (isSelfSavedChat) return null;
    return conversation.participantIds.find((id) => id !== currentUser.id) ?? null;
  }, [conversation.participantIds, currentUser.id, isSelfSavedChat]);
  const otherUser = useMemo(() => (otherId ? allUsers.find((u) => u.id === otherId) : undefined), [allUsers, otherId]);
  const otherPresenceLabel = useMemo(
    () => (otherUser ? resolvePresenceLabel(otherUser) : 'Не в сети'),
    [otherUser]
  );
  const isPartnerDeleted = useMemo(
    () => !conversation.isGroup && !isSelfSavedChat && !!otherUser?.deletedAt,
    [conversation.isGroup, isSelfSavedChat, otherUser]
  );

  const selfUserRef = useMemoFirebase(
    () => (!firestore || !currentUser.id ? null : doc(firestore, 'users', currentUser.id)),
    [firestore, currentUser.id]
  );
  const { data: selfUserLive } = useDoc<User>(selfUserRef);

  const partnerUserRef = useMemoFirebase(
    () =>
      !firestore || !otherId || conversation.isGroup || isSelfSavedChat
        ? null
        : doc(firestore, 'users', otherId),
    [firestore, otherId, conversation.isGroup, isSelfSavedChat]
  );
  const {
    data: partnerUserLive,
    error: partnerUserError,
    isLoading: partnerUserLoading,
  } = useDoc<User>(partnerUserRef);

  const myBlockedIds = useMemo(
    () => normalizeBlockedUserIds(selfUserLive?.blockedUserIds ?? currentUser.blockedUserIds),
    [selfUserLive?.blockedUserIds, currentUser.blockedUserIds]
  );

  const callerForCalls = useMemo(
    (): User => ({ ...currentUser, blockedUserIds: myBlockedIds }),
    [currentUser, myBlockedIds]
  );

  const dmMessagingBlocked = useMemo(() => {
    if (conversation.isGroup || isSelfSavedChat || !otherId) return false;
    if (isPartnerDeleted) return false;
    if (isEitherBlockingFromUserIds(currentUser.id, myBlockedIds, otherId, partnerUserLive?.blockedUserIds)) {
      return true;
    }
    if (partnerUserError && !partnerUserLoading) return true;
    return false;
  }, [
    conversation.isGroup,
    isSelfSavedChat,
    otherId,
    isPartnerDeleted,
    currentUser.id,
    myBlockedIds,
    partnerUserLive?.blockedUserIds,
    partnerUserError,
    partnerUserLoading,
  ]);

  const composerLocked = dmMessagingBlocked;
  const composerLockedHint = useMemo(() => {
    if (!composerLocked || isPartnerDeleted) return undefined;
    if (partnerUserError && !partnerUserLoading) {
      return 'Пользователь ограничил с вами общение. Отправка недоступна.';
    }
    return directChatComposerBlockedHint(
      currentUser.id,
      myBlockedIds,
      otherId!,
      partnerUserLive?.blockedUserIds
    );
  }, [
    composerLocked,
    isPartnerDeleted,
    partnerUserError,
    partnerUserLoading,
    currentUser.id,
    myBlockedIds,
    otherId,
    partnerUserLive?.blockedUserIds,
  ]);

  const unreadCount = useMemo(() => conversation.unreadCounts?.[currentUser.id] || 0, [conversation.unreadCounts, currentUser.id]);
  const unreadThreadCount = useMemo(
    () => conversation.unreadThreadCounts?.[currentUser.id] || 0,
    [conversation.unreadThreadCounts, currentUser.id]
  );

  /** Снимаем индикатор @ в списке диалогов при открытии группового чата. */
  useEffect(() => {
    if (!firestore || !conversation.isGroup) return;
    const pending = conversation.usersWithPendingGroupMention;
    if (!pending?.includes(currentUser.id)) return;
    const convRef = doc(firestore, 'conversations', conversation.id);
    updateDocumentNonBlocking(convRef, {
      usersWithPendingGroupMention: arrayRemove(currentUser.id),
    });
  }, [firestore, conversation.id, conversation.isGroup, conversation.usersWithPendingGroupMention, currentUser.id]);

  const allMessages = useMemo(() => {
    const remoteMessageIds = new Set(messages.map(rm => rm.id));
    const uniqueOptimistic = optimisticMessages.filter(om => !remoteMessageIds.has(om.id));
    return [...messages, ...uniqueOptimistic];
  }, [messages, optimisticMessages]);

  useEffect(() => {
    const hasCiphertext = allMessages.some((m) => m.e2ee?.ciphertext);
    if (!hasCiphertext) {
      setE2eePlaintextByMessageId({});
      return;
    }
    let cancelled = false;
    void (async () => {
      const updates: Record<string, string> = {};
      for (const m of allMessages) {
        if (!m.e2ee?.ciphertext) continue;
        // v2-сообщения включают messageId в AAD; передаём, даже для v1 —
        // v1-путь игнорирует.
        const plain = await e2eeConv.decryptMessagePayload(m.e2ee, m.id);
        updates[m.id] = plain;
      }
      if (!cancelled) {
        setE2eePlaintextByMessageId((prev) => {
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

  const messagesForListRaw = useMemo(() => {
    const clearedAt = conversation.clearedAt?.[currentUser.id];
    return clearedAt ? allMessages.filter(m => new Date(m.createdAt) > new Date(clearedAt)) : allMessages;
  }, [allMessages, conversation.clearedAt, currentUser.id]);

  // E2EE v2 Phase 9: расшифрованные blob-URL'ы для message.e2ee.attachments[]
  // подмешиваются в .attachments перед рендером. Хук ленивый, кэширует
  // результаты внутри useE2eeMediaAttachments.
  const messagesForList = useE2eeHydratedMessages(messagesForListRaw, e2eeMediaApi);

  const handleToggleStar = useCallback(
    (messageId: string, nextStarred: boolean) => {
      if (!firestore || !currentUser.id) return;
      const ref = doc(
        firestore,
        'users',
        currentUser.id,
        'starredChatMessages',
        buildStarredMessageDocId(conversation.id, messageId)
      );
      if (nextStarred) {
        const msg = messagesForList.find((m) => m.id === messageId);
        const html = e2eePlaintextByMessageId[messageId] ?? msg?.text ?? '';
        const previewText = html.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim().slice(0, 240);
        setDocumentNonBlocking(ref, {
          conversationId: conversation.id,
          messageId,
          createdAt: new Date().toISOString(),
          ...(previewText ? { previewText } : {}),
        });
        toast({ title: 'Добавлено в избранное' });
      } else {
        deleteDocumentNonBlocking(ref);
        toast({ title: 'Удалено из избранного' });
      }
    },
    [firestore, currentUser.id, conversation.id, messagesForList, e2eePlaintextByMessageId, toast]
  );

  /** Сколько входящих в загруженном окне ещё без readAt — бейдж якоря и разделитель, чтобы не расходиться с conversation.unreadCounts. */
  const incomingUnreadCount = useMemo(
    () => messagesForList.filter((m) => isIncomingUnreadForViewer(m, currentUser.id)).length,
    [messagesForList, currentUser.id]
  );
  // При скрытых read-receipts readAt не обновляется намеренно, поэтому для якоря
  // и связанных UI-состояний опираемся на conversation.unreadCounts.
  const unreadCountForAnchor = suppressReadReceipts ? unreadCount : incomingUnreadCount;

  useEffect(() => {
    if (!firestore || !suppressReadReceipts) return;
    if (!isFullyReady || !hasScrolledToUnread) return;
    const totalUnread = unreadCount + unreadThreadCount;
    if (totalUnread <= 0) {
      suppressUnreadResetKeyRef.current = '';
      return;
    }
    const key = `${conversation.id}:${totalUnread}`;
    if (suppressUnreadResetKeyRef.current === key) return;
    suppressUnreadResetKeyRef.current = key;
    void markConversationAsRead(firestore, conversation.id, currentUser.id);
  }, [
    firestore,
    suppressReadReceipts,
    isFullyReady,
    hasScrolledToUnread,
    conversation.id,
    currentUser.id,
    unreadCount,
    unreadThreadCount,
  ]);

  const prevUnreadCount = useRef(unreadCount);
  useEffect(() => {
    if (!isFullyReady) return;
    
    if (unreadCount > prevUnreadCount.current) {
      /** Новые непрочитанные с сервера: снова разрешаем разделитель (иначе при приходе с низа hasClearedSeparatorRef блокирует id и «стартовый» скролл не завершается — пометка read не включается). */
            hasClearedSeparatorRef.current = false;
      anchorUnreadStepRef.current = 0;
    }
    prevUnreadCount.current = unreadCount;

    if (unreadCountForAnchor === 0 || suppressReadReceipts) {
      if (unreadSeparatorId) {
          setUnreadSeparatorId(null);
          hasClearedSeparatorRef.current = false;
      }
      anchorUnreadStepRef.current = 0;
      return;
    }

    if (!unreadSeparatorId && !hasClearedSeparatorRef.current) {
      const oldestUnread = messagesForList.find((m) => isIncomingUnreadForViewer(m, currentUser.id));
      if (oldestUnread) {
        setUnreadSeparatorId(oldestUnread.id);
      }
    }
  }, [
    isFullyReady,
    unreadCount,
    unreadSeparatorId,
    messagesForList,
    currentUser.id,
    unreadCountForAnchor,
    suppressReadReceipts,
  ]);

  const flatItems = useMemo(
    () => buildChatListRows(messagesForList, unreadSeparatorId),
    [messagesForList, unreadSeparatorId]
  );

  const flatItemsRef = useRef(flatItems);
  useEffect(() => { flatItemsRef.current = flatItems; }, [flatItems]);
  const increaseViewportBy = useMemo(() => getVirtuosoChatIncreaseViewport(), []);

  const sortedPins = useMemo(() => {
    const raw = conversationPinnedList(conversation);
    const map = new Map(messagesForList.map((m) => [m.id, m]));
    return sortPinnedMessagesByTime(raw, map);
  }, [conversation, messagesForList]);

  const sortedPinsRef = useRef(sortedPins);
  useEffect(() => {
    sortedPinsRef.current = sortedPins;
  }, [sortedPins]);

  const barPinIndexRef = useRef(0);
  useEffect(() => {
    barPinIndexRef.current = barPinIndex;
  }, [barPinIndex]);

  const pinnedBarSkipSyncUntilRef = useRef(0);

  const pinnedIdsKey = useMemo(() => sortedPins.map((p) => p.messageId).join(','), [sortedPins]);

  useEffect(() => {
    const n = sortedPins.length;
    setBarPinIndex((i) => {
      if (n === 0) return 0;
      return Math.min(Math.max(0, i), n - 1);
    });
  }, [pinnedIdsKey, sortedPins.length]);

  /** Рост резерва: прокрутка к концу списка (иначе место есть, но viewport не сдвигается). Снятие резерва у низа: scrollBy без скачка. */
  useLayoutEffect(() => {
    const prev = prevTailReserveRef.current;
    const next = videoCircleTailReservePx;
    const delta = next - prev;
    prevTailReserveRef.current = next;
    if (delta === 0) return;
    const v = virtuosoRef.current;
    if (!v) return;
    if (delta > 0) {
      /* Только компенсация высоты футера; scrollToIndex в конец ломал жест при прокрутке мимо «кружок + сетка». */
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
      measureChatPerf('chat-load-more-start', 'chat-load-more-duration');
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
    incrementChatPerfCounter('chat-load-more-top-check');
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

  useEffect(() => {
    if (isFullyReady && !hasScrolledToUnread && virtuosoRef.current && flatItems.length > 0) {
        if (!suppressReadReceipts && unreadCountForAnchor > 0 && !unreadSeparatorId) return;

        const timer = setTimeout(() => {
            const unreadSeparatorIdx = flatItems.findIndex(item => item.type === 'unread-separator');
            if (unreadSeparatorIdx !== -1) {
                virtuosoRef.current?.scrollToIndex({ index: unreadSeparatorIdx, align: 'start', behavior: 'auto' });
            } else {
                virtuosoRef.current?.scrollToIndex({ index: flatItems.length - 1, align: 'end', behavior: 'auto' });
            }
            // Включаем mark-as-read только после того, как Virtuoso применил скролл: при alignToBottom первый
            // rangeChanged идёт с низа списка и иначе мгновенно помечает все видимые входящие как прочитанные,
            // обнуляет unreadCounts и снимает разделитель до этого таймера.
            requestAnimationFrame(() => {
              requestAnimationFrame(() => {
                hasScrolledToUnreadRef.current = true;
            setHasScrolledToUnread(true);
              });
            });
        }, 200);
        return () => clearTimeout(timer);
    }
  }, [
    isFullyReady,
    hasScrolledToUnread,
    flatItems,
    unreadCountForAnchor,
    unreadSeparatorId,
    suppressReadReceipts,
  ]);

  const handleRangeChanged = useCallback((range: { startIndex: number; endIndex: number }) => {
    currentVisibleRange.current = range;
    if (!isFullyReady || !firestore || !conversation.id) return;

    const currentItems = flatItemsRef.current;
    const lastIdx = currentItems.length - 1;
    if (lastIdx >= 0 && range.endIndex >= lastIdx && hasScrolledToUnreadRef.current) {
        setUnreadSeparatorId(prev => {
            if (prev !== null) {
                hasClearedSeparatorRef.current = true;
                return null;
            }
            return prev;
        });
    }

    const pins = sortedPinsRef.current;
    if (pins.length > 0 && Date.now() >= pinnedBarSkipSyncUntilRef.current) {
      const idx = pickPinnedBarIndexForViewport(pins, flatItemsRef.current, range.startIndex, range.endIndex);
      setBarPinIndex(idx);
    }
  }, [isFullyReady, firestore, conversation.id, currentUser.id]);

  const allMediaItems = useMemo((): MediaViewerItem[] => {
    const items: MediaViewerItem[] = [];
    messagesForList.forEach(msg => {
      if (msg.isDeleted || !msg.attachments) return;
      msg.attachments.forEach(att => {
        if (isGridGalleryAttachment(att)) {
          items.push({ 
            ...att, 
            messageId: msg.id, 
            senderId: msg.senderId, 
            createdAt: msg.createdAt 
          });
        }
      });
    });
    return items.filter((item, index, self) => 
      index === self.findIndex((t) => t.url === item.url)
    );
  }, [messagesForList]);

  const handleOpenMediaViewer = useCallback((att: ChatAttachment) => {
    const idx = allMediaItems.findIndex(item => item.url === att.url);
    if (idx >= 0) {
      setMediaViewerState({ isOpen: true, startIndex: idx });
    }
  }, [allMediaItems]);

  const handleProfileSheetOpenChange = useCallback((open: boolean) => {
    setIsProfileOpen(open);
    if (!open) setProfileInitialSubMenu(null);
    if (!open) setProfileFocusUserId(null);
    if (!open) setProfileSource('chat');
  }, []);

  const handleOpenThreadsFromHeader = useCallback(() => {
    setProfileFocusUserId(null);
    setProfileSource('chat');
    setProfileInitialSubMenu('threads');
    setIsProfileOpen(true);
  }, []);

  useEffect(() => {
    if (!initialProfileOpen) return;
    const incomingUserId =
      initialProfileFocusUserId && conversation.participantIds.includes(initialProfileFocusUserId)
        ? initialProfileFocusUserId
        : null;
    setProfileFocusUserId(incomingUserId);
    setProfileSource(initialProfileSource ?? 'chat');
    setProfileInitialSubMenu(null);
    setIsProfileOpen(true);
    onInitialProfileConsumed?.();
  }, [
    initialProfileOpen,
    initialProfileFocusUserId,
    initialProfileSource,
    conversation.participantIds,
    onInitialProfileConsumed,
  ]);

  const startThreadPanelResize = useCallback(
    (startX: number) => {
      if (typeof window === 'undefined') return;
      threadPanelResizingRef.current = true;
      const startWidth = threadPanelWidth;
      document.body.style.cursor = 'col-resize';
      document.body.style.userSelect = 'none';
      const minWidth = 420;
      const maxWidth = Math.min(Math.floor(window.innerWidth * 0.78), 1180);

      const onMove = (clientX: number) => {
        if (!threadPanelResizingRef.current) return;
        // Ручка на левой границе панели: тянем влево => панель шире.
        const delta = startX - clientX;
        setThreadPanelExpanded(false);
        setThreadPanelWidth(Math.max(minWidth, Math.min(maxWidth, startWidth + delta)));
      };

      const onEnd = () => {
        threadPanelResizingRef.current = false;
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
    [threadPanelWidth]
  );

  const handleMentionProfileOpen = useCallback(
    (userId: string) => {
      if (!conversation.participantIds.includes(userId)) return;
      setProfileFocusUserId(userId);
      setProfileSource('mention');
      setIsProfileOpen(true);
    },
    [conversation.participantIds]
  );

  const handleGroupSenderProfileOpen = useCallback(
    (userId: string) => {
      if (!conversation.participantIds.includes(userId)) return;
      setProfileFocusUserId(userId);
      setProfileSource('sender');
      setIsProfileOpen(true);
    },
    [conversation.participantIds]
  );

  const handleGroupSenderWritePrivate = useCallback(
    async (userId: string) => {
      if (!firestore || userId === currentUser.id) return;
      if (!conversation.isGroup || !conversation.participantIds.includes(userId)) return;
      const other =
        allUsers.find((u) => u.id === userId) ??
        ({
          id: userId,
          name: conversation.participantInfo[userId]?.name ?? 'Участник',
          username: '',
          email: '',
          avatar: conversation.participantInfo[userId]?.avatar ?? '',
          avatarThumb: conversation.participantInfo[userId]?.avatarThumb,
          phone: '',
          deletedAt: null,
          createdAt: '',
        } as User);
      if (!canStartDirectChat(currentUser, other)) {
        toast({
          variant: 'destructive',
          title: 'Нельзя начать чат',
          description: 'Политика доступа не позволяет написать этому пользователю.',
        });
        return;
      }
      try {
        const id = await createOrOpenDirectChat(firestore, currentUser, other);
        let platformWants = false;
        try {
          const ps = await getDoc(doc(firestore, 'platformSettings', 'main'));
          const p = ps.data() as PlatformSettingsDoc | undefined;
          platformWants = !!p?.e2eeDefaultForNewDirectChats;
        } catch {
          /* ignore */
        }
        await autoEnableE2eeForNewDirectChat(firestore, id, currentUser.id, {
          userWants: privacySettings.e2eeForNewDirectChats === true,
          platformWants,
        });
        onSelectConversation(id);
      } catch (e) {
        console.error('[ChatWindow] createOrOpenDirectChat', e);
        toast({
          variant: 'destructive',
          title: 'Не удалось открыть личный чат',
        });
      }
    },
    [
      firestore,
      currentUser,
      conversation.isGroup,
      conversation.participantIds,
      conversation.participantInfo,
      allUsers,
      onSelectConversation,
      toast,
      privacySettings.e2eeForNewDirectChats,
    ]
  );

  const handleSaveStickerFromMessage = useCallback(
    (att: ChatAttachment, mode: 'copy' | 'normalize_sticker' = 'copy') => {
      setStickerSaveMode(mode);
      setStickerSaveAttachment(att);
      setStickerSaveOpen(true);
    },
    []
  );

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
    [conversation.id, firestore, toast]
  );

  const handleStickerSaveConfirmPack = useCallback(
    async (packId: string) => {
      if (!stickerSaveAttachment || !firestore || !storage) return;
      setStickerSaveBusy(true);
      try {
        const r =
          stickerSaveMode === 'normalize_sticker'
            ? await addChatImageAsSquareStickerToPack(
                stickerSaveAttachment,
                packId,
                currentUser.id,
                firestore,
                storage
              )
            : await addChatAttachmentToUserStickerPack(
                stickerSaveAttachment,
                packId,
                currentUser.id,
                firestore,
                storage
              );
        if (r.ok) {
          toast({
            title: 'Сохранено в стикерпак',
            description: stickerSaveMode === 'normalize_sticker' ? 'Изображение приведено к квадрату под размер стикера.' : undefined,
          });
          setStickerSaveOpen(false);
          setStickerSaveAttachment(null);
          setStickerSaveMode('copy');
        } else if (r.error === 'file_too_large') {
          toast({
            title: 'Файл слишком большой',
            description: `До ${Math.round(USER_STICKER_MAX_FILE_BYTES / (1024 * 1024))} МБ.`,
            variant: 'destructive',
          });
        } else if (r.error === 'fetch_failed') {
          toast({
            title: 'Не удалось скачать файл',
            description:
              'Сервер или браузер заблокировал загрузку (CORS). Сохраните медиа на устройство и добавьте через вкладку GIF → «В мой пак».',
            variant: 'destructive',
          });
        } else {
          toast({ title: 'Не удалось сохранить', variant: 'destructive' });
        }
      } finally {
        setStickerSaveBusy(false);
      }
    },
    [stickerSaveAttachment, stickerSaveMode, firestore, storage, currentUser.id, toast]
  );

  const handleStickerPackCreate = useCallback(
    async (name: string) => {
      if (!firestore) return null;
      return createUserStickerPack(firestore, currentUser.id, name);
    },
    [firestore, currentUser.id]
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
    const messagesCollection = collection(firestore, `conversations/${conversation.id}/messages`);
    const newDocRef = doc(messagesCollection);
    const messageId = newDocRef.id;
    const now = new Date().toISOString();
    
    const optimisticAttachments: ChatAttachment[] = [
      ...prebuilt.map((a) => ({ ...a })),
      ...files.map((f) => ({ url: URL.createObjectURL(f), name: f.name, type: f.type, size: f.size })),
    ];
    
    pendingScrollToBottomAfterSendRef.current = true;
    setOptimisticMessages(prev => [...prev, {
      id: messageId, senderId: currentUser.id, text, createdAt: now, readAt: null, deliveryStatus: 'sending',
      attachments: optimisticAttachments,
      ...(replyContext && { replyTo: replyContext }),
    }]);
    if (replyContext) setReplyingTo(null);

    try {
      // E2EE v2 Phase 9: при активном шифровании файлы с encryptable MIME идут
      // через useE2eeMediaAttachments.encryptAndUploadForSend (envelopes в
      // message.e2ee.attachments[]); стикеры/GIFs остаются plaintext.
      // Если шифрование выключено — весь набор грузится plaintext как раньше.
      const encryptAttachments = e2eeConv.e2eeEnabled && effectiveE2eeTypes.media;
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
              const path = `chat-attachments/${conversation.id}/${Date.now()}-${file.name.replace(/\s+/g, '_')}`;
              const uploaded = await internalUpload(file, path, storage);
              uploadedAttachments.push(uploaded);
          }
      }

      // Envelopes для зашифрованных вложений. Пишем в message.e2ee.attachments[].
      // Плейнтекст-массив attachments[] сохраняется только для стикеров/GIF
      // и превью-путей (ConversationMediaPanel и т.п.).
      let e2eeAttachmentEnvelopes:
        | NonNullable<import('@/lib/types').ChatMessageE2eePayload['attachments']>
        | null = null;
      if (filesToEncrypt.length > 0) {
        try {
          const res = await e2eeMediaApi.encryptAndUploadForSend(
            messageId,
            // kindHint: имя файла в чате детерминированно кодирует kind —
            // `video-circle_*.webm` → MediaKindV2.videoCircle, `voice_*.m4a`
            // → voice и т.п. Без этой подсказки mapMimeToKind выдавал бы
            // общий 'video'/'voice', и получатель не мог отличить кружок
            // от обычного видео (рендерился как прямоугольник).
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
        e2eeConv.e2eeEnabled && effectiveE2eeTypes.text && !!text && plainBody.length > 0;
      const hasEncryptedAttachments =
        !!e2eeAttachmentEnvelopes && e2eeAttachmentEnvelopes.length > 0;
      // Если хоть что-то шифруем (текст или медиа) — всё сообщение помечаем
      // как E2EE. Медиа-only получает envelope с пустым plaintext-телом,
      // чтобы push-notification трактовал его как «Зашифрованное сообщение».
      const useE2eeEnvelope = useE2eeForText || hasEncryptedAttachments;
      const replyForWrite = (() => {
        if (!replyContext) return null;
        // 1) При E2EE envelope мы не пишем plaintext текста в replyTo (как раньше).
        if (useE2eeEnvelope && effectiveE2eeTypes.replyPreview !== false) {
          return (({ text: _omitted, ...rest }) => rest)(replyContext);
        }
        // 2) При выключенном reply-preview — не пишем ни текст, ни url превью.
        if (effectiveE2eeTypes.replyPreview === false) {
          const { text: _t, mediaPreviewUrl: _u, ...rest } = replyContext;
          return rest;
        }
        return replyContext;
      })();

      const basePayload: Record<string, unknown> = {
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
        basePayload.e2ee = e2eePayload;
      } else if (text) {
        basePayload.text = text;
      }

      try {
        await setDoc(newDocRef, basePayload as Parameters<typeof setDoc>[1]);
      } catch (writeError) {
        if (isFirestorePermissionDeniedError(writeError)) {
          try {
            await getAuth(firestore.app).currentUser?.getIdToken(true);
            await setDoc(newDocRef, basePayload as Parameters<typeof setDoc>[1]);
          } catch (retryError) {
            logFirestorePermissionDenied({
              source: 'ChatWindow.handleSendMessage',
              operation: 'create',
              path: `conversations/${conversation.id}/messages/${messageId}`,
              firestore,
              failedStep: 'setDoc',
              extra: {
                conversationId: conversation.id,
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

      const conversationRef = doc(firestore, 'conversations', conversation.id);
      const unreadUpdates = getUnreadIncrementUpdate(conversation.participantIds, currentUser.id, 1);
      const plainForMention = text
        ? text.replace(/<[^>]*>/g, '').replace(/&nbsp;/g, ' ')
        : '';
      const mentionCandidates = buildGroupMentionCandidates(conversation, allUsers, currentUser.id, {
        contactProfiles: userContactsIndex?.contactProfiles,
      });
      const mentionedUserIds =
        conversation.isGroup && plainForMention
          ? extractMentionedUserIdsFromPlainText(plainForMention, mentionCandidates, currentUser.id).filter(
              (id) => conversation.participantIds.includes(id) && id !== currentUser.id
            )
          : [];

      const stripHtml = text ? text.replace(/<[^>]*>/g, '') : '';
      let lastPreview = stripHtml;
      if (useE2eeForText) {
        lastPreview = E2EE_LAST_MESSAGE_PREVIEW;
      } else if (!lastPreview) {
        if (prebuilt.some((a) => a.name.startsWith('gif_'))) lastPreview = 'GIF';
        else if (prebuilt.some((a) => a.name.startsWith('sticker_'))) lastPreview = 'Стикер';
        else if (files.length === 1 && files[0].name.startsWith('sticker_')) lastPreview = 'Стикер';
        else if (files.length > 0 || prebuilt.length > 0) lastPreview = 'Вложение';
        else lastPreview = 'Сообщение';
      }
      
      await updateDoc(conversationRef, { 
          lastMessageText: lastPreview, 
          lastMessageTimestamp: now, 
          lastMessageSenderId: currentUser.id, 
          lastMessageIsThread: false,
          ...unreadUpdates,
          ...(mentionedUserIds.length > 0
            ? { usersWithPendingGroupMention: arrayUnion(...mentionedUserIds) }
            : {}),
      });
    } catch (error) {
      console.error('Chat send failed:', error);
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
        console.warn(GEOLOCATION_FIRESTORE_LOG, 'aborted', { reason: 'no firestore or user' });
        return;
      }
      const messagesCollection = collection(firestore, `conversations/${conversation.id}/messages`);
      const newDocRef = doc(messagesCollection);
      const messageId = newDocRef.id;
      const now = new Date().toISOString();
      console.log(GEOLOCATION_FIRESTORE_LOG, 'start', {
        conversationId: conversation.id,
        messageId,
        reply: !!replyContext,
        lat: share.lat,
        lng: share.lng,
        live: meta.kind === 'live',
        liveExpiresAt: meta.kind === 'live' ? meta.expiresAt : undefined,
      });
      pendingScrollToBottomAfterSendRef.current = true;
      setOptimisticMessages((prev) => [
        ...prev,
        {
          id: messageId,
          senderId: currentUser.id,
          createdAt: now,
          readAt: null,
          deliveryStatus: 'sending' as const,
          locationShare: share,
          ...(replyContext && { replyTo: replyContext }),
        },
      ]);
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
        const conversationRef = doc(firestore, 'conversations', conversation.id);
        const unreadUpdates = getUnreadIncrementUpdate(conversation.participantIds, currentUser.id, 1);
        await updateDoc(conversationRef, {
          lastMessageText: '📍 Геолокация',
          lastMessageTimestamp: now,
          lastMessageSenderId: currentUser.id,
          lastMessageIsThread: false,
          ...unreadUpdates,
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
        console.log(GEOLOCATION_FIRESTORE_LOG, 'success', { messageId });
      } catch (err) {
        console.error(GEOLOCATION_FIRESTORE_LOG, 'failed', { messageId, err });
        setOptimisticMessages((prev) => prev.filter((m) => m.id !== messageId));
      }
    },
    [firestore, currentUser, conversation.id, conversation.participantIds, e2eeConv.e2eeEnabled, toast]
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
      const messagesCollection = collection(firestore, `conversations/${conversation.id}/messages`);
      const newDocRef = doc(messagesCollection);
      const messageId = newDocRef.id;
      const now = new Date().toISOString();
      const pollText = '<p>📊 Опрос</p>';
      pendingScrollToBottomAfterSendRef.current = true;
      setOptimisticMessages((prev) => [
        ...prev,
        {
          id: messageId,
          senderId: currentUser.id,
          createdAt: now,
          readAt: null,
          deliveryStatus: 'sending' as const,
          text: pollText,
          chatPollId: pollId,
          ...(replyContext && { replyTo: replyContext }),
        },
      ]);
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
        const conversationRef = doc(firestore, 'conversations', conversation.id);
        const unreadUpdates = getUnreadIncrementUpdate(conversation.participantIds, currentUser.id, 1);
        await updateDoc(conversationRef, {
          lastMessageText: '📊 Опрос',
          lastMessageTimestamp: now,
          lastMessageSenderId: currentUser.id,
          lastMessageIsThread: false,
          ...unreadUpdates,
        });
      } catch {
        setOptimisticMessages((prev) => prev.filter((m) => m.id !== messageId));
        try {
          await deleteDoc(pollRef);
        } catch {
          /* ignore */
        }
      }
    },
    [firestore, currentUser, conversation.id, conversation.participantIds, e2eeConv.e2eeEnabled, toast]
  );

  const handleUpdateMessage = async (id: string, text: string, attachments?: ChatAttachment[]) => {
    if (!firestore || !conversation.id) return;
    const msgRef = doc(firestore, `conversations/${conversation.id}/messages`, id);
    const now = new Date().toISOString();
    const existing = allMessages.find((m) => m.id === id);
    const hadE2eeEnvelope = !!(existing?.e2ee && (existing.e2ee.ciphertext || (existing.e2ee.attachments && existing.e2ee.attachments.length > 0)));
    try {
        if (e2eeConv.e2eeEnabled && hadE2eeEnvelope) {
          // E2EE edit: перешифруем только текст, existing e2ee.attachments
          // сохраняем as-is (перезаливать файлы при редактировании нельзя —
          // ciphertext привязан к messageId, а HKDF-wrap — к epoch).
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
          if (conversation.lastMessageTimestamp === existing?.createdAt) {
            await updateDoc(doc(firestore, 'conversations', conversation.id), {
              lastMessageText: E2EE_LAST_MESSAGE_PREVIEW,
            });
          }
        } else {
        await updateDoc(msgRef, { text, attachments: attachments || [], updatedAt: now });
        if (conversation.lastMessageTimestamp === allMessages.find(m => m.id === id)?.createdAt) {
            await updateDoc(doc(firestore, 'conversations', conversation.id), {
                lastMessageText: text.replace(/<[^>]*>/g, '').slice(0, 100),
            });
          }
        }
    } catch (e) {
        toast({ variant: 'destructive', title: 'Ошибка обновления' });
    }
  };

  const handleDeleteMessage = async (id: string, parentId?: string) => {
    if (!firestore || !conversation.id) return;
    const isThread = !!parentId;
    const path = isThread 
        ? `conversations/${conversation.id}/messages/${parentId}/thread/${id}`
        : `conversations/${conversation.id}/messages/${id}`;
    
    const msgRef = doc(firestore, path);
    const now = new Date().toISOString();

    try {
        const msgSnap = await getDoc(msgRef);
        const msgData = msgSnap.data() as ChatMessage | undefined;

        await updateDoc(msgRef, { isDeleted: true, updatedAt: now });

        if (msgData && !msgData.readAt) {
            const others = conversation.participantIds.filter(uid => uid !== msgData.senderId);
            if (others.length > 0) {
                const convRef = doc(firestore, 'conversations', conversation.id);
                const updates: Record<string, any> = {};
                others.forEach(uid => {
                    const field = isThread ? `unreadThreadCounts.${uid}` : `unreadCounts.${uid}`;
                    updates[field] = increment(-1);
                });
                await updateDoc(convRef, updates);

                if (isThread) {
                    const parentRef = doc(firestore, `conversations/${conversation.id}/messages`, parentId);
                    const parentUpdates: Record<string, any> = {};
                    others.forEach(uid => {
                        parentUpdates[`unreadThreadCounts.${uid}`] = increment(-1);
                    });
                    await updateDoc(parentRef, parentUpdates);
                }
            }
        }
    } catch (e) {
        toast({ variant: 'destructive', title: 'Ошибка удаления' });
    }
  };

  const handlePinMessage = async (msg: ChatMessage) => {
    if (!firestore || !conversation.id) return;
    const convRef = doc(firestore, 'conversations', conversation.id);
    const replyPreview = getReplyPreview(msg, allUsers);
    const existing = conversationPinnedList(conversation);
    if (existing.some((p) => p.messageId === msg.id)) {
      toast({ title: 'Уже закреплено' });
      return;
    }
    if (existing.length >= MAX_PINNED_MESSAGES) {
      toast({
        variant: 'destructive',
        title: 'Лимит закрепов',
        description: `Не более ${MAX_PINNED_MESSAGES} сообщений.`,
      });
      return;
    }

    const entry: PinnedMessage = {
                messageId: msg.id,
      text: replyPreview.text ?? '',
                senderName: replyPreview.senderName,
                senderId: msg.senderId,
                mediaPreviewUrl: replyPreview.mediaPreviewUrl,
      mediaType: replyPreview.mediaType,
      messageCreatedAt: msg.createdAt,
    };
    const map = new Map(messagesForList.map((m) => [m.id, m]));
    const next = sortPinnedMessagesByTime([...existing, entry], map);

    try {
      await updateDoc(convRef, {
        pinnedMessages: next,
        pinnedMessage: deleteField(),
        });
        toast({ title: 'Сообщение закреплено' });
    } catch (e) {
        toast({ variant: 'destructive', title: 'Ошибка закрепления' });
    }
  };

  const handleUnpinOne = async (messageId: string) => {
    if (!firestore || !conversation.id) return;
    const convRef = doc(firestore, 'conversations', conversation.id);
    const existing = conversationPinnedList(conversation);
    const next = existing.filter((p) => p.messageId !== messageId);
    try {
      if (next.length === 0) {
        await updateDoc(convRef, { pinnedMessages: deleteField(), pinnedMessage: deleteField() });
      } else {
        await updateDoc(convRef, { pinnedMessages: next, pinnedMessage: deleteField() });
      }
      toast({ title: 'Сообщение откреплено' });
    } catch (e) {
      toast({ variant: 'destructive', title: 'Ошибка открепления' });
    }
  };

  const handleBulkDelete = async () => {
    if (!firestore || selection.ids.size === 0) return;
    setIsBulkProcessing(true);
    try {
        for (const id of Array.from(selection.ids)) {
            await handleDeleteMessage(id);
        }
        setSelection({ active: false, ids: new Set() });
        toast({ title: 'Сообщения удалены' });
    } catch (e) {
        toast({ variant: 'destructive', title: 'Ошибка при удалении' });
    } finally {
        setIsBulkProcessing(false);
    }
  };

  const handleReactTo = async (messageId: string, emoji: string, threadParentId?: string) => {
    if (!firestore || !currentUser) return;
    const path = threadParentId 
        ? `conversations/${conversation.id}/messages/${threadParentId}/thread/${messageId}`
        : `conversations/${conversation.id}/messages/${messageId}`;
    const msgRef = doc(firestore, path);
    const convRef = doc(firestore, 'conversations', conversation.id);

    try {
        const msgSnap = await getDoc(msgRef);
        const message = msgSnap.data() as ChatMessage;
        if (!message) return;

        const reactions = { ...(message.reactions || {}) };
        let userReactions = reactions[emoji] ? [...reactions[emoji]] : [];
        const now = new Date().toISOString();
        const existingIndex = userReactions.findIndex(r => typeof r === 'string' ? r === currentUser.id : r.userId === currentUser.id);

        if (existingIndex !== -1) {
            userReactions.splice(existingIndex, 1);
            if (userReactions.length === 0) delete reactions[emoji];
            else reactions[emoji] = userReactions;
        } else {
            reactions[emoji] = [...userReactions, { userId: currentUser.id, timestamp: now }];
        }

        await updateDoc(msgRef, { reactions, lastReactionTimestamp: now });
        if (existingIndex === -1) {
            await updateDoc(convRef, {
                lastReactionEmoji: emoji,
                lastReactionTimestamp: now,
                lastReactionSenderId: currentUser.id,
                lastReactionMessageId: messageId,
                lastReactionParentId: threadParentId || null
            });
        }
    } catch (e) { console.error("Reaction failed:", e); }
  };

  const highlightMessageElement = useCallback((messageId: string) => {
    const run = () => {
        const element = document.getElementById(`msg-${messageId}`);
        if (element) {
            element.classList.add('animate-message-highlight');
        window.setTimeout(() => element.classList.remove('animate-message-highlight'), 2000);
      }
    };
    requestAnimationFrame(() => requestAnimationFrame(run));
    window.setTimeout(run, 450);
  }, []);

  const tryScrollToMessageInList = useCallback(
    (messageId: string): boolean => {
      const currentItems = flatItemsRef.current;
      const index = currentItems.findIndex(item => item.type === 'message' && item.message.id === messageId);
      if (index === -1) return false;
      virtuosoRef.current?.scrollToIndex({ index, align: 'center', behavior: 'smooth' });
      highlightMessageElement(messageId);
      return true;
    },
    [highlightMessageElement]
  );

  const navigateToMessage = useCallback(
    (messageId: string) => {
      if (tryScrollToMessageInList(messageId)) {
        setIsSearchActive(false);
        setSearchQuery('');
        pendingNavigateMessageIdRef.current = null;
        return;
      }
      if (hasMore) {
        pendingNavigateMessageIdRef.current = messageId;
        setIsLoadingOlder(true);
        setDisplayLimit((prev) => prev + HISTORY_PAGE_SIZE);
      } else {
        toast({ title: 'Сообщение не найдено' });
      }
    },
    [hasMore, tryScrollToMessageInList, toast]
  );

  const focusMessageHandledRef = useRef<string | null>(null);
  useEffect(() => {
    focusMessageHandledRef.current = null;
  }, [focusMessageId, conversation.id]);

  useEffect(() => {
    if (!focusMessageId || !isFullyReady) return;
    if (focusMessageHandledRef.current === focusMessageId) return;
    focusMessageHandledRef.current = focusMessageId;
    navigateToMessage(focusMessageId);
    onFocusMessageConsumed?.();
  }, [focusMessageId, isFullyReady, navigateToMessage, onFocusMessageConsumed]);

  const handlePinnedBarNavigate = useCallback(() => {
    const pins = sortedPinsRef.current;
    if (!pins.length) return;
    const i = Math.min(barPinIndexRef.current, pins.length - 1);
    const pin = pins[i];
    if (pin) navigateToMessage(pin.messageId);
    pinnedBarSkipSyncUntilRef.current = Date.now() + 900;
    setBarPinIndex((j) => (j - 1 + pins.length) % pins.length);
  }, [navigateToMessage]);

  useEffect(() => {
    const pending = pendingNavigateMessageIdRef.current;
    if (!pending || !isFullyReady) return;
    if (tryScrollToMessageInList(pending)) {
      pendingNavigateMessageIdRef.current = null;
      setIsSearchActive(false);
      setSearchQuery('');
      return;
    }
    if (!hasMore) {
      pendingNavigateMessageIdRef.current = null;
      toast({ title: 'Сообщение не найдено' });
      return;
    }
    setIsLoadingOlder(true);
    setDisplayLimit((prev) => prev + HISTORY_PAGE_SIZE);
  }, [flatItems, isFullyReady, hasMore, tryScrollToMessageInList, toast]);

  const lastSeenReactionAt = conversation.lastReactionSeenAt?.[currentUser.id] || '';
  const latestReaction = (
    conversation.lastReactionTimestamp && 
    conversation.lastReactionTimestamp > lastSeenReactionAt &&
    conversation.lastReactionSenderId !== currentUser.id 
  ) ? {
      emoji: conversation.lastReactionEmoji!,
      messageId: conversation.lastReactionMessageId!,
      parentId: conversation.lastReactionParentId
  } : null;

  const logAnchorDebug = useCallback(
    (event: string, extra?: Record<string, unknown>) => {
      incrementChatPerfCounter('chat-anchor-click-total');
      incrementChatPerfCounter(`chat-anchor-click-${event}`);
      if (typeof window === 'undefined' || process.env.NODE_ENV === 'production') return;
      console.debug('[ChatAnchor][dev]', {
        event,
        conversationId: conversation.id,
        userId: currentUser.id,
        suppressReadReceipts,
        conversationUnread: unreadCount,
        incomingUnread: incomingUnreadCount,
        unreadThread: unreadThreadCount,
        ...extra,
      });
    },
    [
      conversation.id,
      currentUser.id,
      suppressReadReceipts,
      unreadCount,
      incomingUnreadCount,
      unreadThreadCount,
    ]
  );

  const handleAnchorClick = () => {
    if (!firestore) return;
    logAnchorDebug('click');
    const currentItems = flatItemsRef.current;
    const lastIdx = Math.max(0, currentItems.length - 1);
    const separatorIdx = currentItems.findIndex((item) => item.type === 'unread-separator');
    const unreadIds = messagesForList
      .filter((m) => isIncomingUnreadForViewer(m, currentUser.id))
      .map((m) => m.id);

    if (suppressReadReceipts && unreadCount > 0) {
      logAnchorDebug('suppress-reset', { unreadCount });
      virtuosoRef.current?.scrollToIndex({ index: lastIdx, align: 'end', behavior: 'smooth' });
      anchorUnreadStepRef.current = 0;
      void markConversationAsRead(firestore, conversation.id, currentUser.id);
      return;
    }

    if (unreadIds.length > 0) {
      if (anchorUnreadStepRef.current === 0) {
        logAnchorDebug('jump-to-unread', { unreadIds: unreadIds.length, separatorIdx });
        if (separatorIdx !== -1) {
        virtuosoRef.current?.scrollToIndex({ index: separatorIdx, align: 'start', behavior: 'smooth' });
    } else {
          const mi = currentItems.findIndex(
            (it): it is Extract<ChatListRow, { type: 'message' }> =>
              it.type === 'message' && isIncomingUnreadForViewer(it.message, currentUser.id)
          );
          if (mi !== -1) {
            virtuosoRef.current?.scrollToIndex({ index: mi, align: 'start', behavior: 'smooth' });
          }
        }
        anchorUnreadStepRef.current = 1;
        return;
      }
        logAnchorDebug('mark-all-read', { unreadIds: unreadIds.length });
        virtuosoRef.current?.scrollToIndex({ index: lastIdx, align: 'end', behavior: 'smooth' });
      anchorUnreadStepRef.current = 0;
      void (async () => {
        if (suppressReadReceipts) {
          await markConversationAsRead(firestore, conversation.id, currentUser.id);
          return;
        }
        try {
          await markManyMessagesAsRead(firestore, conversation.id, currentUser.id, unreadIds);
          unreadIds.forEach((id) => sessionReadIds.current.add(id));
          await markConversationAsRead(firestore, conversation.id, currentUser.id);
        } catch (e) {
          console.error('[ChatWindow] anchor mark all read failed', e);
          unreadIds.forEach((id) => sessionReadIds.current.delete(id));
        }
      })();
      return;
    }

    logAnchorDebug('jump-to-bottom');
    virtuosoRef.current?.scrollToIndex({ index: lastIdx, align: 'end', behavior: 'smooth' });
    anchorUnreadStepRef.current = 0;
  };

  const handleNavigateToReaction = useCallback(async () => {
    const target = latestReaction;
    if (!target || !firestore) return;
    if (target.parentId) {
      const parentMsgRef = doc(firestore, `conversations/${conversation.id}/messages`, target.parentId);
            const parentMsgSnap = await getDoc(parentMsgRef);
            if (parentMsgSnap.exists()) {
        setThreadReactionScrollToId(target.messageId);
                setSelectedThreadMessage({ ...parentMsgSnap.data(), id: parentMsgSnap.id } as ChatMessage);
            } else {
                toast({ title: 'Обсуждение не найдено' });
            }
        } else {
      navigateToMessage(target.messageId);
    }
    window.setTimeout(() => {
      updateDocumentNonBlocking(doc(firestore, 'conversations', conversation.id), {
        [`lastReactionSeenAt.${currentUser.id}`]: new Date().toISOString(),
      });
    }, 500);
  }, [latestReaction, firestore, conversation.id, currentUser.id, navigateToMessage, toast]);

  const clearThreadReactionScrollTarget = useCallback(() => setThreadReactionScrollToId(null), []);

  const canDeleteBulk = useMemo(() => {
    if (selection.ids.size === 0) return false;
    return Array.from(selection.ids).every(id => {
        const m = allMessages.find(msg => msg.id === id);
        return m && m.senderId === currentUser.id && !m.isDeleted;
    });
  }, [selection.ids, allMessages, currentUser.id]);

  const windowTouchStart = useRef<{ x: number, y: number } | null>(null);
  const handleTouchStart = (e: React.TouchEvent) => {
    windowTouchStart.current = { x: e.touches[0].clientX, y: e.touches[0].clientY };
  };

  const handleTouchEnd = (e: React.TouchEvent) => {
    if (!windowTouchStart.current) return;
    if (isProfileOpen || !!selectedThreadMessage || mediaViewerState.isOpen) {
        windowTouchStart.current = null; return;
    }
    const dx = e.changedTouches[0].clientX - windowTouchStart.current.x;
    const dy = Math.abs(e.changedTouches[0].clientY - windowTouchStart.current.y);
    if (dx > 100 && dy < 60) onBack();
    windowTouchStart.current = null;
  };

  const suppressChatAnchor =
    isProfileOpen || mediaViewerState.isOpen || documentFullscreen;

  const chatDisplayName = conversation.isGroup
    ? conversation.name || 'Группа'
    : isSelfSavedChat
      ? conversation.name || 'Избранное'
      : resolveContactDisplayName(
          userContactsIndex?.contactProfiles,
          otherId,
          (otherUser?.name ?? '').trim() || 'Чат'
        );
  const chatDisplayAvatar = conversation.isGroup
    ? conversation.photoUrl
    : isSelfSavedChat
      ? participantListAvatarUrl(currentUser, conversation.participantInfo[currentUser.id])
      : participantListAvatarUrl(otherUser, otherId ? conversation.participantInfo[otherId] : undefined);

  const formatDateLabel = (dateStr: string) => {
    const date = parseISO(dateStr);
    if (isToday(date)) return 'Сегодня';
    if (isYesterday(date)) return 'Вчера';
    return format(date, 'd MMMM', { locale: ru });
  };

  return (
    <div className="h-full flex flex-col overflow-hidden relative bg-transparent touch-pan-y" onTouchStart={handleTouchStart} onTouchEnd={handleTouchEnd}>
        <ChatWallpaperLayer wallpaper={effectiveWallpaper} />

        {openGameId ? (
          <DurakWebGameDialog
            open={true}
            onOpenChange={(v) => {
              if (!v) closeGameDialog();
            }}
            gameId={openGameId}
            currentUser={currentUser}
          />
        ) : null}

        <div className="relative z-10 flex min-h-0 min-w-0 flex-1 overflow-hidden">
        <div
          className="relative flex min-h-0 min-w-0 flex-1 flex-col"
          onDragOver={(e) => {
            if (selection.active || isPartnerDeleted) return;
            e.preventDefault();
            e.dataTransfer.dropEffect = 'copy';
          }}
          onDrop={(e) => {
            if (selection.active || isPartnerDeleted) return;
            e.preventDefault();
            const files = Array.from(e.dataTransfer.files ?? []).filter((f) => f.size > 0);
            if (files.length) messageInputRef.current?.addDraftFiles(files);
          }}
        >
        <div
          className={cn(
            'flex shrink-0 items-center gap-2 px-3 pb-2 pt-[max(0.35rem,env(safe-area-inset-top))]',
            CHAT_HEADER_SAFE_AREA_STRIP
          )}
        >
            <div className="flex min-w-0 flex-1 items-center gap-2">
            {selection.active ? (
                <SelectionHeader count={selection.ids.size} onCancel={() => setSelection({ active: false, ids: new Set() })} onDelete={handleBulkDelete} onForward={() => { const selectedMessages = allMessages.filter(m => selection.ids.has(m.id)); sessionStorage.setItem('forwardMessages', JSON.stringify(selectedMessages)); router.push('/dashboard/chat/forward'); }} isProcessing={isBulkProcessing} showDelete={canDeleteBulk} />
            ) : isSearchActive ? (
                <div className="flex w-full animate-in slide-in-from-right-4 items-center gap-2">
                    <Button variant="ghost" size="icon" className="rounded-full" onClick={() => { setIsSearchActive(false); setSearchQuery(''); }}><ArrowLeft className="h-5 w-5" /></Button>
                    <div className="relative flex-1">
                        <Input autoFocus placeholder="Поиск сообщений..." value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} className="h-9 rounded-full border-none bg-muted/50" />
                        {searchQuery && <button onClick={() => setSearchQuery('')} className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground"><X className="h-4 w-4" /></button>}
                    </div>
                </div>
            ) : (
                <div className="flex min-w-0 flex-1 items-center justify-between gap-2">
                    <div
                      className={cn(
                        'flex items-center gap-2 cursor-pointer min-w-0 max-w-[min(100%,72vw)] sm:max-w-[min(100%,208px)]',
                        chatHeaderUserGlass,
                        'py-1 pl-1 pr-2.5'
                      )}
                      onClick={() => {
                        setProfileFocusUserId(null);
                        setProfileSource('chat');
                        setIsProfileOpen(true);
                      }}
                    >
                        <Button
                          variant="ghost"
                          size="icon"
                          className="md:hidden shrink-0 rounded-full h-9 w-9 hover:bg-black/5 dark:hover:bg-white/10"
                          onClick={(e) => {
                            e.stopPropagation();
                            onBack();
                          }}
                        >
                          <ArrowLeft className="h-5 w-5" />
                        </Button>
                        <Avatar className="h-11 w-11 shrink-0">
                            <AvatarImage src={chatDisplayAvatar} className="object-cover" />
                            <AvatarFallback className="text-sm font-bold">{chatDisplayName.charAt(0)}</AvatarFallback>
                        </Avatar>
                        <div className="flex flex-col min-w-0">
                            <h2 className="text-sm font-bold truncate leading-tight drop-shadow-sm">{chatDisplayName}</h2>
                            <span className="text-[11px] text-muted-foreground drop-shadow-sm">
                              {conversation.isGroup
                                ? `${conversation.participantIds.length} участников`
                                : isSelfSavedChat
                                  ? 'Только вы'
                                  : otherPresenceLabel}
                            </span>
                        </div>
                    </div>
                    <div className="flex items-center gap-1 shrink-0">
                        <div className={cn('relative p-0.5', chatHeaderIconGlass)}>
                            <Button
                              variant="ghost"
                              size="icon"
                              className="h-9 w-9 rounded-lg hover:bg-black/5 dark:hover:bg-white/10"
                              aria-label="Обсуждения"
                              title="Обсуждения"
                              onClick={handleOpenThreadsFromHeader}
                            >
                              <MessageCircle className={cn('h-[22px] w-[22px]', CHAT_HEADER_IOS.threads)} strokeWidth={2} />
                            </Button>
                            <Badge
                              className={cn(
                                'absolute -top-0.5 -right-0.5 h-4 min-w-[16px] px-1 bg-red-500 text-white text-[9px] font-black border-2 border-background flex items-center justify-center animate-in zoom-in-50 shadow-sm',
                                !unreadThreadCount && 'hidden'
                              )}
                            >
                              {unreadThreadCount > 9
                                ? '9+'
                                : unreadThreadCount}
                            </Badge>
                        </div>
                        <div className={cn('p-0.5', chatHeaderIconGlass)}>
                            <Button
                              variant="ghost"
                              size="icon"
                              className="h-9 w-9 rounded-lg hover:bg-black/5 dark:hover:bg-white/10"
                              onClick={() => setIsSearchActive(true)}
                              aria-label="Поиск по сообщениям"
                            >
                              <Search
                                className={cn(
                                  'h-[22px] w-[22px] drop-shadow-sm dark:drop-shadow-[0_1px_2px_rgba(0,0,0,0.55)]',
                                  CHAT_HEADER_IOS.search
                                )}
                                strokeWidth={2}
                              />
                            </Button>
                </div>
                        {!conversation.isGroup && otherId && !isSelfSavedChat && !dmMessagingBlocked && (
                          <>
                            <div className={cn('p-0.5', chatHeaderIconGlass)}>
                              <Button
                                variant="ghost"
                                size="icon"
                                className="h-9 w-9 rounded-lg hover:bg-black/5 dark:hover:bg-white/10"
                                onClick={() => {
                                  const recv =
                                    otherUser ??
                                    ({
                                      id: otherId,
                                      name: conversation.participantInfo[otherId]?.name ?? 'Пользователь',
                                      blockedUserIds: partnerUserLive?.blockedUserIds,
                                    } as User);
                                  void initiateCall(firestore, callerForCalls, recv, true, toast);
                                }}
                              >
                                <Video className={cn('h-[22px] w-[22px]', CHAT_HEADER_IOS.callVideo)} strokeWidth={2} />
                              </Button>
                            </div>
                            <div className={cn('p-0.5', chatHeaderIconGlass)}>
                              <Button
                                variant="ghost"
                                size="icon"
                                className="h-9 w-9 rounded-lg hover:bg-black/5 dark:hover:bg-white/10"
                                onClick={() => {
                                  const recv =
                                    otherUser ??
                                    ({
                                      id: otherId,
                                      name: conversation.participantInfo[otherId]?.name ?? 'Пользователь',
                                      blockedUserIds: partnerUserLive?.blockedUserIds,
                                    } as User);
                                  void initiateCall(firestore, callerForCalls, recv, false, toast);
                                }}
                              >
                                <Phone className={cn('h-[22px] w-[22px]', CHAT_HEADER_IOS.callAudio)} strokeWidth={2} />
                              </Button>
                            </div>
                          </>
                        )}
                    </div>
                </div>
            )}
            </div>
        </div>

        <div className="relative flex min-h-0 flex-1 flex-col overflow-hidden bg-transparent">
            {sortedPins.length > 0 ? (
              <PinnedMessageBar
                pinnedMessage={sortedPins[Math.min(barPinIndex, sortedPins.length - 1)]}
                totalPins={sortedPins.length}
                onUnpin={() =>
                  void handleUnpinOne(sortedPins[Math.min(barPinIndex, sortedPins.length - 1)].messageId)
                }
                onNavigate={handlePinnedBarNavigate}
              />
            ) : null}
            <div className="flex-1 min-h-0 relative min-w-0 overflow-hidden">
                {!isFullyReady && (
                    <div className="absolute inset-0 z-50 bg-background/80 backdrop-blur-md flex flex-col items-center justify-center space-y-4">
                        <Loader2 className="h-8 w-8 animate-spin text-primary" /><p className="text-xs font-bold uppercase tracking-widest text-muted-foreground">Загрузка...</p>
                    </div>
                )}
                <ChatSearchOverlay
                  query={searchQuery}
                  messages={allMessages}
                  allUsers={allUsers}
                  onSelectResult={navigateToMessage}
                  blurInsetLeftPx={messageSearchBlurInsetLeftPx}
                />
                <div className={cn('relative h-full w-full min-h-0 min-w-0 overflow-hidden transition-opacity duration-500', isFullyReady ? 'opacity-100' : 'opacity-0')}>
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
                        rangeChanged={handleRangeChanged} 
                        computeItemKey={(index, item) => {
                            if (item.type === 'date') return `chat-d-${item.dateKey}-${item.dayStickyOrder}`;
                            if (item.type === 'unread-separator') return `chat-u-${unreadSeparatorId ?? index}`;
                            return `chat-m-${item.message.id}`;
                        }}
                        increaseViewportBy={increaseViewportBy}
                        minOverscanItemCount={VIRTUOSO_CHAT_MIN_OVERSCAN}
                        components={{ 
                            Header: () => isLoadingOlder ? (
                                <div className="p-4 flex items-center justify-center text-muted-foreground">
                                    <Loader2 className="h-5 w-5 animate-spin mr-2" />
                                    <span className="text-[10px] font-black uppercase tracking-widest">Загрузка истории...</span>
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
                            if (item.type === 'date') {
                              return (
                                <ChatDateSeparatorRow
                                  label={formatDateLabel(item.dateKey)}
                                  stickyStackOrder={item.dayStickyOrder}
                                />
                              );
                            }
                            if (item.type === 'unread-separator') return (<div className="flex items-center gap-4 px-6 py-4 animate-in fade-in duration-500"><div className="h-px bg-primary/30 flex-1" /><span className="text-[10px] font-black uppercase tracking-widest text-primary bg-primary/5 px-3 py-1 rounded-full border border-primary/20">Непрочитанные сообщения</span><div className="h-px bg-primary/30 flex-1" /></div>);
                            // Phase 8: system-маркер E2EE рисуется отдельным divider'ом
                            // вместо обычного bubble. Senders = '__system__'.
                            if (item.message.systemEvent && item.message.senderId === '__system__') {
                              return (
                                <ChatSystemEventDivider
                                  event={item.message.systemEvent}
                                />
                              );
                            }
                            const isLastInChat = index === flatItems.length - 1;
                            return (
                              <MessageReadOnViewport
                                messageId={item.message.id}
                                message={item.message}
                                currentUserId={currentUser.id}
                                conversationId={conversation.id}
                                firestore={firestore}
                                canMarkReadByViewport={isFullyReady && hasScrolledToUnread && !suppressReadReceipts}
                                viewportLayoutKey={viewportScrollerKey}
                                sessionReadIds={sessionReadIds}
                              >
                                <div className="py-1 px-4">
                                  <ChatMessageItem message={item.message} currentUser={currentUser} allUsers={allUsers} conversation={conversation} isSelected={selection.ids.has(item.message.id)} isSelectionActive={selection.active} editingMessage={editingMessage?.id === item.message.id ? editingMessage : null} onToggleSelection={(id) => setSelection(prev => { const next = new Set(prev.ids); if (next.has(id)) next.delete(id); else next.add(id); return { active: true, ids: next }; })} onEdit={(m) => { setEditingMessage(m); setReplyingTo(null); }} onUpdateMessage={handleUpdateMessage} onDelete={(id) => handleDeleteMessage(id)} onCopy={(txt) => { const cleanText = txt.replace(/<[^>]*>/g, '').replace(/&nbsp;/g, ' ').trim(); navigator.clipboard.writeText(cleanText); toast({ title: 'Текст скопирован' }); }} onPin={handlePinMessage} onReply={(c) => { setReplyingTo(c); setEditingMessage(null); }} onForward={(m) => { sessionStorage.setItem('forwardMessages', JSON.stringify([m])); router.push('/dashboard/chat/forward'); }} onReact={(mid, emoji) => handleReactTo(mid, emoji)} onOpenImageViewer={handleOpenMediaViewer} onOpenVideoViewer={handleOpenMediaViewer} onNavigateToMessage={navigateToMessage} onOpenThread={(msg) => setSelectedThreadMessage(msg)} chatSettings={chatSettings} isLastInChat={isLastInChat} onMentionProfileOpen={handleMentionProfileOpen} onGroupSenderProfileOpen={handleGroupSenderProfileOpen} onGroupSenderWritePrivate={handleGroupSenderWritePrivate} onSaveStickerGif={handleSaveStickerFromMessage} contactProfiles={userContactsIndex?.contactProfiles} e2eeDecryptedByMessageId={e2eePlaintextByMessageId} isStarred={starredMessageIds.has(item.message.id)} onToggleStar={handleToggleStar} onRetryMediaNorm={handleRetryMediaNorm} />
                                </div>
                              </MessageReadOnViewport>
                            );
                        }}
                    />
                    </ChatViewportScrollerRefContext.Provider>
                    </VideoCircleTailProvider>
                    <ChatAnchor
                      suppressed={suppressChatAnchor}
                      isVisible={showScrollButton}
                      unreadCount={unreadCountForAnchor}
                      lastReaction={latestReaction}
                      onClick={handleAnchorClick}
                      onNavigateToReaction={handleNavigateToReaction}
                    />
                </div>
            </div>
        </div>

        {!selection.active && (
          <div className="relative shrink-0 bg-transparent">
            <ChatMessageInput
              ref={messageInputRef}
              onSendMessage={handleSendMessage}
              onSendLocationShare={handleSendLocationShare}
              onSendPoll={handleSendPoll}
              onUpdateMessage={handleUpdateMessage}
              replyingTo={replyingTo}
              onCancelReply={() => setReplyingTo(null)}
              editingMessage={editingMessage}
              onCancelEdit={() => setEditingMessage(null)}
              conversation={conversation}
              currentUser={currentUser}
              allUsers={allUsers}
              contactProfiles={userContactsIndex?.contactProfiles}
              isPartnerDeleted={isPartnerDeleted}
              composerLocked={composerLocked}
              composerLockedHint={composerLockedHint}
              onRestoreDraftReply={(reply) => setReplyingTo(reply)}
            />
          </div>
        )}
        </div>
        {selectedThreadMessage && (
          <>
            <div
              className="hidden w-1.5 shrink-0 cursor-col-resize items-center justify-center bg-transparent lg:flex"
              onMouseDown={(e) => {
                e.preventDefault();
                startThreadPanelResize(e.clientX);
              }}
              onTouchStart={(e) => startThreadPanelResize(e.touches[0].clientX)}
            >
              <div className="h-8 w-0.5 rounded-full bg-transparent" />
            </div>
            <ThreadWindow
              parentMessage={selectedThreadMessage}
              conversation={conversation}
              currentUser={currentUser}
              allUsers={allUsers}
              suppressFloatingAnchor={isProfileOpen}
              onClose={() => {
                setSelectedThreadMessage(null);
                setThreadReactionScrollToId(null);
              }}
              onOpenImageViewer={handleOpenMediaViewer}
              onOpenVideoViewer={handleOpenMediaViewer}
              onNavigateToMessage={navigateToMessage}
              onUpdateMessage={handleUpdateMessage}
              onDeleteMessage={(id) => handleDeleteMessage(id, selectedThreadMessage.id)}
              onReplyTo={setReplyingTo}
              onForwardMessage={(m) => {
                sessionStorage.setItem('forwardMessages', JSON.stringify([m]));
                router.push('/dashboard/chat/forward');
              }}
              onReactTo={handleReactTo}
              isPartnerDeleted={isPartnerDeleted}
              composerLocked={composerLocked}
              composerLockedHint={composerLockedHint}
              highlightThreadMessageId={threadReactionScrollToId}
              onHighlightThreadMessageConsumed={clearThreadReactionScrollTarget}
              onMentionProfileOpen={handleMentionProfileOpen}
              onGroupSenderProfileOpen={handleGroupSenderProfileOpen}
              onGroupSenderWritePrivate={handleGroupSenderWritePrivate}
              onSaveStickerGif={handleSaveStickerFromMessage}
              contactProfiles={userContactsIndex?.contactProfiles}
              parentE2eeDecryptedByMessageId={e2eePlaintextByMessageId}
              chatWallpaper={effectiveWallpaper}
              asSidebarOnDesktop
              desktopWidthPx={
                typeof window !== 'undefined' && window.innerWidth >= 1024
                  ? threadPanelExpanded
                    ? Math.min(Math.floor(window.innerWidth * 0.78), 1180)
                    : threadPanelWidth
                  : undefined
              }
              isExpandedDesktop={threadPanelExpanded}
              onToggleExpandDesktop={() => setThreadPanelExpanded((v) => !v)}
            />
          </>
        )}
        </div>
        <ChatParticipantProfile
          open={isProfileOpen}
          onOpenChange={handleProfileSheetOpenChange}
          focusUserId={profileFocusUserId}
          onClearProfileFocus={() => setProfileFocusUserId(null)}
          conversation={conversation}
          allUsers={allUsers}
          currentUser={currentUser}
          messages={messagesForList}
          onSelectConversation={onSelectConversation}
          profileSource={profileSource}
          initialSubMenu={profileInitialSubMenu}
          onInitialSubMenuConsumed={() => setProfileInitialSubMenu(null)}
        />
        <StickerPackPickerDialog
          open={stickerSaveOpen}
          onOpenChange={(o) => {
            setStickerSaveOpen(o);
            if (!o) {
              setStickerSaveAttachment(null);
              setStickerSaveMode('copy');
            }
          }}
          userId={currentUser.id}
          title="Сохранить в стикерпак"
          description="Выберите пак и нажмите «Сохранить». Отправка из вкладки «Стикеры». Пункт «Создать стикер» делает квадратное превью под размер стикера."
          busy={stickerSaveBusy}
          onConfirmPack={handleStickerSaveConfirmPack}
          createPack={handleStickerPackCreate}
        />
        <MediaViewer isOpen={mediaViewerState.isOpen} onOpenChange={(open) => setMediaViewerState(prev => ({ ...prev, isOpen: open }))} media={allMediaItems} startIndex={mediaViewerState.startIndex} currentUserId={currentUser.id} allUsers={allUsers} onReply={(m) => { const replyContext = getReplyPreview(m, allUsers); setReplyingTo(replyContext); }} onForward={(m) => { sessionStorage.setItem('forwardMessages', JSON.stringify([m])); router.push('/dashboard/chat/forward'); }} onDelete={(id) => handleDeleteMessage(id)} navigateToMessage={navigateToMessage} />
    </div>
  );
}
