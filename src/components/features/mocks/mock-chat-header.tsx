import * as React from 'react';
import { ArrowLeft, Lock, MessageCircle, Phone, Timer, Video } from 'lucide-react';
import { cn } from '@/lib/utils';

/**
 * Презентационная копия шапки чата (`ChatWindow.tsx`):
 * стрелка назад, аватар (h-11 w-11 в реале — здесь чуть меньше для мокапа),
 * имя/статус, иконки тредов, видеозвонка (зелёный) и аудиозвонка. Опционально
 * показываем замочек (E2EE) рядом с именем и таймер (исчезающие/секретные).
 *
 * Палитра иконок повторяет CHAT_HEADER_IOS из ChatWindow.tsx:
 *   callVideo: text-[#34C759] dark:text-[#48E074]
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
      <button type="button" className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full hover:bg-foreground/5" aria-label="back">
        <ArrowLeft className="h-5 w-5 text-foreground" aria-hidden />
      </button>
      <div className="relative h-11 w-11 shrink-0">
        <div className="flex h-11 w-11 items-center justify-center rounded-full bg-gradient-to-br from-primary to-primary/70 text-sm font-bold text-primary-foreground shadow-sm">
          {initial}
        </div>
        <span className="absolute -bottom-0.5 -right-0.5 h-2.5 w-2.5 rounded-full border-2 border-background bg-emerald-500" />
      </div>
      <div className="min-w-0 flex-1">
        <div className="flex items-center gap-1.5">
          <span className="truncate text-[14px] font-semibold text-foreground">{name}</span>
          {withLock ? <Lock className="h-3 w-3 text-emerald-500 dark:text-emerald-400" aria-hidden /> : null}
        </div>
        <span className="block truncate text-[11px] text-muted-foreground">{status}</span>
      </div>
      {withTimer ? (
        <div className="flex items-center gap-1 rounded-full border border-violet-400/40 bg-violet-400/10 px-2 py-0.5 text-[10px] font-bold text-violet-500 dark:text-violet-300">
          <Timer className="h-3 w-3" aria-hidden />
          {timerLabel ?? '24 ч'}
        </div>
      ) : null}
      {withCallControls ? (
        <>
          <button type="button" className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg hover:bg-foreground/5" aria-label="threads">
            <MessageCircle className="h-[22px] w-[22px] text-foreground/85" strokeWidth={2} aria-hidden />
          </button>
          <button type="button" className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg hover:bg-foreground/5" aria-label="video">
            <Video className="h-[22px] w-[22px] text-[#34C759] dark:text-[#48E074]" strokeWidth={2} aria-hidden />
          </button>
          <button type="button" className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg hover:bg-foreground/5" aria-label="audio">
            <Phone className="h-[22px] w-[22px] text-primary" strokeWidth={2} aria-hidden />
          </button>
        </>
      ) : null}
    </div>
  );
}

/**
 * Презентационная копия `ChatMessageInput`: «+», поле, мигающий курсор,
 * иконки эмодзи и микрофона.
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
