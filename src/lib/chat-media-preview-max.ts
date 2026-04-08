/**
 * Макс. ширина сетки фото/видео в пузыре ([`MessageMedia`](../src/components/chat/parts/MessageMedia.tsx)).
 * После уменьшения с 320px — подхвачено +30% от 160px → 208px.
 */
export const CHAT_MEDIA_PREVIEW_MAX_WIDTH_PX = Math.round(160 * 1.3);

/** Мин. ширина колонки под сетку (+30% от 130px). */
export const CHAT_MEDIA_GRID_MIN_WIDTH_PX = Math.round(130 * 1.3);

/**
 * Превью карты в сообщении с геолокацией — в 1.5 раза шире, чем сетка медиа.
 */
export const CHAT_LOCATION_MAP_PREVIEW_MAX_WIDTH_PX = Math.round(
  CHAT_MEDIA_PREVIEW_MAX_WIDTH_PX * 1.5
);

/**
 * Сетка сообщения, где все ячейки — GIF: ширина ×2 от обычной сетки (JPEG/PNG без изменений).
 */
export const CHAT_GIF_ALBUM_GRID_MAX_WIDTH_PX = CHAT_MEDIA_PREVIEW_MAX_WIDTH_PX * 2;
