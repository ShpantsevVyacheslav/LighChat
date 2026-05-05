import * as React from 'react';
import { ChevronLeft, Lock, MoreHorizontal, Phone, ShieldCheck, Timer, Video } from 'lucide-react';
import { cn } from '@/lib/utils';

/**
 * Презентационная копия шапки чата (`ChatWindow` + `ChatParticipantProfile`):
 * стрелка назад, аватар с онлайн-точкой, имя/статус, иконки звонка/видео и
 * меню. Опционально — замок (E2EE) и таймер (исчезающие/секретные).
 */
export function MockChatHeader({
  name,
  status,
  withLock,
  withTimer,
  timerLabel,
  withCallControls = true,
  className,
}: {
  name: string;
  status: string;
  withLock?: boolean;
  withTimer?: boolean;
  timerLabel?: string;
  withCallControls?: boolean;
  className?: string;
}) {
  const initial = name.charAt(0).toUpperCase();
  return (
    <div
      className={cn(
        'flex items-center gap-2 px-3 py-2',
        'border-b border-black/5 dark:border-white/10',
        'bg-background/70 backdrop-blur-md',
        className
      )}
    >
      <ChevronLeft className="h-4 w-4 shrink-0 text-muted-foreground" aria-hidden />
      <div className="relative h-9 w-9 shrink-0">
        <div className="flex h-9 w-9 items-center justify-center rounded-full bg-gradient-to-br from-primary to-primary/70 text-xs font-bold text-primary-foreground shadow-sm">
          {initial}
        </div>
        <span className="absolute -bottom-0.5 -right-0.5 h-2.5 w-2.5 rounded-full border-2 border-background bg-emerald-500" />
      </div>
      <div className="min-w-0 flex-1">
        <div className="flex items-center gap-1.5">
          <span className="truncate text-[13px] font-semibold text-foreground">{name}</span>
          {withLock ? (
            <span className="inline-flex items-center gap-0.5 rounded-full bg-emerald-500/15 px-1.5 py-0.5 text-[9px] font-bold text-emerald-500 dark:text-emerald-400">
              <ShieldCheck className="h-2.5 w-2.5" aria-hidden />
              E2EE
            </span>
          ) : null}
        </div>
        <span className="block truncate text-[10.5px] text-muted-foreground">{status}</span>
      </div>
      {withTimer ? (
        <div className="flex items-center gap-1 rounded-full border border-violet-400/40 bg-violet-400/10 px-2 py-0.5 text-[10px] font-bold text-violet-500 dark:text-violet-300">
          <Timer className="h-3 w-3" aria-hidden />
          {timerLabel ?? '24 ч'}
        </div>
      ) : null}
      {withCallControls ? (
        <>
          <button type="button" className="rounded-full p-1.5 text-muted-foreground hover:bg-foreground/5" aria-label="phone">
            <Phone className="h-4 w-4" aria-hidden />
          </button>
          <button type="button" className="rounded-full p-1.5 text-muted-foreground hover:bg-foreground/5" aria-label="video">
            <Video className="h-4 w-4" aria-hidden />
          </button>
        </>
      ) : null}
      <button type="button" className="rounded-full p-1.5 text-muted-foreground hover:bg-foreground/5" aria-label="more">
        <MoreHorizontal className="h-4 w-4" aria-hidden />
      </button>
    </div>
  );
}

/**
 * Презентационная копия строки ввода (`ChatMessageInput`): «+», поле,
 * мигающий курсор, иконки эмодзи и микрофона. Без логики — просто визуал.
 */
export function MockChatInput({
  placeholder = 'Сообщение',
  className,
}: {
  placeholder?: string;
  className?: string;
}) {
  return (
    <div
      className={cn(
        'flex items-center gap-2 border-t border-black/5 dark:border-white/10 bg-background/70 px-3 py-2 backdrop-blur-md',
        className
      )}
    >
      <button type="button" className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-foreground/5 text-foreground/70" aria-label="attach">
        <Lock className="hidden" aria-hidden />
        <span className="text-base font-semibold">+</span>
      </button>
      <div className="flex h-9 flex-1 items-center gap-2 rounded-full border border-black/5 dark:border-white/10 bg-background/80 px-3">
        <span className="flex-1 truncate text-[12px] text-muted-foreground">
          {placeholder}
          <span className="ml-1 inline-block h-3 w-px bg-foreground/70 animate-feat-caret align-middle" />
        </span>
        <span className="text-base text-muted-foreground">😊</span>
      </div>
      <button type="button" className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-primary text-primary-foreground" aria-label="send">
        <span className="text-sm">🎙</span>
      </button>
    </div>
  );
}
