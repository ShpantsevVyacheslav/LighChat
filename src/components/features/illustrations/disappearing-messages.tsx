import * as React from 'react';
import { EyeOff } from 'lucide-react';
import { cn } from '@/lib/utils';
import { MockChatHeader, MockChatInput } from '../mocks/mock-chat-header';
import { MockMessageBubble } from '../mocks/mock-message-bubble';

/** Чат с исчезающими сообщениями: цепочка, в которой старые баблы тают. */
export function MockDisappearing({
  className,
  compact,
}: {
  className?: string;
  compact?: boolean;
}) {
  return (
    <div className={cn('relative flex h-full w-full flex-col', className)}>
      <MockChatHeader name="Команда · Дизайн" status="исчезают через 24 ч" withTimer timerLabel="24 ч" />
      <div className="flex flex-1 flex-col gap-1.5 overflow-hidden p-3">
        <MockMessageBubble side="incoming" text="Делюсь черновиком — потом удалится." time="09:14" delayMs={0} />
        <MockMessageBubble side="outgoing" text="Ок, дам комментарии до вечера." time="09:15" delayMs={250} />
        <MockMessageBubble
          side="incoming"
          text="Цвет хедера лучше тёмный."
          time="09:16"
          fading
          vanishing
          animateIn={false}
        />
        <MockMessageBubble
          side="outgoing"
          text="Согласен. Применю и пушну."
          time="09:18"
          fading
          vanishing
          animateIn={false}
        />
        {!compact ? (
          <div className="mt-auto flex items-center gap-2 self-center rounded-full border border-rose-400/40 bg-rose-400/10 px-3 py-1 text-[11px] font-semibold text-rose-500 dark:text-rose-300">
            <EyeOff className="h-3.5 w-3.5" aria-hidden />
            Сообщения исчезают через 24 часа
          </div>
        ) : null}
      </div>
      {!compact ? <MockChatInput /> : null}
    </div>
  );
}
