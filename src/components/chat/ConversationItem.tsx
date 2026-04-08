'use client';

import React, { useState, useRef, useMemo } from 'react';
import { useRouter } from 'next/navigation';
import { format, isToday, isYesterday } from 'date-fns';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Badge } from '@/components/ui/badge';
import { Trash2, Eraser, FolderEdit, Pin, MessageSquare, AtSign } from 'lucide-react';
import { cn } from '@/lib/utils';
import type { User, Conversation } from '@/lib/types';
import { participantListAvatarUrl } from '@/lib/user-avatar-display';
import { useFirestore } from '@/firebase';
import { useConversationTypingOthers } from '@/hooks/use-conversation-typing-others';
import { useElementInViewport } from '@/hooks/use-element-in-viewport';
import { usePageVisibility } from '@/hooks/use-page-visibility';

interface ConversationItemProps {
    conv: Conversation;
    isSelected: boolean;
    isMobile: boolean;
    isListCollapsed: boolean;
    currentUser: User;
    allUsers: User[];
    onSelect: (id: string) => void;
    onContextMenu: (e: React.MouseEvent, conv: Conversation) => void;
    onManageFolders?: (conv: Conversation) => void;
    isPinnedInFolder?: boolean;
    isSavedMessages?: boolean;
}

export function ConversationItem({ 
    conv, isSelected, isMobile, isListCollapsed, 
    currentUser, allUsers, onSelect, onContextMenu,
    onManageFolders,
    isPinnedInFolder = false,
    isSavedMessages = false,
}: ConversationItemProps) {
    const firestore = useFirestore();
    const itemRef = useRef<HTMLDivElement | null>(null);
    const isInViewport = useElementInViewport(itemRef);
    const isPageVisible = usePageVisibility();
    const typingEnabled = isSelected || (isInViewport && isPageVisible);
    const othersTypingFromSubcollection = useConversationTypingOthers(
        firestore,
        conv.id,
        currentUser.id,
        typingEnabled
    );
    const [swipeX, setSwipeX] = useState(0);
    const [isSwiping, setIsSwiping] = useState(false);
    const touchStart = useRef<number | null>(null);
    const touchStartY = useRef<number | null>(null);
    const longPressTimer = useRef<NodeJS.Timeout | null>(null);
    const router = useRouter();

    const otherId = isSavedMessages
        ? currentUser.id
        : conv.participantIds.find(id => id !== currentUser.id)!;
    const liveOtherUser = allUsers.find(u => u.id === otherId);
    
    const isPartnerDeleted = !conv.isGroup && !isSavedMessages && liveOtherUser?.deletedAt;
    const displayName = conv.isGroup
        ? (conv.name || 'Группа')
        : isSavedMessages
            ? (conv.name || 'Избранное')
            : (liveOtherUser?.name || conv.participantInfo[otherId]?.name || 'Чат');
    const avatar = conv.isGroup
        ? conv.photoUrl
        : isSavedMessages
            ? participantListAvatarUrl(currentUser, conv.participantInfo[currentUser.id])
            : participantListAvatarUrl(liveOtherUser, conv.participantInfo[otherId]);
    
    /** Подколлекция typing (новая схема); fallback на поле conv.typing для старых данных. */
    const isSomeoneTyping = useMemo(() => {
        if (othersTypingFromSubcollection) return true;
        if (!conv.typing) return false;
        return Object.entries(conv.typing).some(([uid, isTyping]) => isTyping && uid !== currentUser.id);
    }, [othersTypingFromSubcollection, conv.typing, currentUser.id]);

    const lastTimestamp = Math.max(
        conv.lastMessageTimestamp ? new Date(conv.lastMessageTimestamp).getTime() : 0,
        conv.lastReactionTimestamp ? new Date(conv.lastReactionTimestamp).getTime() : 0
    );
    const lastEventDate = lastTimestamp > 0 ? new Date(lastTimestamp) : null;
    let dateDisplay = '';
    if(lastEventDate) {
        if (isToday(lastEventDate)) dateDisplay = format(lastEventDate, 'HH:mm');
        else if (isYesterday(lastEventDate)) dateDisplay = 'Вчера';
        else dateDisplay = format(lastEventDate, 'dd.MM.yy');
    }
    
    const mainUnreads = conv.unreadCounts?.[currentUser.id] || 0;
    const threadUnreads = conv.unreadThreadCounts?.[currentUser.id] || 0;
    const totalUnread = mainUnreads + threadUnreads;
    const hasPendingGroupMention =
        conv.isGroup && (conv.usersWithPendingGroupMention?.includes(currentUser.id) ?? false);
    
    const isReactionNewer = conv.lastReactionTimestamp && (!conv.lastMessageTimestamp || new Date(conv.lastReactionTimestamp) >= new Date(conv.lastMessageTimestamp));
    
    const isLastMessageHiddenByClear = useMemo(() => {
        if (!conv.clearedAt?.[currentUser.id] || !conv.lastMessageTimestamp) return false;
        return new Date(conv.lastMessageTimestamp) <= new Date(conv.clearedAt[currentUser.id]);
    }, [conv.clearedAt, conv.lastMessageTimestamp, currentUser.id]);

    const isAlreadyCleared = conv.clearedAt?.[currentUser.id] && 
        (!conv.lastMessageTimestamp || new Date(conv.lastMessageTimestamp) <= new Date(conv.clearedAt[currentUser.id]));

    // --- TOUCH HANDLERS ---
    const handleTouchStart = (e: React.TouchEvent) => {
        if (!isMobile) return;
        const touch = e.touches[0];
        touchStart.current = touch.clientX;
        touchStartY.current = touch.clientY;
        setIsSwiping(false);

        // Long press for Context Menu
        longPressTimer.current = setTimeout(() => {
            if (!isSwiping) {
                const fakeEvent = {
                    preventDefault: () => {},
                    stopPropagation: () => {},
                    clientX: touch.clientX,
                    clientY: touch.clientY
                } as any;
                onContextMenu(fakeEvent, conv);
            }
        }, 600);
    };

    const handleTouchMove = (e: React.TouchEvent) => {
        if (!isMobile || touchStart.current === null || touchStartY.current === null) return;
        const currentX = e.touches[0].clientX;
        const currentY = e.touches[0].clientY;
        
        const diffX = touchStart.current - currentX;
        const diffY = Math.abs(touchStartY.current - currentY);
        
        if (Math.abs(diffX) > 10 || diffY > 10) {
            if (longPressTimer.current) {
                clearTimeout(longPressTimer.current);
                longPressTimer.current = null;
            }
        }

        if (Math.abs(diffX) > 10 && diffY < 30) {
            setIsSwiping(true);
        }

        if (diffX > 0 && isSwiping) {
            // Folders (80) + Clear (80) + Delete (80)
            const maxSwipe = conv.isGroup || isSavedMessages ? 160 : 240; 
            setSwipeX(Math.min(diffX, maxSwipe));
        } else {
            setSwipeX(0);
        }
    };

    const handleTouchEnd = () => {
        if (longPressTimer.current) {
            clearTimeout(longPressTimer.current);
            longPressTimer.current = null;
        }
        if (!isMobile) return;
        
        const snapThreshold = 40;
        const snapPoint = conv.isGroup || isSavedMessages ? 160 : 240;

        if (swipeX > snapThreshold) {
            setSwipeX(snapPoint);
        } else {
            setSwipeX(0);
        }
        touchStart.current = null;
        touchStartY.current = null;
    };

    return (
        <div ref={itemRef} className="relative overflow-hidden group/item mb-0.5 rounded-xl select-none">
            {/* Action Tray (revealed on swipe) */}
            <div 
                className={cn(
                    "absolute inset-y-0 right-0 flex items-center z-0 md:hidden transition-opacity duration-200 bg-muted",
                    swipeX > 0 ? "opacity-100" : "opacity-0 pointer-events-none"
                )}
                style={{ width: `${conv.isGroup || isSavedMessages ? 160 : 240}px` }}
            >
                <button 
                    onClick={(e) => { e.stopPropagation(); onManageFolders?.(conv); setSwipeX(0); }}
                    className="h-full w-20 flex flex-col items-center justify-center bg-primary text-white border-r border-white/10"
                >
                    <FolderEdit className="h-5 w-5 mb-1" />
                    <span className="text-[10px] font-bold uppercase">Папки</span>
                </button>
                <button 
                    disabled={!!isAlreadyCleared}
                    onClick={(e) => { e.stopPropagation(); router.push(`/dashboard/chat/${conv.id}/clear`); }}
                    className={cn(
                        "h-full w-20 flex flex-col items-center justify-center bg-amber-500 text-white transition-opacity border-r border-white/10",
                        isAlreadyCleared && "opacity-50 grayscale cursor-not-allowed"
                    )}
                >
                    <Eraser className="h-5 w-5 mb-1" />
                    <span className="text-[10px] font-bold uppercase">Очистить</span>
                </button>
                {!conv.isGroup && !isSavedMessages && (
                    <button 
                        onClick={(e) => { e.stopPropagation(); router.push(`/dashboard/chat/${conv.id}/delete`); }}
                        className="h-full w-20 flex flex-col items-center justify-center bg-red-500 text-white"
                    >
                        <Trash2 className="h-5 w-5 mb-1" />
                        <span className="text-[10px] font-bold uppercase">Удалить</span>
                    </button>
                )}
            </div>

            {/* Sliding Conversation Item */}
            <button 
                className={cn(
                    'relative z-10 flex w-full items-center gap-3 rounded-xl border border-transparent p-2 text-left transition-all duration-200 backdrop-blur-sm',
                    isSelected
                      ? 'border-white/15 bg-background/45 shadow-lg dark:border-white/12 dark:bg-background/32'
                      : 'bg-transparent hover:bg-white/10 dark:hover:bg-white/[0.06]',
                    isListCollapsed && !isMobile && 'justify-center'
                )} 
                style={{ transform: `translateX(${-swipeX}px)` }}
                onClick={() => { if(swipeX > 0) setSwipeX(0); else onSelect(conv.id); }}
                onContextMenu={(e) => !isMobile && onContextMenu(e, conv)}
                onTouchStart={handleTouchStart}
                onTouchMove={handleTouchMove}
                onTouchEnd={handleTouchEnd}
            >
                <div className="relative shrink-0">
                    <Avatar className="h-12 w-12 ring-1 ring-black/5 dark:ring-white/10">
                        <AvatarImage src={avatar} alt={displayName} className="object-cover" />
                        <AvatarFallback className="bg-muted text-foreground font-bold">{displayName.charAt(0)}</AvatarFallback>
                    </Avatar>
                    {!conv.isGroup && !isSavedMessages && liveOtherUser?.online && !isPartnerDeleted && (
                        <div className="absolute bottom-0.5 right-0.5 w-3.5 h-3.5 bg-green-500 border-2 border-background rounded-full z-10" />
                    )}
                    {isListCollapsed && totalUnread > 0 && (
                        <div className="absolute -top-0.5 -right-0.5 w-2.5 h-2.5 bg-red-500 border-2 border-background rounded-full z-10 animate-pulse" />
                    )}
                </div>
                <div className={cn("flex-1 min-w-0", isListCollapsed && !isMobile && "hidden")}>
                    <div className="flex justify-between items-center gap-2">
                        <p className={cn("font-bold truncate text-sm leading-tight flex items-center gap-1.5 min-w-0", isSelected ? "text-primary" : "text-foreground")}>
                            {isPinnedInFolder && <Pin className="h-3.5 w-3.5 shrink-0 text-amber-500" aria-hidden />}
                            {hasPendingGroupMention && (
                                <span
                                    className="inline-flex shrink-0 items-center justify-center rounded-md bg-primary/15 px-1 py-px text-primary ring-1 ring-primary/30"
                                    title="Вас упомянули"
                                    aria-label="Вас упомянули в группе"
                                >
                                    <AtSign className="h-3.5 w-3.5" aria-hidden />
                                </span>
                            )}
                            <span className="truncate">{displayName}</span>
                        </p>
                        <p className={cn("text-[10px] font-medium flex-shrink-0 text-muted-foreground")}>{dateDisplay}</p>
                    </div>
                    <div className="flex justify-between items-center gap-2 mt-0.5 min-w-0">
                        <p
                            className={cn(
                                'text-xs flex min-w-0 flex-1 items-center gap-1.5',
                                isSelected ? 'text-foreground/80' : 'text-muted-foreground'
                            )}
                        >
                            {isSomeoneTyping ? (
                                <span className="text-primary font-bold animate-pulse">Печатает...</span>
                            ) : isLastMessageHiddenByClear ? (
                                <span className="italic opacity-60">История очищена</span>
                            ) : isReactionNewer ? (
                                <>
                                    <span className="shrink-0 text-base leading-none">{conv.lastReactionEmoji}</span>
                                    <span className="min-w-0 flex-1 truncate">
                                        {conv.lastReactionSenderId === currentUser.id
                                            ? 'Вы'
                                            : allUsers.find((u) => u.id === conv.lastReactionSenderId)?.name?.split(' ')[0] || 'Кто-то'}{' '}
                                        поставил(а) реакцию
                                    </span>
                                </>
                            ) : (
                                <>
                                    {conv.lastMessageIsThread && (
                                        <span
                                            className="inline-flex shrink-0 items-center gap-0.5 rounded-md border border-primary/20 bg-primary/10 px-1 py-px text-[9px] font-semibold uppercase tracking-wide text-primary dark:bg-primary/15 dark:border-primary/25"
                                            title="Последнее сообщение в обсуждении"
                                        >
                                            <MessageSquare className="h-2.5 w-2.5 opacity-90" aria-hidden />
                                            Обсуждение
                                        </span>
                                    )}
                                    <span className="min-w-0 flex-1 truncate">
                                        {conv.lastMessageSenderId === currentUser.id && (
                                            <span className="font-medium">Вы: </span>
                                        )}
                                        {conv.lastMessageText || 'Нет сообщений'}
                                    </span>
                                </>
                            )}
                        </p>
                        {totalUnread > 0 && (
                            <Badge className="h-5 shrink-0 rounded-full px-1.5 min-w-[20px] text-[10px] border-none shadow-none bg-primary text-white">
                                {totalUnread}
                            </Badge>
                        )}
                    </div>
                </div>
            </button>
        </div>
    );
}
