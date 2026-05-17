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
import { setE2eeTelemetrySink, type E2eeTelemetryEventType } from '@/lib/e2ee';

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

  // E2EE telemetry → product analytics. Подписываемся на внутренний sink
  // (`setE2eeTelemetrySink`), который E2EE-модуль уже emit'ит в ключевых
  // точках (pairing complete/reject, key rotate, encrypt/decrypt failures,
  // backup create/restore). Маппим E2EE event type'ы на наши GA4-имена и
  // шлём через `track()` — consent gate сам отфильтрует.
  React.useEffect(() => {
    setE2eeTelemetrySink((type: E2eeTelemetryEventType, payload) => {
      if (type === 'e2ee.v2.pairing.completed') {
        track(AnalyticsEvents.e2eePairingCompleted, {
          device_id_present: !!payload.deviceId,
        });
      } else if (type === 'e2ee.v2.decrypt.failure' || type === 'e2ee.v2.media.decrypt.failure') {
        track(AnalyticsEvents.e2eeFailure, {
          stage: type === 'e2ee.v2.decrypt.failure' ? 'decrypt_text' : 'decrypt_media',
          error_code: payload.errorCode ?? 'unknown',
        });
      } else if (type === 'e2ee.v2.enable.failure' || type === 'e2ee.v2.rotate.failure' || type === 'e2ee.v2.media.encrypt.failure') {
        track(AnalyticsEvents.e2eeFailure, {
          stage:
            type === 'e2ee.v2.enable.failure'
              ? 'enable'
              : type === 'e2ee.v2.rotate.failure'
              ? 'rotate'
              : 'encrypt_media',
          error_code: payload.errorCode ?? 'unknown',
        });
      }
      // Прочие telemetry-события (success-варианты, backup-флоу) пока не
      // мапим явно — добавим по необходимости. logE2eeEvent дальше идёт
      // в logger.debug для in-app дебага.
    });
    return () => {
      setE2eeTelemetrySink(null);
    };
  }, []);

  // язык приложения как user-property — пригодится для разбивки всех событий
  React.useEffect(() => {
    if (typeof navigator === 'undefined') return;
    setUserProperty(UserProperties.appLanguage, navigator.language.slice(0, 2));
  }, []);

  // PWA install lifecycle: `beforeinstallprompt` срабатывает когда браузер
  // решил, что сайт пригоден к установке (Chrome / Edge / Yandex). После
  // accept'а юзера эмитится `appinstalled`. Оба события — `window`-level.
  // На iOS Safari ни одного из них нет — там пользователь жмёт «Share →
  // Add to Home Screen» вручную, без программного канала уведомления.
  React.useEffect(() => {
    if (typeof window === 'undefined') return;
    const onBeforeInstall = () => {
      track(AnalyticsEvents.pwaInstallPromptShown, {
        prompt_source: 'browser_native',
      });
    };
    const onAppInstalled = () => {
      track(AnalyticsEvents.pwaInstalled, {
        install_source: 'browser_native',
      });
    };
    window.addEventListener('beforeinstallprompt', onBeforeInstall);
    window.addEventListener('appinstalled', onAppInstalled);
    return () => {
      window.removeEventListener('beforeinstallprompt', onBeforeInstall);
      window.removeEventListener('appinstalled', onAppInstalled);
    };
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
