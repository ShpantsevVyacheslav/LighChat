'use client';

import * as React from 'react';
import { Calendar, Clock, Send } from 'lucide-react';
import { cn } from '@/lib/utils';
import { useI18n } from '@/hooks/use-i18n';
import { MockChatHeader } from '../mocks/mock-chat-header';
import { MockMessageBubble } from '../mocks/mock-message-bubble';
import { getFeaturesContent } from '../features-content';

/**
 * Чат + панель «Запланированные» снизу (по образу `ScheduledMessagesSheet`).
 * В самих баблах нет inline-«scheduled» иконки — расписание видно как
 * отдельная плашка/лист над инпутом.
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
    <div className={cn('relative flex h-full w-full flex-col', className)}>
      <MockChatHeader name={t.peerMikhail} status={t.mikhailStatus} />
      <div className="flex flex-1 flex-col gap-1.5 overflow-hidden p-3">
        <MockMessageBubble side="incoming" text={t.scheduledMsg1} time="20:11" delayMs={0} />
        <MockMessageBubble side="outgoing" text={t.scheduledMsg2} time="20:12" delayMs={250} />
        {!compact ? (
          <div
            className="mt-auto flex items-stretch gap-2 rounded-2xl border border-primary/20 bg-primary/10 p-2 animate-feat-bubble-in"
            style={{ animationDelay: '500ms' }}
          >
            <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-primary/15">
              <Clock className="h-4 w-4 text-primary" aria-hidden />
            </div>
            <div className="min-w-0 flex-1">
              <p className="truncate text-[11px] font-semibold text-primary">{t.scheduledQueueTitle}</p>
              <p className="truncate text-[12px] text-foreground/85">{t.scheduledMsg3}</p>
              <p className="mt-0.5 inline-flex items-center gap-1 text-[10.5px] text-muted-foreground">
                <Calendar className="h-3 w-3" aria-hidden />
                {t.scheduledQueueDate}
              </p>
            </div>
          </div>
        ) : null}
      </div>
      {!compact ? (
        <div className="flex items-center gap-2 border-t border-black/5 dark:border-white/10 bg-background/70 px-3 py-2 backdrop-blur-md">
          <span className="flex-1 truncate text-[12px] text-muted-foreground">
            {t.scheduledMsg3}
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
