import * as React from 'react';
import { Ban, EyeOff, Lock, Timer } from 'lucide-react';
import { cn } from '@/lib/utils';
import { MockChatHeader, MockChatInput } from '../mocks/mock-chat-header';
import { MockMessageBubble } from '../mocks/mock-message-bubble';

/** Мини-чат «секретного» режима: тёмный TTL-таймер, плашки запретов, view-once медиа. */
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
      <div className="flex flex-1 flex-col gap-1.5 overflow-hidden p-3">
        <MockMessageBubble
          side="incoming"
          text="Файл с ценой — пришлю одним просмотром."
          time="14:02"
          fading
          delayMs={0}
        />
        {!compact ? (
          <div
            className="self-start animate-feat-bubble-in rounded-2xl rounded-tl-md border border-violet-400/40 bg-violet-400/10 px-2.5 py-1.5 text-[11px] font-semibold text-violet-500 dark:text-violet-300"
            style={{ animationDelay: '300ms' }}
          >
            <span className="inline-flex items-center gap-1.5">
              <EyeOff className="h-3.5 w-3.5" aria-hidden /> Фото · одноразовый просмотр
            </span>
          </div>
        ) : null}
        <MockMessageBubble side="outgoing" text="Принял. Запрет копий включён." time="14:03" delayMs={550} />
        {!compact ? (
          <div className="mt-auto grid grid-cols-3 gap-1.5">
            {[
              { icon: Timer, label: 'Таймер 1 ч', sub: 'после прочтения', color: 'text-violet-500 dark:text-violet-300', border: 'border-violet-400/30', bg: 'bg-violet-400/10' },
              { icon: Ban, label: 'Без пересылки', sub: 'и копирования', color: 'text-rose-500 dark:text-rose-300', border: 'border-rose-400/30', bg: 'bg-rose-400/10' },
              { icon: Lock, label: 'Замок', sub: 'Face ID / пароль', color: 'text-amber-500 dark:text-amber-300', border: 'border-amber-400/30', bg: 'bg-amber-400/10' },
            ].map((c, i) => {
              const Icon = c.icon;
              return (
                <div
                  key={c.label}
                  className={cn(
                    'animate-feat-bubble-in flex items-center gap-2 rounded-xl border px-2 py-1.5 text-[10.5px]',
                    c.border,
                    c.bg
                  )}
                  style={{ animationDelay: `${750 + i * 120}ms` }}
                >
                  <Icon className={cn('h-3.5 w-3.5 shrink-0', c.color)} aria-hidden />
                  <div className="min-w-0 leading-tight">
                    <p className={cn('font-semibold truncate', c.color)}>{c.label}</p>
                    <p className="text-muted-foreground truncate">{c.sub}</p>
                  </div>
                </div>
              );
            })}
          </div>
        ) : null}
      </div>
      {!compact ? <MockChatInput placeholder="Сообщение исчезнет через 1 ч" /> : null}
    </div>
  );
}
