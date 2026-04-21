'use client';

import React from 'react';
import { cn } from '@/lib/utils';

/** Зазоры между плитками в одном ряду / сетке. */
const gridGap = 'gap-3 sm:gap-4';

/** Вертикальный зазор между рядами плиток. */
const stackGap = 'gap-3 sm:gap-4';

/**
 * 16:9 плитка (`aspect-video` в Tailwind = 16:9): как в эталонной раскладке конференции.
 */
const tileVideoShell = 'relative min-h-0 min-w-0 overflow-hidden rounded-2xl aspect-video';

/** Ширина одной колонки при сетке из 2 столбцов (учёт одного gap-3 / gap-4). */
const widthOneHalf =
  'w-full max-w-[calc((100%-0.75rem)/2)] sm:max-w-[calc((100%-1rem)/2)]';

/** Ширина одной колонки при сетке из 3 столбцов (учёт двух зазоров). */
const widthOneThird =
  'w-full max-w-[calc((100%-1.5rem)/3)] sm:max-w-[calc((100%-2rem)/3)]';

const stageShell =
  'mx-auto flex h-full w-full min-h-0 max-w-[min(96vw,1600px)] flex-col items-center justify-center px-2 py-4 sm:px-3 [&>*]:shrink-0';

function wrapVideoTile(tile: React.ReactNode, key: React.Key, className?: string) {
  return (
    <div key={key} className={cn(tileVideoShell, className)}>
      {tile}
    </div>
  );
}

export type MeetingParticipantTileStageProps = {
  /** Уже отрендеренные плитки (ParticipantView и т.п.) по порядку: локальный первый, остальные. */
  tiles: React.ReactNode[];
};

/**
 * Один «кадр» плиточного режима: раскладка зависит только от числа участников на странице.
 * Плитки 16:9; при 3 участниках — два сверху, один по центру снизу той же ширины, что верхняя половина.
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
      <div className={stageShell}>
        <div className={cn('grid min-h-0 w-full grid-cols-2', gridGap)}>
          {wrapVideoTile(tiles[0], 0)}
          {wrapVideoTile(tiles[1], 1)}
        </div>
      </div>
    );
  }

  if (n === 3) {
    return (
      <div className={cn(stageShell, stackGap)}>
        <div className={cn('grid min-h-0 w-full grid-cols-2', gridGap)}>
          {wrapVideoTile(tiles[0], 0)}
          {wrapVideoTile(tiles[1], 1)}
        </div>
        <div className="flex w-full min-h-0 shrink-0 justify-center">
          <div className={cn(tileVideoShell, widthOneHalf)}>{tiles[2]}</div>
        </div>
      </div>
    );
  }

  if (n === 4) {
    return (
      <div className={stageShell}>
        <div className={cn('grid min-h-0 w-full grid-cols-2 grid-rows-2', gridGap, '[&>*]:min-h-0')}>
          {tiles.map((t, i) => wrapVideoTile(t, i))}
        </div>
      </div>
    );
  }

  if (n === 5) {
    return (
      <div className={cn(stageShell, stackGap)}>
        <div className={cn('grid min-h-0 w-full max-w-[min(100%,1200px)] grid-cols-2', gridGap)}>
          {[0, 1].map((i) => wrapVideoTile(tiles[i], i))}
        </div>
        <div className={cn('grid min-h-0 w-full max-w-[min(100%,1200px)] grid-cols-2', gridGap)}>
          {[2, 3].map((i) => wrapVideoTile(tiles[i], i))}
        </div>
        <div className="flex w-full max-w-[min(100%,1200px)] justify-center">
          <div className={cn(tileVideoShell, widthOneHalf)}>{tiles[4]}</div>
        </div>
      </div>
    );
  }

  if (n === 6) {
    return (
      <div className={stageShell}>
        <div
          className={cn(
            'grid min-h-0 w-full grid-cols-3 auto-rows-auto',
            gridGap,
            '[&>*]:min-h-0',
          )}
        >
          {tiles.map((t, i) => wrapVideoTile(t, i))}
        </div>
      </div>
    );
  }

  if (n === 7) {
    return (
      <div className={cn(stageShell, stackGap)}>
        <div className={cn('grid w-full max-w-[min(100%,1200px)] grid-cols-3', gridGap)}>
          {tiles.slice(0, 3).map((t, i) => wrapVideoTile(t, i))}
        </div>
        <div className={cn('grid w-full max-w-[min(100%,1200px)] grid-cols-3', gridGap)}>
          {tiles.slice(3, 6).map((t, i) => wrapVideoTile(t, i + 3))}
        </div>
        <div className="flex w-full max-w-[min(100%,1200px)] justify-center">
          <div className={cn(tileVideoShell, widthOneThird)}>{tiles[6]}</div>
        </div>
      </div>
    );
  }

  if (n === 8) {
    return (
      <div className={cn(stageShell, stackGap)}>
        <div className={cn('grid w-full max-w-[min(100%,1200px)] grid-cols-3', gridGap)}>
          {tiles.slice(0, 3).map((t, i) => wrapVideoTile(t, i))}
        </div>
        <div className={cn('grid w-full max-w-[min(100%,1200px)] grid-cols-3', gridGap)}>
          {tiles.slice(3, 6).map((t, i) => wrapVideoTile(t, i + 3))}
        </div>
        <div className={cn('flex w-full max-w-[min(100%,1200px)] flex-row flex-wrap justify-center', gridGap)}>
          {wrapVideoTile(tiles[6], 6, widthOneThird)}
          {wrapVideoTile(tiles[7], 7, widthOneThird)}
        </div>
      </div>
    );
  }

  return (
    <div className={stageShell}>
      <div className={cn('grid min-h-0 w-full grid-cols-3 grid-rows-3', gridGap, '[&>*]:min-h-0')}>
        {tiles.slice(0, 9).map((t, i) => wrapVideoTile(t, i))}
      </div>
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
