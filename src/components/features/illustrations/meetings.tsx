import * as React from 'react';
import { Hand, Mic, MicOff, MoreHorizontal, PhoneOff, ScreenShare, Users, Video } from 'lucide-react';
import { cn } from '@/lib/utils';

const TILES = [
  { name: 'Анна', initial: 'А', accent: 'from-rose-500/85 to-rose-700/85' },
  { name: 'Михаил', initial: 'М', accent: 'from-primary/85 to-primary', muted: true },
  { name: 'Юля', initial: 'Ю', accent: 'from-emerald-500/85 to-emerald-700/85', speaking: true },
  { name: 'Костя', initial: 'К', accent: 'from-violet-500/85 to-violet-700/85' },
];

/** Видеовстреча: 16:9 тайлы (как `MeetingParticipantTileStage`), пульсация активного спикера, контролы. */
export function MockMeetings({ className, compact }: { className?: string; compact?: boolean }) {
  return (
    <div className={cn('relative flex h-full w-full flex-col gap-2 p-3', className)}>
      {!compact ? (
        <div className="flex items-center justify-between rounded-2xl border border-black/5 dark:border-white/10 bg-background/70 px-3 py-2">
          <div className="flex items-center gap-2 text-xs font-semibold">
            <span className="h-2 w-2 rounded-full bg-rose-500 animate-pulse" />
            <span>Встреча · 24:18</span>
          </div>
          <div className="flex items-center gap-1.5 text-[11px] text-muted-foreground">
            <Users className="h-3.5 w-3.5" aria-hidden /> 4
          </div>
        </div>
      ) : null}
      <div className="grid flex-1 grid-cols-2 gap-2">
        {TILES.map((t, i) => (
          <div
            key={t.name}
            className={cn(
              'relative aspect-video overflow-hidden rounded-2xl border border-white/10 shadow-inner animate-feat-bubble-in',
              t.speaking && 'animate-feat-speaker-pulse'
            )}
            style={{ animationDelay: `${i * 100}ms` }}
          >
            <div className={cn('absolute inset-0 bg-gradient-to-br opacity-95', t.accent)} />
            <div className="absolute inset-0 bg-black/20" />
            <div className="relative flex h-full items-center justify-center">
              <div className="flex h-12 w-12 items-center justify-center rounded-full bg-white/15 text-base font-bold text-white backdrop-blur-md">
                {t.initial}
              </div>
            </div>
            <div className="absolute bottom-1.5 left-1.5 right-1.5 flex items-center justify-between gap-1 text-[10px] font-semibold text-white">
              <span className="inline-flex items-center gap-1 truncate rounded-md bg-black/45 px-1.5 py-0.5 backdrop-blur-md">
                {t.muted ? <MicOff className="h-3 w-3" aria-hidden /> : <Mic className="h-3 w-3" aria-hidden />}
                <span className="truncate">{t.name}</span>
              </span>
              {t.speaking ? (
                <span className="rounded-md bg-emerald-500/90 px-1 py-0.5 text-[9px]">говорит</span>
              ) : null}
            </div>
          </div>
        ))}
      </div>
      {!compact ? (
        <div className="flex items-center justify-center gap-2 rounded-full border border-black/5 dark:border-white/10 bg-background/80 px-3 py-2 backdrop-blur-md">
          <button type="button" className="rounded-full bg-foreground/10 p-2 text-foreground/80" aria-label="mic">
            <Mic className="h-3.5 w-3.5" aria-hidden />
          </button>
          <button type="button" className="rounded-full bg-foreground/10 p-2 text-foreground/80" aria-label="cam">
            <Video className="h-3.5 w-3.5" aria-hidden />
          </button>
          <button type="button" className="rounded-full bg-foreground/10 p-2 text-foreground/80" aria-label="share">
            <ScreenShare className="h-3.5 w-3.5" aria-hidden />
          </button>
          <button type="button" className="rounded-full bg-foreground/10 p-2 text-foreground/80" aria-label="hand">
            <Hand className="h-3.5 w-3.5" aria-hidden />
          </button>
          <button type="button" className="rounded-full bg-foreground/10 p-2 text-foreground/80" aria-label="more">
            <MoreHorizontal className="h-3.5 w-3.5" aria-hidden />
          </button>
          <button type="button" className="rounded-full bg-rose-500 p-2 text-white shadow" aria-label="leave">
            <PhoneOff className="h-3.5 w-3.5" aria-hidden />
          </button>
        </div>
      ) : null}
    </div>
  );
}
