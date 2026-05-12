'use client';

import type { FirebaseApp } from 'firebase/app';
import type { Analytics } from 'firebase/analytics';

import { logger } from '@/lib/logger';
import type { AnalyticsEventName, AnalyticsParams, UserPropertyName } from './events';

/**
 * Lazy Firebase Analytics wrapper. Загружает `firebase/analytics` только после
 * получения consent — иначе модуль не подтягивается в bundle вообще.
 */

let analytics: Analytics | null = null;
let loadPromise: Promise<Analytics | null> | null = null;

async function ensureAnalytics(app: FirebaseApp): Promise<Analytics | null> {
  if (analytics) return analytics;
  if (typeof window === 'undefined') return null;
  if (loadPromise) return loadPromise;

  loadPromise = (async () => {
    try {
      const mod = await import('firebase/analytics');
      const supported = await mod.isSupported();
      if (!supported) {
        logger.debug('analytics', 'firebase analytics not supported in this browser');
        return null;
      }
      analytics = mod.initializeAnalytics(app, { config: { send_page_view: false } });
      return analytics;
    } catch (e) {
      logger.warn('analytics', 'firebase analytics init failed', e);
      return null;
    }
  })();

  return loadPromise;
}

export async function fbLogEvent(
  app: FirebaseApp,
  event: AnalyticsEventName,
  params: AnalyticsParams,
): Promise<void> {
  const inst = await ensureAnalytics(app);
  if (!inst) return;
  try {
    const mod = await import('firebase/analytics');
    mod.logEvent(inst, event as string, params as Record<string, unknown>);
  } catch (e) {
    logger.warn('analytics', `logEvent ${event} failed`, e);
  }
}

export async function fbSetUserId(app: FirebaseApp, uid: string | null): Promise<void> {
  const inst = await ensureAnalytics(app);
  if (!inst) return;
  try {
    const mod = await import('firebase/analytics');
    mod.setUserId(inst, uid ?? null);
  } catch (e) {
    logger.warn('analytics', 'setUserId failed', e);
  }
}

export async function fbSetUserProperty(
  app: FirebaseApp,
  name: UserPropertyName,
  value: string | number | boolean | null,
): Promise<void> {
  const inst = await ensureAnalytics(app);
  if (!inst) return;
  try {
    const mod = await import('firebase/analytics');
    mod.setUserProperties(inst, { [name]: value as string | null });
  } catch (e) {
    logger.warn('analytics', `setUserProperty ${name} failed`, e);
  }
}

export async function fbSetCollectionEnabled(app: FirebaseApp, enabled: boolean): Promise<void> {
  const inst = await ensureAnalytics(app);
  if (!inst) return;
  try {
    const mod = await import('firebase/analytics');
    mod.setAnalyticsCollectionEnabled(inst, enabled);
  } catch (e) {
    logger.warn('analytics', 'setAnalyticsCollectionEnabled failed', e);
  }
}
