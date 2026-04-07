
'use client';

import React, { useState, useRef } from 'react';
import { cn } from '@/lib/utils';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import type { User, ReactionDetail } from '@/lib/types';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { format, parseISO, isToday, isYesterday } from 'date-fns';
import { ru } from 'date-fns/locale';
import { ScrollArea } from '@/components/ui/scroll-area';

interface MessageReactionsProps {
  reactions: Record<string, (string | ReactionDetail)[]>;
  currentUserId: string;
  allUsers: User[];
  onReact: (emoji: string) => void;
}

type ReactionUserRow = User & { timestamp: string | undefined };

const formatDateSafe = (dateStr?: string) => {
    if (!dateStr) return 'Ранее';
    try {
        const date = parseISO(dateStr);
        if (isToday(date)) return `Сегодня, ${format(date, 'HH:mm')}`;
        if (isYesterday(date)) return `Вчера, ${format(date, 'HH:mm')}`;
        return format(date, 'd MMMM, HH:mm', { locale: ru });
    } catch (e) {
        return 'Ранее';
    }
};

export function MessageReactions({ reactions, currentUserId, allUsers, onReact }: MessageReactionsProps) {
  const [openPopover, setOpenPopover] = useState<string | null>(null);
  const longPressTimer = useRef<NodeJS.Timeout | null>(null);
  const wasLongPressed = useRef(false);

  if (!reactions || Object.keys(reactions).length === 0) return null;

  const handleTouchStart = (emoji: string) => {
    wasLongPressed.current = false;
    longPressTimer.current = setTimeout(() => {
      wasLongPressed.current = true;
      setOpenPopover(emoji);
    }, 600); // Clear long press intent
  };

  const handleTouchEnd = () => {
    if (longPressTimer.current) clearTimeout(longPressTimer.current);
  };

  return (
    <div className="mt-1 flex flex-wrap gap-2 px-2 pb-1 select-none">
      {Object.entries(reactions).map(([emoji, userReactions]) => {
        if (!userReactions || userReactions.length === 0) return null;
        
        // Extract user IDs regardless of format (legacy string or new object)
        const userIds = userReactions.map(r => typeof r === 'string' ? r : r.userId);
        const isMyReaction = userIds.includes(currentUserId);
        
        const reactionUsers = userReactions
          .map((r): ReactionUserRow | null => {
            const uid = typeof r === 'string' ? r : r.userId;
            const time = typeof r === 'string' ? undefined : r.timestamp;
            const userData = allUsers.find((u) => u.id === uid);
            return userData != null ? { ...userData, timestamp: time } : null;
          })
          .filter((u): u is ReactionUserRow => u != null);

        return (
          <Popover 
            key={emoji} 
            open={openPopover === emoji} 
            onOpenChange={(open) => !open && setOpenPopover(null)}
          >
            <PopoverTrigger asChild>
              <button 
                onClick={(e) => { 
                  e.stopPropagation(); 
                  // Critical: prevent toggle if we just opened the popover via long press
                  if (!wasLongPressed.current) {
                    onReact(emoji); 
                  }
                }} 
                onContextMenu={(e) => { e.preventDefault(); setOpenPopover(emoji); }}
                onTouchStart={() => handleTouchStart(emoji)}
                onTouchEnd={handleTouchEnd}
                className={cn(
                  'flex min-h-[40px] items-center gap-1.5 rounded-full px-2.5 py-1 shadow-sm transition-all hover:scale-[1.02] active:scale-95',
                  isMyReaction
                    ? 'bg-primary/10 text-primary'
                    : 'bg-black/5 text-muted-foreground dark:bg-white/5'
                )}
              >
                <span className="text-2xl leading-none">{emoji}</span>
                
                {userIds.length > 3 ? (
                  <span className="px-1 text-xs font-black">{userIds.length}</span>
                ) : (
                  <div className="ml-0.5 flex -space-x-2 pr-0.5">
                    {reactionUsers.slice(0, 3).map(u => (
                      <Avatar key={u.id} className="h-7 w-7 shrink-0">
                        <AvatarImage src={u.avatar} className="object-cover" />
                        <AvatarFallback className="text-[11px] font-bold">{u.name[0]}</AvatarFallback>
                      </Avatar>
                    ))}
                  </div>
                )}
              </button>
            </PopoverTrigger>
            <PopoverContent className="w-64 p-0 rounded-2xl border-none shadow-2xl bg-popover/90 backdrop-blur-xl overflow-hidden z-[600]" side="top" align="center">
                <div className="p-3 border-b bg-white/5 flex items-center justify-between">
                    <span className="text-xl leading-none">{emoji}</span>
                    <span className="text-[10px] font-black uppercase tracking-widest text-muted-foreground">Оценили: {userIds.length}</span>
                </div>
                <ScrollArea className="max-h-60">
                    <div className="p-1 space-y-0.5">
                        {reactionUsers.map(u => (
                            <div key={u.id} className="flex items-center gap-3 p-2 rounded-xl hover:bg-white/5 transition-colors">
                                <Avatar className="h-8 w-8 border border-white/5 shrink-0">
                                    <AvatarImage src={u.avatar} className="object-cover" />
                                    <AvatarFallback className="text-xs">{u.name[0]}</AvatarFallback>
                                </Avatar>
                                <div className="flex flex-col min-w-0 flex-1">
                                    <span className="text-sm font-bold truncate leading-tight block w-full">{u.name}</span>
                                    <span className="text-[9px] font-medium text-muted-foreground mt-0.5">{formatDateSafe(u.timestamp)}</span>
                                </div>
                            </div>
                        ))}
                    </div>
                </ScrollArea>
            </PopoverContent>
          </Popover>
        );
      })}
    </div>
  );
}
