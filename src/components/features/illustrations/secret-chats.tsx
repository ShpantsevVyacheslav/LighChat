import * as React from 'react';
import { Timer, Ban, EyeOff } from 'lucide-react';
import { cn } from '@/lib/utils';
import { MockChatHeader } from '../mocks/mock-chat-header';
import { MockMessageBubble } from '../mocks/mock-message-bubble';

export function MockSecretChats({
  className,
  compact,
}: {
  className?: string;
  compact?: boolean;
}) {
  return (
    <div className={cn('relative flex h-full w-full flex-col', className)}>
      <MockChatHeader name="Группа · Проект" status="секретный · 6 участников" withLock withTimer timerLabel="1 ч" />
      <div className="flex flex-1 flex-col gap-2 overflow-hidden p-3">
        <MockMessageBubble side="incoming" text="Файл с ценой — пришлю одним просмотром." time="14:02" fading />
        {!compact ? (
          <div className="self-start rounded-2xl border border-violet-400/30 bg-violet-400/10 px-2.5 py-1.5 text-[11px] font-semibold text-violet-300">
            <span className="inline-flex items-center gap-1.5">
              <EyeOff className="h-3.5 w-3.5" aria-hidden /> Фото · одноразовый просмотр
            </span>
          </div>
        ) : null}
        <MockMessageBubble side="outgoing" text="Принял. Запрет на пересылку и копию включён." time="14:03" />
        {!compact ? (
          <div className="mt-1 grid grid-cols-2 gap-2">
            <div className="flex items-center gap-2 rounded-xl border border-black/5 dark:border-white/10 bg-background/60 px-2.5 py-2 text-[11px]">
              <Timer className="h-3.5 w-3.5 text-violet-300" aria-hidden />
              <div className="leading-tight">
                <p className="font-semibold text-foreground">Таймер 1 ч</p>
                <p className="text-muted-foreground">после прочтения</p>
              </div>
            </div>
            <div className="flex items-center gap-2 rounded-xl border border-black/5 dark:border-white/10 bg-background/60 px-2.5 py-2 text-[11px]">
              <Ban className="h-3.5 w-3.5 text-rose-400" aria-hidden />
              <div className="leading-tight">
                <p className="font-semibold text-foreground">Без пересылки</p>
                <p className="text-muted-foreground">и копирования</p>
              </div>
            </div>
          </div>
        ) : null}
      </div>
    </div>
  );
}
