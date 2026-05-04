import * as React from 'react';
import { cn } from '@/lib/utils';

const SUITS = [
  { glyph: '♠', color: 'text-foreground' },
  { glyph: '♥', color: 'text-rose-500' },
  { glyph: '♦', color: 'text-rose-500' },
  { glyph: '♣', color: 'text-foreground' },
];

function Card({
  rank,
  suitIdx,
  rotate,
  className,
}: {
  rank: string;
  suitIdx: number;
  rotate: number;
  className?: string;
}) {
  const s = SUITS[suitIdx % SUITS.length];
  return (
    <div
      className={cn(
        'absolute origin-bottom flex flex-col justify-between rounded-lg border border-black/10 bg-white text-foreground shadow-[0_8px_18px_-6px_rgba(0,0,0,0.4)] dark:bg-zinc-100',
        'h-20 w-14 px-1.5 py-1 sm:h-24 sm:w-16 sm:px-2 sm:py-1.5',
        className
      )}
      style={{ transform: `rotate(${rotate}deg)` }}
    >
      <div className={cn('text-left text-[10px] font-bold leading-none', s.color)}>
        <div>{rank}</div>
        <div className="text-[12px]">{s.glyph}</div>
      </div>
      <div className={cn('self-end text-right text-[10px] font-bold leading-none rotate-180', s.color)}>
        <div>{rank}</div>
        <div className="text-[12px]">{s.glyph}</div>
      </div>
    </div>
  );
}

export function MockGames({ className, compact }: { className?: string; compact?: boolean }) {
  const cards = [
    { rank: '6', s: 0, r: -28, x: -68, y: 0 },
    { rank: '7', s: 1, r: -14, x: -34, y: -8 },
    { rank: 'В', s: 2, r: 0, x: 0, y: -12 },
    { rank: 'Д', s: 3, r: 14, x: 34, y: -8 },
    { rank: 'К', s: 0, r: 28, x: 68, y: 0 },
  ];
  return (
    <div className={cn('relative flex h-full w-full items-center justify-center overflow-hidden', className)}>
      <div className="absolute inset-0 bg-gradient-to-br from-emerald-700/40 via-emerald-800/30 to-emerald-900/50" />
      <div className="absolute inset-3 rounded-[24px] border border-emerald-300/20 bg-emerald-900/20" />
      {!compact ? (
        <div className="absolute left-3 top-3 rounded-full bg-amber-400/90 px-2 py-0.5 text-[10px] font-bold text-amber-950 shadow">
          Дурак · ход Анны
        </div>
      ) : null}
      <div className="relative h-32 w-72 sm:h-40 sm:w-80">
        {cards.map((c, i) => (
          <Card
            key={i}
            rank={c.rank}
            suitIdx={c.s}
            rotate={c.r}
            className="left-1/2 top-1/2 -translate-x-1/2"
          />
        ))}
      </div>
      {!compact ? (
        <div className="absolute bottom-3 left-3 right-3 flex items-center justify-between rounded-2xl border border-white/10 bg-black/30 px-3 py-2 text-[11px] text-white backdrop-blur-md">
          <span>Козырь · ♥</span>
          <span className="opacity-80">В колоде · 12</span>
        </div>
      ) : null}
    </div>
  );
}
