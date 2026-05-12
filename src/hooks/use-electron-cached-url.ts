'use client';

/**
 * Electron-wrapper удалён (см. AGENTS.md). Этот хук теперь — passthrough
 * для существующих call-sites: возвращает исходный URL без локального
 * кэша. Удалите вызовы в следующем рефакторинге chat media-display.
 *
 * @deprecated Always returns the input URL.
 */
export function useElectronCachedUrl(remoteUrl: string | null | undefined): string {
  return remoteUrl ?? '';
}
