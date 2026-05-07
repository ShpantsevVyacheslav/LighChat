'use client';

import * as React from 'react';
import { Plus } from 'lucide-react';
import { cn } from '@/lib/utils';
import { useI18n } from '@/hooks/use-i18n';
import { getFeaturesContent } from '../features-content';

/**
 * Игральная карта в стиле реального `DurakCardWidget`:
 *  - face-up: off-white фон `#F6F7FB`, ОДИН большой символ масти по центру,
 *    ранг+масть в левом-верхнем углу одной строкой («7♠»), и тот же блок
 *    повёрнутый на 180° в правом-нижнем;
 *  - козырь — жёлтая обводка `#FBBF24` + жёлтое свечение тени;
 *  - face-down: тёмно-синий градиент `#2C3E66 → #1A2540` с белым кругом
 *    в центре (как в реальном `_Back`).
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
        'relative rounded-[10px] border bg-[#F6F7FB] shadow-[0_6px_14px_-4px_rgba(0,0,0,0.45)]',
        trump ? 'border-[#FBBF24]/65 shadow-[0_0_10px_rgba(251,191,36,0.30)]' : 'border-black/15',
        className,
      )}
      style={style}
    >
      <span
        className="absolute left-1 top-0.5 leading-none"
        style={{ color: fg, fontWeight: 900, fontSize: 10 }}
      >
        {rank}
        {suit}
      </span>
      <span
        className="absolute inset-0 flex items-center justify-center leading-none"
        style={{ color: fg, fontWeight: 900, fontSize: 22 }}
      >
        {suit}
      </span>
      <span
        className="absolute bottom-0.5 right-1 rotate-180 leading-none"
        style={{ color: fg, fontWeight: 900, fontSize: 10 }}
      >
        {rank}
        {suit}
      </span>
    </div>
  );
}

/**
 * Анимированный мокап «Дурака» в стиле реального экрана LighChat:
 *  – дно стола: радиальный градиент сине-серый (`DurakFeltBackground`);
 *  – сверху аватар-индикатор оппонента с ringом «ход»;
 *  – колода-стопка слева + козырь под наклоном НАД ней (как в реале);
 *  – по центру 3 слота на пары: атака → защита, повторяется три раза,
 *    затем «не отбился» — все карты улетают к проигравшему оппоненту;
 *  – внизу — рука игрока (8 карт ровным рядом, козыри жёлтым).
 */
