import * as functions from "firebase-functions/v1";
import { HttpsError } from "firebase-functions/v1/https";

import { recordAnalyticsEvent } from "../../analytics/recordEvent";
import { ALLOWED_EVENTS, ALLOWED_PLATFORMS } from "../../analytics/events";

/**
 * Callable для приёма продуктовой аналитики с клиентов, где нет нативного
 * firebase_analytics SDK (Flutter Windows/Linux). Web использует свой
 * REST endpoint `src/app/api/analytics/event/route.ts`.
 *
 * Контракт:
 *   data: { event: string, params: object, ts?: number }
 *   context.auth — опционально (для анонимных событий допустимо).
 *
 * Rate-limit: in-process Map, 240 событий/мин на uid/ip — этого достаточно
 * чтобы отбить эпизодический spam, но не задушить нормального клиента.
 */

const rateBuckets = new Map<string, { count: number; resetAt: number }>();
const LIMIT = 240;

function rateLimit(key: string): boolean {
  const now = Date.now();
  const b = rateBuckets.get(key);
  if (!b || b.resetAt < now) {
    rateBuckets.set(key, { count: 1, resetAt: now + 60_000 });
    return true;
  }
  b.count += 1;
  return b.count <= LIMIT;
}

export const logAnalyticsEvent = functions.https.onCall(async (data, context) => {
  const event = typeof data?.event === "string" ? data.event : "";
  if (!ALLOWED_EVENTS.has(event)) {
    throw new HttpsError("invalid-argument", "unknown_event");
  }

  const platform =
    typeof data?.platform === "string" && ALLOWED_PLATFORMS.has(data.platform) ?
      data.platform :
      undefined;

  const uid = context.auth?.uid ?? null;
  const rateKey = uid ?? context.rawRequest.ip ?? "anon";
  if (!rateLimit(rateKey)) {
    return { ok: true, dropped: true };
  }

  await recordAnalyticsEvent({
    event,
    params: data?.params ?? {},
    uid,
    platform,
    source: "callable",
  });

  return { ok: true };
});
