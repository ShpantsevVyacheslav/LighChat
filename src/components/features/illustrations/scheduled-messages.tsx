import * as React from 'react';
import { Calendar, Clock, Send } from 'lucide-react';
import { cn } from '@/lib/utils';
import { MockChatHeader } from '../mocks/mock-chat-header';
import { MockMessageBubble } from '../mocks/mock-message-bubble';

/** Чат с отложенным сообщением: пилюля очереди + отдельный «scheduled» бабл. */
export function MockScheduled({
  className,
  compact,
}: {
  className?: string;
  compact?: boolean;
}) {
  return (
    <div className={cn('relative flex h-full w-full flex-col', className)}>
      <MockChatHeader name="Михаил" status="был сегодня в 21:40" />
      <div className="flex flex-1 flex-col gap-1.5 overflow-hidden p-3">
        <MockMessageBubble side="incoming" text="Не забудь напомнить про планёрку." time="20:11" delayMs={0} />
        <MockMessageBubble side="outgoing" text="Уже поставил отправку на утро." time="20:12" delayMs={250} />
        <MockMessageBubble
          side="outgoing"
          text="Доброе утро! Через 15 минут начинаем планёрку."
          time="08:45"
          scheduled
          scheduledHint="Отправится завтра в 08:45"
          delayMs={550}
        />
        {!compact ? (
          <div
            className="mt-auto flex items-center justify-between rounded-2xl border border-primary/20 bg-primary/10 px-3 py-2 text-[11px] text-primary animate-feat-bubble-in"
            style={{ animationDelay: '850ms' }}
          >
            <span className="inline-flex items-center gap-1.5 font-semibold">
              <Clock className="h-3.5 w-3.5" aria-hidden />
              В очереди · 1 сообщение
            </span>
            <span className="inline-flex items-center gap-1 opacity-80">
              <Calendar className="h-3.5 w-3.5" aria-hidden />
              завтра, 08:45
            </span>
          </div>
        ) : null}
      </div>
      {!compact ? (
        <div className="flex items-center gap-2 border-t border-black/5 dark:border-white/10 bg-background/70 px-3 py-2 backdrop-blur-md">
          <span className="flex-1 truncate text-[12px] text-muted-foreground">
            Доброе утро! Через 15 минут начинаем планёрку.
          </span>
          <button
            type="button"
            className="flex h-9 w-9 items-center justify-center rounded-full bg-primary text-primary-foreground animate-feat-clock-glow"
            aria-label="schedule"
          >
            <Send className="h-4 w-4" aria-hidden />
          </button>
        </div>
      ) : null}
    </div>
  );
}
