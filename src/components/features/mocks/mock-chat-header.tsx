import * as React from 'react';
import { ChevronLeft, MessageCircle, Phone, Search, Video } from 'lucide-react';
import type { LucideIcon } from 'lucide-react';
import { cn } from '@/lib/utils';

/**
 * iOS-стиль шапки чата LighChat (см. реальный `ChatWindow` на мобилке):
 *  - стрелка-back в круглой полупрозрачной пилюле;
 *  - аватар с маленькой online-точкой;
 *  - имя + статус под ним (как «Last seen yesterday»);
 *  - 4 круглые иконки-чипа: треды, поиск, видео, телефон.
 */
function HeaderChip({
  icon: Icon,
  className,
}: {
  icon: LucideIcon;
  className?: string;
}) {
  return (
    <span
      className={cn(
        'flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-black/30 text-white',
        className,
      )}
    >
      <Icon className="h-4 w-4" aria-hidden />
    </span>
  );
}

export function MockChatHeader({
  name,
  status,
  className,
}: {
  name: string;
  status: string;
  className?: string;
}) {
  const initial = name.charAt(0).toUpperCase();
  return (
    <div
      className={cn(
        'flex items-center gap-2 px-3 py-2',
        'border-b border-black/5 dark:border-white/10',
        'bg-background/70 backdrop-blur-md',
        className,
      )}
    >
      <HeaderChip icon={ChevronLeft} />
      <div className="relative h-10 w-10 shrink-0">
        <div className="flex h-10 w-10 items-center justify-center rounded-full bg-gradient-to-br from-primary to-primary/70 text-sm font-bold text-primary-foreground shadow-sm">
          {initial}
        </div>
        <span className="absolute -bottom-0.5 -right-0.5 h-2.5 w-2.5 rounded-full border-2 border-background bg-emerald-500" />
      </div>
      <div className="min-w-0 flex-1">
        <span className="block truncate text-[14px] font-semibold text-foreground">{name}</span>
        <span className="block truncate text-[11px] text-muted-foreground">{status}</span>
      </div>
      <HeaderChip icon={MessageCircle} />
      <HeaderChip icon={Search} />
      <HeaderChip icon={Video} />
      <HeaderChip icon={Phone} />
    </div>
  );
}

/**
 * Презентационная копия `ChatMessageInput`: «+», поле, мигающий курсор,
 * иконки эмодзи и микрофона.
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
