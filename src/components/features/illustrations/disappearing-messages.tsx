import * as React from 'react';
import { EyeOff } from 'lucide-react';
import { cn } from '@/lib/utils';
import { MockChatHeader } from '../mocks/mock-chat-header';
import { MockMessageBubble } from '../mocks/mock-message-bubble';

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
      <div className="flex flex-1 flex-col gap-2 overflow-hidden p-3">
        <MockMessageBubble side="incoming" text="Делюсь черновиком — потом удалится." time="09:14" />
        <MockMessageBubble side="outgoing" text="Ок, дам комментарии до вечера." time="09:15" />
        <div className="opacity-70">
          <MockMessageBubble side="incoming" text="Кстати, цвет хедера лучше тёмный." time="09:16" fading />
        </div>
        <div className="opacity-40">
          <MockMessageBubble side="outgoing" text="Согласен. Применю и пушну." time="09:18" fading />
        </div>
        {!compact ? (
          <div className="mt-auto flex items-center gap-2 self-center rounded-full border border-rose-400/30 bg-rose-400/10 px-3 py-1 text-[11px] font-semibold text-rose-300">
            <EyeOff className="h-3.5 w-3.5" aria-hidden />
            Сообщения исчезают через 24 часа
          </div>
        ) : null}
      </div>
    </div>
  );
}
