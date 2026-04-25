'use client';

import React from 'react';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { cn } from '@/lib/utils';
import type { User } from '@/lib/types';
import { userAvatarListUrl } from '@/lib/user-avatar-display';
import { CHAT_GLASS_MENTION_LIST } from '@/lib/chat-glass-styles';

interface GroupMentionSuggestionsProps {
  participants: User[];
  onPick: (user: User) => void;
  className?: string;
}

/**
 * Компактная панель @-упоминаний: стеклянный стиль, нативная прокрутка (стабильные клики).
 * Выбор по mouseDown + preventDefault, чтобы фокус не уходил с редактора до вставки.
 */
export function GroupMentionSuggestions({ participants, onPick, className }: GroupMentionSuggestionsProps) {
  const visibleRows = Math.max(1, Math.min(participants.length || 1, 5));
  const rowHeightPx = 46;
  const listMaxHeightPx = visibleRows * rowHeightPx + 8;

  return (
    <div
      className={cn(
        'pointer-events-auto select-none',
        'w-max min-w-[220px] max-w-[min(calc(100vw-2rem),300px)]',
        CHAT_GLASS_MENTION_LIST,
        'mb-1.5 overflow-hidden',
        className
      )}
      role="listbox"
      aria-label="Упоминание участника"
    >
      <div
        className="overflow-y-auto overscroll-contain p-1 [scrollbar-width:thin]"
        style={{ maxHeight: `min(${listMaxHeightPx}px, 42vh)` }}
      >
        {participants.length === 0 ? (
          <p className="px-3 py-2.5 text-sm text-muted-foreground">Нет совпадений</p>
        ) : (
          participants.map((p) => (
            <button
              key={p.id}
              type="button"
              role="option"
              className={cn(
                'w-full flex items-center gap-2.5 px-2 py-2 rounded-xl text-left transition-colors',
                'hover:bg-white/25 dark:hover:bg-white/10 active:bg-white/35 dark:active:bg-white/15',
                'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/50'
              )}
              onMouseDown={(e) => {
                e.preventDefault();
                e.stopPropagation();
                onPick(p);
              }}
            >
              <Avatar className="h-8 w-8 shrink-0 border border-black/5 dark:border-white/10">
                <AvatarImage src={userAvatarListUrl(p)} />
                <AvatarFallback className="text-xs font-semibold">{(p.name || '?')[0]}</AvatarFallback>
              </Avatar>
              <div className="min-w-0 flex-1 flex flex-col items-start">
                <span className="text-sm font-semibold truncate w-full">{p.name}</span>
                {p.username ? (
                  <span className="text-[11px] text-muted-foreground truncate w-full">@{p.username}</span>
                ) : null}
              </div>
            </button>
          ))
        )}
      </div>
    </div>
  );
}
