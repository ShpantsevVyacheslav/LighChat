
'use client';

import { useEffect } from 'react';
import { useTotalUnreadCount } from './use-unread-counts';

/**
 * Hook to synchronize global unread chat count with system app badges (PWA and Electron).
 */
export function useBadge(userId: string | undefined) {
  const totalBadgeCount = useTotalUnreadCount(userId);

  useEffect(() => {
    // 1. Browser PWA Badge
    if (typeof navigator !== 'undefined' && 'setAppBadge' in navigator) {
      if (totalBadgeCount > 0) {
        (navigator as any).setAppBadge(totalBadgeCount).catch(() => {});
      } else {
        (navigator as any).clearAppBadge().catch(() => {});
      }
    }

    // 2. Electron App Badge
    if (typeof window !== 'undefined' && (window as any).electronAPI?.setBadge) {
      (window as any).electronAPI.setBadge(totalBadgeCount);
    }
  }, [totalBadgeCount]);

  return totalBadgeCount;
}
