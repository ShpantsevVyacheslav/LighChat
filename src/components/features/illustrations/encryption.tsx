import * as React from 'react';
import { ShieldCheck, Lock } from 'lucide-react';
import { cn } from '@/lib/utils';
import { MockChatHeader } from '../mocks/mock-chat-header';
import { MockMessageBubble } from '../mocks/mock-message-bubble';

export function MockEncryption({
  className,
  compact,
}: {
  className?: string;
  compact?: boolean;
}) {
  return (
    <div className={cn('relative flex h-full w-full flex-col', className)}>
      <MockChatHeader name="Анна" status="онлайн · защищено" withLock />
      <div className="flex flex-1 flex-col gap-2 overflow-hidden p-3">
        {!compact ? (
          <div className="mx-auto mb-1 flex items-center gap-1.5 rounded-full border border-emerald-400/30 bg-emerald-400/10 px-2 py-0.5 text-[10px] font-semibold text-emerald-300">
            <ShieldCheck className="h-3 w-3" aria-hidden />
            Сообщения зашифрованы сквозным шифрованием
          </div>
        ) : null}
        <MockMessageBubble side="incoming" text="Привет! Это точно ты?" time="12:31" />
        <MockMessageBubble
          side="outgoing"
          text="Я. Сравним отпечатки ключей в карточке устройства."
          time="12:32"
        />
        <MockMessageBubble side="incoming" text="Совпали — значит, нас никто не слушает." time="12:33" />
        {!compact ? (
          <div className="mt-auto flex items-center gap-2 self-end rounded-2xl border border-emerald-400/30 bg-emerald-400/10 px-2.5 py-1.5 text-[11px] font-semibold text-emerald-300">
            <Lock className="h-3.5 w-3.5" aria-hidden />
            Отпечаток · 5F2A · 8B91 · 3DCC
          </div>
        ) : null}
      </div>
    </div>
  );
}
