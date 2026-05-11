import type { ChatAttachment } from '@/lib/types';
import { isAttachmentLikelyIosStickerCutout } from '@/lib/ios-sticker-detect';

const IMAGE_EXT = /\.(jpe?g|png|gif|webp|avif|heic|heif|bmp|jfif)(\?|#|$)/i;
const VIDEO_EXT = /\.(mp4|webm|mov|mkv|m4v|ogv)(\?|#|$)/i;

/**
 * Вложение для сетки MessageMedia (как в фильтре компонента).
 * Учитывает пустой MIME у File при оптимистичной отправке и octet-stream.
 *
 * Defensive: E2EE-вложения / оптимистичные / legacy messages могут прийти с
 * `name === undefined` или `type === undefined`. Без guard вся медиа-вкладка
 * ConversationMediaPanel валится с "Cannot read properties of undefined
 * (reading 'startsWith')" и крашит /dashboard/profile?conversationId=...
 */
export function isGridGalleryAttachment(att: ChatAttachment): boolean {
  const name = att.name ?? '';
  const type = att.type ?? '';
  if (name.startsWith('sticker_') || name.startsWith('gif_') || name.startsWith('video-circle_')) return false;
  if (isAttachmentLikelyIosStickerCutout(att)) return false;
  if (type.startsWith('image/') && !type.includes('svg')) return true;
  if (type.startsWith('video/')) return true;
  const loose =
    !type ||
    type === 'application/octet-stream' ||
    type === 'binary/octet-stream';
  if (loose) {
    if (IMAGE_EXT.test(name)) return true;
    if (VIDEO_EXT.test(name)) return true;
  }
  return false;
}

export function isGridGalleryVideo(att: ChatAttachment): boolean {
  const name = att.name ?? '';
  const type = att.type ?? '';
  if (name.startsWith('video-circle_')) return false;
  if (type.startsWith('video/')) return true;
  const loose =
    !type ||
    type === 'application/octet-stream' ||
    type === 'binary/octet-stream';
  if (loose && VIDEO_EXT.test(name)) return true;
  return false;
}
