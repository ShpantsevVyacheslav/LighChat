import * as React from 'react';
import { Check, CheckCheck, Clock, EyeOff } from 'lucide-react';
import { cn } from '@/lib/utils';

export type MockBubbleProps = {
  side: 'incoming' | 'outgoing';
  text: string;
  time?: string;
  /** Сообщение «в очереди»: значок часов, мягкая прозрачность. */
  scheduled?: boolean;
  scheduledHint?: string;
  /** Исчезающее сообщение: пунктир и затухание. */
  fading?: boolean;
  /** Прочитано (двойная галочка). По умолчанию для outgoing — true. */
  read?: boolean;
  className?: string;
};

export function MockMessageBubble({
  side,
  text,
  time = '12:34',
  scheduled,
  scheduledHint,
  fading,
  read = true,
  className,
}: MockBubbleProps) {
  const incoming = side === 'incoming';
  return (
    <div
      className={cn(
        'flex w-full',
        incoming ? 'justify-start' : 'justify-end',
        className
      )}
    >
      <div
        className={cn(
          'relative max-w-[78%] rounded-2xl px-3 py-2 text-sm leading-snug shadow-sm',
          incoming
            ? 'rounded-bl-sm bg-background/80 text-foreground border border-black/5 dark:border-white/10'
            : 'rounded-br-sm bg-primary text-primary-foreground',
          fading && 'border-dashed opacity-60',
          scheduled && 'opacity-80'
        )}
      >
        <span>{text}</span>
        <span
          className={cn(
            'mt-0.5 ml-2 inline-flex items-center gap-0.5 text-[10px] align-middle',
            incoming ? 'text-muted-foreground' : 'text-primary-foreground/80'
          )}
        >
          {scheduled ? <Clock className="h-2.5 w-2.5" aria-hidden /> : null}
          {fading ? <EyeOff className="h-2.5 w-2.5" aria-hidden /> : null}
          <span>{time}</span>
          {!incoming && !scheduled
            ? read
              ? <CheckCheck className="h-2.5 w-2.5" aria-hidden />
              : <Check className="h-2.5 w-2.5" aria-hidden />
            : null}
        </span>
        {scheduled && scheduledHint ? (
          <span className="mt-1 block text-[10px] italic opacity-80">{scheduledHint}</span>
        ) : null}
      </div>
    </div>
  );
}
