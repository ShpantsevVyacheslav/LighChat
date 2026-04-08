import type { UserStickerItemDoc } from '@/lib/user-sticker-packs';

/**
 * Документ `publicStickerPacks/{packId}` — общие стикерпаки для всех авторизованных пользователей.
 * Запись только у роли `admin` (см. firestore.rules).
 */
export type PublicStickerPackDoc = {
  name: string;
  /** Порядок в списке (меньше — выше). */
  sortOrder: number;
  createdAt: string;
  updatedAt: string;
};

/**
 * Элемент пака — те же поля, что у личных стикеров (`UserStickerItemDoc`).
 */
export type PublicStickerItemDoc = UserStickerItemDoc;
