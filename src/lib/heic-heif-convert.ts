'use client';

/**
 * Клиентская конвертация HEIC/HEIF → PNG (heic2any). Нужна для WebKit/Chromium:
 * `<img>` не декодирует HEIC, стикеры с iOS иначе отображаются «битым» файлом.
 */

import { logger } from '@/lib/logger';

export function isHeicHeifMime(type: string | undefined | null): boolean {
  const t = (type || '').toLowerCase();
  return t.includes('heic') || t.includes('heif');
}

export function isHeicHeifFileName(name: string): boolean {
  const base = name.split(/[?#]/)[0] ?? name;
  return /\.hei[cf]$/i.test(base);
}

export function isHeicHeifAttachment(att: { name: string; type: string }): boolean {
  return isHeicHeifMime(att.type) || isHeicHeifFileName(att.name);
}

export async function convertHeicHeifBlobToPngBlob(blob: Blob): Promise<Blob> {
  const heic2any = (await import('heic2any')).default;
  const result = await heic2any({ blob, toType: 'image/png' });
  const out = Array.isArray(result) ? result[0] : result;
  if (!out || !(out instanceof Blob)) throw new Error('heic2any: empty result');
  return out;
}

/** Загрузка по URL (Storage/Firebase) и конвертация для показа в `<img>`. */
export async function fetchUrlAndConvertHeicToPngObjectUrl(url: string): Promise<string | null> {
  try {
    const res = await fetch(url, { mode: 'cors' });
    if (!res.ok) return null;
    const blob = await res.blob();
    const png = await convertHeicHeifBlobToPngBlob(blob);
    return URL.createObjectURL(png);
  } catch (e) {
    logger.warn('heic', 'convert display URL failed', e);
    return null;
  }
}
