'use client';

import React from 'react';
import { useTheme } from 'next-themes';
import { cn } from '@/lib/utils';
import {
  isBuiltinWallpaperValue,
  pickBuiltinWallpaperSrc,
  resolveBuiltinWallpaper,
} from '@/lib/builtinWallpapers';
import {
  isAnimatedWallpaperValue,
  pickAnimatedWallpaperSrc,
  resolveAnimatedWallpaper,
} from '@/lib/animatedWallpapers';

export function isChatWallpaperImageUrl(wallpaper: string | null | undefined): boolean {
  return !!(wallpaper && (wallpaper.startsWith('http') || wallpaper.startsWith('data:')));
}

type ChatWallpaperLayerProps = {
  /**
   * `chatSettings.chatWallpaper`. Поддерживаемые форматы:
   * - `http(s)://...` или `data:...` — пользовательская картинка;
   * - `builtin:<slug>` — встроенный обой (см. `src/lib/builtinWallpapers.ts`);
   * - любая другая строка — CSS `background` (градиент).
   */
  wallpaper: string | null | undefined;
  className?: string;
};

/**
 * Фон переписки (градиент или картинка + затемнение). Один источник для `ChatWindow`, треда и пустой колонки чата.
 */
export function ChatWallpaperLayer({ wallpaper, className }: ChatWallpaperLayerProps) {
  const { resolvedTheme } = useTheme();
  const builtin = resolveBuiltinWallpaper(wallpaper);
  const animated = resolveAnimatedWallpaper(wallpaper);
  const themeKey = resolvedTheme === 'dark' ? 'dark' : 'light';
  const builtinSrc = builtin ? pickBuiltinWallpaperSrc(builtin, themeKey) : null;
  // Для web сейчас рендерим только статичный preview анимированного обоя.
  // Сама «живая» анимация (падающая звезда, луч маяка) реализована
  // на mobile-стороне через Flutter `AnimatedWallpaperLayer`.
  const animatedSrc = animated ? pickAnimatedWallpaperSrc(animated, themeKey) : null;
  const isImage =
    !builtin && !animated && isChatWallpaperImageUrl(wallpaper);
  const wallpaperStyle =
    !builtin &&
    !animated &&
    !isImage &&
    wallpaper &&
    !isBuiltinWallpaperValue(wallpaper) &&
    !isAnimatedWallpaperValue(wallpaper)
      ? ({ background: wallpaper } as React.CSSProperties)
      : undefined;

  if (!builtinSrc && !animatedSrc && !isImage && !wallpaperStyle) return null;

  const renderedSrc =
    builtinSrc ?? animatedSrc ?? (isImage ? wallpaper! : null);

  return (
    <div
      className={cn('absolute inset-0 z-0 min-h-full min-w-full pointer-events-none', className)}
      aria-hidden
    >
      {renderedSrc ? (
        <>
          <img src={renderedSrc} alt="" className="absolute inset-0 h-full min-h-full w-full object-cover object-center" />
          <div className="absolute inset-0 bg-black/40 dark:bg-black/55" />
        </>
      ) : (
        <div className="absolute inset-0" style={wallpaperStyle} />
      )}
    </div>
  );
}
