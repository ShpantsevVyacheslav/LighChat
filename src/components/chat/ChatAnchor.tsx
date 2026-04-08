'use client';

import React, { useEffect, useState } from 'react';
import { createPortal } from 'react-dom';
import { Button } from '@/components/ui/button';
import { ChevronDown } from 'lucide-react';
import { cn } from '@/lib/utils';

interface ChatAnchorProps {
  isVisible: boolean;
  unreadCount: number;
  lastReaction: { emoji: string; messageId: string } | null;
  onClick: () => void;
  onNavigateToReaction: () => void;
  /** Не показывать кнопку (оверлей профиля, медиапросмотр, document fullscreen — z-index якоря выше листов). */
  suppressed?: boolean;
}

/**
 * Продвинутая кнопка прокрутки (Якорь).
 * Логика:
 * 1. Счётчик непрочитанных (в открытом чате — по данным ленты, см. родитель).
 * 2. Реакция: клик ведёт к сообщению с реакцией.
 * 3. Непрочитанные: первый клик — к первому непрочитанному, второй — к низу и сброс (обрабатывает ChatWindow).
 *
 * Рендер через портал в document.body + fixed + высокий z-index, чтобы список Virtuoso и оверлеи
 * не перехватывали касания. Кольцо focus-visible убираем — иначе видна «синяя обводка».
 */
export function ChatAnchor({ 
  isVisible, 
  unreadCount, 
  lastReaction, 
  onClick, 
  onNavigateToReaction,
  suppressed = false,
}: ChatAnchorProps) {
  const [mounted, setMounted] = useState(false);
  useEffect(() => setMounted(true), []);

  if (suppressed) return null;
  if (!isVisible && unreadCount === 0 && !lastReaction) return null;
  if (!mounted || typeof document === 'undefined') return null;

  const node = (
    <div
      className="pointer-events-auto fixed z-[10050] flex flex-col items-center gap-2 animate-in zoom-in-95 duration-300"
      style={{
        /** Выше строки ввода: ~высота панели (редактор + отступы) + зазор ~12px + safe-area */
        bottom:
          'calc(5.75rem + max(0.75rem, env(safe-area-inset-bottom, 0px)))',
        right: 'max(1.5rem, env(safe-area-inset-right, 0px))',
      }}
    >
      <Button
        type="button"
        size="icon"
        variant="ghost"
        className={cn(
          'rounded-full h-12 w-12 touch-manipulation shadow-2xl bg-background/30 backdrop-blur-xl border border-white/10 transition-all active:scale-90 hover:bg-background/50',
          'ring-0 ring-offset-0 focus-visible:ring-0 focus-visible:ring-offset-0 outline-none',
          unreadCount > 0 ? 'text-primary border-primary/20 bg-primary/5' : 'text-muted-foreground',
          lastReaction && 'scale-110'
        )}
        onClick={(e) => {
          e.preventDefault();
          e.stopPropagation();
          if (lastReaction) {
            onNavigateToReaction();
          } else {
            onClick();
          }
        }}
      >
        <div className="relative flex items-center justify-center w-full h-full">
          {lastReaction ? (
            <span className="text-xl animate-bounce">{lastReaction.emoji}</span>
          ) : (
            <>
              <ChevronDown className={cn("h-6 w-6 transition-transform", unreadCount > 0 && "animate-bounce")} />
              {unreadCount > 0 && (
                <span className="absolute -top-2 -right-1 bg-red-500 text-white text-[10px] font-black h-5 min-w-[20px] px-1.5 rounded-full flex items-center justify-center border-2 border-background shadow-lg">
                  {unreadCount > 99 ? '99+' : unreadCount}
                </span>
              )}
            </>
          )}
        </div>
      </Button>
    </div>
  );

  return createPortal(node, document.body);
}