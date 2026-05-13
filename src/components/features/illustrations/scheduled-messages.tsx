'use client';

import * as React from 'react';
import { CalendarClock, Clock } from 'lucide-react';
import { cn } from '@/lib/utils';
import { useI18n } from '@/hooks/use-i18n';
import { MockChatHeader } from '../mocks/mock-chat-header';
import { MockMessageBubble } from '../mocks/mock-message-bubble';
import { getFeaturesContent } from '../features-content';

/**
 * Чат + наезжающий **справа** `ScheduledMessagesSheet` — на web это
 * shadcn `<Sheet side="right">` (см. `ScheduledMessagesSheet.tsx`), не
 * bottom-sheet. Точка входа — `CalendarClock` иконка с бейджем-счётчиком
 * в шапке чата.
 *
 * Сами баблы выглядят как обычные — никаких inline-«scheduled» иконок.
 */
export function MockScheduled({
  className,
  compact,
}: {
  className?: string;
  compact?: boolean;
}) {
  const { locale } = useI18n();
  const t = React.useMemo(() => getFeaturesContent(locale).mockText, [locale]);
  return (
    <div className={cn('relative flex h-full w-full overflow-hidden', className)}>
      {/* Основной чат (слева) — занимает ~60% ширины, остальное даём Sheet */}
      <div className="flex flex-1 flex-col">
        <div className="relative">
          <MockChatHeader name={t.peerMikhail} status={t.mikhailStatus} />
          {/* CalendarClock иконка с бейджем — точка входа в Sheet. */}
          <div className="pointer-events-none absolute right-[164px] top-1/2 -translate-y-1/2">
            <div className="relative animate-feat-clock-glow rounded-xl bg-primary/15 p-1.5">
              <CalendarClock className="h-4 w-4 text-primary" aria-hidden />
              <span className="absolute -right-1 -top-1 flex h-3.5 min-w-[14px] items-center justify-center rounded-full bg-primary px-1 text-[9px] font-bold leading-none text-primary-foreground shadow">
                1
              </span>
            </div>
          </div>
        </div>
        <div className="flex flex-1 flex-col gap-1.5 overflow-hidden p-3">
          <MockMessageBubble side="incoming" text={t.scheduledMsg1} time="20:11" delayMs={0} />
          <MockMessageBubble side="outgoing" text={t.scheduledMsg2} time="20:12" delayMs={250} />
        </div>
      </div>
      {/* Right-side Sheet — наезжает справа (реальный shadcn `<Sheet side="right">`). */}
      {!compact ? (
        <div
          className="relative w-[42%] max-w-[280px] animate-feat-bubble-in flex flex-col border-l border-black/5 dark:border-white/10 bg-background/95 backdrop-blur-2xl shadow-[-12px_0_40px_-12px_rgba(0,0,0,0.35)]"
          style={{ animationDelay: '500ms' }}
        >
          <div className="flex items-center justify-between gap-2 px-3 pt-3 pb-1">
            <p className="text-[12px] font-bold text-foreground">{t.scheduledQueueTitle}</p>
            <span className="rounded-full bg-primary/15 px-2 py-0.5 text-[9px] font-bold uppercase text-primary">
              1
            </span>
          </div>
          <div className="flex flex-1 items-start p-3 pt-1">
            <div className="flex w-full items-start gap-2 rounded-xl border border-black/5 dark:border-white/10 bg-background/60 p-2">
              <div className="flex h-7 w-7 shrink-0 items-center justify-center rounded-lg bg-primary/15">
                <Clock className="h-3.5 w-3.5 text-primary" aria-hidden />
              </div>
              <div className="min-w-0 flex-1">
                <p className="line-clamp-2 text-[11px] font-medium leading-snug text-foreground">
                  {t.scheduledMsg3}
                </p>
                <p className="inline-flex items-center gap-1 text-[9px] text-muted-foreground">
                  <CalendarClock className="h-2.5 w-2.5" aria-hidden />
                  {t.scheduledQueueDate}
                </p>
              </div>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
}
