/**
 * Клиентский запрос координат для «Поделиться геолокацией».
 * Логи в консоль с префиксом [LighChat:geolocation] — фильтр в DevTools.
 * Ключ NEXT_PUBLIC_GOOGLE_MAPS_API_KEY не используется здесь (только Static Map URL после получения lat/lng).
 */

export const GEOLOCATION_CLIENT_LOG = '[LighChat:geolocation]';
export const GEOLOCATION_FIRESTORE_LOG = '[LighChat:geolocation:firestore]';

function log(phase: string, detail?: Record<string, unknown>) {
  if (detail !== undefined) {
    console.log(GEOLOCATION_CLIENT_LOG, phase, detail);
  } else {
    console.log(GEOLOCATION_CLIENT_LOG, phase);
  }
}

export function geolocationErrorCodeName(code: number): string {
  switch (code) {
    case 1:
      return 'PERMISSION_DENIED';
    case 2:
      return 'POSITION_UNAVAILABLE';
    case 3:
      return 'TIMEOUT';
    default:
      return `UNKNOWN(${code})`;
  }
}

function getCurrentPositionPromise(options: PositionOptions): Promise<GeolocationPosition> {
  return new Promise((resolve, reject) => {
    navigator.geolocation.getCurrentPosition(resolve, reject, options);
  });
}

function optionsForLog(o: PositionOptions) {
  return {
    enableHighAccuracy: o.enableHighAccuracy ?? false,
    timeout: o.timeout,
    maximumAge: o.maximumAge,
  };
}

export class GeolocationUnsupportedError extends Error {
  constructor() {
    super('GEOLOCATION_UNSUPPORTED');
    this.name = 'GeolocationUnsupportedError';
  }
}

/**
 * Запрашивает позицию с логами. При TIMEOUT (часто с enableHighAccuracy на ПК) — вторая попытка без высокой точности.
 */
export async function requestCurrentPositionForShare(): Promise<GeolocationPosition> {
  if (typeof navigator === 'undefined' || !navigator.geolocation) {
    log('abort', { reason: 'navigator.geolocation недоступен' });
    throw new GeolocationUnsupportedError();
  }

  const mapsKeyPresent = Boolean(process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY?.trim());
  log('start', {
    mapsKeyPresent,
    hint: 'Координаты даёт только браузер (Geolocation API), не Google Maps ключ',
    ...(mapsKeyPresent
      ? {}
      : {
          envHint:
            'mapsKeyPresent=false: ключ не попал в клиентский бандл — проверьте NEXT_PUBLIC_GOOGLE_MAPS_API_KEY в .env.local и перезапустите npm run dev / пересоберите production',
        }),
  });

  if (typeof navigator.permissions?.query === 'function') {
    try {
      const status = await navigator.permissions.query({ name: 'geolocation' });
      log('permission.query', { state: status.state });
    } catch (e) {
      log('permission.query.error', { message: e instanceof Error ? e.message : String(e) });
    }
  } else {
    log('permission.query', { skipped: 'Permissions API нет в этом браузере' });
  }

  const highAccuracy: PositionOptions = {
    enableHighAccuracy: true,
    timeout: 20000,
    maximumAge: 60000,
  };
  log('getCurrentPosition', { attempt: 1, options: optionsForLog(highAccuracy) });

  try {
    const pos = await getCurrentPositionPromise(highAccuracy);
    log('success', {
      lat: pos.coords.latitude,
      lng: pos.coords.longitude,
      accuracyM: pos.coords.accuracy,
      timestamp: pos.timestamp,
    });
    return pos;
  } catch (first) {
    const err = first as GeolocationPositionError;
    log('error', {
      attempt: 1,
      code: err.code,
      codeName: geolocationErrorCodeName(err.code),
      message: err.message || '(пусто — так бывает в части браузеров)',
    });

    if (err.code === 3) {
      const fallback: PositionOptions = {
        enableHighAccuracy: false,
        timeout: 45000,
        maximumAge: 300000,
      };
      log('getCurrentPosition', { attempt: 2, note: 'повтор после TIMEOUT', options: optionsForLog(fallback) });
      try {
        const pos = await getCurrentPositionPromise(fallback);
        log('success', {
          attempt: 2,
          lat: pos.coords.latitude,
          lng: pos.coords.longitude,
          accuracyM: pos.coords.accuracy,
        });
        return pos;
      } catch (second) {
        const e2 = second as GeolocationPositionError;
        log('error', {
          attempt: 2,
          code: e2.code,
          codeName: geolocationErrorCodeName(e2.code),
          message: e2.message || '(пусто)',
        });
        if (e2.code === 3) {
          const cachedOk: PositionOptions = {
            enableHighAccuracy: false,
            timeout: 10000,
            maximumAge: 86_400_000,
          };
          log('getCurrentPosition', {
            attempt: 3,
            note: 'после двойного TIMEOUT: разрешить кэш до 24 ч (часто мгновенный ответ)',
            options: optionsForLog(cachedOk),
          });
          try {
            const pos = await getCurrentPositionPromise(cachedOk);
            log('success', {
              attempt: 3,
              lat: pos.coords.latitude,
              lng: pos.coords.longitude,
              accuracyM: pos.coords.accuracy,
            });
            return pos;
          } catch (third) {
            const e3 = third as GeolocationPositionError;
            log('error', {
              attempt: 3,
              code: e3.code,
              codeName: geolocationErrorCodeName(e3.code),
              message: e3.message || '(пусто)',
            });
            throw third;
          }
        }
        throw second;
      }
    }

    throw first;
  }
}
