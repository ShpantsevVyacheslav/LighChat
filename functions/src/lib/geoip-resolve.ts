import * as logger from "firebase-functions/logger";

/**
 * Lazy-инициализация `geoip-lite`. Прямой `import geoip from "geoip-lite"`
 * на top-level загружает ~30 MB бинарной MaxMind базы при модулe load,
 * что вылетает за startup probe timeout Cloud Run (контейнер не успевает
 * слушать порт 8080 → Healthcheck failed). Делаем `require` при первом
 * lookup'е — container стартует мгновенно, БД грузится при первом
 * invocation. Subsequent invocations используют кешированный модуль.
 */
type GeoipLookupFn = (ip: string) => { country?: string; city?: string } | null;
let geoipLookup: GeoipLookupFn | null = null;
function getGeoipLookup(): GeoipLookupFn | null {
  if (geoipLookup) return geoipLookup;
  try {
    // eslint-disable-next-line @typescript-eslint/no-require-imports, @typescript-eslint/no-var-requires
    const mod = require("geoip-lite") as { lookup: GeoipLookupFn };
    geoipLookup = mod.lookup;
    return geoipLookup;
  } catch (e) {
    logger.error("[geoip-resolve] failed to load geoip-lite", e);
    return null;
  }
}

/**
 * Резолвит IP → { country, city } через offline MaxMind GeoLite2 базу
 * (`geoip-lite`). Используется в callable-функциях, которые пишут гео
 * устройства (`updateDeviceLastLocation`, `confirmQrLogin`).
 *
 * Контекст: раньше код брал гео из заголовков `x-appengine-country` /
 * `x-appengine-city`, но эти заголовки проставляет ТОЛЬКО App Engine
 * Standard (1st gen). Наши функции — Cloud Functions 2nd gen на Cloud
 * Run, и эти заголовки всегда пустые. В результате во всех документах
 * `users/{uid}/devices/{deviceId}` хранились только `lastLoginIp`, а
 * `lastLoginCountry`/`lastLoginCity` оставались `""` — админ-таб
 * «География пользователей» показывал «известно у 0 из N».
 *
 * Если есть заголовки от App Engine / LB (на случай будущей миграции
 * за Cloud Load Balancer с client-geo header rules) — отдаём им
 * приоритет: они авторитетнее, чем offline-DB lookup.
 */

export type GeoResolveInput = {
  ip: string;
  headerCountry?: string;
  headerCity?: string;
};

export type GeoResolveResult = {
  country: string; // ISO-2 ('RU', 'US', ...) или ''
  city: string;
};

/**
 * Приватный IP / loopback — для них geoip-lite вернёт null, нет смысла
 * вообще вызывать lookup. Дополнительная защита: некоторые dev/test
 * вызовы могут приходить с 127.0.0.1.
 */
function isPrivateOrLoopback(ip: string): boolean {
  if (!ip) return true;
  if (ip === "::1" || ip.startsWith("127.")) return true;
  if (ip.startsWith("10.")) return true;
  if (ip.startsWith("192.168.")) return true;
  // 172.16.0.0/12
  if (/^172\.(1[6-9]|2\d|3[01])\./.test(ip)) return true;
  // IPv6 ULA
  if (ip.toLowerCase().startsWith("fc") || ip.toLowerCase().startsWith("fd")) return true;
  return false;
}

export function resolveGeoFromIp(input: GeoResolveInput): GeoResolveResult {
  const headerCountry = (input.headerCountry || "").trim().toUpperCase().slice(0, 8);
  const headerCity = (input.headerCity || "").trim().slice(0, 64);
  if (headerCountry || headerCity) {
    return { country: headerCountry, city: headerCity };
  }

  const ip = (input.ip || "").trim();
  if (!ip || isPrivateOrLoopback(ip)) {
    return { country: "", city: "" };
  }

  try {
    const lookup = getGeoipLookup();
    if (!lookup) return { country: "", city: "" };
    const result = lookup(ip);
    if (!result) {
      return { country: "", city: "" };
    }
    return {
      country: (result.country || "").toUpperCase().slice(0, 8),
      city: (result.city || "").slice(0, 64),
    };
  } catch (e) {
    logger.warn("[geoip-resolve] lookup failed", { ip, error: String(e) });
    return { country: "", city: "" };
  }
}
