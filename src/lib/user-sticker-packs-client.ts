'use client';

import { addDoc, collection, deleteDoc, doc, getDocs, updateDoc, writeBatch } from 'firebase/firestore';
import { deleteObject, getDownloadURL, ref as storageRef, uploadBytes } from 'firebase/storage';
import type { Firestore } from 'firebase/firestore';
import type { FirebaseStorage } from 'firebase/storage';

import type { ChatAttachment } from '@/lib/types';
import { getImageMetadata } from '@/lib/media-utils';
import { USER_STICKER_MAX_FILE_BYTES } from '@/lib/user-sticker-packs';
import { convertHeicHeifBlobToPngBlob, isHeicHeifAttachment } from '@/lib/heic-heif-convert';
import {
  USER_STICKER_SQUARE_MAX_PX,
  USER_STICKER_VIDEO_MAX_UPLOAD_SEC,
  blobToSquareCenterCroppedPngBlob,
  getVideoFileDurationSeconds,
} from '@/lib/sticker-media-normalize';
import { logger } from '@/lib/logger';

export type AddImageFilesToPackOptions = {
  /** Уже приведён к квадрату (например из «Создать стикер»). */
  skipCanvasNormalize?: boolean;
};

async function normalizeStaticImageFileForUserStickerPack(file: File): Promise<File> {
  if (file.type === 'image/gif' || file.type === 'image/svg+xml') return file;
  let work = file;
  if (isHeicHeifAttachment({ name: file.name, type: file.type })) {
    try {
      const b = await convertHeicHeifBlobToPngBlob(file);
      work = new File([b], file.name.replace(/\.hei[cf]$/i, '.png'), { type: 'image/png' });
    } catch (e) {
      logger.warn('stickers', 'HEIC normalize for pack', e);
      return file;
    }
  }
  if (!work.type.startsWith('image/')) return file;
  try {
    const out = await blobToSquareCenterCroppedPngBlob(work, USER_STICKER_SQUARE_MAX_PX);
    const base =
      work.name
        .replace(/\.[^.]+$/, '')
        .replace(/[^\w.\-]+/g, '_')
        .slice(0, 80) || 'sticker';
    return new File([out], `${base}_sq.png`, { type: 'image/png' });
  } catch (e) {
    logger.warn('stickers', 'square crop failed, using original', e);
    return file;
  }
}

/**
 * Подсчёт вхождений `storagePath` по всем стикерам пользователя (дублированные паки могут ссылаться на один файл).
 */
async function countUserStickerStoragePaths(fs: Firestore, userId: string): Promise<Map<string, number>> {
  const counts = new Map<string, number>();
  const packsSnap = await getDocs(collection(fs, 'users', userId, 'stickerPacks'));
  await Promise.all(
    packsSnap.docs.map(async (packDoc) => {
      const itemsSnap = await getDocs(collection(fs, 'users', userId, 'stickerPacks', packDoc.id, 'items'));
      for (const it of itemsSnap.docs) {
        const sp = it.data().storagePath;
        if (typeof sp === 'string' && sp.length > 0) {
          counts.set(sp, (counts.get(sp) || 0) + 1);
        }
      }
    })
  );
  return counts;
}

/**
 * Удаляет пак, документы `items` и файлы в Storage, на которые больше нет ссылок в других паках.
 */
export async function deleteUserStickerPack(
  fs: Firestore,
  st: FirebaseStorage,
  userId: string,
  packId: string
): Promise<{ ok: boolean; error?: string }> {
  try {
    const pathCounts = await countUserStickerStoragePaths(fs, userId);
    const itemsCol = collection(fs, 'users', userId, 'stickerPacks', packId, 'items');
    const itemsSnap = await getDocs(itemsCol);
    const storagePathsToRemove: string[] = [];

    for (const d of itemsSnap.docs) {
      const path = d.data().storagePath;
      if (typeof path === 'string' && path.length > 0 && (pathCounts.get(path) || 0) === 1) {
        storagePathsToRemove.push(path);
      }
    }

    for (const path of storagePathsToRemove) {
      try {
        await deleteObject(storageRef(st, path));
      } catch (e) {
        logger.warn('stickers', 'deleteObject (pack delete)', { path, e });
      }
    }

    const itemRefs = itemsSnap.docs.map((d) => d.ref);
    for (let i = 0; i < itemRefs.length; i += 500) {
      const batch = writeBatch(fs);
      for (const ref of itemRefs.slice(i, i + 500)) {
        batch.delete(ref);
      }
      await batch.commit();
    }

    await deleteDoc(doc(fs, 'users', userId, 'stickerPacks', packId));
    logger.debug('stickers', 'pack deleted', { packId, userId });
    return { ok: true };
  } catch (e) {
    logger.warn('stickers', 'deleteUserStickerPack failed', e);
    return { ok: false, error: 'delete_failed' };
  }
}

