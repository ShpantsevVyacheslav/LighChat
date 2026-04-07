'use client';

import { getImageMetadata } from '@/lib/media-utils';

/**
 * Авто-пометка `sticker_*` только для сценария «вставка в поле ввода» (в т.ч. клавиатура
 * стикеров iOS). Файлы с галереи / drag-drop / `<input type="file">` не проходят через эту
 * эвристику — остаются обычными вложениями (см. `ChatMessageInput.ingestAttachmentFiles`).
 */
const STICKER_MAX_SIDE_PX = 640;
const STICKER_MAX_BYTES = 900_000;
const STICKER_MIN_ASPECT = 0.4;
/** Доля выборочных пикселей с alpha < 250 — признак прозрачности, типичной для наклеек. */
const TRANSPARENT_PIXEL_RATIO_MIN = 0.012;

/**
 * Проверка альфы на уменьшенной выборке (быстрее, чем полный кадр).
 */
async function imageFileHasPerceivableAlpha(file: File): Promise<boolean> {
  const t = file.type.toLowerCase();
  if (t !== 'image/png' && t !== 'image/webp') return false;

  return new Promise((resolve) => {
    const url = URL.createObjectURL(file);
    const img = new Image();
    img.onload = () => {
      try {
        const w = img.naturalWidth;
        const h = img.naturalHeight;
        const maxSample = 96;
        const scale = Math.min(maxSample / w, maxSample / h, 1);
        const cw = Math.max(1, Math.round(w * scale));
        const ch = Math.max(1, Math.round(h * scale));
        const canvas = document.createElement('canvas');
        canvas.width = cw;
        canvas.height = ch;
        const ctx = canvas.getContext('2d');
        if (!ctx) {
          URL.revokeObjectURL(url);
          resolve(false);
          return;
        }
        ctx.drawImage(img, 0, 0, cw, ch);
        const data = ctx.getImageData(0, 0, cw, ch).data;
        let soft = 0;
        let n = 0;
        const stride = 4 * 3;
        for (let i = 0; i < data.length; i += stride) {
          n += 1;
          if (data[i + 3] < 250) soft += 1;
        }
        URL.revokeObjectURL(url);
        resolve(n > 0 && soft / n >= TRANSPARENT_PIXEL_RATIO_MIN);
      } catch {
        URL.revokeObjectURL(url);
        resolve(false);
      }
    };
    img.onerror = () => {
      URL.revokeObjectURL(url);
      resolve(false);
    };
    img.src = url;
  });
}

/** Редкие плоские стикеры без заметной прозрачности — очень маленький почти квадрат. */
function looksLikeTinySquareSticker(w: number, h: number, fileSize: number): boolean {
  const max = Math.max(w, h);
  const min = Math.min(w, h);
  if (max > 420 || fileSize > 450_000) return false;
  return min / max >= 0.82;
}

export async function shouldTreatImageFileAsIosSticker(file: File): Promise<boolean> {
  if (!file.type.startsWith('image/')) return false;
  const mime = file.type.toLowerCase();
  if (mime.includes('svg')) return false;
  if (mime === 'image/gif') return false;
  if (mime === 'image/jpeg' || mime === 'image/jpg' || mime === 'image/heic' || mime === 'image/heif') {
    return false;
  }
  if (file.size > STICKER_MAX_BYTES) return false;

  try {
    const { width: w, height: h } = await getImageMetadata(file);
    if (!w || !h) return false;
    const max = Math.max(w, h);
    const min = Math.min(w, h);
    if (max > STICKER_MAX_SIDE_PX) return false;
    const ratio = min / max;
    if (ratio < STICKER_MIN_ASPECT) return false;

    if (mime === 'image/png' || mime === 'image/webp') {
      if (await imageFileHasPerceivableAlpha(file)) return true;
      if (looksLikeTinySquareSticker(w, h, file.size)) return true;
      return false;
    }

    return false;
  } catch {
    return false;
  }
}

function stickerExtFromMime(mime: string): string {
  if (mime === 'image/png') return 'png';
  if (mime === 'image/webp') return 'webp';
  if (mime === 'image/jpeg' || mime === 'image/jpg') return 'jpg';
  if (mime === 'image/heic' || mime === 'image/heif') return 'heic';
  return 'png';
}

/**
 * Если файл проходит узкую проверку «стикер с клавиатуры / вставка», переименовывает в `sticker_*`.
 */
export async function normalizeFileAsStickerIfApplicable(
  file: File,
  applyKeyboardStickerHeuristic = true
): Promise<File> {
  if (!applyKeyboardStickerHeuristic) return file;
  if (file.name.startsWith('sticker_') || file.name.startsWith('gif_')) return file;
  const ok = await shouldTreatImageFileAsIosSticker(file);
  if (!ok) return file;
  const ext = stickerExtFromMime(file.type || 'image/png');
  const name = `sticker_${Date.now()}_${Math.random().toString(36).slice(2, 9)}.${ext}`;
  return new File([file], name, { type: file.type, lastModified: file.lastModified });
}

export async function normalizeFilesAsStickersIfApplicable(
  files: File[],
  applyKeyboardStickerHeuristic = true
): Promise<File[]> {
  return Promise.all(files.map((f) => normalizeFileAsStickerIfApplicable(f, applyKeyboardStickerHeuristic)));
}
