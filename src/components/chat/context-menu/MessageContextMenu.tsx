'use client';

import React from 'react';
import { createPortal } from 'react-dom';
import { 
  Trash2, Edit, Copy, Pin, Forward, Reply, 
  CheckSquare, MessageSquare, BookmarkPlus
} from 'lucide-react';
import { Separator } from '@/components/ui/separator';
import { cn } from '@/lib/utils';
import type { ChatMessage } from '@/lib/types';
import { format, parseISO } from 'date-fns';
import { ru } from 'date-fns/locale';
import type { FocusCircleHole } from '@/components/chat/context-menu/message-focus-hole';

const REACTION_LIST = ['👌', '😁', '🤝', '😱', '❤️', '👍', '🔥', '😂', '😮', '😢', '👏', '🎉', '✅'];

export type MessageContextMenuPosition = {
  top: number;
  left: number;
  shiftY: number;
  menuHeight: number;
  /** Область пузыря в координатах viewport — под неё не кладём blur, чтобы сообщение оставалось чётким. */
  bubbleRect: { top: number; left: number; width: number; height: number };
  /** Скругление выреза под реальный border-radius пузыря (px). */
  bubbleCornerRadiusPx?: number;
  /** Для одиночного стикера — вырез круглый (инсет по bbox контейнера стикера). */
  focusHoleShape?: 'rect' | 'circle';
  focusCircle?: FocusCircleHole;
};

interface MessageContextMenuProps {
  isOpen: boolean;
  onClose: () => void;
  position: MessageContextMenuPosition | null;
  message: ChatMessage;
  isCurrentUser: boolean;
  hasText: boolean;
  canEdit: boolean;
  /** Показать «Сохранить в мои стикеры» (сообщение со стикером/GIF из чата). */
  canSaveSticker?: boolean;
  onAction: (action: 'reply' | 'copy' | 'edit' | 'pin' | 'forward' | 'delete' | 'react' | 'select' | 'thread' | 'save_sticker', payload?: string) => void;
}

