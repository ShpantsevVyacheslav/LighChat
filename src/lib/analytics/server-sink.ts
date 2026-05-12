'use client';

import { logger } from '@/lib/logger';
import type { AnalyticsEventName, AnalyticsParams, Platform } from './events';

/**
 * Серверный канал. Шлёт `POST /api/analytics/event` с idToken'ом — функция
 * валидирует enum, пишет в Firestore `analyticsEvents/{auto}` и форвардит в
 * GA4 Measurement Protocol. Используется в двух случаях:
 *   1) Когда client SDK недоступен (Safari ITP / AdBlock / отказался от cookies).
 *   2) Для критичных конверсий (sign_up_success, purchase_completed) —
 *      двойная запись для надёжности.
 */

let inFlight = 0;
const MAX_IN_FLIGHT = 8;

export async function serverLogEvent(
  event: AnalyticsEventName,
  params: AnalyticsParams,
  idToken: string | null,
  platform: Platform,
): Promise<void> {
  if (typeof window === 'undefined') return;
  if (inFlight >= MAX_IN_FLIGHT) {
    logger.debug('analytics', `server-sink backpressure (in-flight=${inFlight}), drop ${event}`);
    return;
  }
  inFlight++;
  try {
    await fetch('/api/analytics/event', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        event,
        params,
        platform,
        ts: Date.now(),
        idToken: idToken ?? null,
      }),
      keepalive: true,
    });
  } catch (e) {
    logger.debug('analytics', `serverLogEvent ${event} failed`, e);
  } finally {
    inFlight--;
  }
}
