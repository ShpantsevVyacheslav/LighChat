/** Человекочитаемый размер (двоичные приставки). */
export function formatStorageBytes(bytes: number): string {
  if (!Number.isFinite(bytes) || bytes <= 0) return '0 Б';
  const units = ['Б', 'КиБ', 'МиБ', 'Гб', 'ТиБ'];
  let v = bytes;
  let u = 0;
  while (v >= 1024 && u < units.length - 1) {
    v /= 1024;
    u += 1;
  }
  const dec = u === 0 ? 0 : v < 10 ? 2 : 1;
  return `${v.toFixed(dec)} ${units[u]}`;
}

export function bytesToGiB(bytes: number): number {
  return bytes / 1024 ** 3;
}
