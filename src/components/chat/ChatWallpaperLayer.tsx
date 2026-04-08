'use client';

import React from 'react';
import { cn } from '@/lib/utils';

export function isChatWallpaperImageUrl(wallpaper: string | null | undefined): boolean {
  return !!(wallpaper && (wallpaper.startsWith('http') || wallpaper.startsWith('data:')));
}

type ChatWallpaperLayerProps = {
  /** `chatSettings.chatWallpaper`: URL/data URL изображения или CSS `background` (градиент). */
  wallpaper: string | null | undefined;
  className?: string;
};

/**
 * Фон переписки (градиент или картинка + затемнение). Один источник для `ChatWindow`, треда и пустой колонки чата.
 */
export function ChatWallpaperLayer({ wallpaper, className }: ChatWallpaperLayerProps) {
  const isImage = isChatWallpaperImageUrl(wallpaper);
  const wallpaperStyle = !isImage && wallpaper ? ({ background: wallpaper } as React.CSSProperties) : undefined;

  if (!isImage && !wallpaperStyle) return null;

  return (
    <div
      className={cn('absolute inset-0 z-0 min-h-full min-w-full pointer-events-none', className)}
      aria-hidden
    >
      {isImage ? (
        <>
          <img src={wallpaper!} alt="" className="absolute inset-0 h-full min-h-full w-full object-cover object-center" />
          <div className="absolute inset-0 bg-black/40 dark:bg-black/55" />
        </>
      ) : (
        <div className="absolute inset-0" style={wallpaperStyle} />
      )}
    </div>
  );
}
