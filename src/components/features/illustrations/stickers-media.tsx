import * as React from 'react';
import { BarChart3, ImagePlus, Search, Sticker } from 'lucide-react';
import { cn } from '@/lib/utils';

const FACES = [
  { glyph: '😀', accent: 'from-amber-300 to-amber-500' },
  { glyph: '😎', accent: 'from-violet-400 to-violet-600' },
  { glyph: '🤩', accent: 'from-rose-400 to-rose-600' },
  { glyph: '😴', accent: 'from-sky-400 to-sky-600' },
  { glyph: '😡', accent: 'from-red-500 to-rose-700' },
  { glyph: '🤔', accent: 'from-emerald-400 to-emerald-600' },
  { glyph: '🥳', accent: 'from-pink-400 to-pink-600' },
  { glyph: '😇', accent: 'from-amber-400 to-orange-600' },
];

export function MockStickersMedia({
  className,
  compact,
}: {
  className?: string;
  compact?: boolean;
}) {
  return (
    <div className={cn('relative flex h-full w-full flex-col p-3', className)}>
      <div className="flex items-center gap-2 rounded-full border border-black/5 dark:border-white/10 bg-background/80 px-3 py-1.5 backdrop-blur-md">
        <Search className="h-3.5 w-3.5 text-muted-foreground" aria-hidden />
        <span className="text-[12px] text-muted-foreground">поиск стикеров и GIF</span>
        <Sticker className="ml-auto h-4 w-4 text-amber-400" aria-hidden />
      </div>
      <div className="mt-3 grid grid-cols-4 gap-2">
        {FACES.map((f) => (
          <div
            key={f.glyph}
            className={cn(
              'flex aspect-square items-center justify-center rounded-2xl text-2xl shadow-sm bg-gradient-to-br',
              f.accent
            )}
            aria-hidden
          >
            <span className="drop-shadow-[0_2px_2px_rgba(0,0,0,0.25)]">{f.glyph}</span>
          </div>
        ))}
      </div>
      {!compact ? (
        <div className="mt-3 grid grid-cols-2 gap-2">
          <div className="rounded-2xl border border-black/5 dark:border-white/10 bg-background/60 p-2.5">
            <div className="flex items-center gap-1.5 text-[10px] font-semibold uppercase tracking-wide text-muted-foreground">
              <BarChart3 className="h-3 w-3" aria-hidden /> Опрос
            </div>
            <p className="mt-1 text-[11px] font-semibold text-foreground">Куда едем в субботу?</p>
            <div className="mt-1 space-y-1">
              {[
                { name: 'В горы', pct: 62 },
                { name: 'На дачу', pct: 31 },
              ].map((o) => (
                <div key={o.name} className="relative h-5 overflow-hidden rounded-md bg-foreground/5">
                  <div
                    className="absolute inset-y-0 left-0 bg-amber-400/40"
                    style={{ width: `${o.pct}%` }}
                  />
                  <div className="relative flex h-full items-center justify-between px-2 text-[10px] font-semibold">
                    <span>{o.name}</span>
                    <span>{o.pct}%</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
          <div className="overflow-hidden rounded-2xl border border-black/5 dark:border-white/10">
            <div className="relative h-full min-h-[110px] bg-gradient-to-br from-rose-400 via-amber-300 to-emerald-400">
              <div className="absolute inset-0 bg-[url('data:image/svg+xml;utf8,<svg xmlns=%22http://www.w3.org/2000/svg%22 width=%2240%22 height=%2240%22 fill=%22none%22><circle cx=%2220%22 cy=%2220%22 r=%2210%22 fill=%22white%22 fill-opacity=%220.18%22/></svg>')]" />
              <div className="absolute bottom-1.5 left-1.5 right-1.5 flex items-center justify-between rounded-md bg-black/40 px-2 py-1 text-[10px] font-semibold text-white backdrop-blur-md">
                <span className="inline-flex items-center gap-1">
                  <ImagePlus className="h-3 w-3" aria-hidden /> Редактор фото
                </span>
                <span className="opacity-80">обрезать · подписать</span>
              </div>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
}
