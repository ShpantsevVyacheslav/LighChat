'use client';

import { addDoc, collection, doc, updateDoc } from 'firebase/firestore';
import { getDownloadURL, ref as storageRef, uploadBytes } from 'firebase/storage';
import type { Firestore } from 'firebase/firestore';
import type { FirebaseStorage } from 'firebase/storage';

import type { ChatAttachment } from '@/lib/types';
import { getImageMetadata } from '@/lib/media-utils';
import { USER_STICKER_MAX_FILE_BYTES } from '@/lib/user-sticker-packs';

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
  st: FirebaseStorage
): Promise<{ ok: number; skipped: number; errors: string[] }> {
  let ok = 0;
  let skipped = 0;
  const errors: string[] = [];
  for (const file of files) {
    if (!file.type.startsWith('image/')) {
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
      const fallback = file.type.split('/')[1]?.replace('+xml', '') || 'bin';
      const ext = rawExt || fallback;
      const path = `users/${userId}/sticker-packs/${packId}/${idPart}.${ext}`;
      const fileRef = storageRef(st, path);
      await uploadBytes(fileRef, file);
      const downloadUrl = await getDownloadURL(fileRef);
      let width: number | undefined;
      let height: number | undefined;
      if (file.type !== 'image/svg+xml') {
        const meta = await getImageMetadata(file);
        if (meta.width > 0 && meta.height > 0) {
          width = meta.width;
          height = meta.height;
        }
      }
      const now = new Date().toISOString();
      await addDoc(collection(fs, 'users', userId, 'stickerPacks', packId, 'items'), {
        downloadUrl,
        storagePath: path,
        contentType: file.type,
        size: file.size,
        ...(width && height ? { width, height } : {}),
        createdAt: now,
      });
      await updateDoc(doc(fs, 'users', userId, 'stickerPacks', packId), { updatedAt: now });
      ok += 1;
    } catch (e) {
      console.warn('[LighChat:stickers] upload failed', e);
      errors.push('upload_failed');
      skipped += 1;
    }
  }
  return { ok, skipped, errors };
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
    const blob = await res.blob();
    if (blob.size > USER_STICKER_MAX_FILE_BYTES) return { ok: false, error: 'file_too_large' };
    const type =
      blob.type && blob.type.startsWith('image/')
        ? blob.type
        : att.type?.startsWith('image/')
          ? att.type
          : 'image/gif';
    if (!type.startsWith('image/')) return { ok: false, error: 'not_image' };
    const safeName = (att.name || 'saved').replace(/[^\w.\-]+/g, '_').slice(0, 120) || 'saved';
    const file = new File([blob], safeName, { type });
    const r = await addImageFilesToUserStickerPack(packId, [file], userId, fs, st);
    if (r.ok > 0) return { ok: true };
    if (r.errors.includes('file_too_large')) return { ok: false, error: 'file_too_large' };
    return { ok: false, error: r.errors[0] || 'upload_failed' };
  } catch (e) {
    console.warn('[LighChat:stickers] remote save failed', e);
    return { ok: false, error: 'fetch_failed' };
  }
}
