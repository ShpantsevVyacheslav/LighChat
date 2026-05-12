import * as admin from "firebase-admin";
import { logger } from "firebase-functions/v1";

import { ALLOWED_EVENTS, ALLOWED_PLATFORMS, AnalyticsEventName } from "./events";

/**
 * Серверный helper для записи продуктовой аналитики.
 *
 * Что делает:
 *   1) Пишет событие в Firestore `analyticsEvents/{auto}` — оттуда читает
 *      ежесуточный rollup и admin-дашборд.
 *   2) Параллельно (fire-and-forget) форвардит в GA4 Measurement Protocol
 *      если в `platformSettings/main` есть конфиг `analytics.{measurementId,apiSecret}`.
 *
 * Контракт:
 *   - `event` валидируется по whitelist (`ALLOWED_EVENTS`);
 *   - `params` — плоский объект без PII (нельзя `email`, `phone`, `name`, длинные id);
 *   - `platform` — один из ALLOWED_PLATFORMS;
 *   - вызов не бросает: серверная аналитика не должна валить основной flow.
 */

const MAX_PARAMS = 24;
const MAX_PARAM_LEN = 100;

let analyticsConfigCache: { measurementId: string; apiSecret: string } | null = null;
let analyticsConfigLoadedAt = 0;
const CONFIG_TTL_MS = 5 * 60 * 1000;

async function loadAnalyticsConfig(): Promise<{ measurementId: string; apiSecret: string } | null> {
  const now = Date.now();
  if (analyticsConfigCache && now - analyticsConfigLoadedAt < CONFIG_TTL_MS) {
    return analyticsConfigCache;
  }
  try {
    const snap = await admin.firestore().doc("platformSettings/main").get();
    const data = snap.data();
    const ga = data?.analytics as { measurementId?: string; apiSecret?: string } | undefined;
    if (ga?.measurementId && ga?.apiSecret) {
      analyticsConfigCache = {
        measurementId: ga.measurementId,
        apiSecret: ga.apiSecret,
      };
    } else {
      analyticsConfigCache = null;
    }
    analyticsConfigLoadedAt = now;
    return analyticsConfigCache;
  } catch (e) {
    logger.warn("analytics: failed to load platformSettings/main", e);
    return null;
  }
}

export type RecordEventInput = {
  event: AnalyticsEventName | string;
  params?: Record<string, string | number | boolean | null | undefined>;
  uid?: string | null;
  platform?: string;
  source?: string;
};

function sanitizeParams(
  params: Record<string, string | number | boolean | null | undefined> | undefined,
): Record<string, string | number | boolean | null> {
  if (!params) return {};
  const out: Record<string, string | number | boolean | null> = {};
  let i = 0;
  for (const [k, v] of Object.entries(params)) {
    if (i >= MAX_PARAMS) break;
    if (typeof k !== "string" || k.length === 0 || k.length > 40) continue;
    if (v === undefined) continue;
    if (v === null) {
      out[k] = null;
    } else if (typeof v === "string") {
      out[k] = v.slice(0, MAX_PARAM_LEN);
    } else if (typeof v === "number" || typeof v === "boolean") {
      out[k] = v;
    }
    i++;
  }
  return out;
}

async function sendMeasurementProtocol(
  cfg: { measurementId: string; apiSecret: string },
  clientId: string,
  uid: string | null,
  event: string,
  params: Record<string, string | number | boolean | null>,
): Promise<void> {
  const url = `https://www.google-analytics.com/mp/collect?measurement_id=${encodeURIComponent(
    cfg.measurementId,
  )}&api_secret=${encodeURIComponent(cfg.apiSecret)}`;
  const cleanParams: Record<string, string | number | boolean> = {};
  for (const [k, v] of Object.entries(params)) {
    if (v === null) continue;
    cleanParams[k] = v;
  }
  const body = JSON.stringify({
    client_id: clientId,
    user_id: uid ?? undefined,
    events: [{ name: event, params: cleanParams }],
  });
  try {
    await fetch(url, { method: "POST", body });
  } catch (e) {
    // Любая ошибка MP — лишь warn. Не должна валить основной trigger.
    logger.debug("ga4 mp send failed", e);
  }
}

export async function recordAnalyticsEvent(input: RecordEventInput): Promise<void> {
  const { event } = input;
  if (typeof event !== "string" || !ALLOWED_EVENTS.has(event)) {
    logger.warn(`recordAnalyticsEvent: unknown event "${event}" — dropping`);
    return;
  }

  const platform =
    input.platform && ALLOWED_PLATFORMS.has(input.platform) ? input.platform : "server";

  const params = sanitizeParams(input.params);

  try {
    await admin.firestore().collection("analyticsEvents").add({
      event,
      params,
      platform,
      uid: input.uid ?? null,
      ts: new Date().toISOString(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      source: input.source ?? "server",
    });
  } catch (e) {
    logger.warn(`analyticsEvents write failed for ${event}`, e);
  }

  const cfg = await loadAnalyticsConfig();
  if (cfg) {
    const clientId = input.uid ?? `server-${Math.random().toString(36).slice(2, 14)}`;
    // не await — fire-and-forget
    void sendMeasurementProtocol(cfg, clientId, input.uid ?? null, event, params);
  }
}