function buildRoundedHoleMaskDataUrl(
  vw: number,
  vh: number,
  hole: { top: number; left: number; width: number; height: number },
  cornerRadiusPx: number
): string {
  const { top, left, width, height } = hole;
  const rx = Math.max(
    0,
    Math.min(cornerRadiusPx, Math.min(width, height) / 2 - 0.5)
  );
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${vw}" height="${vh}"><defs><mask id="m"><rect width="${vw}" height="${vh}" fill="white"/><rect x="${left}" y="${top}" width="${width}" height="${height}" rx="${rx}" ry="${rx}" fill="black"/></mask></defs><rect width="${vw}" height="${vh}" fill="white" mask="url(#m)"/></svg>`;
  return `url("data:image/svg+xml;charset=utf-8,${encodeURIComponent(svg)}")`;
}

function buildCircleHoleMaskDataUrl(vw: number, vh: number, circle: FocusCircleHole): string {
  const { cx, cy, r } = circle;
  const safeR = Math.max(0, r - 0.25);
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${vw}" height="${vh}"><defs><mask id="m"><rect width="${vw}" height="${vh}" fill="white"/><circle cx="${cx}" cy="${cy}" r="${safeR}" fill="black"/></mask></defs><rect width="${vw}" height="${vh}" fill="white" mask="url(#m)"/></svg>`;
  return `url("data:image/svg+xml;charset=utf-8,${encodeURIComponent(svg)}")`;
}

/**
 * Один слой blur + затемнение с маской: вырез с rx совпадает с пузырём (картинка, ссылка и т.д.).
 * Координаты hole должны быть сняты после layout (в т.ч. после translateY меню).
 */
function MessageFocusBackdropMasked({
  bubbleRect,
  bubbleCornerRadiusPx,
  focusHoleShape,
  focusCircle,
  onClose,
}: {
  bubbleRect: MessageContextMenuPosition['bubbleRect'];
  bubbleCornerRadiusPx: number;
  focusHoleShape?: 'rect' | 'circle';
  focusCircle?: FocusCircleHole;
  onClose: () => void;
}) {
  if (typeof window === 'undefined') return null;
  const vw = window.innerWidth;
  const vh = window.innerHeight;
  const maskUrl =
    focusHoleShape === 'circle' && focusCircle
      ? buildCircleHoleMaskDataUrl(vw, vh, focusCircle)
      : buildRoundedHoleMaskDataUrl(vw, vh, bubbleRect, bubbleCornerRadiusPx);

  const blockCtx = (e: React.MouseEvent) => {
    e.preventDefault();
    onClose();
  };

  return (
    <div
      className="fixed inset-0 z-[2400] bg-black/40 backdrop-blur-[12px] animate-[fade-in_0.2s_ease-out_forwards] pointer-events-auto"
      style={{
        WebkitMaskImage: maskUrl,
        maskImage: maskUrl,
        WebkitMaskSize: `${vw}px ${vh}px`,
        maskSize: `${vw}px ${vh}px`,
        WebkitMaskRepeat: 'no-repeat',
        maskRepeat: 'no-repeat',
        WebkitMaskPosition: '0 0',
        maskPosition: '0 0',
      }}
      onClick={onClose}
      onContextMenu={blockCtx}
      aria-hidden
    />
  );
}

/**
 * Выпадающее меню действий сообщения.
 * Рендерится через Portal поверх всего интерфейса.
 */
export function MessageContextMenu({ 
  isOpen, onClose, position, message, isCurrentUser, hasText, canEdit, canSaveSticker = false, onAction 
}: MessageContextMenuProps) {
  if (!isOpen || !position) return null;

  const sentDate = parseISO(message.createdAt);
  const sentDateStr = format(sentDate, 'dd.MM.yyyy', { locale: ru });
  const sentTimeStr = format(sentDate, 'HH:mm');

  const readDate = message.readAt ? parseISO(message.readAt) : null;
  const readDateStr = readDate ? format(readDate, 'dd.MM.yyyy', { locale: ru }) : null;
  const readTimeStr = readDate ? format(readDate, 'HH:mm') : null;

  return createPortal(
    <>
      <MessageFocusBackdropMasked
        bubbleRect={position.bubbleRect}
        bubbleCornerRadiusPx={position.bubbleCornerRadiusPx ?? 14}
        focusHoleShape={position.focusHoleShape}
        focusCircle={position.focusCircle}
        onClose={onClose}
      />
      <div
        className="fixed z-[2450] w-[240px] animate-in zoom-in-95 duration-200"
        style={{ top: position.top, left: position.left }}
        onClick={(e) => e.stopPropagation()}
      >
        <div className="bg-popover/60 backdrop-blur-2xl rounded-[1.5rem] shadow-2xl overflow-hidden border border-white/10 flex flex-col">
          {/* Message Info Header */}
          <div className="px-4 py-3 bg-white/5 border-b border-white/5 flex flex-col gap-1.5 text-white/40">
            <div className="space-y-1">
                <p className="text-[10px] font-bold uppercase tracking-wide flex justify-between">
                    <span>Отправлено:</span>
                    <span className="text-white/80">{sentDateStr} {sentTimeStr}</span>
                </p>
                {message.readAt && (
                    <p className="text-[10px] font-bold uppercase tracking-wide flex justify-between">
                        <span>Прочитано:</span>
                        <span className="text-blue-400">{readDateStr} {readTimeStr}</span>
                    </p>
                )}
            </div>
          </div>

          {/* Reaction Picker */}
          <div className="flex items-center px-2 py-3.5 bg-white/5 border-b border-white/5 gap-1.5 overflow-x-auto no-scrollbar scroll-smooth">
            {REACTION_LIST.map(emoji => (
              <button 
                key={emoji} 
                onClick={() => { onAction('react', emoji); onClose(); }} 
                className="flex-shrink-0 p-1.5 text-3xl leading-none transition-transform duration-200 hover:scale-110 active:scale-95"
              >
                {emoji}
              </button>
            ))}
          </div>

          {/* Action List */}
          <div className="p-1 space-y-0.5">
            <MenuButton icon={Reply} label="Ответить" onClick={() => { onAction('reply'); onClose(); }} />
            <MenuButton icon={MessageSquare} label="Обсудить" onClick={() => { onAction('thread'); onClose(); }} />
            {hasText && (
              <MenuButton icon={Copy} label="Копировать" onClick={() => { onAction('copy'); onClose(); }} />
            )}
            {canEdit && (
              <MenuButton icon={Edit} label="Изменить" onClick={() => { onAction('edit'); onClose(); }} />
            )}
            <MenuButton icon={Pin} label="Закрепить" onClick={() => { onAction('pin'); onClose(); }} />
            {canSaveSticker && (
              <MenuButton
                icon={BookmarkPlus}
                label="Сохранить в мои стикеры"
                onClick={() => { onAction('save_sticker'); onClose(); }}
              />
            )}
            <MenuButton icon={Forward} label="Переслать" onClick={() => { onAction('forward'); onClose(); }} />
            <MenuButton icon={CheckSquare} label="Выбрать" onClick={() => { onAction('select'); onClose(); }} />
            
            {isCurrentUser && (
              <>
                <Separator className="my-1 opacity-10" />
                <MenuButton 
                  icon={Trash2} 
                  label="Удалить" 
                  onClick={() => { onAction('delete'); onClose(); }} 
                  className="text-red-500 hover:bg-red-500/20"
                />
              </>
            )}
          </div>
        </div>
      </div>
    </>,
    document.body
  );
}

function MenuButton({ icon: Icon, label, onClick, className }: { icon: any, label: string, onClick: () => void, className?: string }) {
  return (
    <button 
      onClick={onClick}
      className={cn(
        "w-full flex items-center px-3 py-2 text-sm hover:bg-white/10 rounded-xl transition-colors text-left font-medium",
        className
      )}
    >
      <Icon className="mr-3 h-4 w-4 opacity-60" />
      {label}
    </button>
  );
}