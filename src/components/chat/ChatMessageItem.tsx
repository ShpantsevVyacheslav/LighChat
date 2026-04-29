'use client';

import React, { useState, useMemo, useRef, useLayoutEffect } from 'react';

import type { User, Conversation, ChatMessage, ChatAttachment, ReplyContext, ChatSettings, UserContactLocalProfile } from '@/lib/types';
import { cn } from '@/lib/utils';
import {
  isOnlyEmojis,
  getReplyPreview,
  getFirstStickerOrGifAttachment,
  getFirstGridGalleryImageForStickerCreation,
} from '@/lib/chat-utils';
import { isAttachmentLikelyIosStickerCutout } from '@/lib/ios-sticker-detect';
import { bubbleRadiusToClass } from '@/lib/chat-bubble-radius';

import { Checkbox } from '@/components/ui/checkbox';
import { Trash2, Reply as ReplyIcon, MessageSquare } from 'lucide-react';
import { Avatar, AvatarFallback, AvatarImage } from '../ui/avatar';
import { participantListAvatarUrl } from '@/lib/user-avatar-display';

import { MessageText } from './parts/MessageText';
import { MessageLocationCard } from './parts/MessageLocationCard';
import { MessagePollInline } from './parts/MessagePollInline';
import { MessageMedia } from './parts/MessageMedia';
import { HeicAwareChatImage } from './parts/HeicAwareChatImage';
import { useChatAttachmentDisplaySrc } from '@/components/chat/use-chat-attachment-display-src';
import { MessageStatus } from './parts/MessageStatus';
import { MessageDisappearingEta } from './parts/MessageDisappearingEta';
import { MessageReply } from './parts/MessageReply';
import { MessageReactions } from './parts/MessageReactions';
import { AudioMessagePlayer } from './AudioMessagePlayer';
import { VideoCirclePlayer } from './VideoCirclePlayer';
import { MessageContextMenu, type MessageContextMenuPosition } from './context-menu/MessageContextMenu';
import {
  shouldUseCircularStickerMenuHole,
  readStickerCircleHoleFromRect,
} from './context-menu/message-focus-hole';
import { GroupMessageSenderMenu } from './GroupMessageSenderMenu';
import { isGridGalleryAttachment, isGridGalleryVideo } from '@/components/chat/attachment-visual';

const USER_COLORS = [
    'text-red-500', 'text-blue-500', 'text-green-500', 'text-yellow-500',
    'text-purple-500', 'text-pink-500', 'text-indigo-500', 'text-teal-500',
];

/** Паддинг выреза маски: >0 даёт «вылезание» за скруглённый контент (фото и т.д.). Оставляем 0 — граница по getBoundingClientRect пузыря. */
const MENU_FOCUS_HOLE_PAD_PX = 0;

/** Вырез под blur: bbox пузыря; rx из computed border-radius. */
function readBubbleHoleGeometry(el: HTMLElement, pad: number): Pick<MessageContextMenuPosition, 'bubbleRect' | 'bubbleCornerRadiusPx'> {
    const br = el.getBoundingClientRect();
    const bubbleRect = {
        top: br.top - pad,
        left: br.left - pad,
        width: br.width + pad * 2,
        height: br.height + pad * 2,
    };
    const raw = getComputedStyle(el).borderTopLeftRadius;
    const parsed = parseFloat(raw);
    const bubbleCornerRadiusPx = Number.isFinite(parsed)
        ? Math.min(Math.max(parsed, 0), Math.min(bubbleRect.width, bubbleRect.height) / 2)
        : 14;
    return { bubbleRect, bubbleCornerRadiusPx };
}

const getUserColor = (userId: string) => {
    let hash = 0;
    for (let i = 0; i < userId.length; i++) {
        hash = userId.charCodeAt(i) + ((hash << 5) - hash);
    }
    const index = Math.abs(hash % USER_COLORS.length);
    return USER_COLORS[index];
};

function GifAttachmentImage({ att }: { att: ChatAttachment }) {
    const displaySrc = useChatAttachmentDisplaySrc(att);
    if (att.type.startsWith('video/')) {
        return (
            <video
                src={displaySrc}
                className="pointer-events-none h-auto w-full max-h-64 object-contain"
                loop
                muted
                playsInline
                autoPlay
            />
        );
    }
    return <img src={displaySrc} alt="" loading="lazy" decoding="async" className="h-auto w-full max-h-64 object-contain" />;
}

interface ChatMessageItemProps {
    message: ChatMessage;
    currentUser: User;
    allUsers: User[];
    conversation: Conversation;
    isSelected: boolean;
    isSelectionActive: boolean;
    editingMessage: { id: string; text: string; attachments?: ChatAttachment[] } | null;
    onToggleSelection: (id: string) => void;
    onEdit: (msg: { id: string; text: string; attachments?: ChatAttachment[] }) => void;
    onUpdateMessage: (id: string, text: string, attachments?: ChatAttachment[]) => void;
    onDelete: (id: string) => void;
    onCopy: (text: string) => void;
    onPin: (msg: ChatMessage) => void;
    onReply: (context: ReplyContext) => void;
    onForward: (msg: ChatMessage) => void;
    onNavigateToMessage: (messageId: string) => void;
    onOpenImageViewer: (image: ChatAttachment) => void;
    onOpenVideoViewer: (video: ChatAttachment) => void;
    onOpenThread?: (message: ChatMessage) => void;
    onReact: (messageId: string, emoji: string) => void;
    isThreadMessage?: boolean;
    disableContextMenu?: boolean;
    chatSettings?: ChatSettings;
    /** Последний элемент в виртуальном списке чата/ветки — для нижнего резерва у развёрнутого видеокружка */
    isLastInChat?: boolean;
    /** Клик по @упоминанию в тексте — открыть профиль участника */
    onMentionProfileOpen?: (userId: string) => void;
    /** Группа: из меню отправителя открыть профиль (источник = sender). */
    onGroupSenderProfileOpen?: (userId: string) => void;
    /** Группа: из меню отправителя — открыть или создать личный чат с автором сообщения */
    onGroupSenderWritePrivate?: (userId: string) => void | Promise<void>;
    /** Локальные имена контактов текущего пользователя (рендер @ в тексте). */
    contactProfiles?: Record<string, UserContactLocalProfile>;
    /** Сохранить стикер/GIF из сообщения в пак текущего пользователя (контекстное меню). */
    onSaveStickerGif?: (attachment: ChatAttachment, mode?: 'copy' | 'normalize_sticker') => void;
    /** Расшифрованный HTML для E2E (id сообщения → текст). */
    e2eeDecryptedByMessageId?: Record<string, string>;
    /** Избранное (только основная лента; в ветке не передаётся). */
    isStarred?: boolean;
    onToggleStar?: (messageId: string, nextStarred: boolean) => void;
    onRetryMediaNorm?: (message: ChatMessage) => void | Promise<void>;
}

