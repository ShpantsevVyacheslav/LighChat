/**
 * Нормализация логина для автогенерации и проверок.
 * Если строка похожа на email (есть `@`), в качестве основы берётся только часть до `@`
 * (например `shpantsev.vyacheslav@m.thelightech.com` → `shpantsev.vyacheslav`).
 */

export function usernameLocalPartFromMaybeEmail(raw: string): string {
  const s = String(raw ?? "")
    .trim()
    .replace(/^@/, "");
  const at = s.indexOf("@");
  if (at === -1) return s;
  return s.slice(0, at).trim();
}

export function normalizeUsernameCandidate(raw: string): string {
  let base = usernameLocalPartFromMaybeEmail(raw).toLowerCase();
  base = base
    .replace(/[^a-z0-9_.]+/gu, "_")
    .replace(/_+/gu, "_")
    .replace(/\.{2,}/gu, ".")
    .replace(/^[._]+|[._]+$/gu, "");
  return base.slice(0, 30);
}

/**
 * Допустимый нормализованный логин: латиница, цифры, `_`, `.`; длина 3–30;
 * не начинается/не заканчивается точкой; без `..`.
 */
export function isNormalizedUsernameTokenAllowed(normalized: string): boolean {
  const s = String(normalized ?? "").trim();
  if (s.length < 3 || s.length > 30) return false;
  if (!/^[a-z0-9][a-z0-9._]*[a-z0-9]$/u.test(s)) return false;
  if (s.includes("..")) return false;
  return true;
}
