'use client';

import React from 'react';
import { cn } from '@/lib/utils';

const tileSquareWrap = 'aspect-square w-[min(44vmin,400px)] max-w-[46vw] sm:max-w-[380px] shrink-0 min-w-0';
const rowGap = 'gap-3 sm:gap-4';

function wrapSquare(tile: React.ReactNode, key: React.Key) {
  return (
    <div key={key} className={cn(tileSquareWrap, 'overflow-hidden rounded-xl')}>
      {tile}
    </div>
  );
}

export type MeetingParticipantTileStageProps = {
  /** Уже отрендеренные плитки (ParticipantView и т.п.) по порядку: локальный первый, остальные. */
  tiles: React.ReactNode[];
};

/**
 * Один «кадр» плиточного режима: раскладка зависит только от числа участников на этой странице.
 * 1 — на весь экран; 2 — два квадрата по центру; 3 — два сверху, один по центру снизу;
 * 4 — 2×2; 5–8 — ряды по правилам; 9 — 3×3.
 */
export function MeetingParticipantTileStage({ tiles }: MeetingParticipantTileStageProps) {
  const n = tiles.length;
  if (n === 0) return null;

  if (n === 1) {
    return (
      <div className="flex h-full w-full min-h-0 items-center justify-center p-2 sm:p-3">
        <div className="h-full w-full min-h-0 max-h-full overflow-hidden rounded-2xl">{tiles[0]}</div>
      </div>
    );
  }

  if (n === 2) {
    return (
      <div
        className={cn(
          'flex h-full w-full min-h-0 flex-row flex-wrap items-center justify-center content-center',
          rowGap,
          'px-2 py-4'
        )}
      >
        {tiles.map((t, i) => wrapSquare(t, i))}
      </div>
    );
  }

  if (n === 3) {
    return (
      <div
        className={cn(
          'flex h-full w-full min-h-0 flex-col items-center justify-center',
          rowGap,
          'px-2 py-4'
        )}
      >
        <div className={cn('flex flex-row items-center justify-center', rowGap)}>
          {wrapSquare(tiles[0], 0)}
          {wrapSquare(tiles[1], 1)}
        </div>
        <div className="flex w-full justify-center">{wrapSquare(tiles[2], 2)}</div>
      </div>
    );
  }

  if (n === 4) {
    return (
      <div className="mx-auto grid h-full min-h-0 w-full max-w-[min(100%,960px)] grid-cols-2 grid-rows-2 gap-3 content-center justify-items-stretch px-2 py-2 [&>*]:min-h-0">
        {tiles.map((t, i) => (
          <div key={i} className="min-h-0 min-w-0 overflow-hidden rounded-xl">
            {t}
          </div>
        ))}
      </div>
    );
  }

  if (n === 5) {
    return (
      <div className={cn('flex h-full min-h-0 w-full flex-col items-center justify-center', rowGap, 'py-2')}>
        <div className={cn('flex flex-row flex-wrap justify-center', rowGap)}>{[0, 1].map((i) => wrapSquare(tiles[i], i))}</div>
        <div className={cn('flex flex-row flex-wrap justify-center', rowGap)}>{[2, 3].map((i) => wrapSquare(tiles[i], i))}</div>
        <div className="flex justify-center">{wrapSquare(tiles[4], 4)}</div>
      </div>
    );
  }

  if (n === 6) {
    return (
      <div className="mx-auto grid h-full min-h-0 w-full max-w-[min(100%,1200px)] grid-cols-3 grid-rows-2 gap-3 px-2 py-2 content-center">
        {tiles.map((t, i) => (
          <div key={i} className="min-h-0 min-w-0 overflow-hidden rounded-xl">
            {t}
          </div>
        ))}
      </div>
    );
  }

  if (n === 7) {
    return (
      <div className={cn('flex h-full min-h-0 w-full flex-col items-center justify-center', rowGap, 'py-2')}>
        <div className="grid w-full max-w-[min(100%,1200px)] grid-cols-3 gap-3 px-2">
          {tiles.slice(0, 3).map((t, i) => (
            <div key={i} className="min-h-0 min-w-0 overflow-hidden rounded-xl">
              {t}
            </div>
          ))}
        </div>
        <div className="grid w-full max-w-[min(100%,1200px)] grid-cols-3 gap-3 px-2">
          {tiles.slice(3, 6).map((t, i) => (
            <div key={i + 3} className="min-h-0 min-w-0 overflow-hidden rounded-xl">
              {t}
            </div>
          ))}
        </div>
        <div className="flex w-full justify-center px-2">
          <div className="aspect-square w-[min(44vmin,400px)] max-w-[46vw] overflow-hidden rounded-xl sm:max-w-[380px]">
            {tiles[6]}
          </div>
        </div>
      </div>
    );
  }

  if (n === 8) {
    return (
      <div className={cn('flex h-full min-h-0 w-full flex-col items-center justify-center', rowGap, 'py-2')}>
        <div className="grid w-full max-w-[min(100%,1200px)] grid-cols-3 gap-3 px-2">
          {tiles.slice(0, 3).map((t, i) => (
            <div key={i} className="min-h-0 min-w-0 overflow-hidden rounded-xl">
              {t}
            </div>
          ))}
        </div>
        <div className="grid w-full max-w-[min(100%,1200px)] grid-cols-3 gap-3 px-2">
          {tiles.slice(3, 6).map((t, i) => (
            <div key={i + 3} className="min-h-0 min-w-0 overflow-hidden rounded-xl">
              {t}
            </div>
          ))}
        </div>
        <div className={cn('flex flex-row flex-wrap justify-center', rowGap)}>
          {wrapSquare(tiles[6], 6)}
          {wrapSquare(tiles[7], 7)}
        </div>
      </div>
    );
  }

  return (
    <div className="mx-auto grid h-full min-h-0 w-full max-w-[min(100%,1200px)] grid-cols-3 grid-rows-3 gap-3 px-2 py-2 content-center">
      {tiles.slice(0, 9).map((t, i) => (
        <div key={i} className="min-h-0 min-w-0 overflow-hidden rounded-xl">
          {t}
        </div>
      ))}
    </div>
  );
}

export const MEETING_TILES_PER_PAGE = 9;

export function chunkMeetingTiles<T>(items: T[], pageSize: number): T[][] {
  if (pageSize <= 0) return [items];
  const pages: T[][] = [];
  for (let i = 0; i < items.length; i += pageSize) {
    pages.push(items.slice(i, i + pageSize));
  }
  return pages.length ? pages : [[]];
}
