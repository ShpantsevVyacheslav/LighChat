'use client';

import * as React from 'react';
import { Ban, EyeOff, Lock, Timer } from 'lucide-react';
import { Switch } from '@/components/ui/switch';
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
      <MockChatHeader name={t.groupProject} status={t.secretStatus} withLock />
      <div className="flex flex-1 flex-col gap-1.5 overflow-hidden p-3">
        <MockMessageBubble side="incoming" text={t.secretMsg1} time="14:02" delayMs={0} />
        <MockMessageBubble side="outgoing" text={t.secretMsg2} time="14:03" delayMs={300} />
        {!compact ? (
          // Имитация `SecretChatSettingsDialog`: три switch-row с реальными
          // настройками — таймер, запрет пересылки, замок чата.
          <div className="mt-auto flex flex-col gap-1 rounded-2xl border border-violet-400/25 bg-violet-400/[0.05] p-1.5">
            <p className="px-2 pt-0.5 text-[9px] font-bold uppercase tracking-wide text-violet-500 dark:text-violet-300">
              {t.secretSettingsTitle}
            </p>
            {[
              { icon: Timer, label: t.secretSettingTtl, value: t.secretSettingTtlValue, on: true },
              { icon: EyeOff, label: t.secretSettingNoForward, on: true },
              { icon: Lock, label: t.secretSettingLock, on: false },
            ].map((row, i) => {
              const Icon = row.icon;
              return (
                <div
                  key={i}
                  className="animate-feat-bubble-in flex items-center gap-2 rounded-xl bg-background/55 px-2 py-1"
                  style={{ animationDelay: `${600 + i * 120}ms` }}
                >
                  <Icon className="h-3.5 w-3.5 shrink-0 text-violet-500 dark:text-violet-300" aria-hidden />
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-[11px] font-semibold text-foreground">{row.label}</p>
                    {row.value ? (
                      <p className="truncate text-[10px] text-muted-foreground">{row.value}</p>
                    ) : null}
                  </div>
                  <Switch checked={row.on} aria-readonly className="pointer-events-none scale-75" />
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
