/**
 * Приводит сохранённый цвет фона плитки к виду #rrggbb для нативного input[type=color].
 */
export function tileBackgroundToColorInputValue(
  raw: string | null | undefined,
  fallback: string
): string {
  if (typeof raw !== 'string') return fallback;
  let s = raw.trim();
  if (!s) return fallback;
  if (/^#[0-9a-fA-F]{3}$/.test(s)) {
    s = `#${s[1]}${s[1]}${s[2]}${s[2]}${s[3]}${s[3]}`;
  }
  const six = /^#([0-9a-fA-F]{6})/.exec(s);
  if (six) return `#${six[1].toLowerCase()}`;
  return fallback;
}
