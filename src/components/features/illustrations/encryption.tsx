import * as React from 'react';
import { Fingerprint, ShieldCheck } from 'lucide-react';
import { cn } from '@/lib/utils';
import { MockChatHeader, MockChatInput } from '../mocks/mock-chat-header';
import { MockMessageBubble, MockTypingBubble } from '../mocks/mock-message-bubble';

/** Мини-чат с E2EE-баннером и бейджем отпечатка ключа (`E2eeFingerprintBadge`). */
export function MockEncryption({
  className,
  compact,
}: {
  className?: string;
  compact?: boolean;
}) {
  return (
    <div className={cn('relative flex h-full w-full flex-col', className)}>
      <MockChatHeader name="Анна" status="онлайн · в сети" withLock />
      <div className="flex flex-1 flex-col gap-1.5 overflow-hidden p-3">
        {!compact ? (
          <div className="mx-auto mb-1 flex items-center gap-1.5 rounded-full border border-emerald-500/30 bg-emerald-500/10 px-2.5 py-0.5 text-[10px] font-semibold text-emerald-500 dark:text-emerald-400">
            <ShieldCheck className="h-3 w-3" aria-hidden />
            Сообщения зашифрованы
          </div>
        ) : null}
        <MockMessageBubble side="incoming" text="Привет! Это точно ты?" time="12:31" delayMs={0} />
        <MockMessageBubble side="outgoing" text="Я. Сравним отпечаток ключа?" time="12:32" delayMs={300} />
        {!compact ? <MockTypingBubble /> : null}
        <MockMessageBubble side="incoming" text="Совпали — нас никто не слушает." time="12:33" delayMs={650} />
        {!compact ? (
          <div
            className="mt-auto flex items-center gap-2 self-end rounded-2xl border border-emerald-500/30 bg-emerald-500/10 px-2.5 py-1.5 text-[11px] font-semibold text-emerald-600 dark:text-emerald-300 animate-feat-bubble-in"
            style={{ animationDelay: '900ms' }}
          >
            <Fingerprint className="h-3.5 w-3.5" aria-hidden />
            <span className="font-mono">5f2a 8b91 3dcc 70a4</span>
          </div>
        ) : null}
      </div>
      {!compact ? <MockChatInput /> : null}
    </div>
  );
}
