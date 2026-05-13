import * as React from 'react';
import { Check, CheckCheck } from 'lucide-react';
import { cn } from '@/lib/utils';

export type MockBubbleProps = {
  side: 'incoming' | 'outgoing';
  text: string;
  time?: string;
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
 *  - outgoing: `bg-primary text-primary-foreground` (как реальный чат);
 *  - incoming: `bg-muted` (как реальный чат);
 *  - tail-clip через `rounded-{tr|tl}-none` (square corner вверху);
 *  - время + двойная галочка отрисованы **под пузырём** отдельной строкой,
 *    как в реальном UI LighChat (не внутри пузыря).
 */
export function MockMessageBubble({
  side,
  text,
  time = '12:34',
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
        'flex w-full flex-col gap-0.5',
        incoming ? 'items-start' : 'items-end',
        animateIn && 'animate-feat-bubble-in',
        className
      )}
      style={animateIn ? { animationDelay: `${delayMs}ms` } : undefined}
    >
      <div
        className={cn(
          // Реальный `ChatMessageItem` использует `text-sm` (14px) по умолчанию;
          // финальный размер настраивается пользователем через `chatSettings.fontSize`.
          'relative max-w-[78%] px-3 py-2 text-sm leading-snug shadow-sm rounded-2xl',
          // Реальный ChatMessageItem использует rounded-tr-none/tl-none для «хвостика».
          withTail && (incoming ? 'rounded-tl-none' : 'rounded-tr-none'),
          incoming
            ? 'bg-muted text-foreground'
            : 'bg-primary text-primary-foreground'
        )}
      >
        {text}
      </div>
      {/* Meta под пузырём: время + галочки, как в реальном LighChat. */}
      <span
        className={cn(
          'inline-flex items-center gap-0.5 px-1 text-[10px] text-muted-foreground'
        )}
      >
        <span>{time}</span>
        {!incoming
          ? read
            ? <CheckCheck className="h-3 w-3 text-primary" aria-hidden />
            : <Check className="h-3 w-3" aria-hidden />
          : null}
      </span>
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
