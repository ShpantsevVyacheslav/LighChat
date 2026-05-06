'use client';

import * as React from 'react';
import { cn } from '@/lib/utils';
import { useI18n } from '@/hooks/use-i18n';
import { getFeaturesContent } from '../features-content';

/**
 * Игральная карта в стиле реального `DurakCardWidget`:
 *  - face-up: off-white фон `#F6F7FB`, ранг+масть слева сверху и справа снизу
 *    (повёрнуто), большая масть в центре;
 *  - козырь — жёлтая обводка `#FBBF24`;
 *  - face-down: тёмно-синий градиент `#2C3E66 → #1A2540` с белым кругом.
 */
function PlayingCard({
  rank,
  suit,
  red,
  trump,
  faceDown,
  className,
  style,
}: {
  rank?: string;
  suit?: string;
  red?: boolean;
  trump?: boolean;
  faceDown?: boolean;
  className?: string;
  style?: React.CSSProperties;
}) {
  if (faceDown) {
    return (
      <div
        className={cn(
          'relative rounded-[10px] p-1 shadow-[0_6px_14px_-4px_rgba(0,0,0,0.45)]',
          className,
        )}
        style={style}
      >
        <div
          className="flex h-full w-full items-center justify-center rounded-md border border-white/15"
          style={{ background: 'linear-gradient(135deg,#2C3E66,#1A2540)' }}
        >
          <span className="block h-3 w-3 rounded-full border border-white/30 bg-white/15" />
        </div>
      </div>
    );
  }
  const fg = red ? '#DC2626' : '#111827';
  return (
    <div
      className={cn(
        'relative rounded-[12px] border bg-[#F6F7FB] shadow-[0_6px_14px_-4px_rgba(0,0,0,0.4)]',
        trump ? 'border-[#FBBF24]/55' : 'border-black/15',
        className,
      )}
      style={style}
    >
      <div className="absolute left-1.5 top-1 text-left leading-none" style={{ color: fg, fontWeight: 900 }}>
        <div className="text-[10px]">{rank}</div>
        <div className="text-[12px]">{suit}</div>
      </div>
      <div
        className="absolute inset-0 flex items-center justify-center text-[28px]"
        style={{ color: fg, fontWeight: 900 }}
      >
        {suit}
      </div>
      <div
        className="absolute bottom-1 right-1.5 rotate-180 text-left leading-none"
        style={{ color: fg, fontWeight: 900 }}
      >
        <div className="text-[10px]">{rank}</div>
        <div className="text-[12px]">{suit}</div>
      </div>
    </div>
  );
}

/** Аватар игрока в реальном стиле: круглый, имя сверху, счёт карт справа. */
function PlayerStrip({
  name,
  initial,
  cards,
  active,
  align,
}: {
  name: string;
  initial: string;
  cards: number;
  active?: boolean;
  align: 'left' | 'right';
}) {
  return (
    <div
      className={cn(
        'flex items-center gap-1.5 rounded-full border px-2 py-1 text-[10px] font-semibold backdrop-blur-md',
        active
          ? 'border-amber-300/70 bg-amber-400/15 text-amber-100 ring-2 ring-amber-300/40'
          : 'border-white/15 bg-black/40 text-white/85',
        align === 'right' && 'flex-row-reverse',
      )}
    >
      <span
        className={cn(
          'flex h-5 w-5 items-center justify-center rounded-full text-[10px] font-bold',
          active ? 'bg-amber-300 text-amber-950' : 'bg-white/20 text-white',
        )}
      >
        {initial}
      </span>
      <span className="truncate">{name}</span>
      <span className="rounded-full bg-white/15 px-1.5 py-px text-[9px] font-bold">{cards}</span>
    </div>
  );
}

