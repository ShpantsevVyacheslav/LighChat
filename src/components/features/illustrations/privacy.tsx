import * as React from 'react';
import { Shield } from 'lucide-react';
import { cn } from '@/lib/utils';

/**
 * Privacy-страница в реальной стилистике (`settings/privacy/page.tsx`):
 * заголовок-плашка + ряд `MockSwitchRow`, в одной строке тумблер сам
 * перещёлкивается, чтобы сцена не выглядела статично.
 */
function AnimatedSwitchRow({
  label,
  hint,
  on,
  animateToggle,
  delayMs,
}: {
  label: string;
  hint?: string;
  on: boolean;
  animateToggle?: boolean;
  delayMs: number;
}) {
  return (
    <div
      className="flex items-center justify-between gap-3 rounded-2xl border border-black/5 dark:border-white/10 bg-background/70 px-3 py-2.5 animate-feat-bubble-in"
      style={{ animationDelay: `${delayMs}ms` }}
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
            'absolute h-4 w-4 rounded-full bg-white shadow',
            animateToggle ? 'animate-feat-switch-toggle' : on ? 'translate-x-[18px]' : 'translate-x-[2px]'
          )}
        />
      </span>
    </div>
  );
}

export function MockPrivacy({ className, compact }: { className?: string; compact?: boolean }) {
  return (
    <div className={cn('relative flex h-full w-full flex-col gap-2 p-3', className)}>
      <div className="flex items-center gap-2 rounded-2xl border border-primary/20 bg-primary/10 px-3 py-2">
        <Shield className="h-4 w-4 text-primary" aria-hidden />
        <div className="leading-tight">
          <p className="text-xs font-semibold text-foreground">Приватность</p>
          <p className="text-[10px] text-muted-foreground">Решайте, что видят другие.</p>
        </div>
      </div>
      <div className="grid flex-1 gap-1.5 overflow-hidden">
        <AnimatedSwitchRow label="Статус «онлайн»" hint="Видят, что вы сейчас в сети" on delayMs={0} />
        <AnimatedSwitchRow label="Был в сети" hint="Точное время последнего визита" on={false} animateToggle delayMs={120} />
        <AnimatedSwitchRow label="Отчёты о прочтении" hint="Двойная галочка собеседнику" on delayMs={240} />
        {!compact ? (
          <>
            <AnimatedSwitchRow label="Глобальный поиск" hint="Найти вас по имени могут все" on={false} delayMs={360} />
            <AnimatedSwitchRow label="Добавление в группы" hint="Только из контактов" on delayMs={480} />
          </>
        ) : null}
      </div>
    </div>
  );
}
