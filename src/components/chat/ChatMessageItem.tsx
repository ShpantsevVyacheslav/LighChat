'use client';

import React, { useState, useMemo, useRef, useLayoutEffect } from 'react';
import { parseISO } from 'date-fns';

import type { User, Conversation, ChatMessage, ChatAttachment, ReplyContext, ChatSettings } from '@/lib/types';
import { cn } from '@/lib/utils';
import { isOnlyEmojis, getReplyPreview, getFirstStickerOrGifAttachment } from '@/lib/chat-utils';
import { bubbleRadiusToClass } from '@/lib/chat-bubble-radius';

import { Checkbox } from '@/components/ui/checkbox';
import { Trash2, Reply as ReplyIcon, MessageSquare } from 'lucide-react';
import { Avatar, AvatarFallback, AvatarImage } from '../ui/avatar';

import { MessageText } from './parts/MessageText';
import { MessageLocationCard } from './parts/MessageLocationCard';
import { MessagePollInline } from './parts/MessagePollInline';
import { MessageMedia } from './parts/MessageMedia';
import { MessageStatus } from './parts/MessageStatus';
import { MessageReply } from './parts/MessageReply';
import { MessageReactions } from './parts/MessageReactions';
import { AudioMessagePlayer } from './AudioMessagePlayer';
import { VideoCirclePlayer } from './VideoCirclePlayer';
import { MessageContextMenu, type MessageContextMenuPosition } from './context-menu/MessageContextMenu';
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
    /** Группа: из меню отправителя — открыть или создать личный чат с автором сообщения */
    onGroupSenderWritePrivate?: (userId: string) => void | Promise<void>;
    /** Сохранить стикер/GIF из сообщения в пак текущего пользователя (контекстное меню). */
    onSaveStickerGif?: (attachment: ChatAttachment) => void;
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
    onGroupSenderWritePrivate,
    onSaveStickerGif,
}: ChatMessageItemProps) => {
    const isCurrentUser = message.senderId === currentUser.id;
    const isDeleted = !!message.isDeleted;

    const stickerGifForSave = useMemo(
        () => (!isDeleted ? getFirstStickerOrGifAttachment(message) : null),
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
    const longPressTimer = useRef<NodeJS.Timeout | null>(null);
    const touchStartRef = useRef<{ x: number, y: number } | null>(null);

    const liveGroupSender = useMemo(
      () => (conversation.isGroup ? allUsers.find((u) => u.id === message.senderId) : undefined),
      [conversation.isGroup, allUsers, message.senderId],
    );

    const isSticker = useMemo(() => message.attachments?.some(att => att.name.startsWith('sticker_')), [message.attachments]);
    const isGifAttachment = useMemo(() => message.attachments?.some(att => att.name.startsWith('gif_')), [message.attachments]);
    const isStickerLike = isSticker || isGifAttachment;
    const isPureEmoji = useMemo(
        () =>
            message.text &&
            isOnlyEmojis(message.text) &&
            !message.attachments?.length &&
            !message.replyTo &&
            !message.locationShare &&
            !message.chatPollId,
        [message.text, message.attachments, message.replyTo, message.locationShare, message.chatPollId]
    );
    const isVideoCircle = useMemo(() => message.attachments?.some(att => att.name.startsWith('video-circle_')), [message.attachments]);
    const isPollMessage = !!message.chatPollId;
    const stickerCaptionPlain = useMemo(() => {
        if (!message.text) return '';
        return message.text.replace(/<[^>]*>/g, '').replace(/&nbsp;/g, ' ').trim();
    }, [message.text]);
    const hasStickerCaption = isStickerLike && stickerCaptionPlain.length > 0;
    const isMediaOnly = useMemo(
        () =>
            !message.text &&
            !!message.attachments?.length &&
            !message.replyTo &&
            !message.locationShare &&
            !message.chatPollId,
        [message.text, message.attachments, message.replyTo, message.locationShare, message.chatPollId]
    );

    /** Сетка MessageMedia (фото/видео не стикер/кружок) — нужна явная ширина, иначе w-fit + w-full схлопывают превью. */
    const hasGridVisualMedia = useMemo(() => {
        const list = message.attachments;
        if (!list?.length) return false;
        return list.some(isGridGalleryAttachment);
    }, [message.attachments]);

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
        const bubbleRectEl = bubbleEl.getBoundingClientRect();
        const viewportWidth = window.innerWidth;
        const menuHeight = 360; const menuWidth = 240;
        let top = bubbleRectEl.bottom + 4;
        let left = isCurrentUser ? bubbleRectEl.right - menuWidth : bubbleRectEl.left;
        let shiftY = 0;
        if (top + menuHeight > window.innerHeight - 90) shiftY = (window.innerHeight - 90) - (top + menuHeight);
        left = Math.max(16, Math.min(left, viewportWidth - menuWidth - 16));
        const { bubbleRect, bubbleCornerRadiusPx } = readBubbleHoleGeometry(bubbleEl, MENU_FOCUS_HOLE_PAD_PX);
        setMenuPosition({
            top: top + shiftY,
            left,
            shiftY,
            menuHeight,
            bubbleRect,
            bubbleCornerRadiusPx,
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
            const el = bubbleRef.current;
            if (!el) return;
            const { bubbleRect: nextRect, bubbleCornerRadiusPx: nextR } = readBubbleHoleGeometry(
                el,
                MENU_FOCUS_HOLE_PAD_PX
            );
            setMenuPosition((prev) => {
                if (!prev) return prev;
                const { bubbleRect: a, bubbleCornerRadiusPx: ar = 14 } = prev;
                const same =
                    a.top === nextRect.top &&
                    a.left === nextRect.left &&
                    a.width === nextRect.width &&
                    a.height === nextRect.height &&
                    ar === nextR;
                if (same) return prev;
                return { ...prev, bubbleRect: nextRect, bubbleCornerRadiusPx: nextR };
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
    }, [isMenuOpen]);

    const onMenuAction = (action: string, payload?: string) => {
        switch(action) {
            case 'reply': onReply(getReplyPreview(message, allUsers)); break;
            case 'copy': onCopy(message.text || ''); break;
            case 'edit': onEdit({ id: message.id, text: message.text || '', attachments: message.attachments }); break;
            case 'pin': onPin(message); break;
            case 'forward': onForward(message); break;
            case 'delete': onDelete(message.id); break;
            case 'react': if (payload) onReact(message.id, payload); break;
            case 'select': onToggleSelection(message.id); break;
            case 'thread': onOpenThread?.(message); break;
            case 'save_sticker': {
                const a = getFirstStickerOrGifAttachment(message);
                if (a && onSaveStickerGif) onSaveStickerGif(a);
                break;
            }
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
            onReply(getReplyPreview(message, allUsers));
        }
        setSwipeX(0); touchStartRef.current = null;
    };

    const senderName =
      conversation.isGroup && !isCurrentUser
        ? liveGroupSender?.name || conversation.participantInfo[message.senderId]?.name || 'Неизвестный'
        : null;
    const groupSenderAvatar =
      conversation.isGroup && !isCurrentUser
        ? liveGroupSender?.avatar || conversation.participantInfo[message.senderId]?.avatar || ''
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
                (isVideoCircle && isVideoPlaying) ? 'justify-center my-10' : (isCurrentUser ? 'justify-end' : 'justify-start'), 
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
                hasGridVisualMedia ? 'min-w-[min(100%,320px)] shrink-0' : 'min-w-0',
                (isVideoCircle && isVideoPlaying) ? 'max-w-full w-full justify-center flex-row' : (isCurrentUser ? 'flex-row-reverse ml-auto max-w-[90%] md:max-w-[75%]' : 'flex-row max-w-[90%] md:max-w-[75%]'), 
                isVideoPlaying && 'z-[510] !max-w-full'
            )} style={{ transform: `translateX(${swipeX}px)` }}>
                {!isCurrentUser && conversation.isGroup && !(isVideoCircle && isVideoPlaying) && !isMenuOpen && (
                    showGroupSenderActions ? (
                        <GroupMessageSenderMenu
                            senderId={message.senderId}
                            currentUserId={currentUser.id}
                            disabled={groupSenderMenuDisabled}
                            onOpenProfile={onMentionProfileOpen}
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
                            ? 'w-full max-w-[min(100%,320px)] min-w-[min(100%,260px)] shrink-0'
                            : isVideoCircle && isVideoPlaying
                              ? 'min-w-0 w-full max-w-full items-center'
                              : 'min-w-0 w-fit',
                        !(isVideoCircle && isVideoPlaying) &&
                            (isCurrentUser ? 'items-end' : 'items-start')
                    )}
                >
                    <div 
                        ref={bubbleRef} onContextMenu={handleOpenMenu}
                        className={cn(
                            'relative flex flex-col cursor-pointer select-none active:scale-[0.99] group/bubble',
                            !isMenuOpen && 'transition-all duration-500',
                            hasGridVisualMedia ? 'w-full' : 'w-fit',
                            (isPureEmoji || isStickerLike || isDeleted) && 'border-none bg-transparent shadow-none',
                            isVideoCircle &&
                                !isDeleted &&
                                (isVideoPlaying
                                    ? 'min-h-0 min-w-0 w-full max-w-full overflow-visible rounded-full border-none bg-transparent p-0 shadow-none flex justify-center'
                                    : 'min-h-[192px] min-w-[192px] overflow-visible rounded-full border-none bg-transparent p-0 shadow-none'),
                            isVideoCircle && !isDeleted && isMenuOpen && 'ring-2 ring-white/50',
                            !(isPureEmoji || isDeleted || isVideoCircle || isStickerLike) &&
                                cn(
                                    radiusClass,
                                    'border-none shadow-sm',
                                    isPollMessage && !isDeleted && !isMenuOpen && 'rounded-none shadow-none',
                                    isMenuOpen && hasGridVisualMedia ? 'overflow-hidden' : 'overflow-visible',
                                    isMenuOpen && 'ring-2 ring-white/50 ring-offset-0'
                                ),
                            !(isPureEmoji || isVideoCircle || isStickerLike || isDeleted || isPollMessage) &&
                                (isCurrentUser
                                    ? cn(
                                          hasCustomOutgoing ? 'text-white' : 'bg-primary text-white',
                                          showBubbleTailClip && 'rounded-tr-none'
                                      )
                                    : cn(
                                          hasCustomIncoming ? 'text-white' : 'bg-muted dark:bg-muted/50',
                                          showBubbleTailClip && 'rounded-tl-none'
                                      )),
                            isPollMessage && !isDeleted && 'bg-transparent',
                            isMediaOnly && !isStickerLike && !isDeleted && 'border-none bg-transparent shadow-none',
                        )}
                        style={bubbleInlineStyle}
                    >
                        {isDeleted ? (
                            <div className="flex items-center gap-1.5 text-sm italic text-muted-foreground/80 py-2 px-0 font-medium select-none min-h-[32px]"><Trash2 className="h-3.5 w-3.5" />Сообщение удалено</div>
                        ) : (
                            <div className={cn('flex flex-col select-none', hasGridVisualMedia ? 'min-w-full w-full' : 'min-w-0')}>
                                {senderName && !isPureEmoji && !isStickerLike && !isVideoPlaying && !isMenuOpen && !isMediaOnly && (
                                    showGroupSenderActions ? (
                                        <GroupMessageSenderMenu
                                            senderId={message.senderId}
                                            currentUserId={currentUser.id}
                                            disabled={groupSenderMenuDisabled}
                                            onOpenProfile={onMentionProfileOpen}
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
                                        <div className={cn("text-[11px] font-bold px-3 pt-2 uppercase tracking-wider", senderColor)}>{senderName}</div>
                                    )
                                )}
                                <div className={cn('flex flex-col select-none', hasGridVisualMedia ? 'min-w-full w-full' : 'min-w-0', isVideoPlaying && 'overflow-visible')}>
                                    {message.replyTo && !isPureEmoji && !isStickerLike && !isVideoPlaying && (
                                        <MessageReply replyTo={message.replyTo} isCurrentUser={isCurrentUser} onClick={() => onNavigateToMessage(message.replyTo!.messageId)} />
                                    )}
                                    {message.locationShare && !isStickerLike && !isVideoPlaying && (
                                        <div className={cn('w-full min-w-0', hasGridVisualMedia ? 'px-0' : 'px-2 pt-1')}>
                                            <MessageLocationCard share={message.locationShare} isCurrentUser={isCurrentUser} />
                                        </div>
                                    )}
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
                                                <div className={cn('mt-1 flex', isCurrentUser ? 'justify-end pr-0.5' : 'justify-start pl-0.5')}>
                                                    <MessageStatus
                                                        timestamp={message.createdAt}
                                                        isCurrentUser={isCurrentUser}
                                                        deliveryStatus={message.deliveryStatus}
                                                        readAt={message.readAt}
                                                        bare
                                                    />
                                                </div>
                                            )}
                                        </div>
                                    )}
                                    <div className={cn('flex flex-col', hasGridVisualMedia ? 'min-w-full w-full' : 'min-w-0', (isVideoCircle || isVideoPlaying) ? 'overflow-visible' : 'overflow-visible')}>
                                        {hasGridVisualMedia && (
                                            <div className="relative w-full min-w-[min(100%,260px)] shrink-0">
                                                <MessageMedia attachments={message.attachments || []} isCurrentUser={isCurrentUser} onImageClick={(att) => (isGridGalleryVideo(att) ? onOpenVideoViewer(att) : onOpenImageViewer(att))} />
                                                {isMediaOnly && showTimestamps && !isVideoCircle && !isStickerLike && (
                                                    <MessageStatus timestamp={message.createdAt} isCurrentUser={isCurrentUser} deliveryStatus={message.deliveryStatus} readAt={message.readAt} overlay isColoredBubble={isColoredBubble} />
                                                )}
                                            </div>
                                        )}
                                        {message.attachments?.map((att, idx) => {
                                            if (att.name.startsWith('video-circle_')) return <VideoCirclePlayer key={idx} attachment={att} isCurrentUser={isCurrentUser} createdAt={message.createdAt} deliveryStatus={message.deliveryStatus} readAt={message.readAt} onPlaybackStateChange={setIsVideoPlaying} isLastInChat={isLastInChat} />;
                                            if (att.name.startsWith('sticker_')) return (
                                                <div
                                                    key={idx}
                                                    className="relative mx-auto w-[min(150px,40vw)] shrink-0 aspect-square flex items-center justify-center p-0.5"
                                                >
                                                    <img
                                                        src={att.url}
                                                        alt=""
                                                        width={150}
                                                        height={150}
                                                        className="max-h-full max-w-full object-contain"
                                                        draggable={false}
                                                    />
                                                </div>
                                            );
                                            if (att.name.startsWith('gif_')) return <div key={idx} className="relative max-w-[min(100%,280px)] w-48 sm:w-64 p-2 shrink-0"><img src={att.url} alt="" className="h-auto w-full max-h-64 object-contain" /></div>;
                                            if (att.type.startsWith('audio/')) return <div key={idx} className="p-2 relative shrink-0"><AudioMessagePlayer attachment={att} isCurrentUser={isCurrentUser} /></div>;
                                            return null;
                                        })}
                                        {(!isVideoCircle && !message.chatPollId) && (!isStickerLike || hasStickerCaption) && (
                                            <div className="relative group/text">
                                                <MessageText
                                                    text={message.text}
                                                    isCurrentUser={isCurrentUser}
                                                    isPureEmoji={!!isPureEmoji}
                                                    fontSizeClass={fontSizeClass}
                                                    isColoredBubble={isColoredBubble}
                                                    conversation={conversation}
                                                    allUsers={allUsers}
                                                    onMentionProfileOpen={onMentionProfileOpen}
                                                >
                                                    {!isStickerLike && !isPureEmoji && showTimestamps && (!isMediaOnly || !hasGridVisualMedia) && (
                                                        <MessageStatus timestamp={message.createdAt} isCurrentUser={isCurrentUser} deliveryStatus={message.deliveryStatus} readAt={message.readAt} isColoredBubble={isColoredBubble} />
                                                    )}
                                                </MessageText>
                                            </div>
                                        )}
                                    </div>
                                </div>
                            </div>
                        )}
                    </div>
                    {!isDeleted && reactionsNode}
                    {!isDeleted && (message.threadCount ?? 0) > 0 && !isThreadMessage && (
                        <button onClick={(e) => { e.stopPropagation(); onOpenThread?.(message); }} className={cn("flex items-center gap-1.5 mt-1 px-3 py-1.5 rounded-full border text-[10px] font-bold uppercase tracking-wider transition-all hover:scale-105 active:scale-95 shadow-sm", isCurrentUser ? "bg-white/10 border-white/40 text-white self-end" : "bg-primary/5 border-primary/10 text-primary self-start")}><MessageSquare className="h-3 w-3" /><span>{(message.threadCount ?? 0)}</span></button>
                    )}
                </div>
            </div>
            <MessageContextMenu isOpen={isMenuOpen} onClose={closeContextMenu} position={menuPosition} message={message} isCurrentUser={isCurrentUser} hasText={!!message.text} canEdit={isCurrentUser && !!message.text && !isOnlyEmojis(message.text)} canSaveSticker={!!onSaveStickerGif && !!stickerGifForSave} onAction={onMenuAction} />
        </div>
    );
};

export const ChatMessageItem = React.memo(ChatMessageItemComponent);
ChatMessageItem.displayName = 'ChatMessageItem';
