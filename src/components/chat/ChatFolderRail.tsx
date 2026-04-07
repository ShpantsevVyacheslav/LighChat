'use client';

import React, { useCallback, useEffect, useRef, useState } from 'react';
import type { ChatFolder, Conversation } from '@/lib/types';
import { cn } from '@/lib/utils';
import { CHAT_SIDEBAR_RAIL_GLASS } from '@/lib/chat-glass-styles';
import {
  Inbox,
  MessageCircle,
  CircleUser,
  Users,
  Folder,
  FolderPlus,
  Star,
  MoreHorizontal,
} from 'lucide-react';
import { LighChatSidebarMarkButton } from '@/components/chat/LighChatSidebarMarkButton';

const FOLDER_ICONS: Record<string, React.ComponentType<{ className?: string }>> = {
  all: Inbox,
  unread: MessageCircle,
  personal: CircleUser,
  groups: Users,
};

const HOLD_TO_DRAG_MS = 520;
const HOLD_CANCEL_MOVE_PX = 14;

export interface ChatFolderRailProps {
  folders: ChatFolder[];
  activeFolderId: string;
  savedMessagesConversationId: string | null;
  selectedConversationId: string | null;
  conversations: Conversation[];
  currentUserId: string;
  onSelectFolder: (folderId: string) => void;
  onOpenSavedMessages: () => void;
  onPersistFolderOrder: (orderedIds: string[]) => void;
  onNewFolderClick: () => void;
  onCustomFolderContextMenu: (e: React.MouseEvent, folder: ChatFolder) => void;
  /** Мобильная полоса папок над поиском (без drag-reorder). */
  layout?: 'vertical' | 'horizontal';
  /** Десктоп (вертикальный рельс): переключение ширины боковой панели по клику на логотип над «Избранное». */
  onToggleSidebarCollapse?: () => void;
}

