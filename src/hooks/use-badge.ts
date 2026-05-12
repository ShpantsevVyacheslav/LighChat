'use client';

import { useEffect } from 'react';
import { useTotalUnreadCountWithOptions } from './use-unread-counts';

/**
 * Hook to synchronize global unread chat count with system app badges.
 * Использует браузерный PWA Badge API (`navigator.setAppBadge`) — поддержано
 * в Chromium-PWA на desktop/Android и в Safari 16.4+ на macOS PWA.
 *
 * Electron-ветка (`window.electronAPI.setBadge`) удалена вместе с декомиссией
 * desktop shell — нативное приложение теперь Flutter (см.
 * `mobile/app/lib/features/desktop_shell/desktop_tray.dart::setBadgeCount`).
 */
export function useBadge(userId: string | undefined, enabled: boolean = true) {
  const totalBadgeCount = useTotalUnreadCountWithOptions(userId, enabled);

  useEffect(() => {
    if (typeof navigator !== 'undefined' && 'setAppBadge' in navigator) {
      if (totalBadgeCount > 0) {
        (navigator as { setAppBadge?: (n: number) => Promise<void> })
          .setAppBadge?.(totalBadgeCount)
          .catch(() => {});
      } else {
        (navigator as { clearAppBadge?: () => Promise<void> })
          .clearAppBadge?.()
          .catch(() => {});
      }
    }
  }, [totalBadgeCount]);

  return totalBadgeCount;
}
