import { ref as storageRef, uploadBytes, getDownloadURL, type FirebaseStorage } from 'firebase/storage';
import { compressImage } from '@/lib/image-compression';

/** Максимум стороны полноразмерного аватара перед загрузкой (качество/вес в браузере). */
export const USER_AVATAR_FULL_MAX_DIMENSION = 2048;

export type UploadedAvatarPair = {
  avatarUrl: string;
  /** Круглое превью 512×512; `null`, если исходный файл круга не передан. */
  avatarThumbUrl: string | null;
};

/**
 * Загружает полноразмерный JPEG (со сжатием до USER_AVATAR_FULL_MAX_DIMENSION) и опционально готовое круглое превью.
 */
export async function uploadUserAvatarPair(
  storage: FirebaseStorage,
  uid: string,
  fullFile: File,
  circleFile: File | undefined,
  timestamp = Date.now(),
): Promise<UploadedAvatarPair> {
  const compressed = await compressImage(
    fullFile,
    0.92,
    USER_AVATAR_FULL_MAX_DIMENSION,
  );
  const fullBlob = await (await fetch(compressed)).blob();
  const base = `avatars/${uid}/${timestamp}`;
  const fullPath = `${base}_full.jpg`;
  const fullRef = storageRef(storage, fullPath);
  await uploadBytes(fullRef, fullBlob);
  const avatarUrl = await getDownloadURL(fullRef);

  let avatarThumbUrl: string | null = null;
  if (circleFile) {
    const thumbPath = `${base}_thumb.jpg`;
    const thumbRef = storageRef(storage, thumbPath);
    await uploadBytes(thumbRef, circleFile);
    avatarThumbUrl = await getDownloadURL(thumbRef);
  }
  return { avatarUrl, avatarThumbUrl };
}
