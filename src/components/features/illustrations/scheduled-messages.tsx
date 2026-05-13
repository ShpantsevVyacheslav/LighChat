'use client';

import * as React from 'react';
import { CalendarClock, Clock } from 'lucide-react';
import { cn } from '@/lib/utils';
import { useI18n } from '@/hooks/use-i18n';
import { MockChatHeader } from '../mocks/mock-chat-header';
import { MockMessageBubble } from '../mocks/mock-message-bubble';
import { getFeaturesContent } from '../features-content';

/**
 * Чат + наезжающий снизу `ScheduledMessagesSheet`. Реально это
 * Bottom Sheet с drag-handle сверху, открывается по `CalendarClock`-иконке
 * в шапке (бейдж со счётчиком ожидающих) — мы повторяем оба элемента.
 *
 * Сами баблы выглядят как обычные — никаких inline-«scheduled» иконок в
 * баблах в реальном UI нет.
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
    <div className={cn('relative flex h-full w-full flex-col overflow-hidden', className)}>
      <div className="relative">
        <MockChatHeader name={t.peerMikhail} status={t.mikhailStatus} />
        {/* CalendarClock иконка с бейджем — реальная точка входа в Sheet. */}
        <div className="pointer-events-none absolute right-[124px] top-1/2 -translate-y-1/2">
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
      {/* Bottom Sheet — наезжает снизу с drag-handle. */}
      {!compact ? (
        <div
          className="relative animate-feat-bubble-in rounded-t-[24px] border-t border-x border-black/5 dark:border-white/10 bg-background/95 backdrop-blur-2xl shadow-[0_-12px_40px_-12px_rgba(0,0,0,0.35)]"
          style={{ animationDelay: '500ms' }}
        >
          {/* Drag handle */}
          <div className="flex justify-center pt-2">
            <span className="block h-1.5 w-12 rounded-full bg-foreground/25" />
          </div>
          <div className="flex items-center justify-between gap-2 px-4 pb-2 pt-2.5">
            <p className="text-[12px] font-bold text-foreground">{t.scheduledQueueTitle}</p>
            <span className="rounded-full bg-primary/15 px-2 py-0.5 text-[9px] font-bold uppercase text-primary">
              1
            </span>
          </div>
          <div className="flex items-stretch gap-2 px-4 pb-3">
            <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-primary/15">
              <Clock className="h-4 w-4 text-primary" aria-hidden />
            </div>
            <div className="min-w-0 flex-1 rounded-xl border border-black/5 dark:border-white/10 bg-background/60 px-2.5 py-1.5">
              <p className="truncate text-[12px] font-medium text-foreground">
                {t.scheduledMsg3}
              </p>
              <p className="inline-flex items-center gap-1 text-[10px] text-muted-foreground">
                <CalendarClock className="h-2.5 w-2.5" aria-hidden />
                {t.scheduledQueueDate}
              </p>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
}
