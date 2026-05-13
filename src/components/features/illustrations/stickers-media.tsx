'use client';

import * as React from 'react';
import { BarChart3, Heart, ImagePlus, Search, Sticker } from 'lucide-react';
import { cn } from '@/lib/utils';
import { useI18n } from '@/hooks/use-i18n';
import { getFeaturesContent } from '../features-content';

// Реальный sticker-picker `ChatStickerGifPanel` использует сетку 3-col,
// не 4-col. Опрос и фоторедактор — это совершенно другие UI (отдельные
// диалоги), поэтому мы выделяем их отдельным блоком ниже с явными подписями.
const FACES = [
  { glyph: '😀', accent: 'from-amber-300 to-amber-500' },
  { glyph: '😎', accent: 'from-violet-400 to-violet-600' },
  { glyph: '🤩', accent: 'from-rose-400 to-rose-600' },
  { glyph: '😴', accent: 'from-sky-400 to-sky-600' },
  { glyph: '😡', accent: 'from-red-500 to-rose-700' },
  { glyph: '🤔', accent: 'from-emerald-400 to-emerald-600' },
];

/** Стикер-пикер + плитка опроса + превью медиа-редактора. */
export function MockStickersMedia({
  className,
  compact,
}: {
  className?: string;
  compact?: boolean;
}) {
  const { locale } = useI18n();
  const t = React.useMemo(() => getFeaturesContent(locale).mockText, [locale]);
  return (
    <div className={cn('relative flex h-full w-full flex-col p-3', className)}>
      <div className="flex items-center gap-2 rounded-full border border-black/5 dark:border-white/10 bg-background/80 px-3 py-1.5 backdrop-blur-md">
        <Search className="h-3.5 w-3.5 text-muted-foreground" aria-hidden />
        <span className="flex-1 text-[12px] text-muted-foreground">
          {t.stickerSearchHint}
          <span className="ml-1 inline-block h-3 w-px bg-foreground/70 animate-feat-caret align-middle" />
        </span>
        <Sticker className="h-4 w-4 text-amber-500 dark:text-amber-400" aria-hidden />
      </div>
      {/* Реальный `ChatStickerGifPanel` — 3 эксклюзивные вкладки. */}
      <div className="mt-2 flex items-center gap-1 rounded-full bg-background/40 p-0.5">
        <span className="flex-1 rounded-full bg-primary px-2 py-0.5 text-center text-[10px] font-bold text-primary-foreground">
          {t.stickerTabEmoji}
        </span>
        <span className="flex-1 px-2 py-0.5 text-center text-[10px] font-semibold text-muted-foreground">
          {t.stickerTabStickers}
        </span>
        <span className="flex-1 px-2 py-0.5 text-center text-[10px] font-semibold text-muted-foreground">
          {t.stickerTabGif}
        </span>
      </div>
      <div className="mt-2 grid grid-cols-3 gap-2">
        {FACES.map((f, i) => (
          <div
            key={f.glyph}
            className={cn(
              'flex aspect-square items-center justify-center rounded-2xl bg-gradient-to-br shadow-sm animate-feat-bubble-in',
              f.accent
            )}
            style={{ animationDelay: `${i * 60}ms` }}
            aria-hidden
          >
            <span className="text-2xl drop-shadow-[0_2px_2px_rgba(0,0,0,0.25)]">{f.glyph}</span>
          </div>
        ))}
      </div>
      {!compact ? (
        <>
          <p className="mt-3 px-0.5 text-[9px] font-bold uppercase tracking-wider text-muted-foreground">
            {t.stickerOtherUis}
          </p>
        {/* Подпись делает явным: эти блоки — отдельные UI, не часть emoji-popover */}
        <div className="mt-1 grid grid-cols-2 gap-2">
          <div
            className="rounded-2xl border border-black/5 dark:border-white/10 bg-background/60 p-2.5 animate-feat-bubble-in"
            style={{ animationDelay: '600ms' }}
          >
            <div className="flex items-center gap-1.5 text-[10px] font-semibold uppercase tracking-wide text-muted-foreground">
              <BarChart3 className="h-3 w-3" aria-hidden /> {t.pollLabel}
            </div>
            <p className="mt-1 text-[11px] font-semibold text-foreground">{t.pollTitle}</p>
            <div className="mt-1.5 space-y-1">
              {[
                { name: t.pollOption1, pct: 62 },
                { name: t.pollOption2, pct: 31 },
              ].map((o) => (
                <div key={o.name} className="relative h-5 overflow-hidden rounded-md bg-foreground/5">
                  <div
                    className="absolute inset-y-0 left-0 bg-amber-400/45 transition-[width] duration-700"
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
          <div
            className="overflow-hidden rounded-2xl border border-black/5 dark:border-white/10 animate-feat-bubble-in"
            style={{ animationDelay: '700ms' }}
          >
            <div className="relative h-full min-h-[110px] bg-gradient-to-br from-rose-400 via-amber-300 to-emerald-400">
              <div className="absolute inset-0 bg-[url('data:image/svg+xml;utf8,<svg xmlns=%22http://www.w3.org/2000/svg%22 width=%2240%22 height=%2240%22 fill=%22none%22><circle cx=%2220%22 cy=%2220%22 r=%2210%22 fill=%22white%22 fill-opacity=%220.18%22/></svg>')]" />
              <span className="absolute right-2 top-2 rounded-full bg-black/45 p-1 backdrop-blur-md">
                <Heart className="h-3 w-3 text-rose-300" aria-hidden />
              </span>
              <div className="absolute top-2 left-2 inline-flex items-center gap-1 rounded-md bg-black/45 px-1.5 py-0.5 text-[9px] font-bold uppercase tracking-wide text-white backdrop-blur-md">
                <ImagePlus className="h-2.5 w-2.5" aria-hidden /> {t.editorLabel}
              </div>
              <div className="absolute bottom-1.5 left-1.5 right-1.5 flex items-center justify-between rounded-md bg-black/45 px-2 py-1 text-[10px] font-semibold text-white backdrop-blur-md">
                <span className="opacity-85">{t.editorHint}</span>
              </div>
            </div>
          </div>
        </div>
        </>
      ) : null}
    </div>
  );
}
