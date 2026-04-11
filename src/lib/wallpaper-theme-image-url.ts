/**
 * URL изображения обоев для выборки цвета в canvas.
 * Прямая загрузка с Firebase Storage в Safari/WebKit даёт CORS при `crossOrigin` + `getImageData`;
 * тот же пиксельный путь через same-origin `/api/wallpaper-for-theme` обходит ограничение.
 */
export function wallpaperImageUrlForThemeSampling(wallpaperUrl: string): string {
  if (wallpaperUrl.startsWith("data:") || wallpaperUrl.startsWith("blob:")) {
    return wallpaperUrl;
  }
  if (wallpaperUrl.startsWith("http://") || wallpaperUrl.startsWith("https://")) {
    return `/api/wallpaper-for-theme?url=${encodeURIComponent(wallpaperUrl)}`;
  }
  return wallpaperUrl;
}
