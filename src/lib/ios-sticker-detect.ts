'use client';

import { getImageMetadata } from '@/lib/media-utils';
import { convertHeicHeifBlobToPngBlob, isHeicHeifFileName, isHeicHeifMime } from '@/lib/heic-heif-convert';

/**
 * Авто-пометка `sticker_*` для стикеров iOS (вставка, клавиатура) и для малых HEIC/HEIF
 * из «Поднять субъект» / наклеек: до отправки конвертируем в PNG — иначе в чате `<img>` не рендерит HEIC.
 * Файлы HEIC размером как обычное фото не проходят геометрию и остаются обычным вложением.
 */
const STICKER_MAX_SIDE_PX = 640;
const STICKER_MAX_BYTES = 900_000;
/** Для PNG/WebP с заметной прозрачностью и для HEIC→PNG с альфой — типичный «Поднять субъект» крупнее 640px. */
const STICKER_LOOSE_MAX_SIDE_PX = 2048;
const STICKER_LOOSE_MAX_BYTES = 2_000_000;
/** Сырые HEIC до этого размера пробуем конвертировать для проверки альфы (тяжёлые снимки не гоняем). */
const HEIC_TRY_CONVERT_MAX_BYTES = 8_000_000;
const STICKER_MIN_ASPECT = 0.4;
/** Доля выборочных пикселей с alpha < 250 — признак прозрачности, типичной для наклеек. */
const TRANSPARENT_PIXEL_RATIO_MIN = 0.012;

function fileLooksLikeHeicContainer(file: File): boolean {
  return isHeicHeifMime(file.type) || isHeicHeifFileName(file.name);
}

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

async function passesStickerGeometry(file: File): Promise<boolean> {
  try {
    const { width: w, height: h } = await getImageMetadata(file);
    if (!w || !h) return false;
    const max = Math.max(w, h);
    const min = Math.min(w, h);
    if (max > STICKER_MAX_SIDE_PX) return false;
    if (min / max < STICKER_MIN_ASPECT) return false;
    return true;
  } catch {
    return false;
  }
}

async function passesStickerGeometryLoose(file: File): Promise<boolean> {
  try {
    const { width: w, height: h } = await getImageMetadata(file);
    if (!w || !h) return false;
    const max = Math.max(w, h);
    const min = Math.min(w, h);
    if (max > STICKER_LOOSE_MAX_SIDE_PX) return false;
    if (min / max < STICKER_MIN_ASPECT) return false;
    return true;
  } catch {
    return false;
  }
}

async function shouldTreatNonHeicIosSticker(file: File): Promise<boolean> {
  if (!file.type.startsWith('image/')) return false;
  const mime = file.type.toLowerCase();
  if (mime.includes('svg')) return false;
  if (mime === 'image/gif') return false;
  if (mime === 'image/jpeg' || mime === 'image/jpg') return false;
  if (isHeicHeifMime(mime)) return false;

  try {
    const { width: w, height: h } = await getImageMetadata(file);
    if (!w || !h) return false;
    const max = Math.max(w, h);
    const min = Math.min(w, h);
    const ratio = min / max;
    if (ratio < STICKER_MIN_ASPECT) return false;

    if (mime === 'image/png' || mime === 'image/webp') {
      const hasAlpha = await imageFileHasPerceivableAlpha(file);
      if (hasAlpha) {
        if (file.size > STICKER_LOOSE_MAX_BYTES) return false;
        if (max > STICKER_LOOSE_MAX_SIDE_PX) return false;
        return true;
      }
      if (file.size > STICKER_MAX_BYTES) return false;
      if (max > STICKER_MAX_SIDE_PX) return false;
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
  return 'png';
}

/**
 * HEIC/HEIF из iOS: при подходящих размерах конвертируем в PNG и именуем `sticker_*`
 * (независимо от того, вставка с клавиатуры или выбор файла).
 */
export async function normalizeFileAsStickerIfApplicable(
  file: File,
  applyKeyboardStickerHeuristic = true
): Promise<File> {
  if (file.name.startsWith('sticker_') || file.name.startsWith('gif_')) return file;

  if (fileLooksLikeHeicContainer(file)) {
    if (file.size > HEIC_TRY_CONVERT_MAX_BYTES) return file;
    let pngBlob: Blob;
    try {
      pngBlob = await convertHeicHeifBlobToPngBlob(file);
    } catch (e) {
      console.warn('[LighChat:sticker] HEIC→PNG failed', e);
      return file;
    }
    const probe = new File([pngBlob], 'probe.png', { type: 'image/png', lastModified: file.lastModified });
    const hasAlpha = await imageFileHasPerceivableAlpha(probe);
    const looseOk =
      hasAlpha &&
      probe.size <= STICKER_LOOSE_MAX_BYTES &&
      (await passesStickerGeometryLoose(probe));
    const strictOk =
      file.size <= STICKER_MAX_BYTES && (await passesStickerGeometry(probe));
    if (!looseOk && !strictOk) return file;

    const name = `sticker_${Date.now()}_${Math.random().toString(36).slice(2, 9)}.png`;
    return new File([pngBlob], name, { type: 'image/png', lastModified: file.lastModified });
  }

  if (!applyKeyboardStickerHeuristic) return file;

  const ok = await shouldTreatNonHeicIosSticker(file);
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

/**
 * Синхронная эвристика для уже сохранённых вложений: «вырез» / наклейка без префикса `sticker_`.
 * iOS не добавляет отдельного MIME — опираемся на PNG/WebP, геометрию и размер (без чтения пикселей).
 * JPEG без альфы распознать нельзя; при отправке новых файлов помогает `normalizeFileAsStickerIfApplicable`.
 */
export function isAttachmentLikelyIosStickerCutout(att: { name?: string; type?: string; size: number; width?: number; height?: number }): boolean {
  // Defensive: E2EE/оптимистичные/legacy могут принести `name`/`type` undefined.
  const name = att.name ?? '';
  if (name.startsWith('gif_')) return false;
  if (name.startsWith('sticker_') || att.type === 'image/svg+xml') return true;
  const t = (att.type || '').toLowerCase();
  if (t !== 'image/png' && t !== 'image/webp') return false;

  const w = att.width;
  const h = att.height;
  if (!w || !h || w <= 0 || h <= 0) return false;

  const max = Math.max(w, h);
  const min = Math.min(w, h);
  const ratio = min / max;
  if (max > STICKER_LOOSE_MAX_SIDE_PX || att.size > STICKER_LOOSE_MAX_BYTES) return false;
  if (ratio < STICKER_MIN_ASPECT) return false;

  if (max <= STICKER_MAX_SIDE_PX && att.size <= STICKER_MAX_BYTES) return true;
  if (ratio >= 0.85) return true;
  if (max <= 1024 && ratio >= 0.5) return true;
  return false;
}
