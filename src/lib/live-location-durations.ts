/**
 * Варианты длительности «живой» геолокации (кроме одноразовой отправки точки в чат).
 */
export type LiveLocationDurationId =
  | 'once'
  | 'm5'
  | 'm15'
  | 'm30'
  | 'h1'
  | 'h2'
  | 'h6'
  | 'd1'
  | 'forever';

export type LiveLocationDurationOption = {
  id: LiveLocationDurationId;
  label: string;
  /** null для «навсегда»; для once не используется */
  durationMs: number | null;
};

export const LIVE_LOCATION_DURATION_OPTIONS: LiveLocationDurationOption[] = [
  { id: 'once', label: 'Одноразово (только это сообщение)', durationMs: null },
  { id: 'm5', label: '5 минут', durationMs: 5 * 60 * 1000 },
  { id: 'm15', label: '15 минут', durationMs: 15 * 60 * 1000 },
  { id: 'm30', label: '30 минут', durationMs: 30 * 60 * 1000 },
  { id: 'h1', label: '1 час', durationMs: 60 * 60 * 1000 },
  { id: 'h2', label: '2 часа', durationMs: 2 * 60 * 60 * 1000 },
  { id: 'h6', label: '6 часов', durationMs: 6 * 60 * 60 * 1000 },
  { id: 'd1', label: '1 день', durationMs: 24 * 60 * 60 * 1000 },
  { id: 'forever', label: 'Навсегда (пока не отключу)', durationMs: null },
];

export function expiresAtForDurationId(id: LiveLocationDurationId): string | null {
  if (id === 'once' || id === 'forever') return null;
  const opt = LIVE_LOCATION_DURATION_OPTIONS.find((o) => o.id === id);
  const ms = opt?.durationMs;
  if (ms == null) return null;
  return new Date(Date.now() + ms).toISOString();
}