/** Создаёт пак `users/{uid}/stickerPacks/{id}`. */
export async function createUserStickerPack(fs: Firestore, userId: string, rawName: string): Promise<string | null> {
  const name = rawName.trim() || 'Мой пак';
  const now = new Date().toISOString();
  const ref = await addDoc(collection(fs, 'users', userId, 'stickerPacks'), {
    name,
    createdAt: now,
    updatedAt: now,
  });
  return ref.id;
}

/**
 * Загрузка изображений/GIF в пак пользователя (Firestore + Storage).
 * Вынесено из хука для переиспользования из диалогов и панели GIF.
 */
export async function addImageFilesToUserStickerPack(
  packId: string,
  files: File[],
  userId: string,
  fs: Firestore,
  st: FirebaseStorage,
  opts?: AddImageFilesToPackOptions
): Promise<{ ok: number; skipped: number; errors: string[] }> {
  let ok = 0;
  let skipped = 0;
  const errors: string[] = [];
  for (const file of files) {
    if (file.type.startsWith('video/')) {
      const dur = await getVideoFileDurationSeconds(file);
      if (dur == null || dur > USER_STICKER_VIDEO_MAX_UPLOAD_SEC) {
        errors.push('video_too_long');
        skipped += 1;
        continue;
      }
      if (file.size > USER_STICKER_MAX_FILE_BYTES) {
        errors.push('file_too_large');
        skipped += 1;
        continue;
      }
      try {
        const idPart = `${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
        const rawExt = file.name.split('.').pop()?.replace(/[^a-zA-Z0-9]/g, '') || '';
        const fallback = file.type.split('/')[1]?.replace('+xml', '') || 'mp4';
        const ext = rawExt || fallback;
        const path = `users/${userId}/sticker-packs/${packId}/${idPart}.${ext}`;
        const fileRef = storageRef(st, path);
        await uploadBytes(fileRef, file, { contentType: file.type });
        const downloadUrl = await getDownloadURL(fileRef);
        const now = new Date().toISOString();
        await addDoc(collection(fs, 'users', userId, 'stickerPacks', packId, 'items'), {
          downloadUrl,
          storagePath: path,
          contentType: file.type,
          size: file.size,
          createdAt: now,
        });
        await updateDoc(doc(fs, 'users', userId, 'stickerPacks', packId), { updatedAt: now });
        ok += 1;
      } catch (e) {
        logger.warn('stickers', 'video upload failed', e);
        errors.push('upload_failed');
        skipped += 1;
      }
      continue;
    }

    if (!file.type.startsWith('image/')) {
      skipped += 1;
      continue;
    }

    let uploadFile = file;
    if (!opts?.skipCanvasNormalize) {
      try {
        uploadFile = await normalizeStaticImageFileForUserStickerPack(file);
      } catch (e) {
        logger.warn('stickers', 'normalize before upload', e);
        uploadFile = file;
      }
    }

    if (uploadFile.size > USER_STICKER_MAX_FILE_BYTES) {
      errors.push('file_too_large');
      skipped += 1;
      continue;
    }
    try {
      const idPart = `${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
      const rawExt = uploadFile.name.split('.').pop()?.replace(/[^a-zA-Z0-9]/g, '') || '';
      const fallback = uploadFile.type.split('/')[1]?.replace('+xml', '') || 'bin';
      const ext = rawExt || fallback;
      const path = `users/${userId}/sticker-packs/${packId}/${idPart}.${ext}`;
      const fileRef = storageRef(st, path);
      await uploadBytes(fileRef, uploadFile);
      const downloadUrl = await getDownloadURL(fileRef);
      let width: number | undefined;
      let height: number | undefined;
      if (uploadFile.type !== 'image/svg+xml') {
        const meta = await getImageMetadata(uploadFile);
        if (meta.width > 0 && meta.height > 0) {
          width = meta.width;
          height = meta.height;
        }
      }
      const now = new Date().toISOString();
      await addDoc(collection(fs, 'users', userId, 'stickerPacks', packId, 'items'), {
        downloadUrl,
        storagePath: path,
        contentType: uploadFile.type,
        size: uploadFile.size,
        ...(width && height ? { width, height } : {}),
        createdAt: now,
      });
      await updateDoc(doc(fs, 'users', userId, 'stickerPacks', packId), { updatedAt: now });
      ok += 1;
    } catch (e) {
      logger.warn('stickers', 'upload failed', e);
      errors.push('upload_failed');
      skipped += 1;
    }
  }
  return { ok, skipped, errors };
}

/**
 * Картинка из чата (сетка) → квадратный PNG под размер стикера и запись в пак.
 */
export async function addChatImageAsSquareStickerToPack(
  att: ChatAttachment,
  packId: string,
  userId: string,
  fs: Firestore,
  st: FirebaseStorage
): Promise<{ ok: boolean; error?: string }> {
  if (!att.url?.trim()) return { ok: false, error: 'no_url' };
  try {
    const res = await fetch(att.url, { mode: 'cors' });
    if (!res.ok) return { ok: false, error: 'fetch_failed' };
    let blob: Blob = await res.blob();
    let type =
      blob.type && blob.type.startsWith('image/')
        ? blob.type
        : att.type?.startsWith('image/')
          ? att.type
          : 'image/jpeg';
    let safeName = (att.name || 'image').replace(/[^\w.\-]+/g, '_').slice(0, 120) || 'image';
    if (isHeicHeifAttachment({ name: safeName, type })) {
      try {
        blob = await convertHeicHeifBlobToPngBlob(blob);
        type = 'image/png';
        safeName = safeName.replace(/\.hei[cf]$/i, '.png');
        if (!safeName.toLowerCase().endsWith('.png')) safeName = `${safeName}.png`;
      } catch (e) {
        logger.warn('stickers', 'HEIC square sticker', e);
        return { ok: false, error: 'convert_failed' };
      }
    }
    if (!type.startsWith('image/')) return { ok: false, error: 'not_image' };
    const pngBlob = await blobToSquareCenterCroppedPngBlob(blob, USER_STICKER_SQUARE_MAX_PX);
    const outFile = new File([pngBlob], 'from_chat_sticker.png', { type: 'image/png' });
    if (outFile.size > USER_STICKER_MAX_FILE_BYTES) return { ok: false, error: 'file_too_large' };
    const r = await addImageFilesToUserStickerPack(packId, [outFile], userId, fs, st, {
      skipCanvasNormalize: true,
    });
    if (r.ok > 0) return { ok: true };
    if (r.errors.includes('file_too_large')) return { ok: false, error: 'file_too_large' };
    return { ok: false, error: r.errors[0] || 'upload_failed' };
  } catch (e) {
    logger.warn('stickers', 'chat square sticker', e);
    return { ok: false, error: 'fetch_failed' };
  }
}

/**
 * Скачивает вложение (URL из чата) и сохраняет копию в пак пользователя.
 * Нужен CORS на стороне хоста URL; иначе вернётся fetch_failed.
 */
export async function addChatAttachmentToUserStickerPack(
  att: ChatAttachment,
  packId: string,
  userId: string,
  fs: Firestore,
  st: FirebaseStorage
): Promise<{ ok: boolean; error?: string }> {
  if (!att.url?.trim()) return { ok: false, error: 'no_url' };
  try {
    const res = await fetch(att.url, { mode: 'cors' });
    if (!res.ok) return { ok: false, error: 'fetch_failed' };
    let blob: Blob = await res.blob();
    let type =
      blob.type && blob.type.startsWith('image/')
        ? blob.type
        : att.type?.startsWith('image/')
          ? att.type
          : 'image/gif';
    if (!type.startsWith('image/')) return { ok: false, error: 'not_image' };
    let safeName = (att.name || 'saved').replace(/[^\w.\-]+/g, '_').slice(0, 120) || 'saved';
    if (isHeicHeifAttachment({ name: safeName, type })) {
      try {
        blob = await convertHeicHeifBlobToPngBlob(blob);
        type = 'image/png';
        safeName = safeName.replace(/\.hei[cf]$/i, '.png');
        if (!safeName.toLowerCase().endsWith('.png')) safeName = `${safeName}.png`;
      } catch (e) {
        logger.warn('stickers', 'HEIC convert for pack failed', e);
        return { ok: false, error: 'convert_failed' };
      }
    }
    if (blob.size > USER_STICKER_MAX_FILE_BYTES) return { ok: false, error: 'file_too_large' };
    const file = new File([blob], safeName, { type });
    const r = await addImageFilesToUserStickerPack(packId, [file], userId, fs, st);
    if (r.ok > 0) return { ok: true };
    if (r.errors.includes('file_too_large')) return { ok: false, error: 'file_too_large' };
    return { ok: false, error: r.errors[0] || 'upload_failed' };
  } catch (e) {
    logger.warn('stickers', 'remote save failed', e);
    return { ok: false, error: 'fetch_failed' };
  }
}