export function ChatFolderRail({
  folders,
  activeFolderId,
  savedMessagesConversationId,
  selectedConversationId,
  conversations,
  currentUserId,
  onSelectFolder,
  onOpenSavedMessages,
  onPersistFolderOrder,
  onNewFolderClick,
  onCustomFolderContextMenu,
  layout = 'vertical',
  onToggleSidebarCollapse,
}: ChatFolderRailProps) {
  const isHorizontal = layout === 'horizontal';
  const [draggingId, setDraggingId] = useState<string | null>(null);
  const [touchReorderIds, setTouchReorderIds] = useState<string[] | null>(null);
  const holdTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const holdStartRef = useRef<{ folderId: string; x: number; y: number } | null>(null);
  const railRef = useRef<HTMLDivElement>(null);
  const touchDraggingRef = useRef(false);
  const touchSourceIdRef = useRef<string | null>(null);
  const suppressNextFolderClickRef = useRef(false);
  const touchReorderIdsRef = useRef<string[] | null>(null);
  touchReorderIdsRef.current = touchReorderIds;
  const pointerMoveFolderRef = useRef<(clientX: number, clientY: number) => void>(() => {});

  const orderedFolders = touchReorderIds
    ? touchReorderIds.map((id) => folders.find((f) => f.id === id)!).filter(Boolean)
    : folders;

  const clearHoldTimer = () => {
    if (holdTimerRef.current) {
      clearTimeout(holdTimerRef.current);
      holdTimerRef.current = null;
    }
    holdStartRef.current = null;
  };

  useEffect(() => () => clearHoldTimer(), []);

  const applyNewOrder = useCallback(
    (ids: string[]) => {
      const valid = new Set(folders.map((f) => f.id));
      const next = ids.filter((id) => valid.has(id));
      folders.forEach((f) => {
        if (!next.includes(f.id)) next.push(f.id);
      });
      onPersistFolderOrder(next);
    },
    [folders, onPersistFolderOrder]
  );

  const reorderIds = (ids: string[], fromId: string, toId: string) => {
    const from = ids.indexOf(fromId);
    const to = ids.indexOf(toId);
    if (from < 0 || to < 0 || from === to) return ids;
    const next = [...ids];
    const [item] = next.splice(from, 1);
    next.splice(to, 0, item);
    return next;
  };

  const onDragStart = (e: React.DragEvent, folderId: string) => {
    if (isHorizontal) return;
    e.dataTransfer.setData('text/plain', folderId);
    e.dataTransfer.effectAllowed = 'move';
    setDraggingId(folderId);
  };

  const onDragEnd = () => {
    setDraggingId(null);
  };

  const onDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    e.dataTransfer.dropEffect = 'move';
  };

  const onDrop = (e: React.DragEvent, dropFolderId: string) => {
    e.preventDefault();
    const fromId = e.dataTransfer.getData('text/plain');
    if (!fromId || fromId === dropFolderId) return;
    const ids = folders.map((f) => f.id);
    applyNewOrder(reorderIds(ids, fromId, dropFolderId));
    setDraggingId(null);
  };

  const onPointerDownFolder = (folderId: string, clientX: number, clientY: number) => {
    if (isHorizontal) return;
    clearHoldTimer();
    holdStartRef.current = { folderId, x: clientX, y: clientY };
    holdTimerRef.current = setTimeout(() => {
      holdTimerRef.current = null;
      if (!holdStartRef.current) return;
      touchDraggingRef.current = true;
      touchSourceIdRef.current = folderId;
      const initial = folders.map((f) => f.id);
      touchReorderIdsRef.current = initial;
      setTouchReorderIds(initial);
      setDraggingId(folderId);
    }, HOLD_TO_DRAG_MS);
  };

  /** Папка под координатами: сначала DOM, иначе ближайшая строка по Y (чтобы вверх работало над «Избранное»/зазорами). */
  const folderIdAtPoint = (clientX: number, clientY: number): string | null => {
    const rail = railRef.current;
    if (!rail) return null;

    const fromEl = document.elementFromPoint(clientX, clientY);
    const rowFromEl = fromEl?.closest('[data-folder-row-id]') as HTMLElement | null;
    const idFromEl = rowFromEl?.getAttribute('data-folder-row-id');
    if (idFromEl) return idFromEl;

    const stack = document.elementsFromPoint(clientX, clientY);
    for (const node of stack) {
      if (!(node instanceof Element)) continue;
      const row = node.closest('[data-folder-row-id]') as HTMLElement | null;
      const id = row?.getAttribute('data-folder-row-id');
      if (id) return id;
    }

    const rows = [...rail.querySelectorAll('[data-folder-row-id]')] as HTMLElement[];
    if (!rows.length) return null;

    const railRect = rail.getBoundingClientRect();
    if (clientX < railRect.left - 12 || clientX > railRect.right + 12) return null;

    const firstFolderTop = rows[0].getBoundingClientRect().top;
    if (clientY < firstFolderTop - 10) return null;

    const pad = 6;
    for (const row of rows) {
      const r = row.getBoundingClientRect();
      if (
        clientY >= r.top - pad &&
        clientY <= r.bottom + pad &&
        clientX >= r.left - 12 &&
        clientX <= r.right + 12
      ) {
        return row.getAttribute('data-folder-row-id');
      }
    }

    let best: string | null = null;
    let bestDist = Infinity;
    for (const row of rows) {
      const r = row.getBoundingClientRect();
      const midY = (r.top + r.bottom) / 2;
      const dist = Math.abs(clientY - midY);
      if (dist < bestDist) {
        bestDist = dist;
        best = row.getAttribute('data-folder-row-id');
      }
    }
    return best;
  };

  const onPointerMoveFolder = (clientX: number, clientY: number) => {
    const start = holdStartRef.current;
    if (holdTimerRef.current && start) {
      const dx = Math.abs(clientX - start.x);
      const dy = Math.abs(clientY - start.y);
      if (dx > HOLD_CANCEL_MOVE_PX || dy > HOLD_CANCEL_MOVE_PX) {
        clearHoldTimer();
      }
    }
    if (!touchDraggingRef.current || !railRef.current) return;
    const overId = folderIdAtPoint(clientX, clientY);
    const src = touchSourceIdRef.current;
    if (!overId || !src || overId === src) return;
    setTouchReorderIds((prev) => {
      if (!prev) return prev;
      const next = reorderIds(prev, src, overId);
      touchReorderIdsRef.current = next;
      return next;
    });
  };

  pointerMoveFolderRef.current = onPointerMoveFolder;

  useEffect(() => {
    const el = railRef.current;
    if (!el || touchReorderIds == null) return;

    const onMove = (e: TouchEvent) => {
      if (!touchDraggingRef.current || !e.touches[0]) return;
      e.preventDefault();
      pointerMoveFolderRef.current(e.touches[0].clientX, e.touches[0].clientY);
    };

    el.addEventListener('touchmove', onMove, { passive: false });
    return () => el.removeEventListener('touchmove', onMove);
  }, [touchReorderIds]);

  const endTouchDrag = () => {
    clearHoldTimer();
    const hadTouchReorder = touchDraggingRef.current && touchSourceIdRef.current !== null;
    const idsSnapshot = touchReorderIdsRef.current;
    if (idsSnapshot?.length) {
      applyNewOrder(idsSnapshot);
    }
    if (hadTouchReorder) {
      suppressNextFolderClickRef.current = true;
      window.setTimeout(() => {
        suppressNextFolderClickRef.current = false;
      }, 320);
    }
    setTouchReorderIds(null);
    touchReorderIdsRef.current = null;
    setDraggingId(null);
    touchDraggingRef.current = false;
    touchSourceIdRef.current = null;
  };

  const savedUnread =
    savedMessagesConversationId &&
    conversations.find((c) => c.id === savedMessagesConversationId);
  const savedUnreadCount = savedUnread
    ? (savedUnread.unreadCounts?.[currentUserId] || 0) +
      (savedUnread.unreadThreadCounts?.[currentUserId] || 0)
    : 0;

  const savedActive =
    !!savedMessagesConversationId && selectedConversationId === savedMessagesConversationId;

  return (
    <div
      ref={railRef}
      className={cn(
        CHAT_SIDEBAR_RAIL_GLASS,
        'relative flex gap-1 scrollbar-hide',
        isHorizontal
          ? 'shrink-0 flex-row items-center overflow-x-auto overflow-y-hidden py-2 pl-1 pr-2 touch-pan-x'
          : cn(
              'w-16 shrink-0 flex-col items-stretch overflow-y-auto py-2',
              touchReorderIds != null ? 'touch-none' : 'touch-pan-y'
            )
      )}
      onTouchEnd={isHorizontal ? undefined : endTouchDrag}
      onTouchCancel={isHorizontal ? undefined : endTouchDrag}
    >
      {!isHorizontal && (
        <div
          className="pointer-events-none absolute inset-y-3 right-0 w-px bg-gradient-to-b from-transparent via-primary/12 to-transparent dark:via-white/10"
          aria-hidden
        />
      )}

      {/* Избранное: в вертикальном сайдбаре — отдельная плашка; на мобильной горизонтальной ленте не показываем (доступ из списка чатов). */}
      {!isHorizontal ? (
        <>
          {onToggleSidebarCollapse ? (
            <LighChatSidebarMarkButton
              onClick={onToggleSidebarCollapse}
              title="Свернуть боковую панель"
            />
          ) : null}
          <button
            type="button"
            disabled={!savedMessagesConversationId}
            onClick={() => {
              if (savedMessagesConversationId) onOpenSavedMessages();
            }}
            title="Избранное"
            className={cn(
              'relative mx-1 flex flex-col items-center justify-center gap-1 rounded-2xl py-2 text-center transition-all duration-200',
              savedActive
                ? 'bg-primary/15 font-medium text-primary shadow-sm dark:bg-primary/20'
                : 'text-muted-foreground hover:bg-white/12 dark:hover:bg-white/[0.08]',
              !savedMessagesConversationId && 'pointer-events-none opacity-40'
            )}
          >
            <Star className={cn('h-5 w-5 shrink-0', savedActive && 'drop-shadow-sm')} />
            <span
              className={cn(
                'w-full truncate px-0.5 text-[9px] leading-tight',
                savedActive ? 'font-bold' : 'font-medium'
              )}
            >
              Избранное
            </span>
            {savedUnreadCount > 0 && (
              <span className="absolute -right-0.5 -top-0.5 flex h-4 min-w-[16px] items-center justify-center rounded-full bg-primary px-1 text-[8px] font-black text-primary-foreground shadow-sm ring-2 ring-background">
                {savedUnreadCount > 99 ? '99+' : savedUnreadCount}
              </span>
            )}
          </button>
          <div className="mx-2 my-1 h-px w-auto shrink-0 bg-border/40" aria-hidden />
        </>
      ) : null}

      {orderedFolders.map((folder) => {
        const isActive = activeFolderId === folder.id && !savedActive;
        const isDefault = folder.type !== 'custom';
        const FIcon = FOLDER_ICONS[folder.id] || Folder;
        const unreadCount = conversations
          .filter((c) => folder.conversationIds.includes(c.id))
          .reduce(
            (s, c) =>
              s + (c.unreadCounts?.[currentUserId] || 0) + (c.unreadThreadCounts?.[currentUserId] || 0),
            0
          );
        const isDraggingRow = draggingId === folder.id;

        return (
          <div
            key={folder.id}
            data-folder-row-id={folder.id}
            draggable={!isHorizontal}
            onDragStart={(e) => onDragStart(e, folder.id)}
            onDragEnd={onDragEnd}
            onDragOver={onDragOver}
            onDrop={(e) => onDrop(e, folder.id)}
            onContextMenu={(e) => {
              if (!isDefault) {
                e.preventDefault();
                onCustomFolderContextMenu(e, folder);
              }
            }}
            className={cn(
              'relative rounded-2xl transition-opacity',
              isHorizontal ? 'mx-0 min-w-[3.75rem] shrink-0' : 'mx-1',
              isDraggingRow && 'opacity-60 z-10'
            )}
          >
            <div className="relative flex flex-col">
              <button
                type="button"
                onClick={() => {
                  if (suppressNextFolderClickRef.current) return;
                  onSelectFolder(folder.id);
                }}
                onTouchStart={(e) =>
                  onPointerDownFolder(folder.id, e.touches[0].clientX, e.touches[0].clientY)
                }
                className={cn(
                  'flex w-full flex-col items-center justify-center gap-1 rounded-2xl text-center transition-all duration-200',
                  isHorizontal ? 'px-1 py-1.5' : 'py-2',
                  isActive
                    ? 'bg-primary/15 font-medium text-primary shadow-sm dark:bg-primary/20'
                    : 'text-muted-foreground hover:bg-white/12 dark:hover:bg-white/[0.08]'
                )}
              >
                <FIcon className={cn('h-5 w-5 shrink-0', isActive && 'drop-shadow-sm')} />
                <span
                  className={cn(
                    'text-[9px] leading-tight truncate w-full px-0.5',
                    isActive ? 'font-bold' : 'font-medium'
                  )}
                >
                  {folder.name}
                </span>
                {unreadCount > 0 && (
                  <span className="absolute -top-0.5 -right-0.5 flex h-4 min-w-[16px] px-1 items-center justify-center rounded-full text-[8px] font-black bg-primary text-primary-foreground shadow-sm ring-2 ring-background">
                    {unreadCount > 99 ? '99+' : unreadCount}
                  </span>
                )}
              </button>
              {!isDefault && (
                <button
                  type="button"
                  aria-label="Меню папки"
                  className={cn(
                    'absolute bottom-0 right-0 h-6 w-6 flex items-center justify-center rounded-lg text-muted-foreground hover:bg-background/80 active:scale-95',
                    isHorizontal ? 'md:flex' : 'md:hidden'
                  )}
                  onClick={(e) => {
                    e.stopPropagation();
                    onCustomFolderContextMenu(e, folder);
                  }}
                >
                  <MoreHorizontal className="h-4 w-4" />
                </button>
              )}
            </div>
          </div>
        );
      })}

      {/* Создание папки — не элемент списка категорий: разделитель + «действие» (пунктир, акцент). */}
      {isHorizontal ? (
        <div
          className="mx-1.5 h-9 w-px shrink-0 self-center bg-border/80 dark:bg-white/22"
          aria-hidden
        />
      ) : (
        <div className="mx-2 my-1.5 h-px w-auto shrink-0 bg-border/55 dark:bg-white/12" aria-hidden />
      )}
      <button
        type="button"
        onClick={onNewFolderClick}
        className={cn(
          'flex flex-col items-center justify-center rounded-2xl transition-all duration-200',
          'border border-white/25 bg-white/20 text-primary shadow-sm backdrop-blur-md',
          'hover:bg-white/30 active:scale-[0.98] dark:border-white/12 dark:bg-white/[0.08] dark:hover:bg-white/[0.12]',
          isHorizontal ? 'mx-0 min-w-[3.5rem] shrink-0 px-1 py-1.5' : 'mx-1 py-2'
        )}
      >
        <FolderPlus className="h-5 w-5 shrink-0" />
        <span className="mt-0.5 text-[9px] font-semibold leading-tight">Новая</span>
      </button>
    </div>
  );
}