const ChatMessageItemComponent = ({
    message, currentUser, allUsers, conversation, isSelected, isSelectionActive,
    onToggleSelection, onEdit, onDelete,
    onCopy, onPin, onReply, onForward, onReact,
    onOpenImageViewer, onOpenVideoViewer,
    onNavigateToMessage,
    onOpenThread,
    isThreadMessage = false,
    disableContextMenu = false,
    chatSettings,
    isLastInChat = false,
    onMentionProfileOpen,
    onGroupSenderProfileOpen,
    onGroupSenderWritePrivate,
    onSaveStickerGif,
    contactProfiles,
    e2eeDecryptedByMessageId,
    isStarred = false,
    onToggleStar,
    onRetryMediaNorm,
}: ChatMessageItemProps) => {
    const isCurrentUser = message.senderId === currentUser.id;
    const isDeleted = !!message.isDeleted;
    const showDisappearingEta =
        !isDeleted &&
        message.senderId !== '__system__' &&
        !message.systemEvent &&
        message.expireAt != null;

    const hasDecryptedEntry =
        e2eeDecryptedByMessageId != null && Object.prototype.hasOwnProperty.call(e2eeDecryptedByMessageId, message.id);
    const isE2eePending = !!(message.e2ee?.ciphertext && !message.text && !hasDecryptedEntry);
    const displayTextHtml = hasDecryptedEntry
        ? (e2eeDecryptedByMessageId![message.id] ?? '')
        : (message.text ?? '');

    const stickerGifForSave = useMemo(
        () => (!isDeleted ? getFirstStickerOrGifAttachment(message) : null),
        [isDeleted, message]
    );
    const gridImageForStickerCreate = useMemo(
        () => (!isDeleted ? getFirstGridGalleryImageForStickerCreation(message) : null),
        [isDeleted, message]
    );
    
    const [isMenuOpen, setIsMenuOpen] = useState(false);
    const [menuPosition, setMenuPosition] = useState<MessageContextMenuPosition | null>(null);

    const closeContextMenu = () => {
        setIsMenuOpen(false);
        setMenuPosition(null);
    };

    const [isVideoPlaying, setIsVideoPlaying] = useState(false);
    const [swipeX, setSwipeX] = useState(0);
    
    const bubbleRef = useRef<HTMLDivElement>(null);
    /** Контейнер одиночного стикера — bbox для круглого выреза маски меню. */
    const stickerMenuHoleRef = useRef<HTMLDivElement>(null);
    const longPressTimer = useRef<NodeJS.Timeout | null>(null);
    const touchStartRef = useRef<{ x: number, y: number } | null>(null);

    const liveGroupSender = useMemo(
      () => (conversation.isGroup ? allUsers.find((u) => u.id === message.senderId) : undefined),
      [conversation.isGroup, allUsers, message.senderId],
    );

    const senderLiveShareForLocation = useMemo(() => {
        if (isCurrentUser) return currentUser.liveLocationShare ?? null;
        const u = allUsers.find((x) => x.id === message.senderId);
        return u?.liveLocationShare ?? null;
    }, [isCurrentUser, currentUser.liveLocationShare, allUsers, message.senderId]);

    const senderProfileResolvedForLocation = useMemo(() => {
        if (isCurrentUser) return true;
        return allUsers.some((u) => u.id === message.senderId);
    }, [isCurrentUser, allUsers, message.senderId]);

    const threadReplyUsers = useMemo(() => {
        const sourceIds = Array.isArray(message.threadParticipantIds)
            ? message.threadParticipantIds
            : [];
        const ids = sourceIds.length
            ? sourceIds
            : message.lastThreadMessageSenderId
              ? [message.lastThreadMessageSenderId]
              : [];
        const uniqueIds = Array.from(new Set(ids.filter((id) => typeof id === 'string' && id.trim().length > 0)));
        return uniqueIds.map((id) => {
            const liveUser = allUsers.find((u) => u.id === id);
            const participant = conversation.participantInfo?.[id];
            return {
                id,
                name: liveUser?.name || participant?.name || 'U',
                avatarUrl: participantListAvatarUrl(liveUser, participant),
            };
        });
    }, [allUsers, conversation.participantInfo, message.lastThreadMessageSenderId, message.threadParticipantIds]);

    const isSticker = useMemo(
        () => message.attachments?.some((att) => isAttachmentLikelyIosStickerCutout(att)) ?? false,
        [message.attachments],
    );
    const isGifAttachment = useMemo(() => message.attachments?.some(att => att.name.startsWith('gif_')), [message.attachments]);
    const isStickerLike = isSticker || isGifAttachment;
    const isPureEmoji = useMemo(
        () =>
            displayTextHtml &&
            isOnlyEmojis(displayTextHtml) &&
            !message.attachments?.length &&
            !message.replyTo &&
            !message.locationShare &&
            !message.chatPollId,
        [displayTextHtml, message.attachments, message.replyTo, message.locationShare, message.chatPollId]
    );
    const isVideoCircle = useMemo(() => message.attachments?.some(att => att.name.startsWith('video-circle_')), [message.attachments]);
    const isPollMessage = !!message.chatPollId;
    const stickerCaptionPlain = useMemo(() => {
        if (!displayTextHtml) return '';
        return displayTextHtml.replace(/<[^>]*>/g, '').replace(/&nbsp;/g, ' ').trim();
    }, [displayTextHtml]);
    const hasStickerCaption = isStickerLike && stickerCaptionPlain.length > 0;
    const circularStickerMenuHole = useMemo(() => shouldUseCircularStickerMenuHole(message, stickerCaptionPlain), [
        message.id,
        message.isDeleted,
        stickerCaptionPlain,
        message.replyTo,
        message.locationShare,
        message.chatPollId,
        message.attachments,
    ]);
    const isMediaOnly = useMemo(
        () =>
            !displayTextHtml &&
            !!message.attachments?.length &&
            !message.replyTo &&
            !message.locationShare &&
            !message.chatPollId,
        [displayTextHtml, message.attachments, message.replyTo, message.locationShare, message.chatPollId]
    );

    /** Сетка MessageMedia — ширины 208px / 169px = `CHAT_MEDIA_*` в `@/lib/chat-media-preview-max`. */
    const hasGridVisualMedia = useMemo(() => {
        if (message.isDeleted) return false;
        const list = message.attachments;
        if (!list?.length) return false;
        return list.some(isGridGalleryAttachment);
    }, [message.attachments, message.isDeleted]);
    /** Полноэкранный «кино»-режим только для сообщения из одного кружка; иначе сетка/видео сверху не прыгает при play. */
    const useFullBleedVideoCirclePlaying = useMemo(
        () => isVideoCircle && isVideoPlaying && !hasGridVisualMedia,
        [isVideoCircle, isVideoPlaying, hasGridVisualMedia],
    );
    const hasNeedsMediaNorm = useMemo(() => {
        if (message.isDeleted) return false;
        const list = message.attachments || [];
        if (!list.length) return false;
        return list.some((att) => {
            const t = (att.type || '').toLowerCase();
            const path = att.url.split('?')[0].toLowerCase();
            return t.includes('webm') || path.endsWith('.webm');
        });
    }, [message.attachments, message.isDeleted]);
    const mediaNormStatus = message.mediaNorm?.status ?? (hasNeedsMediaNorm ? 'pending' : null);
    const mediaNormPending = mediaNormStatus === 'pending';
    const mediaNormFailed = mediaNormStatus === 'failed';

    /** Геолокация вне стикера/видео; истёкшая live — см. [`MessageLocationCard`](./parts/MessageLocationCard.tsx). */
    const showShareableLocation = useMemo(
        () => !!message.locationShare && !isStickerLike && !isVideoPlaying,
        [message.locationShare, isStickerLike, isVideoPlaying]
    );

    const showInnerColoredBubble = useMemo(
        () =>
            !isDeleted &&
            !!(
                message.chatPollId ||
                hasGridVisualMedia ||
                (message.attachments?.length ?? 0) > 0 ||
                !!(displayTextHtml?.trim())
            ),
        [isDeleted, message.chatPollId, hasGridVisualMedia, message.attachments?.length, displayTextHtml]
    );

    const radiusClass = bubbleRadiusToClass(chatSettings?.bubbleRadius);
    const showBubbleTailClip =
        !isMenuOpen &&
        !isPureEmoji &&
        !isVideoCircle &&
        !isStickerLike &&
        !isDeleted &&
        !isPollMessage;
    const fontSizeClass = chatSettings?.fontSize === 'small' ? 'text-xs' : chatSettings?.fontSize === 'large' ? 'text-base' : 'text-sm';
    const showTimestamps = chatSettings?.showTimestamps !== false;
    const hasCustomOutgoing = !!chatSettings?.bubbleColor;
    const hasCustomIncoming = !!chatSettings?.incomingBubbleColor;
    const isColoredBubble = !isCurrentUser && hasCustomIncoming;

    const bubbleInlineStyle = useMemo(() => {
        if (isPureEmoji || isVideoCircle || isStickerLike || isDeleted || isMediaOnly || isPollMessage) return undefined;
        const color = isCurrentUser ? chatSettings?.bubbleColor : chatSettings?.incomingBubbleColor;
        return color ? { backgroundColor: color } : undefined;
    }, [isCurrentUser, chatSettings?.bubbleColor, chatSettings?.incomingBubbleColor, isPureEmoji, isVideoCircle, isStickerLike, isDeleted, isMediaOnly, isPollMessage]);

    const handleOpenMenu = (e: React.MouseEvent | React.TouchEvent) => {
        if (isDeleted || isSelectionActive || disableContextMenu) return;
        e.preventDefault(); e.stopPropagation();
        const bubbleEl = bubbleRef.current;
        if (!bubbleEl) return;
        const useCircleHole = circularStickerMenuHole;
        const holeTarget =
            useCircleHole && stickerMenuHoleRef.current ? stickerMenuHoleRef.current : bubbleEl;
        const bubbleRectEl = bubbleEl.getBoundingClientRect();
        const viewportWidth = window.innerWidth;
        const menuHeight = 360; const menuWidth = 240;
        const top = bubbleRectEl.bottom + 4;
        let left = isCurrentUser ? bubbleRectEl.right - menuWidth : bubbleRectEl.left;
        let shiftY = 0;
        if (top + menuHeight > window.innerHeight - 90) shiftY = (window.innerHeight - 90) - (top + menuHeight);
        left = Math.max(16, Math.min(left, viewportWidth - menuWidth - 16));
        const { bubbleRect, bubbleCornerRadiusPx } = readBubbleHoleGeometry(holeTarget, MENU_FOCUS_HOLE_PAD_PX);
        const focusCircle =
            useCircleHole && stickerMenuHoleRef.current
                ? readStickerCircleHoleFromRect(stickerMenuHoleRef.current)
                : undefined;
        setMenuPosition({
            top: top + shiftY,
            left,
            shiftY,
            menuHeight,
            bubbleRect,
            bubbleCornerRadiusPx,
            focusHoleShape: useCircleHole && focusCircle ? 'circle' : 'rect',
            focusCircle,
        });
        setIsMenuOpen(true);
    };

    /**
     * Синхронизация выреза под blur с пузырём после translateY/paddingBottom.
     * Без transition на строке при открытом меню transform применяется сразу; дополнительно
     * два rAF — на случай, если Virtuoso/скролл двигает узел уже после layout.
     */
    useLayoutEffect(() => {
        if (!isMenuOpen || !bubbleRef.current) return;
        const applyGeometry = () => {
            const bubbleEl = bubbleRef.current;
            if (!bubbleEl) return;
            const useCircleHole = circularStickerMenuHole;
            const holeTarget =
                useCircleHole && stickerMenuHoleRef.current ? stickerMenuHoleRef.current : bubbleEl;
            const { bubbleRect: nextRect, bubbleCornerRadiusPx: nextR } = readBubbleHoleGeometry(
                holeTarget,
                MENU_FOCUS_HOLE_PAD_PX
            );
            const nextCircle =
                useCircleHole && stickerMenuHoleRef.current
                    ? readStickerCircleHoleFromRect(stickerMenuHoleRef.current)
                    : undefined;
            const nextShape = useCircleHole && nextCircle ? 'circle' : 'rect';
            setMenuPosition((prev) => {
                if (!prev) return prev;
                const { bubbleRect: a, bubbleCornerRadiusPx: ar = 14, focusHoleShape: sh, focusCircle: fc } = prev;
                const c = nextCircle;
                const sameRect =
                    a.top === nextRect.top &&
                    a.left === nextRect.left &&
                    a.width === nextRect.width &&
                    a.height === nextRect.height &&
                    ar === nextR &&
                    sh === nextShape;
                const sameCircle =
                    nextShape !== 'circle' ||
                    (c &&
                        fc &&
                        c.cx === fc.cx &&
                        c.cy === fc.cy &&
                        c.r === fc.r);
                if (sameRect && sameCircle) return prev;
                return {
                    ...prev,
                    bubbleRect: nextRect,
                    bubbleCornerRadiusPx: nextR,
                    focusHoleShape: nextShape,
                    focusCircle: nextShape === 'circle' ? c : undefined,
                };
            });
        };
        applyGeometry();
        let raf2 = 0;
        const raf1 = requestAnimationFrame(() => {
            raf2 = requestAnimationFrame(applyGeometry);
        });
        return () => {
            cancelAnimationFrame(raf1);
            cancelAnimationFrame(raf2);
        };
    }, [isMenuOpen, message]);

    const onMenuAction = (action: string, payload?: string) => {
        switch(action) {
            case 'reply': onReply(getReplyPreview(message, allUsers, e2eeDecryptedByMessageId)); break;
            case 'copy': onCopy(displayTextHtml || ''); break;
            case 'edit': onEdit({ id: message.id, text: displayTextHtml || '', attachments: message.attachments }); break;
            case 'pin': onPin(message); break;
            case 'forward': onForward(message); break;
            case 'delete': onDelete(message.id); break;
            case 'react': if (payload) onReact(message.id, payload); break;
            case 'select': onToggleSelection(message.id); break;
            case 'thread': onOpenThread?.(message); break;
            case 'save_sticker': {
                const a = getFirstStickerOrGifAttachment(message);
                if (a && onSaveStickerGif) onSaveStickerGif(a, 'copy');
                break;
            }
            case 'create_sticker': {
                const a = getFirstGridGalleryImageForStickerCreation(message);
                if (a && onSaveStickerGif) onSaveStickerGif(a, 'normalize_sticker');
                break;
            }
            case 'star':
                if (onToggleStar) onToggleStar(message.id, !isStarred);
                break;
        }
    };

    const handleTouchStart = (e: React.TouchEvent) => {
        const touch = e.touches[0];
        touchStartRef.current = { x: touch.clientX, y: touch.clientY };
        setSwipeX(0);
        
        const target = e.target as HTMLElement;
        if (bubbleRef.current?.contains(target) && !isSelectionActive && !isDeleted) {
            longPressTimer.current = setTimeout(() => handleOpenMenu(e), 600);
        }
    };

    const handleTouchMove = (e: React.TouchEvent) => {
        if (!touchStartRef.current || isDeleted || isSelectionActive) return;
        const touch = e.touches[0];
        const dx = touch.clientX - touchStartRef.current.x;
        const dy = Math.abs(touch.clientY - touchStartRef.current.y);
        
        // Detect SWIPE LEFT (negative dx) for Reply
        if (dx < -10 && dy < 30) {
            if (longPressTimer.current) { clearTimeout(longPressTimer.current); longPressTimer.current = null; }
            setSwipeX(Math.max(dx, -80));
        } else if (Math.abs(dx) > 10 || dy > 10) {
            if (longPressTimer.current) { clearTimeout(longPressTimer.current); longPressTimer.current = null; }
        }
    };

    const handleTouchEnd = () => {
        if (longPressTimer.current) { clearTimeout(longPressTimer.current); longPressTimer.current = null; }
        if (swipeX < -60 && !isDeleted) {
            onReply(getReplyPreview(message, allUsers, e2eeDecryptedByMessageId));
        }
        setSwipeX(0); touchStartRef.current = null;
    };

    const senderName =
      conversation.isGroup && !isCurrentUser
        ? liveGroupSender?.name || conversation.participantInfo[message.senderId]?.name || 'Неизвестный'
        : null;
    const groupSenderAvatar =
      conversation.isGroup && !isCurrentUser
        ? participantListAvatarUrl(
            liveGroupSender,
            conversation.participantInfo[message.senderId],
          )
        : '';
    const groupSenderInitial = (senderName || '?').charAt(0);
    const senderColor = senderName ? getUserColor(message.senderId) : '';

    const showGroupSenderActions =
        conversation.isGroup &&
        !isCurrentUser &&
        !!onMentionProfileOpen &&
        !!onGroupSenderWritePrivate;
    const groupSenderMenuDisabled = isSelectionActive || isDeleted || isMenuOpen;

    const reactionsNode = (
        <MessageReactions 
            reactions={message.reactions || {}} 
            currentUserId={currentUser.id} 
            onReact={(emoji) => onReact(message.id, emoji)} 
            allUsers={allUsers}
        />
    );

    return (
        <div 
            id={`msg-${message.id}`} data-video-focus={isVideoPlaying}
            className={cn(
                'group flex min-h-[32px] w-full touch-pan-y select-none items-start gap-2 px-4 relative',
                !isMenuOpen && 'transition-all duration-500',
                useFullBleedVideoCirclePlaying ? 'justify-center my-10' : (isCurrentUser ? 'justify-end' : 'justify-start'), 
                isSelectionActive && !isDeleted && 'cursor-pointer active:bg-muted/30',
                isVideoPlaying && 'z-[500] relative',
                isMenuOpen && menuPosition && 'z-[40]'
            )} 
            style={{ 
                transform: (isMenuOpen && menuPosition) ? `translateY(${menuPosition.shiftY}px)` : 'none',
                paddingBottom: isMenuOpen ? `${menuPosition?.menuHeight || 320}px` : '0px' 
            }}
            onTouchStart={handleTouchStart}
            onTouchMove={handleTouchMove}
            onTouchEnd={handleTouchEnd}
            onClick={() => isSelectionActive && !isDeleted && onToggleSelection(message.id)}
        >
            {/* Visual indicator for LEFT swipe (reply icon on the right) */}
            {swipeX < -20 && (
                <div className="absolute right-4 top-1/2 -translate-y-1/2 transition-opacity duration-200 pointer-events-none" style={{ opacity: Math.min(Math.abs(swipeX) / 60, 1) }}>
                    <div className={cn("p-2 rounded-full bg-primary/20 text-primary transition-transform duration-200", swipeX < -60 ? "scale-125" : "scale-100")}>
                        <ReplyIcon className="h-4 w-4" />
                    </div>
                </div>
            )}

            {isSelectionActive && !isVideoPlaying && !isDeleted && (
                <div className="mt-2 shrink-0">
                    <Checkbox 
                        checked={isSelected} 
                        onCheckedChange={() => onToggleSelection(message.id)} 
                        className="rounded-full h-5 w-5 border-2" 
                    />
                </div>
            )}

            <div className={cn(
                'flex items-end gap-2',
                !isMenuOpen && 'transition-all duration-500',
                hasGridVisualMedia ? 'min-w-[min(100%,208px)] shrink-0' : 'min-w-0',
                useFullBleedVideoCirclePlaying ? 'max-w-full w-full justify-center flex-row' : (isCurrentUser ? 'flex-row-reverse ml-auto max-w-[90%] md:max-w-[75%]' : 'flex-row max-w-[90%] md:max-w-[75%]'), 
                useFullBleedVideoCirclePlaying && 'z-[510] !max-w-full'
            )} style={{ transform: `translateX(${swipeX}px)` }}>
                {!isCurrentUser && conversation.isGroup && !useFullBleedVideoCirclePlaying && !isMenuOpen && (
                    showGroupSenderActions ? (
                        <GroupMessageSenderMenu
                            senderId={message.senderId}
                            currentUserId={currentUser.id}
                            disabled={groupSenderMenuDisabled}
                            onOpenProfile={onGroupSenderProfileOpen ?? onMentionProfileOpen}
                            onWritePrivate={onGroupSenderWritePrivate}
                        >
                            <button
                                type="button"
                                className="rounded-full shrink-0 mb-1 border-0 bg-transparent p-0 cursor-pointer outline-none focus-visible:ring-2 focus-visible:ring-ring"
                                aria-label={`Действия: ${senderName ?? 'отправитель'}`}
                                onPointerDown={(e) => e.stopPropagation()}
                                onClick={(e) => e.stopPropagation()}
                            >
                                <Avatar className="h-8 w-8 shrink-0 border border-black/5">
                                    <AvatarImage src={groupSenderAvatar} />
                                    <AvatarFallback>{groupSenderInitial}</AvatarFallback>
                                </Avatar>
                            </button>
                        </GroupMessageSenderMenu>
                    ) : (
                    <Avatar className="h-8 w-8 shrink-0 mb-1 border border-black/5">
                            <AvatarImage src={groupSenderAvatar} />
                            <AvatarFallback>{groupSenderInitial}</AvatarFallback>
                    </Avatar>
                    )
                )}
                
                <div
                    className={cn(
                        'flex flex-col gap-1 relative',
                        hasGridVisualMedia
                            ? 'w-full max-w-[min(100%,208px)] min-w-[min(100%,169px)] shrink-0'
                            : useFullBleedVideoCirclePlaying
                              ? 'min-w-0 w-full max-w-full items-center'
                              : 'min-w-0 w-fit',
                        !useFullBleedVideoCirclePlaying &&
                            (isCurrentUser ? 'items-end' : 'items-start')
                    )}
                >
                    <div
                        ref={bubbleRef}
                        onContextMenu={handleOpenMenu}
                        className={cn(
                            'relative flex flex-col gap-1 cursor-pointer select-none active:scale-[0.99] group/bubble',
                            !isMenuOpen && 'transition-all duration-500',
                            showShareableLocation && !showInnerColoredBubble && !hasGridVisualMedia
                                ? 'w-fit shrink-0'
                                : hasGridVisualMedia && showInnerColoredBubble
                                  ? 'w-full min-w-[min(100%,208px)] shrink-0'
                                  : showInnerColoredBubble
                                    ? 'min-w-0 w-fit'
                                    : 'min-w-0 w-fit',
                            (isPureEmoji || isStickerLike || isDeleted) && 'border-none bg-transparent shadow-none',
                            isMenuOpen &&
                                !circularStickerMenuHole &&
                                'ring-2 ring-white/50 ring-offset-0',
                            isMenuOpen && hasGridVisualMedia && showInnerColoredBubble
                                ? 'overflow-hidden'
                                : 'overflow-visible',
                        )}
                    >
                        {isDeleted ? (
                            <div
                                className={cn(
                                    'flex items-center gap-1.5 text-sm italic text-muted-foreground/80 py-2 px-0 font-medium select-none min-h-[32px]',
                                    isCurrentUser ? 'self-end' : 'self-start',
                                )}
                            >
                                <Trash2 className="h-3.5 w-3.5" />
                                Сообщение удалено
                            </div>
                        ) : (
                            <div className={cn('flex flex-col select-none gap-1', hasGridVisualMedia ? 'min-w-full w-full' : 'min-w-0')}>
                                {senderName && !isPureEmoji && !isStickerLike && !useFullBleedVideoCirclePlaying && !isMenuOpen && !isMediaOnly && (
                                    showGroupSenderActions ? (
                                        <GroupMessageSenderMenu
                                            senderId={message.senderId}
                                            currentUserId={currentUser.id}
                                            disabled={groupSenderMenuDisabled}
                                            onOpenProfile={onGroupSenderProfileOpen ?? onMentionProfileOpen}
                                            onWritePrivate={onGroupSenderWritePrivate}
                                        >
                                            <button
                                                type="button"
                                                className={cn(
                                                    'text-[11px] font-bold px-3 pt-2 uppercase tracking-wider w-full text-left rounded-md border-0 bg-transparent cursor-pointer outline-none focus-visible:ring-2 focus-visible:ring-ring',
                                                    senderColor
                                                )}
                                                onPointerDown={(e) => e.stopPropagation()}
                                                onClick={(e) => e.stopPropagation()}
                                            >
                                                {senderName}
                                            </button>
                                        </GroupMessageSenderMenu>
                                    ) : (
                                        <div className={cn('text-[11px] font-bold px-3 pt-2 uppercase tracking-wider', senderColor)}>{senderName}</div>
                                    )
                                )}
                                {message.replyTo && !isPureEmoji && !isStickerLike && !useFullBleedVideoCirclePlaying && (
                                    <MessageReply
                                        replyTo={message.replyTo}
                                        isCurrentUser={isCurrentUser}
                                        onClick={() => onNavigateToMessage(message.replyTo!.messageId)}
                                    />
                                )}
                                {showShareableLocation && (
                                    <MessageLocationCard
                                        share={message.locationShare!}
                                        isCurrentUser={isCurrentUser}
                                        createdAt={message.createdAt}
                                        senderLiveShare={senderLiveShareForLocation}
                                        senderProfileResolved={senderProfileResolvedForLocation}
                                        deliveryStatus={message.deliveryStatus}
                                        readAt={message.readAt}
                                        showTimestamps={showTimestamps}
                                    />
                                )}
                                {showInnerColoredBubble && (
                                    <div
                                        className={cn(
                                            'relative flex flex-col',
                                            hasGridVisualMedia
                                                ? 'min-w-full w-full max-w-[min(100%,208px)] min-w-[min(100%,169px)]'
                                                : 'min-w-0 w-fit',
                                            isVideoCircle &&
                                                !isDeleted &&
                                                (isVideoPlaying
                                                    ? hasGridVisualMedia
                                                        ? 'min-w-0 w-full overflow-visible rounded-full border-none bg-transparent p-0 shadow-none'
                                                        : 'min-h-0 min-w-0 w-full max-w-full overflow-visible rounded-full border-none bg-transparent p-0 shadow-none flex justify-center'
                                                    : 'min-h-[192px] min-w-[192px] overflow-visible rounded-full border-none bg-transparent p-0 shadow-none'),
                                            !(isPureEmoji || isDeleted || isVideoCircle || isStickerLike) &&
                                                cn(
                                                    radiusClass,
                                                    'border-none shadow-sm',
                                                    isPollMessage && !isDeleted && !isMenuOpen && 'rounded-none shadow-none',
                                                    isMenuOpen && hasGridVisualMedia ? 'overflow-hidden' : 'overflow-visible',
                                                ),
                                            !(isPureEmoji || isVideoCircle || isStickerLike || isDeleted || isPollMessage) &&
                                                (isCurrentUser
                                                    ? cn(
                                                          hasCustomOutgoing ? 'text-white' : 'bg-primary text-white',
                                                          showBubbleTailClip && 'rounded-tr-none',
                                                      )
                                                    : cn(
                                                          hasCustomIncoming ? 'text-white' : 'bg-muted dark:bg-muted/50',
                                                          showBubbleTailClip && 'rounded-tl-none',
                                                      )),
                                            isPollMessage && !isDeleted && 'bg-transparent',
                                            isMediaOnly && !isStickerLike && !isDeleted && 'border-none bg-transparent shadow-none',
                                        )}
                                        style={bubbleInlineStyle}
                                    >
                                        <div className={cn('flex flex-col select-none', hasGridVisualMedia ? 'min-w-full w-full' : 'min-w-0')}>
                                            <div
                                                className={cn(
                                                    'flex flex-col select-none',
                                                    hasGridVisualMedia ? 'min-w-full w-full' : 'min-w-0',
                                                    isVideoPlaying && 'overflow-visible',
                                                )}
                                            >
                                                {message.chatPollId && !isStickerLike && !isVideoPlaying && (
                                                    <div className={cn('w-full min-w-0', hasGridVisualMedia ? 'px-0' : 'px-2 pt-1')}>
                                                        <MessagePollInline
                                                            conversationId={conversation.id}
                                                            pollId={message.chatPollId}
                                                            currentUser={currentUser}
                                                            conversation={conversation}
                                                            allUsers={allUsers}
                                                            isCurrentUser={isCurrentUser}
                                                        />
                                                        {showTimestamps && (
                                                            <div
                                                                className={cn(
                                                                    'mt-1 flex flex-wrap items-center gap-x-2 gap-y-0.5',
                                                                    isCurrentUser ? 'justify-end pr-0.5' : 'justify-start pl-0.5',
                                                                )}
                                                            >
                                                                <MessageStatus
                                                                    timestamp={message.createdAt}
                                                                    isCurrentUser={isCurrentUser}
                                                                    deliveryStatus={message.deliveryStatus}
                                                                    readAt={message.readAt}
                                                                    bare
                                                                />
                                                                {showDisappearingEta ? (
                                                                    <MessageDisappearingEta
                                                                        expireAt={message.expireAt}
                                                                        variant="bare"
                                                                    />
                                                                ) : null}
                                                            </div>
                                                        )}
                                                    </div>
                                                )}
                                                <div
                                                    className={cn(
                                                        'flex flex-col',
                                                        hasGridVisualMedia ? 'min-w-full w-full' : 'min-w-0',
                                                        (isVideoCircle || isVideoPlaying) ? 'overflow-visible' : 'overflow-visible',
                                                    )}
                                                >
                                                    {hasGridVisualMedia && (
                                                        <div className="relative w-full min-w-[min(100%,169px)] shrink-0">
                                                            <MessageMedia
                                                                attachments={message.attachments || []}
                                                                isCurrentUser={isCurrentUser}
                                                                onImageClick={(att) =>
                                                                    isGridGalleryVideo(att) ? onOpenVideoViewer(att) : onOpenImageViewer(att)
                                                                }
                                                            />
                                                            {isMediaOnly && showTimestamps && !isVideoCircle && !isStickerLike && (
                                                                <>
                                                                    <MessageStatus
                                                                        timestamp={message.createdAt}
                                                                        isCurrentUser={isCurrentUser}
                                                                        deliveryStatus={message.deliveryStatus}
                                                                        readAt={message.readAt}
                                                                        overlay
                                                                        isColoredBubble={isColoredBubble}
                                                                    />
                                                                    {showDisappearingEta ? (
                                                                        <div className="pointer-events-none absolute bottom-11 left-2 z-20 max-w-[min(100%,12rem)]">
                                                                            <MessageDisappearingEta
                                                                                expireAt={message.expireAt}
                                                                                variant="muted"
                                                                            />
                                                                        </div>
                                                                    ) : null}
                                                                </>
                                                            )}
                                                        </div>
                                                    )}
                                        {message.attachments?.map((att, idx) => {
                                                        if (att.name.startsWith('video-circle_'))
                                                            return (
                                                                <div
                                                                    key={idx}
                                                                    className={cn(
                                                                        hasGridVisualMedia &&
                                                                            isVideoPlaying &&
                                                                            'flex w-full shrink-0 justify-center',
                                                                    )}
                                                                >
                                                                    <VideoCirclePlayer
                                                                        attachment={att}
                                                                        isCurrentUser={isCurrentUser}
                                                                        createdAt={message.createdAt}
                                                                        deliveryStatus={message.deliveryStatus}
                                                                        readAt={message.readAt}
                                                                        onPlaybackStateChange={setIsVideoPlaying}
                                                                        isLastInChat={isLastInChat}
                                                                    />
                                                                </div>
                                                            );
                                                        if (isAttachmentLikelyIosStickerCutout(att))
                                                            return (
                                                                <div
                                                                    key={idx}
                                                                    ref={stickerMenuHoleRef}
                                                                    className="relative mx-auto w-[min(150px,40vw)] shrink-0 aspect-square flex items-center justify-center p-0.5"
                                                                >
                                                                    <HeicAwareChatImage
                                                                        attachment={att}
                                                                        alt=""
                                                                        width={150}
                                                                        height={150}
                                                                        className="max-h-full max-w-full object-contain"
                                                                        draggable={false}
                                                                    />
                                                                </div>
                                                            );
                                                        if (att.name.startsWith('gif_'))
                                                            return (
                                                                <div key={idx} className="relative max-w-[min(100%,280px)] w-48 sm:w-64 p-2 shrink-0">
                                                                    <GifAttachmentImage att={att} />
                                                                </div>
                                                            );
                                                        if (att.type.startsWith('audio/'))
                                                            return (
                                                                <div key={idx} className="p-2 relative shrink-0">
                                                                    <AudioMessagePlayer attachment={att} isCurrentUser={isCurrentUser} />
                                                                </div>
                                                            );
                                            return null;
                                        })}
                                                    {hasNeedsMediaNorm && (mediaNormPending || mediaNormFailed) && (
                                                        <div className="mx-2 my-1 rounded-xl border border-white/15 bg-black/25 px-3 py-2 text-xs">
                                                            <div className="font-semibold text-white/90">
                                                                {mediaNormPending ? 'Медиа обрабатывается…' : 'Не удалось обработать медиа'}
                                                            </div>
                                                            <div className="mt-0.5 text-white/65">
                                                                {mediaNormPending
                                                                    ? 'Файл станет доступен после серверной нормализации.'
                                                                    : 'Нажмите, чтобы запустить обработку повторно.'}
                                                            </div>
                                                            {mediaNormFailed && onRetryMediaNorm && (
                                                                <button
                                                                    type="button"
                                                                    onClick={(e) => {
                                                                        e.stopPropagation();
                                                                        void onRetryMediaNorm(message);
                                                                    }}
                                                                    className="mt-2 rounded-md border border-white/20 px-2 py-1 text-[11px] font-semibold text-cyan-300 hover:bg-white/10"
                                                                >
                                                                    Повторить
                                                                </button>
                                                            )}
                                                        </div>
                                                    )}
                                                    {(!isVideoCircle && !message.chatPollId) && (!isStickerLike || hasStickerCaption) && (
                                            <div className="relative group/text">
                                                            <MessageText
                                                                text={
                                                                    isE2eePending
                                                                        ? '<p class="text-muted-foreground italic">Расшифровка…</p>'
                                                                        : displayTextHtml
                                                                }
                                                                isCurrentUser={isCurrentUser}
                                                                isPureEmoji={!!isPureEmoji}
                                                                fontSizeClass={fontSizeClass}
                                                                isColoredBubble={isColoredBubble}
                                                                conversation={conversation}
                                                                allUsers={allUsers}
                                                                contactProfiles={contactProfiles}
                                                                onMentionProfileOpen={onMentionProfileOpen}
                                                            >
                                                                {!isStickerLike &&
                                                                    !isPureEmoji &&
                                                                    showTimestamps &&
                                                                    (!isMediaOnly || !hasGridVisualMedia) && (
                                                                        <span className="inline-flex flex-wrap items-center gap-x-1.5 align-baseline">
                                                                            <MessageStatus
                                                                                timestamp={message.createdAt}
                                                                                isCurrentUser={isCurrentUser}
                                                                                deliveryStatus={message.deliveryStatus}
                                                                                readAt={message.readAt}
                                                                                isColoredBubble={isColoredBubble}
                                                                            />
                                                                            {showDisappearingEta ? (
                                                                                <MessageDisappearingEta
                                                                                    expireAt={message.expireAt}
                                                                                    variant="inline"
                                                                                    className={
                                                                                        isColoredBubble
                                                                                            ? 'text-white/55'
                                                                                            : undefined
                                                                                    }
                                                                                />
                                                                            ) : null}
                                                                        </span>
                                                                    )}
                                                </MessageText>
                                            </div>
                                        )}
                                    </div>
                                </div>
                                        </div>
                                    </div>
                                )}
                            </div>
                        )}
                    </div>
                    {!isDeleted && reactionsNode}
                    {!isDeleted && (message.threadCount ?? 0) > 0 && !isThreadMessage && (
                        <button
                            onClick={(e) => { e.stopPropagation(); onOpenThread?.(message); }}
                            className={cn(
                                "flex items-center gap-2 mt-1 px-3 py-1.5 rounded-full border text-[10px] font-bold uppercase tracking-wider transition-all hover:scale-105 active:scale-95 shadow-sm",
                                isCurrentUser
                                    ? "bg-white/10 border-white/40 text-white self-end"
                                    : "bg-primary/5 border-primary/10 text-primary self-start"
                            )}
                        >
                            <MessageSquare className="h-3 w-3" />
                            {threadReplyUsers.length > 0 && (
                                <span className="flex -space-x-1">
                                    {threadReplyUsers.slice(0, 3).map((u) => (
                                        <Avatar key={u.id} className="h-4 w-4 border border-white/50">
                                            <AvatarImage src={u.avatarUrl || undefined} alt={u.name} className="object-cover" />
                                            <AvatarFallback className="text-[8px] font-semibold">
                                                {u.name.charAt(0).toUpperCase()}
                                            </AvatarFallback>
                                        </Avatar>
                                    ))}
                                </span>
                            )}
                            <span>{(message.threadCount ?? 0)}</span>
                        </button>
                    )}
                </div>
            </div>
            <MessageContextMenu
                isOpen={isMenuOpen}
                onClose={closeContextMenu}
                position={menuPosition}
                message={message}
                isCurrentUser={isCurrentUser}
                hasText={!!displayTextHtml}
                canEdit={isCurrentUser && !!displayTextHtml && !isOnlyEmojis(displayTextHtml)}
                canSaveSticker={!!onSaveStickerGif && !!stickerGifForSave}
                canCreateSticker={!!onSaveStickerGif && !!gridImageForStickerCreate}
                showStarAction={!isDeleted && !!onToggleStar && !isThreadMessage}
                isStarred={isStarred}
                showThreadAction={!isDeleted && !isThreadMessage && !!onOpenThread}
                onAction={onMenuAction}
            />
        </div>
    );
};

export const ChatMessageItem = React.memo(ChatMessageItemComponent);
ChatMessageItem.displayName = 'ChatMessageItem';