export function MockGames({ className, compact }: { className?: string; compact?: boolean }) {
  const { locale } = useI18n();
  const t = React.useMemo(() => getFeaturesContent(locale).mockText, [locale]);

  // Пары на столе: атака внизу, защита поверх со смещением.
  const pairs: { atk: { rank: string; suit: string; red?: boolean }; def?: { rank: string; suit: string; red?: boolean } }[] = [
    { atk: { rank: '7', suit: '♣' }, def: { rank: '9', suit: '♣' } },
    { atk: { rank: '10', suit: '♦', red: true }, def: { rank: 'Q', suit: '♦', red: true } },
    { atk: { rank: 'J', suit: '♠' } },
  ];

  // Рука игрока: 6 карт веером, козыри подсвечены.
  const hand: { rank: string; suit: string; red?: boolean; trump?: boolean }[] = [
    { rank: '6', suit: '♠' },
    { rank: '8', suit: '♥', red: true },
    { rank: '9', suit: '♥', red: true, trump: true },
    { rank: 'J', suit: '♥', red: true, trump: true },
    { rank: 'Q', suit: '♣' },
    { rank: 'A', suit: '♦', red: true },
  ];

  return (
    <div className={cn('relative h-full w-full overflow-hidden', className)}>
      {/* Зелёное игровое сукно (как в реальном экране) */}
      <div className="absolute inset-0" style={{ background: 'radial-gradient(ellipse at 50% 40%,#1F5F47 0%,#0F2D24 65%,#081C16 100%)' }} />
      <div className="absolute inset-3 rounded-[24px] border border-emerald-300/15 bg-emerald-900/20 shadow-[inset_0_0_40px_rgba(0,0,0,0.4)]" />

      <div className="relative flex h-full w-full flex-col p-3">
        {/* Верх: оппонент + бейдж «ваш ход» */}
        <div className="flex items-start justify-between">
          <PlayerStrip name={t.gamesOpponent} initial="A" cards={5} align="left" />
          {!compact ? (
            <div className="rounded-full bg-amber-300/95 px-2.5 py-1 text-[10px] font-bold text-amber-950 shadow animate-feat-bubble-in">
              {t.gamesYourTurn}
            </div>
          ) : null}
        </div>

        {/* Карты оппонента сверху (рубашкой) */}
        <div className="mt-1 flex justify-center">
          {Array.from({ length: 5 }).map((_, i) => (
            <PlayingCard
              key={i}
              faceDown
              className="-ml-3 first:ml-0 h-10 w-7 animate-feat-card-deal"
              style={{
                transform: `rotate(${(i - 2) * 6}deg)`,
                animationDelay: `${i * 80}ms`,
              }}
            />
          ))}
        </div>

        {/* Стол (пары) и колода+козырь сбоку */}
        <div className="relative mt-2 flex-1">
          {/* Колода + козырь слева (как у боевого экрана) */}
          <div className="absolute left-2 top-1/2 -translate-y-1/2 flex flex-col items-center gap-1">
            <div className="relative h-12 w-9">
              {/* Стопка-колода */}
              <PlayingCard faceDown className="absolute inset-0" />
              <PlayingCard faceDown className="absolute inset-0 -translate-x-0.5 -translate-y-0.5" />
              {/* Лежащий «козырь» снизу под наклоном */}
              <PlayingCard
                rank="J"
                suit="♥"
                red
                trump
                className="absolute -bottom-2 left-2 h-9 w-7 rotate-90"
              />
            </div>
            <div className="rounded-full bg-black/40 px-2 py-0.5 text-[9px] font-bold text-white backdrop-blur-md">
              {t.gamesDeck} · 12
            </div>
          </div>

          {/* Пары на столе по центру */}
          <div className="absolute left-1/2 top-1/2 flex -translate-x-1/2 -translate-y-1/2 gap-3">
            {pairs.map((p, i) => (
              <div
                key={i}
                className="relative h-16 w-11 animate-feat-card-deal"
                style={{ animationDelay: `${400 + i * 200}ms` }}
              >
                <PlayingCard
                  rank={p.atk.rank}
                  suit={p.atk.suit}
                  red={p.atk.red}
                  className="absolute inset-0"
                />
                {p.def ? (
                  <PlayingCard
                    rank={p.def.rank}
                    suit={p.def.suit}
                    red={p.def.red}
                    className="absolute left-2.5 top-2.5 h-16 w-11 rotate-[8deg]"
                    style={{ animationDelay: `${600 + i * 200}ms` }}
                  />
                ) : (
                  <span className="absolute left-2.5 top-2.5 flex h-16 w-11 items-center justify-center rounded-[12px] border border-dashed border-white/40 text-white/55">
                    +
                  </span>
                )}
              </div>
            ))}
          </div>
        </div>

        {/* Действия + рука */}
        {!compact ? (
          <div className="mb-1 flex items-center gap-1.5">
            <button
              type="button"
              className="flex-1 rounded-xl bg-emerald-500 py-1.5 text-[11px] font-bold text-white shadow"
            >
              {t.gamesActionBeat}
            </button>
            <button
              type="button"
              className="flex-1 rounded-xl border border-white/20 bg-white/10 py-1.5 text-[11px] font-bold text-white"
            >
              {t.gamesActionTake}
            </button>
          </div>
        ) : null}

        <div className="relative h-16">
          {hand.map((c, i) => {
            // Веер: equally spaced rotation; центр в i=2.5
            const offset = i - (hand.length - 1) / 2;
            const rotate = offset * 8;
            return (
              <PlayingCard
                key={i}
                rank={c.rank}
                suit={c.suit}
                red={c.red}
                trump={c.trump}
                className="absolute bottom-0 h-16 w-11 origin-bottom animate-feat-card-deal"
                style={{
                  left: `calc(50% + ${offset * 26}px - 22px)`,
                  transform: `translateY(${Math.abs(offset) * 1.5}px) rotate(${rotate}deg)`,
                  animationDelay: `${800 + i * 100}ms`,
                }}
              />
            );
          })}
        </div>
      </div>
    </div>
  );
}
