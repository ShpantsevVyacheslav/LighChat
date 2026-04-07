'use client';

import React, { useState, useRef } from 'react';
import { createPortal } from 'react-dom';
import { format, parseISO } from 'date-fns';
import { ru } from 'date-fns/locale';
import { 
  Trash2, Edit, Copy, Clock, Check, MoreVertical 
} from 'lucide-react';
import { cn } from '@/lib/utils';
import type { MeetingMessage, User, ChatAttachment } from '@/lib/types';
import { Avatar, AvatarFallback, AvatarImage } from '../ui/avatar';
import { Separator } from '../ui/separator';

const isOnlyEmojis = (text: string) => {
    if (!text) return false;
    const cleaned = text.replace(/<[^>]*>/g, '').replace(/&nbsp;/g, ' ').trim();
    if (!cleaned) return false;
    const emojiRegex = /^(\p{Extended_Pictographic}|\p{Emoji_Component}|\u200d|\ufe0f|\s)+$/u;
    return emojiRegex.test(cleaned);
};

interface MeetingChatMessageItemProps {
  message: MeetingMessage;
  currentUser: User;
  onEdit: (m: MeetingMessage) => void;
  onDelete: () => void;
  onOpenImage: (att: ChatAttachment) => void;
}

export function MeetingChatMessageItem({ 
  message, 
  currentUser, 
  onEdit, 
  onDelete, 
  onOpenImage 
}: MeetingChatMessageItemProps) {
  const isMe = message.senderId === currentUser.id;
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [menuPos, setMenuPos] = useState({ x: 0, y: 0 });
  const longPressTimer = useRef<NodeJS.Timeout | null>(null);

  const handleContextMenu = (e: React.MouseEvent) => {
    if (message.isDeleted) return;
    e.preventDefault();
    setMenuPos({ x: e.clientX, y: e.clientY });
    setIsMenuOpen(true);
  };

  const handleTouchStart = (e: React.TouchEvent) => {
    if (message.isDeleted) return;
    longPressTimer.current = setTimeout(() => {
      const touch = e.touches[0];
      setMenuPos({ x: touch.clientX, y: touch.clientY });
      setIsMenuOpen(true);
    }, 600);
  };

  const handleTouchEnd = () => {
    if (longPressTimer.current) clearTimeout(longPressTimer.current);
  };

  const handleCopy = () => {
    if (message.text) {
      navigator.clipboard.writeText(message.text);
      setIsMenuOpen(false);
    }
  };

  const timeStr = format(
    typeof message.createdAt === 'string' 
      ? parseISO(message.createdAt) 
      : message.createdAt?.toDate?.() || new Date(), 
    'HH:mm'
  );

  const hasAttachments = message.attachments && message.attachments.length > 0;
  const hasText = !!message.text && message.text.trim().length > 0;

  return (
    <div className={cn("px-6 py-1.5 flex flex-col", isMe ? "items-end" : "items-start")}>
      {!isMe && (
        <span className="text-[9px] font-black uppercase text-white/30 ml-3 mb-1 tracking-widest">
          {message.senderName}
        </span>
      )}
      <div 
        className={cn(
          "relative group cursor-pointer active:scale-[0.99] transition-all max-w-[85%]",
          message.isDeleted ? "" : ""
        )}
        onContextMenu={handleContextMenu}
        onTouchStart={handleTouchStart}
        onTouchEnd={handleTouchEnd}
      >
        <div className={cn(
          "text-sm break-words flex flex-col overflow-hidden transition-all duration-300", 
          message.isDeleted 
            ? "bg-transparent shadow-none border-none" 
            : cn(
                "rounded-2xl shadow-sm border",
                isMe ? "bg-primary text-white rounded-tr-none border-primary/20" : "bg-white/10 text-white/90 rounded-tl-none border-white/5",
                hasAttachments ? "p-0" : "px-4 py-2.5"
              )
        )}>
          {message.isDeleted ? (
            <div className="flex items-center gap-2 italic text-xs opacity-70 py-2 px-0 font-medium select-none min-h-[32px]">
              <Trash2 className="h-3 w-3" /> Сообщение удалено
            </div>
          ) : (
            <>
              {hasAttachments && (
                <div className={cn(
                    "grid gap-1 overflow-hidden", 
                    message.attachments!.length > 1 ? "grid-cols-2" : "grid-cols-1",
                    message.text ? "mb-0" : ""
                )}>
                  {message.attachments!.map((att, i) => (
                    <div key={i} className="aspect-square relative group/img overflow-hidden bg-black/20" onClick={() => onOpenImage(att)}>
                      <img src={att.url} className="h-full w-full object-cover transition-transform group-hover/img:scale-105" alt="" />
                    </div>
                  ))}
                </div>
              )}
              {message.text && (
                <div className={cn("relative", hasAttachments ? "px-4 py-2" : "")}>
                  <div className="inline">
                    {message.text}
                  </div>
                  <div className="inline-flex items-center gap-1.5 ml-2 align-bottom opacity-40 text-[10px] font-bold">
                    {message.updatedAt && <Edit className="h-2 w-2" />}
                    <span>{timeStr}</span>
                  </div>
                </div>
              )}
              {!message.text && hasAttachments && (
                <div className="absolute bottom-2 right-2 flex justify-end px-2 pt-1 opacity-45 text-[10px] font-bold bg-black/40 backdrop-blur-md rounded-full text-white pointer-events-none">
                   {timeStr}
                </div>
              )}
            </>
          )}
        </div>
      </div>

      {isMenuOpen && createPortal(
        <div className="fixed inset-0 z-[200] bg-black/20" onClick={() => setIsMenuOpen(false)} onContextMenu={(e) => { e.preventDefault(); setIsMenuOpen(false); }}>
          <div 
            className="fixed z-[210] w-48 bg-slate-900/60 backdrop-blur-xl border border-white/10 rounded-2xl shadow-2xl overflow-hidden p-1 animate-in zoom-in-95 duration-200"
            style={{ 
              top: Math.min(menuPos.y, window.innerHeight - 150), 
              left: Math.max(16, Math.min(menuPos.x, window.innerWidth - 200)) 
            }}
            onClick={e => e.stopPropagation()}
          >
            {hasText && (
              <button onClick={handleCopy} className="w-full flex items-center px-3 py-2 text-xs font-bold hover:bg-white/10 rounded-xl transition-colors text-white/80">
                <Copy className="mr-3 h-4 w-4 opacity-60" /> Копировать
              </button>
            )}
            {isMe && !message.isDeleted && (
              <>
                {hasText && !isOnlyEmojis(message.text!) && (
                  <button onClick={() => { onEdit(message); setIsMenuOpen(false); }} className="w-full flex items-center px-3 py-2 text-xs font-bold hover:bg-white/10 rounded-xl transition-colors text-white/80">
                    <Edit className="mr-3 h-4 w-4 opacity-60" /> Изменить
                  </button>
                )}
                <Separator className="my-1 bg-white/5" />
                <button onClick={() => { onDelete(); setIsMenuOpen(false); }} className="w-full flex items-center px-3 py-2 text-xs font-bold hover:bg-red-500/20 text-red-500 rounded-xl transition-colors">
                  <Trash2 className="mr-3 h-4 w-4" /> Удалить
                </button>
              </>
            )}
          </div>
        </div>,
        document.body
      )}
    </div>
  );
}
