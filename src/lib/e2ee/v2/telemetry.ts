/**
 * Phase 9 — лёгкая клиентская телеметрия для E2EE v2.
 *
 * Что делает:
 *  - Один единственный ассинк-хэндлер `logE2eeEvent(...)` печатает событие в
 *    `logger.debug` (через wrapper) с единым префиксом `[e2ee/v2]` и —
 *    опционально — вызывает подключаемый subscriber (см. `setE2eeTelemetrySink`).
 *  - События типизированы, чтобы при rollout'е было проще фильтровать логи и
 *    подключать реальную аналитику (Datadog/Firebase Analytics/Sentry).
 *
 * Почему так скромно: на момент Phase 9 у проекта нет централизованного
 * analytics-пайплайна, а ставить новую зависимость в ответственном E2EE-пути
 * мы не хотим (см. user rule §8 Dependency Management). Этот модуль —
 * контракт, к которому легко пристегнуть реальный sink в будущем.
 *
 * Безопасность: все `data` должны быть «безобидные» идентификаторы/коды
 * (conversationId, userId, deviceId). НИКОГДА не логируем открытый текст,
 * шифротекст, ключи, отпечатки в полной форме.
 */

import { logger } from '@/lib/logger';

export type E2eeTelemetryEventType =
  | 'e2ee.v2.enable.success'
  | 'e2ee.v2.enable.failure'
  | 'e2ee.v2.rotate.success'
  | 'e2ee.v2.rotate.failure'
  | 'e2ee.v2.device.published'
  | 'e2ee.v2.device.revoked'
  | 'e2ee.v2.decrypt.failure'
  | 'e2ee.v2.media.encrypt.failure'
  | 'e2ee.v2.media.decrypt.failure'
  | 'e2ee.v2.backup.create.success'
  | 'e2ee.v2.backup.create.failure'
  | 'e2ee.v2.backup.restore.success'
  | 'e2ee.v2.backup.restore.failure'
  | 'e2ee.v2.pairing.initiated'
  | 'e2ee.v2.pairing.completed'
  | 'e2ee.v2.pairing.rejected';

export type E2eeTelemetryPayload = {
  /** Текущий пользователь (если известен). */
  userId?: string;
  /** ID чата, если событие чат-контекстное. */
  conversationId?: string;
  /** ID устройства (без приватника). */
  deviceId?: string;
  /** Код ошибки — строковый идентификатор без трассировки stack'ов. */
  errorCode?: string;
  /** Произвольные числовые метрики (epoch, chunkCount). */
  metrics?: Record<string, number>;
};

export type E2eeTelemetrySink = (
  type: E2eeTelemetryEventType,
  payload: E2eeTelemetryPayload
) => void;

let activeSink: E2eeTelemetrySink | null = null;

/**
 * Подключить sink (например, при инициализации Analytics). Повторный вызов
 * заменяет предыдущий. Передайте `null`, чтобы отключить.
 */
export function setE2eeTelemetrySink(sink: E2eeTelemetrySink | null): void {
  activeSink = sink;
}

/**
 * Основная точка входа. Никогда не бросает исключения — внутри try/catch,
 * чтобы сломанный sink не уронил E2EE-поток.
 */
export function logE2eeEvent(
  type: E2eeTelemetryEventType,
  payload: E2eeTelemetryPayload = {}
): void {
  try {
    // logger.debug — глушится в prod, виден в dev / при verbose flag.
    // Все consumer'ы могут подцепиться через activeSink (Sentry breadcrumbs).
    logger.debug('e2ee', type, payload);
    activeSink?.(type, payload);
  } catch {
    /* intentionally silent — telemetry must never break the crypto path */
  }
}

/** Утилита: извлечь «безопасный» код ошибки из произвольного Error. */
export function normalizeErrorCode(err: unknown): string {
  if (err instanceof Error) {
    const msg = err.message || 'unknown';
    // Ограничиваем до 80 символов, чтобы в лог не улетали длинные stack-like строки.
    return msg.slice(0, 80);
  }
  const s = String(err);
  return s.slice(0, 80);
}
