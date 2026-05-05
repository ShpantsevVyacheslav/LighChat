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
  /** «Тающее» сообщение: применяется зацикленная анимация. */
  vanishing?: boolean;
  /** Прочитано (двойная галочка). По умолчанию для outgoing — true. */
  read?: boolean;
  /** Стиль клипа «хвостика»: повторяет реальный ChatMessageItem. */
  withTail?: boolean;
  /** Анимировать появление (вход снизу). */
  animateIn?: boolean;
  /** Задержка для staggered. */
  delayMs?: number;
  className?: string;
};

/**
 * Презентационная копия `ChatMessageItem`-бабла:
 * - outgoing: `bg-primary text-primary-foreground` (как реальный чат);
 * - incoming: `bg-muted` (как реальный чат);
 * - tail-clip через `rounded-{tr|tl}-md`;
 * - двойная галочка времени, иконки часов/EyeOff, как в реальной строке meta.
 */
export function MockMessageBubble({
  side,
  text,
  time = '12:34',
  scheduled,
  scheduledHint,
  fading,
  vanishing,
  read = true,
  withTail = true,
  animateIn = true,
  delayMs = 0,
  className,
}: MockBubbleProps) {
  const incoming = side === 'incoming';
  return (
    <div
      className={cn(
        'flex w-full',
        incoming ? 'justify-start' : 'justify-end',
        animateIn && 'animate-feat-bubble-in',
        className
      )}
      style={animateIn ? { animationDelay: `${delayMs}ms` } : undefined}
    >
      <div
        className={cn(
          'relative max-w-[78%] px-3 py-2 text-[13px] leading-snug shadow-sm rounded-2xl',
          // Реальный ChatMessageItem использует rounded-tr-none/tl-none для «хвостика».
          withTail && (incoming ? 'rounded-tl-none' : 'rounded-tr-none'),
          incoming
            ? 'bg-muted text-foreground'
            : 'bg-primary text-primary-foreground',
          fading && 'border border-dashed border-current/30',
          scheduled && 'opacity-90',
          vanishing && 'animate-feat-fade-vanish'
        )}
      >
        <span>{text}</span>
        <span
          className={cn(
            'mt-0.5 ml-2 inline-flex items-center gap-0.5 text-[10px] align-middle',
            incoming ? 'text-muted-foreground' : 'text-primary-foreground/85'
          )}
        >
          {scheduled ? <Clock className="h-2.5 w-2.5" aria-hidden /> : null}
          {fading ? <EyeOff className="h-2.5 w-2.5" aria-hidden /> : null}
          <span>{time}</span>
          {!incoming && !scheduled
            ? read
              ? <CheckCheck className="h-3 w-3" aria-hidden />
              : <Check className="h-3 w-3" aria-hidden />
            : null}
        </span>
        {scheduled && scheduledHint ? (
          <span className="mt-0.5 block text-[10px] italic opacity-85">{scheduledHint}</span>
        ) : null}
      </div>
    </div>
  );
}

/** Печатающий индикатор «∙ ∙ ∙» в стиле incoming-бабла. */
export function MockTypingBubble({ className }: { className?: string }) {
  return (
    <div className={cn('flex w-full justify-start', className)}>
      <div className="flex items-center gap-1 rounded-2xl rounded-tl-none bg-muted px-3 py-2 shadow-sm">
        {[0, 1, 2].map((i) => (
          <span
            key={i}
            className="block h-1.5 w-1.5 rounded-full bg-muted-foreground/70 animate-feat-typing"
            style={{ animationDelay: `${i * 160}ms` }}
          />
        ))}
      </div>
    </div>
  );
}
