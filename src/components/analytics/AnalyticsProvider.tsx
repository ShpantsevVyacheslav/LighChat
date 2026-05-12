'use client';

import * as React from 'react';
import { usePathname, useSearchParams } from 'next/navigation';

import { useFirebase } from '@/firebase/provider';
import {
  AnalyticsEvents,
  initAnalytics,
  setUserProperty,
  track,
} from '@/lib/analytics';
import { UserProperties } from '@/lib/analytics/events';

/**
 * Инициализирует analytics на старте и шлёт `page_view` при каждом изменении
 * pathname/search-params. Внутри не делает ничего, если consent ещё не выдан —
 * это контролирует `track()` в `src/lib/analytics/index.ts`.
 */
export function AnalyticsProvider({ children }: { children: React.ReactNode }) {
  const { firebaseApp, auth } = useFirebase();
  const pathname = usePathname();
  const searchParams = useSearchParams();

  // bootstrap once
  React.useEffect(() => {
    if (!firebaseApp || !auth) return;
    initAnalytics({ app: firebaseApp, auth });
  }, [firebaseApp, auth]);

  // язык приложения как user-property — пригодится для разбивки всех событий
  React.useEffect(() => {
    if (typeof navigator === 'undefined') return;
    setUserProperty(UserProperties.appLanguage, navigator.language.slice(0, 2));
  }, []);

  // page_view
  const prevPathRef = React.useRef<string | null>(null);
  const prevTsRef = React.useRef<number>(Date.now());
  React.useEffect(() => {
    if (!pathname) return;
    const now = Date.now();
    const prev = prevPathRef.current;
    const timeOnPrevMs = prev ? now - prevTsRef.current : 0;

    // utm + referrer вытащим только на landing (главная или /auth)
    const utm: Record<string, string | null> = {};
    if (pathname === '/' || pathname.startsWith('/auth')) {
      utm.utm_source = searchParams?.get('utm_source') ?? null;
      utm.utm_medium = searchParams?.get('utm_medium') ?? null;
      utm.utm_campaign = searchParams?.get('utm_campaign') ?? null;
    }

    track(AnalyticsEvents.pageView, {
      screen_name: routeTemplate(pathname),
      screen_path: pathname,
      prev_screen: prev,
      time_on_prev_ms: timeOnPrevMs,
      ...utm,
    });

    prevPathRef.current = pathname;
    prevTsRef.current = now;
  }, [pathname, searchParams]);

  return <>{children}</>;
}

/**
 * Превращает `/dashboard/chat/abc123` в `/dashboard/chat/[id]` для GA4
 * cardinality-limit (иначе каждый chatId был бы отдельным screen_name).
 */
function routeTemplate(pathname: string): string {
  return pathname
    .split('/')
    .map((seg) => {
      if (!seg) return seg;
      if (/^[0-9a-fA-F]{20,}$/.test(seg)) return '[id]';
      if (/^[0-9]+$/.test(seg)) return '[id]';
      return seg;
    })
    .join('/');
}