export function MockGames({ className, compact }: { className?: string; compact?: boolean }) {
  const { locale } = useI18n();
  const t = React.useMemo(() => getFeaturesContent(locale).mockText, [locale]);

  // Пары на столе: 3 атаки + 3 защиты, появляются по очереди.
  const pairs: {
    atk: { rank: string; suit: string; red?: boolean };
    def: { rank: string; suit: string; red?: boolean };
  }[] = [
    { atk: { rank: '7', suit: '♣' }, def: { rank: '9', suit: '♣' } },
    { atk: { rank: '10', suit: '♦', red: true }, def: { rank: 'Q', suit: '♦', red: true } },
    { atk: { rank: 'J', suit: '♠' }, def: { rank: 'K', suit: '♠' } },
  ];

  // Рука игрока — 8 карт, плотно прижатых рядом, козыри подсвечены.
  const hand: { rank: string; suit: string; red?: boolean; trump?: boolean }[] = [
    { rank: '6', suit: '♠' },
    { rank: '8', suit: '♥', red: true },
    { rank: '9', suit: '♥', red: true, trump: true },
    { rank: 'J', suit: '♥', red: true, trump: true },
    { rank: 'Q', suit: '♣' },
    { rank: 'K', suit: '♠' },
    { rank: '10', suit: '♦', red: true },
    { rank: 'A', suit: '♦', red: true },
  ];

  return (
    <div className={cn('relative h-full w-full overflow-hidden', className)}>
      {/* Реальный фон стола: радиальный сине-серый + виньетка */}
      <div
        className="absolute inset-0"
        style={{
          background:
            'radial-gradient(ellipse at 20% 10%, #5F86A1 0%, #253F52 55%, #0B121B 100%)',
        }}
      />
      {/* Лёгкий шум-сетка */}
      <div
        className="absolute inset-0 opacity-[0.08] mix-blend-overlay"
        style={{
          backgroundImage:
            'radial-gradient(circle at 1px 1px, rgba(255,255,255,0.6) 1px, transparent 0)',
          backgroundSize: '6px 6px',
        }}
      />

      <div className="relative flex h-full w-full flex-col p-2.5">
        {/* Top: аватар оппонента (с ring «ход») + бейдж счётчика карт */}
        <div className="flex items-start justify-center">
          <div className="relative">
            <div
              className={cn(
                'flex h-9 w-9 items-center justify-center rounded-full bg-gradient-to-br from-rose-500 to-rose-700 text-xs font-extrabold text-white',
                'ring-2 ring-emerald-400/85 ring-offset-2 ring-offset-transparent animate-feat-durak-loser-glow',
              )}
            >
              {t.peerAlice.charAt(0)}
            </div>
            <span className="absolute -right-1 -top-1 flex h-4 min-w-[16px] items-center justify-center rounded-full bg-black/60 px-1 text-[9px] font-bold text-white shadow">
              5
            </span>
            <p className="mt-1 text-center text-[9px] font-bold leading-tight text-white/95">
              {t.peerAlice}
            </p>
            <p className="text-center text-[8px] font-semibold text-emerald-300">
              {t.gamesYourTurn}
            </p>
          </div>
        </div>

        {/* Middle: deck + trump слева, слоты пар по центру */}
        <div className="relative mt-1 flex-1">
          {/* Колода + козырь над колодой (как в реальном UI) */}
          <div className="absolute left-0 top-2 flex items-start gap-1">
            {/* Стопка-колода (3 рубашки внахлёст) */}
            <div className="relative h-12 w-9">
              <PlayingCard faceDown className="absolute inset-0" />
              <PlayingCard
                faceDown
                className="absolute inset-0 -translate-x-0.5 -translate-y-0.5"
              />
              <PlayingCard
                faceDown
                className="absolute inset-0 -translate-x-1 -translate-y-1"
              />
              {/* Бейдж счётчика поверх стопки */}
              <span className="absolute -left-1.5 -top-2 rounded-full bg-black/60 px-1.5 py-0.5 text-[9px] font-bold text-white shadow">
                12
              </span>
            </div>
            {/* Козырь — лежит горизонтально НАД стопкой (выше по экрану),
                торчит из-под её правого края, лицом вверх */}
            <PlayingCard
              rank="7"
              suit="♥"
              red
              trump
              className="-ml-3 -mt-1 h-8 w-12 rotate-90 origin-top-left"
            />
          </div>

          {/* Слоты пар (3) — центр стола */}
          <div className="absolute inset-0 flex items-center justify-center gap-2">
            {pairs.map((p, i) => {
              // Каждая пара появляется со своим delay — атака первой, защита через ~0.8s.
              const atkDelay = i * 1.6;
              const defDelay = i * 1.6 + 0.8;
              return (
                <div key={i} className="relative h-14 w-10">
                  {/* Пунктирный слот-плейсхолдер «+» — виден на финальной фазе (сброс) */}
                  <div className="absolute inset-0 flex items-center justify-center rounded-[10px] border border-dashed border-white/20 animate-feat-durak-slot-empty">
                    <Plus className="h-3 w-3 text-white/30" aria-hidden />
                  </div>
                  {/* Атакующая карта */}
                  <PlayingCard
                    rank={p.atk.rank}
                    suit={p.atk.suit}
                    red={p.atk.red}
                    className="absolute inset-0 animate-feat-durak-attack"
                    style={{ animationDelay: `${atkDelay}s` }}
                  />
                  {/* Защитная карта (поверх со смещением) */}
                  <PlayingCard
                    rank={p.def.rank}
                    suit={p.def.suit}
                    red={p.def.red}
                    className="absolute inset-0 animate-feat-durak-defend"
                    style={{ animationDelay: `${defDelay}s` }}
                  />
                </div>
              );
            })}
          </div>
        </div>

        {/* Bottom: рука игрока — 8 карт ровным рядом */}
        <div className="mt-1 flex items-end justify-center">
          {hand.map((c, i) => (
            <PlayingCard
              key={i}
              rank={c.rank}
              suit={c.suit}
              red={c.red}
              trump={c.trump}
              className={cn(
                'h-12 w-8 -ml-2 first:ml-0',
                // Маленький приподнятый «ход» у одной из козырных
                i === 2 && 'animate-feat-bubble-in',
              )}
              style={{
                animationDelay: i === 2 ? '300ms' : undefined,
              }}
            />
          ))}
        </div>

        {/* Действия Beat/Take — лента под рукой (только на полной версии) */}
        {!compact ? (
          <div className="mt-1.5 grid grid-cols-2 gap-1.5">
            <div className="flex h-6 items-center justify-center rounded-md bg-emerald-500/85 text-[10px] font-bold text-white shadow-sm">
              {t.gamesActionBeat}
            </div>
            <div className="flex h-6 items-center justify-center rounded-md border border-white/15 bg-black/30 text-[10px] font-bold text-white/85">
              {t.gamesActionTake}
            </div>
          </div>
        ) : null}
      </div>
    </div>
  );
}
