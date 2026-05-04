import * as React from 'react';
import { cn } from '@/lib/utils';

/**
 * Презентационная копия настройки в стиле `settings/privacy/page.tsx`:
 * лейбл, подсказка и стилизованный «свитч». Не интерактивна — только
 * визуал. Использует ту же типографику и обводку, что и Switch UI.
 */
export function MockSwitchRow({
  label,
  hint,
  on,
  className,
}: {
  label: string;
  hint?: string;
  on?: boolean;
  className?: string;
}) {
  return (
    <div
      className={cn(
        'flex items-center justify-between gap-3 rounded-2xl border border-black/5 dark:border-white/10 bg-background/60 px-3 py-2.5',
        className
      )}
    >
      <div className="min-w-0 flex-1">
        <p className="truncate text-sm font-semibold text-foreground">{label}</p>
        {hint ? <p className="truncate text-[11px] text-muted-foreground">{hint}</p> : null}
      </div>
      <span
        className={cn(
          'relative inline-flex h-5 w-9 shrink-0 items-center rounded-full transition-colors',
          on ? 'bg-primary' : 'bg-muted-foreground/30'
        )}
        aria-hidden
      >
        <span
          className={cn(
            'absolute h-4 w-4 rounded-full bg-white shadow transition-transform',
            on ? 'translate-x-[18px]' : 'translate-x-[2px]'
          )}
        />
      </span>
    </div>
  );
}
