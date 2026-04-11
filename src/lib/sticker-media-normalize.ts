/**
 * Клиентская нормализация медиа для пользовательских стикерпаков и превью в сетке чата.
 */

export const USER_STICKER_SQUARE_MAX_PX = 512;
/** Видео в пак — только если длительность не больше этого порога (сек). */
export const USER_STICKER_VIDEO_MAX_UPLOAD_SEC = 5;
/** В сетке сообщения короткие ролики ведут себя как зацикленный GIF. */
export const CHAT_GRID_VIDEO_GIFLIKE_MAX_SEC = 10;

function loadImageElement(url: string): Promise<HTMLImageElement> {
  return new Promise((resolve, reject) => {
    const i = new Image();
    i.crossOrigin = 'anonymous';
    i.onload = () => resolve(i);
    i.onerror = () => reject(new Error('sticker_image_load_failed'));
    i.src = url;
  });
}

export async function getVideoFileDurationSeconds(file: File): Promise<number | null> {
  if (typeof document === 'undefined') return null;
  const url = URL.createObjectURL(file);
  try {
    const v = document.createElement('video');
    v.preload = 'metadata';
    v.muted = true;
    return await new Promise((resolve) => {
      const done = (d: number | null) => {
        v.removeAttribute('src');
        v.load();
        resolve(d);
      };
      v.onloadedmetadata = () => {
        const d = v.duration;
        done(Number.isFinite(d) && d > 0 ? d : null);
      };
      v.onerror = () => done(null);
      v.src = url;
    });
  } finally {
    URL.revokeObjectURL(url);
  }
}

/** Центральный квадратный кроп, масштаб до maxPx×maxPx, PNG. */
export async function blobToSquareCenterCroppedPngBlob(blob: Blob, maxPx: number): Promise<Blob> {
  if (typeof document === 'undefined') throw new Error('no_document');
  const url = URL.createObjectURL(blob);
  try {
    const img = await loadImageElement(url);
    const w = img.naturalWidth;
    const h = img.naturalHeight;
    if (!w || !h) throw new Error('invalid_image_dims');
    const side = Math.min(w, h);
    const sx = (w - side) / 2;
    const sy = (h - side) / 2;
    const canvas = document.createElement('canvas');
    canvas.width = maxPx;
    canvas.height = maxPx;
    const ctx = canvas.getContext('2d');
    if (!ctx) throw new Error('no_canvas');
    ctx.drawImage(img, sx, sy, side, side, 0, 0, maxPx, maxPx);
    return await new Promise<Blob>((res, rej) => {
      canvas.toBlob((b) => (b ? res(b) : rej(new Error('toBlob_failed'))), 'image/png', 0.92);
    });
  } finally {
    URL.revokeObjectURL(url);
  }
}
