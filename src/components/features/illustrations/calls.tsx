import * as React from 'react';
import { Mic, PhoneOff, Video } from 'lucide-react';
import { cn } from '@/lib/utils';

const EQ_CLASSES = [
  'animate-feat-eq-1',
  'animate-feat-eq-2',
  'animate-feat-eq-3',
  'animate-feat-eq-4',
];

function Equalizer() {
  return (
    <div className="flex h-4 items-end gap-0.5">
      {Array.from({ length: 14 }).map((_, i) => (
        <span
          key={i}
          className={cn('block w-0.5 rounded-sm bg-emerald-500 dark:bg-emerald-400', EQ_CLASSES[i % EQ_CLASSES.length])}
          style={{ animationDelay: `${(i * 80) % 600}ms` }}
        />
      ))}
    </div>
  );
}

/** Аудио-звонок (pill-баннер как `AudioCallOverlay`) + видео-кружок (`VideoCirclePlayer`). */
export function MockCalls({ className, compact }: { className?: string; compact?: boolean }) {
  return (
    <div className={cn('relative flex h-full w-full items-center justify-center p-4', className)}>
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_center,hsl(var(--primary)/0.18),transparent_70%)]" />
      <div className="relative flex w-full max-w-sm flex-col items-center gap-3">
        <div className="flex items-center gap-3 self-stretch rounded-3xl border border-emerald-500/25 bg-emerald-500/10 px-4 py-3 backdrop-blur-md">
          <div className="flex h-10 w-10 items-center justify-center rounded-full bg-gradient-to-br from-emerald-400 to-emerald-600 text-sm font-bold text-emerald-950">
            А
          </div>
          <div className="min-w-0 flex-1">
            <p className="text-sm font-semibold text-foreground">Анна · аудио-звонок</p>
            <p className="text-[11px] text-muted-foreground">3:42 · качество HD · E2EE</p>
          </div>
          <Equalizer />
        </div>
        {!compact ? (
          <div className="flex items-center gap-3">
            <div className="relative h-24 w-24 shrink-0 overflow-hidden rounded-full border-4 border-background shadow-2xl animate-feat-bubble-in">
              <div className="absolute inset-0 bg-gradient-to-br from-violet-500 to-primary" />
              <div className="absolute inset-0 flex items-center justify-center text-3xl font-bold text-white drop-shadow">
                М
              </div>
              <div className="absolute bottom-1 right-1 rounded-full bg-black/55 p-1 backdrop-blur-md">
                <Video className="h-2.5 w-2.5 text-white" aria-hidden />
              </div>
              <div className="pointer-events-none absolute inset-0 ring-2 ring-emerald-400/0 animate-feat-speaker-pulse rounded-full" />
            </div>
            <div className="leading-tight">
              <p className="text-sm font-semibold text-foreground">Видео-кружок</p>
              <p className="text-[11px] text-muted-foreground">0:42 / 1:00 · автозапуск</p>
              <p className="mt-1 text-[10px] uppercase tracking-wider text-emerald-500 dark:text-emerald-400">e2ee</p>
            </div>
          </div>
        ) : null}
        {!compact ? (
          <div className="flex items-center gap-2 rounded-full border border-black/5 dark:border-white/10 bg-background/80 px-3 py-2">
            <button type="button" className="rounded-full bg-foreground/10 p-2" aria-label="mic">
              <Mic className="h-3.5 w-3.5" aria-hidden />
            </button>
            <button type="button" className="rounded-full bg-foreground/10 p-2" aria-label="cam">
              <Video className="h-3.5 w-3.5" aria-hidden />
            </button>
            <button type="button" className="rounded-full bg-rose-500 p-2 text-white" aria-label="end">
              <PhoneOff className="h-3.5 w-3.5" aria-hidden />
            </button>
          </div>
        ) : null}
      </div>
    </div>
  );
}
