'use client';

import * as React from 'react';
import { Ban, EyeOff, Lock, Timer } from 'lucide-react';
import { cn } from '@/lib/utils';
import { useI18n } from '@/hooks/use-i18n';
import { MockChatHeader, MockChatInput } from '../mocks/mock-chat-header';
import { MockMessageBubble } from '../mocks/mock-message-bubble';
import { getFeaturesContent } from '../features-content';

/** Мини-чат «секретного» режима: обычный чат + три плашки-«правила» снизу. */
export function MockSecretChats({
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
      <MockChatHeader name={t.groupProject} status={t.secretStatus} />
      <div className="flex flex-1 flex-col gap-1.5 overflow-hidden p-3">
        <MockMessageBubble side="incoming" text={t.secretMsg1} time="14:02" delayMs={0} />
        <MockMessageBubble side="outgoing" text={t.secretMsg2} time="14:03" delayMs={300} />
        {!compact ? (
          <div className="mt-auto grid grid-cols-3 gap-1.5">
            {[
              { icon: Timer, color: 'text-violet-500 dark:text-violet-300', border: 'border-violet-400/30', bg: 'bg-violet-400/10' },
              { icon: EyeOff, color: 'text-rose-500 dark:text-rose-300', border: 'border-rose-400/30', bg: 'bg-rose-400/10' },
              { icon: Lock, color: 'text-amber-500 dark:text-amber-300', border: 'border-amber-400/30', bg: 'bg-amber-400/10' },
            ].map((c, i) => {
              const Icon = c.icon;
              return (
                <div
                  key={i}
                  className={cn(
                    'animate-feat-bubble-in flex items-center justify-center rounded-xl border px-2 py-2',
                    c.border,
                    c.bg
                  )}
                  style={{ animationDelay: `${600 + i * 120}ms` }}
                >
                  <Icon className={cn('h-4 w-4', c.color)} aria-hidden />
                </div>
              );
            })}
          </div>
        ) : (
          <div className="mt-auto flex justify-center gap-1.5">
            <Timer className="h-3.5 w-3.5 text-violet-500" aria-hidden />
            <Ban className="h-3.5 w-3.5 text-rose-500" aria-hidden />
            <Lock className="h-3.5 w-3.5 text-amber-500" aria-hidden />
          </div>
        )}
      </div>
      {!compact ? <MockChatInput placeholder={t.peerHello} /> : null}
    </div>
  );
}
