import type { ChatAttachment } from '@/lib/types';

/** Документ `users/{uid}/stickerPacks/{packId}`. */
export type UserStickerPackDoc = {
  name: string;
  createdAt: string;
  updatedAt: string;
};

/** Документ `users/{uid}/stickerPacks/{packId}/items/{itemId}`. */
export type UserStickerItemDoc = {
  downloadUrl: string;
  storagePath: string;
  contentType: string;
  size: number;
  width?: number;
  height?: number;
  createdAt: string;
};

/** Лимит на один файл (стикер / GIF в паке). */
export const USER_STICKER_MAX_FILE_BYTES = 8 * 1024 * 1024;

export function extensionForMime(mime: string): string {
  if (mime === 'image/png') return 'png';
  if (mime === 'image/jpeg' || mime === 'image/jpg') return 'jpg';
  if (mime === 'image/webp') return 'webp';
  if (mime === 'image/gif') return 'gif';
  if (mime === 'image/svg+xml') return 'svg';
  if (mime === 'video/mp4') return 'mp4';
  if (mime === 'video/webm') return 'webm';
  if (mime === 'video/quicktime') return 'mov';
  return 'img';
}

/** Вложение для отправки в чат (`gif_` для GIF и короткого видео в паке, иначе `sticker_`). */
export function userStickerItemToAttachment(item: UserStickerItemDoc & { id: string }): ChatAttachment {
  const ext = extensionForMime(item.contentType);
  const isGifLike = item.contentType === 'image/gif' || item.contentType.startsWith('video/');
  const prefix = isGifLike ? 'gif' : 'sticker';
  return {
    url: item.downloadUrl,
    name: `${prefix}_${item.id}_${Date.now()}.${ext}`,
    type: item.contentType,
    size: item.size,
    ...(item.width && item.height ? { width: item.width, height: item.height } : {}),
  };
}
