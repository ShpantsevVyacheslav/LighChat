import * as React from 'react';
import { ChevronLeft, Lock, MessageCircle, Mic, Paperclip, Phone, Smile, Video } from 'lucide-react';
import type { LucideIcon } from 'lucide-react';
import { cn } from '@/lib/utils';

/**
 * Шапка чата как в реальном `ChatWindow.tsx` LighChat: `chatHeaderIconGlass`
 * стеклянный chip + цвета SF Symbols-style. Никаких круглых `bg-black/30`-чипов.
 *
 * Source-of-truth: `chatHeaderIconGlass` =
 *   "rounded-xl bg-background/28 dark:bg-background/20 backdrop-blur-md shadow-sm"
 * CHAT_HEADER_IOS = {
 *   threads:   text-[#007AFF] dark:text-[#64B5FF]
 *   callVideo: text-[#34C759] dark:text-[#48E074]
 *   callAudio: text-[#34C759] dark:text-[#48E074]
 * }
 */
const CHIP_GLASS =
  'rounded-xl bg-background/28 dark:bg-background/20 backdrop-blur-md shadow-sm';

function HeaderChip({
  icon: Icon,
  className,
  iconClassName,
}: {
  icon: LucideIcon;
  className?: string;
  iconClassName?: string;
}) {
  // Размеры синхронизированы с реальным `ChatWindow` (h-[22px] w-[22px]
  // на иконке внутри chatHeaderIconGlass-чипа).
  return (
    <div className={cn('p-0.5', CHIP_GLASS, className)}>
      <div className="flex h-8 w-8 items-center justify-center">
        <Icon className={cn('h-[22px] w-[22px]', iconClassName)} strokeWidth={2} aria-hidden />
      </div>
    </div>
  );
}

export function MockChatHeader({
  name,
  status,
  className,
  /** Для DM-чатов реальный UI показывает иконку тредов; групповые без неё. */
  withThreads = true,
  /** Маленькая иконка замка рядом с именем — для секретных и E2EE-чатов. */
  withLock = false,
}: {
  name: string;
  status: string;
  className?: string;
  withThreads?: boolean;
  withLock?: boolean;
}) {
  const initial = name.charAt(0).toUpperCase();
  return (
    <div
      className={cn(
        // Реальный header использует gap-1 между chip-иконками и gap-2
        // у user-блока. Здесь делаем единый gap-1 для consistency.
        'flex items-center gap-1 px-3 py-2',
        'border-b border-black/5 dark:border-white/10',
        'bg-background/70 backdrop-blur-md',
        className,
      )}
    >
      <HeaderChip icon={ChevronLeft} iconClassName="text-foreground/85" />
      {/* Аватар h-11 w-11 — как в реальном `ChatWindow` (Avatar component). */}
      <div className="relative ml-1 h-11 w-11 shrink-0">
        <div className="flex h-11 w-11 items-center justify-center rounded-full bg-gradient-to-br from-primary to-primary/70 text-sm font-bold text-primary-foreground shadow-sm">
          {initial}
        </div>
        <span className="absolute -bottom-0.5 -right-0.5 h-2.5 w-2.5 rounded-full border-2 border-background bg-emerald-500" />
      </div>
      <div className="ml-1 min-w-0 flex-1">
        <div className="flex items-center gap-1.5">
          <span className="truncate text-[14px] font-semibold text-foreground">{name}</span>
          {withLock ? (
            <Lock
              className="h-3 w-3 shrink-0 text-emerald-500 dark:text-emerald-400"
              aria-hidden
            />
          ) : null}
        </div>
        <span className="block truncate text-[11px] text-muted-foreground">{status}</span>
      </div>
      {withThreads ? (
        <HeaderChip
          icon={MessageCircle}
          iconClassName="text-[#007AFF] dark:text-[#64B5FF]"
        />
      ) : null}
      <HeaderChip
        icon={Video}
        iconClassName="text-[#34C759] dark:text-[#48E074]"
      />
      <HeaderChip
        icon={Phone}
        iconClassName="text-[#34C759] dark:text-[#48E074]"
      />
    </div>
  );
}

/**
 * Презентационная копия `ChatMessageInput`: иконка `Paperclip` (attach)
 * без фона, поле с placeholder и мигающим курсором, иконка эмодзи (`Smile`)
 * справа в поле, и круглая `Mic`-кнопка primary справа.
 */
export function MockChatInput({
  placeholder,
  className,
}: {
  placeholder: string;
  className?: string;
}) {
  return (
    <div
      className={cn(
        'flex items-center gap-2 border-t border-black/5 dark:border-white/10 bg-background/70 px-3 py-2 backdrop-blur-md',
        className,
      )}
    >
      <button
        type="button"
        className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full text-muted-foreground hover:bg-foreground/5"
        aria-label="attach"
      >
        <Paperclip className="h-4 w-4" aria-hidden />
      </button>
      <div className="flex h-9 flex-1 items-center gap-2 rounded-full border border-black/5 dark:border-white/10 bg-background/80 px-3">
        <span className="flex-1 truncate text-[12px] text-muted-foreground">
          {placeholder}
          <span className="ml-1 inline-block h-3 w-px bg-foreground/70 animate-feat-caret align-middle" />
        </span>
        <Smile className="h-4 w-4 text-muted-foreground" aria-hidden />
      </div>
      <button
        type="button"
        className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-primary text-primary-foreground"
        aria-label="record"
      >
        <Mic className="h-4 w-4" aria-hidden />
      </button>
    </div>
  );
}
