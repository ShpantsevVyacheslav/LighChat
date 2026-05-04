import * as React from 'react';
import { cn } from '@/lib/utils';

/**
 * Рамка-«экран» для мокапов: повторяет визуальный язык приложения
 * (стеклянный фон + лёгкая обводка + большой радиус). Сами мокапы лежат
 * внутри без логики и подписок — статичная композиция реальных стилей.
 */
export function FeatureMockFrame({
  children,
  className,
  innerClassName,
  ratio = 'aspect-[16/10]',
}: {
  children: React.ReactNode;
  className?: string;
  innerClassName?: string;
  /** Tailwind-класс пропорций рамки. Для thumbnail можно передать 'aspect-[4/3]'. */
  ratio?: string;
}) {
  return (
    <div
      className={cn(
        'relative overflow-hidden rounded-[28px]',
        'border border-black/5 dark:border-white/10',
        'bg-gradient-to-br from-background/80 via-background/60 to-background/40',
        'shadow-[0_30px_80px_-30px_rgba(0,0,0,0.35)]',
        ratio,
        className
      )}
    >
      <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_20%_-10%,hsl(var(--primary)/0.18),transparent_55%),radial-gradient(circle_at_85%_110%,hsl(var(--accent)/0.18),transparent_55%)]" />
      <div className={cn('relative z-10 flex h-full w-full', innerClassName)}>{children}</div>
    </div>
  );
}
