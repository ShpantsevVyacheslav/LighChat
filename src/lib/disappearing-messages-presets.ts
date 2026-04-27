/** Значения `conversations.disappearingMessageTtlSec` (секунды). `null` = выкл. */
export const DISAPPEARING_MESSAGE_TTL_OFF = null;

export type DisappearingMessageTtlPreset = {
  label: string;
  /** null — выключено */
  ttlSec: number | null;
};

export const DISAPPEARING_MESSAGE_TTL_PRESETS: DisappearingMessageTtlPreset[] = [
  { label: 'Выкл', ttlSec: null },
  { label: '1 ч', ttlSec: 3600 },
  { label: '24 ч', ttlSec: 86400 },
  { label: '7 дн.', ttlSec: 604800 },
  { label: '30 дн.', ttlSec: 2592000 },
];

export function formatDisappearingTtlSummary(ttlSec: number | null | undefined): string {
  if (ttlSec == null || ttlSec <= 0 || !Number.isFinite(ttlSec)) return 'Выкл';
  const p = DISAPPEARING_MESSAGE_TTL_PRESETS.find((x) => x.ttlSec === ttlSec);
  if (p) return p.label === 'Выкл' ? 'Выкл' : p.label;
  if (ttlSec < 3600) return `${Math.round(ttlSec / 60)} мин`;
  if (ttlSec < 86400) return `${Math.round(ttlSec / 3600)} ч`;
  if (ttlSec < 604800) return `${Math.round(ttlSec / 86400)} дн.`;
  return `${Math.round(ttlSec / 604800)} нед.`;
}
