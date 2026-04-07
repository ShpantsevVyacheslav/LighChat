'use client';

import React, { useMemo, useState, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { Avatar, AvatarImage, AvatarFallback } from '@/components/ui/avatar';
import { Search, X } from 'lucide-react';
import { format, parseISO } from 'date-fns';
import { ru } from 'date-fns/locale';
import { cn } from '@/lib/utils';
import type { ChatMessage, User } from '@/lib/types';

interface ChatSearchOverlayProps {
  query: string;
  messages: ChatMessage[];
  allUsers: User[];
  onSelectResult: (messageId: string) => void;
  /** Левый край затемнения/blur (px): только колонка чата, без сайдбара списка диалогов. */
  blurInsetLeftPx?: number;
}

/** Отступ сверху под плавающую шапку чата (~h-14 + safe area). */
const SEARCH_OVERLAY_TOP = 'calc(3.5rem + env(safe-area-inset-top, 0px))';

/**
 * Максимальная высота только области списка (под шапкой оверлея + заголовок «Результаты…»).
 * Панель в целом получается по высоте контента, но список скроллится, если не помещается.
 */
const SEARCH_RESULTS_LIST_MAX_H =
  'calc(100dvh - 3.5rem - env(safe-area-inset-top, 0px) - env(safe-area-inset-bottom, 0px) - 5.25rem)';

/** Панель результатов: плотный фон без «стекла», без обводки в светлой теме (не сливается с чатом). */
const SEARCH_RESULTS_SHELL =
  'rounded-2xl border-0 bg-background/[0.97] shadow-lg dark:border dark:border-white/12 dark:bg-background/[0.92]';

/** Строка результата: без рамки в light; в dark — лёгкая граница. */
const SEARCH_RESULT_ROW_FRAME =
  'rounded-xl border-0 bg-background/[0.99] shadow-sm transition-colors hover:bg-background hover:shadow-md active:scale-[0.99] ' +
  'dark:border dark:border-white/12 dark:bg-background/[0.88] dark:hover:bg-background/[0.92] dark:hover:border-white/16';

/**
 * Результаты поиска по сообщениям: портал на передний план, плотная панель без blur ленты,
 * затемнение области чата без backdrop-filter (чат под оверлеем остаётся резким).
 */
export function ChatSearchOverlay({
  query,
  messages,
  allUsers,
  onSelectResult,
  blurInsetLeftPx = 0,
}: ChatSearchOverlayProps) {
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  const searchResults = useMemo(() => {
    if (!query.trim() || query.length < 2) return [];
    return messages
      .filter((m) => {
        if (m.isDeleted) return false;
        const textMatch = m.text?.replace(/<[^>]*>/g, '').toLowerCase().includes(query.toLowerCase());
        return textMatch;
      })
      .reverse();
  }, [messages, query]);

  if (!query || query.length < 2) return null;

  const horizontalOverlayStyle = {
    top: SEARCH_OVERLAY_TOP,
    left: blurInsetLeftPx,
    right: 0,
  } as const;

  const panel = (
    <>
      <div
        className="fixed bottom-0 z-[2100] bg-black/25 dark:bg-black/45"
        style={horizontalOverlayStyle}
        aria-hidden
      />
      <div
        className="pointer-events-none fixed bottom-0 z-[2110] flex flex-col p-3 pt-2"
        style={horizontalOverlayStyle}
      >
        <div
          className={cn(SEARCH_RESULTS_SHELL, 'pointer-events-auto mx-auto flex w-full max-w-2xl flex-col overflow-hidden')}
        >
          <div className="flex shrink-0 items-center justify-between border-b border-black/[0.08] p-3.5 dark:border-white/12">
            <div className="flex items-center gap-2">
              <Search className="h-4 w-4 shrink-0 text-primary" />
              <span className="text-[10px] font-black uppercase tracking-widest text-foreground">
                Результаты поиска: {searchResults.length}
              </span>
            </div>
          </div>
          <div
            className="overflow-y-auto overscroll-y-contain"
            style={{ maxHeight: SEARCH_RESULTS_LIST_MAX_H }}
          >
            <div className="space-y-2 p-2.5 pb-3">
              {searchResults.length > 0 ? (
                searchResults.map((msg) => {
                  const sender = allUsers.find((u) => u.id === msg.senderId);
                  return (
                    <div
                      key={msg.id}
                      role="button"
                      tabIndex={0}
                      onClick={() => onSelectResult(msg.id)}
                      onKeyDown={(e) => {
                        if (e.key === 'Enter' || e.key === ' ') {
                          e.preventDefault();
                          onSelectResult(msg.id);
                        }
                      }}
                      className={cn(
                        SEARCH_RESULT_ROW_FRAME,
                        'flex cursor-pointer items-start gap-3 p-3 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background'
                      )}
                    >
                      <Avatar className="h-9 w-9 shrink-0 dark:border dark:border-white/15">
                        <AvatarImage src={sender?.avatar} className="object-cover" />
                        <AvatarFallback className="text-foreground">{sender?.name?.charAt(0)}</AvatarFallback>
                      </Avatar>
                      <div className="min-w-0 flex-1">
                        <div className="mb-0.5 flex items-start justify-between gap-2">
                          <span className="truncate text-sm font-semibold text-foreground">
                            {sender?.name || 'Участник'}
                          </span>
                          <span className="shrink-0 whitespace-nowrap text-[10px] font-semibold text-foreground/70">
                            {format(parseISO(msg.createdAt), 'dd.MM.yy HH:mm', { locale: ru })}
                          </span>
                        </div>
                        <p className="truncate text-sm leading-snug text-foreground/88">
                          {msg.text?.replace(/<[^>]*>/g, '') || 'Вложение'}
                        </p>
                      </div>
                    </div>
                  );
                })
              ) : (
                <div
                  className={cn(
                    SEARCH_RESULT_ROW_FRAME,
                    'flex flex-col items-center justify-center py-10 text-foreground/80'
                  )}
                >
                  <div className="mb-3 rounded-full bg-background/60 p-3 dark:bg-background/50">
                    <X className="h-8 w-8 text-foreground/70" />
                  </div>
                  <p className="text-xs font-black uppercase tracking-widest text-foreground">Ничего не найдено</p>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </>
  );

  if (!mounted) return null;

  return createPortal(panel, document.body);
}
