import * as React from 'react';
import { Mic, MicOff, Video, PhoneOff, MessageSquare, Users } from 'lucide-react';
import { cn } from '@/lib/utils';

const TILES = [
  { name: 'Анна', initial: 'А', accent: 'from-rose-500/70 to-rose-700/70' },
  { name: 'Михаил', initial: 'М', accent: 'from-primary/70 to-primary', muted: true },
  { name: 'Юля', initial: 'Ю', accent: 'from-emerald-500/70 to-emerald-700/70', speaking: true },
  { name: 'Костя', initial: 'К', accent: 'from-violet-500/70 to-violet-700/70' },
];

export function MockMeetings({ className, compact }: { className?: string; compact?: boolean }) {
  return (
    <div className={cn('relative flex h-full w-full flex-col gap-2 p-3', className)}>
      {!compact ? (
        <div className="flex items-center justify-between rounded-2xl border border-black/5 dark:border-white/10 bg-background/60 px-3 py-2">
          <div className="flex items-center gap-2 text-xs font-semibold">
            <span className="h-2 w-2 rounded-full bg-rose-500" />
            <span>Встреча · 24:18</span>
          </div>
          <div className="flex items-center gap-1.5 text-[11px] text-muted-foreground">
            <Users className="h-3.5 w-3.5" aria-hidden /> 4
          </div>
        </div>
      ) : null}
      <div className="grid flex-1 grid-cols-2 gap-2">
        {TILES.map((t) => (
          <div
            key={t.name}
            className={cn(
              'relative overflow-hidden rounded-2xl border border-white/10 shadow-inner',
              t.speaking && 'ring-2 ring-emerald-400/70'
            )}
          >
            <div className={cn('absolute inset-0 bg-gradient-to-br opacity-90', t.accent)} />
            <div className="absolute inset-0 bg-black/20" />
            <div className="relative flex h-full items-center justify-center">
              <div className="flex h-10 w-10 items-center justify-center rounded-full bg-white/15 text-base font-bold text-white backdrop-blur-md">
                {t.initial}
              </div>
            </div>
            <div className="absolute bottom-1.5 left-1.5 right-1.5 flex items-center justify-between text-[10px] font-semibold text-white">
              <span className="truncate rounded-md bg-black/40 px-1.5 py-0.5">{t.name}</span>
              {t.muted ? (
                <span className="rounded-md bg-black/40 px-1 py-0.5">
                  <MicOff className="h-3 w-3" aria-hidden />
                </span>
              ) : null}
            </div>
          </div>
        ))}
      </div>
      {!compact ? (
        <div className="flex items-center justify-center gap-2 rounded-full border border-black/5 dark:border-white/10 bg-background/70 px-3 py-2 backdrop-blur-md">
          <button type="button" className="rounded-full bg-foreground/10 p-2" aria-label="mic">
            <Mic className="h-3.5 w-3.5" aria-hidden />
          </button>
          <button type="button" className="rounded-full bg-foreground/10 p-2" aria-label="cam">
            <Video className="h-3.5 w-3.5" aria-hidden />
          </button>
          <button type="button" className="rounded-full bg-foreground/10 p-2" aria-label="chat">
            <MessageSquare className="h-3.5 w-3.5" aria-hidden />
          </button>
          <button type="button" className="rounded-full bg-rose-500 p-2 text-white" aria-label="leave">
            <PhoneOff className="h-3.5 w-3.5" aria-hidden />
          </button>
        </div>
      ) : null}
    </div>
  );
}
