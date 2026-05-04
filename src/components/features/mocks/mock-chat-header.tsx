import * as React from 'react';
import { Lock, Timer } from 'lucide-react';
import { cn } from '@/lib/utils';

export function MockChatHeader({
  name,
  status,
  withLock,
  withTimer,
  timerLabel,
  className,
}: {
  name: string;
  status: string;
  withLock?: boolean;
  withTimer?: boolean;
  timerLabel?: string;
  className?: string;
}) {
  const initial = name.charAt(0).toUpperCase();
  return (
    <div
      className={cn(
        'flex items-center gap-3 px-4 py-3',
        'border-b border-black/5 dark:border-white/10',
        'bg-background/40 backdrop-blur-md',
        className
      )}
    >
      <div className="relative h-9 w-9 shrink-0">
        <div className="flex h-9 w-9 items-center justify-center rounded-full bg-gradient-to-br from-primary/70 to-primary text-xs font-bold text-primary-foreground shadow">
          {initial}
        </div>
        <span className="absolute -bottom-0.5 -right-0.5 h-2.5 w-2.5 rounded-full border-2 border-background bg-emerald-400" />
      </div>
      <div className="min-w-0 flex-1">
        <div className="flex items-center gap-1.5">
          <span className="truncate text-sm font-semibold text-foreground">{name}</span>
          {withLock ? <Lock className="h-3 w-3 text-emerald-400" aria-hidden /> : null}
        </div>
        <span className="block truncate text-[11px] text-muted-foreground">{status}</span>
      </div>
      {withTimer ? (
        <div className="flex items-center gap-1 rounded-full border border-violet-400/30 bg-violet-400/10 px-2 py-0.5 text-[10px] font-semibold text-violet-300">
          <Timer className="h-3 w-3" aria-hidden />
          {timerLabel ?? '24 ч'}
        </div>
      ) : null}
    </div>
  );
}
