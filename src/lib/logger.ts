/**
 * [audit L-003] Project-wide logger для web/electron клиентов.
 *
 * Зачем:
 *  - Раньше прямые `console.*` (~340 в `src/`) шумели в prod-консоли пользователя
 *    и потенциально утекали PII (см. audit H-005). Прямые вызовы лезут в логи
 *    Crashlytics/Sentry/баг-репорты пользователя — каждый из 340 вызовов был
 *    риском.
 *  - С wrapper'ом мы централизуем: в prod подавляем `debug`/`info`, оставляем
 *    `warn`/`error`. При желании добавим remote sink (Sentry/Crashlytics).
 *
 * Использование:
 *   import { logger } from '@/lib/logger';
 *   logger.debug('user-auth', 'sign-in start', { uid });
 *   logger.error('storage', 'upload failed', err);
 *
 * Контракт:
 *  - `area` — короткий тег модуля (1–2 слова), помогает фильтровать в DevTools.
 *  - extra — необязательный объект; крупные структуры избегайте (push в console.log
 *    держит ссылку → утечка памяти при долгих сессиях).
 *
 * Глушилка:
 *  - prod: `debug` / `info` no-op'ятся.
 *  - dev: всё печатается с префиксом `[area]`.
 *  - принудительный verbose в prod: `localStorage.setItem('lc_log_verbose', '1')`.
 */

function isVerboseEnabled(): boolean {
  if (typeof process !== 'undefined' && process.env.NODE_ENV !== 'production') return true;
  if (typeof window === 'undefined') return false;
  try {
    return window.localStorage.getItem('lc_log_verbose') === '1';
  } catch {
    return false;
  }
}

function format(area: string, message: string): string {
  return `[${area}] ${message}`;
}

export const logger = {
  debug(area: string, message: string, extra?: unknown): void {
    if (!isVerboseEnabled()) return;
    if (extra !== undefined) {
      // eslint-disable-next-line no-console
      console.debug(format(area, message), extra);
    } else {
      // eslint-disable-next-line no-console
      console.debug(format(area, message));
    }
  },
  info(area: string, message: string, extra?: unknown): void {
    if (!isVerboseEnabled()) return;
    if (extra !== undefined) {
      // eslint-disable-next-line no-console
      console.info(format(area, message), extra);
    } else {
      // eslint-disable-next-line no-console
      console.info(format(area, message));
    }
  },
  warn(area: string, message: string, extra?: unknown): void {
    if (extra !== undefined) {
      // eslint-disable-next-line no-console
      console.warn(format(area, message), extra);
    } else {
      // eslint-disable-next-line no-console
      console.warn(format(area, message));
    }
  },
  error(area: string, message: string, error?: unknown, extra?: unknown): void {
    if (error !== undefined && extra !== undefined) {
      // eslint-disable-next-line no-console
      console.error(format(area, message), error, extra);
    } else if (error !== undefined) {
      // eslint-disable-next-line no-console
      console.error(format(area, message), error);
    } else {
      // eslint-disable-next-line no-console
      console.error(format(area, message));
    }
  },
};
