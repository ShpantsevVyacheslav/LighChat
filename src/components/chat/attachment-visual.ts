import type { ChatAttachment } from '@/lib/types';

const IMAGE_EXT = /\.(jpe?g|png|gif|webp|avif|heic|heif|bmp|jfif)(\?|#|$)/i;
const VIDEO_EXT = /\.(mp4|webm|mov|mkv|m4v|ogv)(\?|#|$)/i;

/**
 * Вложение для сетки MessageMedia (как в фильтре компонента).
 * Учитывает пустой MIME у File при оптимистичной отправке и octet-stream.
 */
export function isGridGalleryAttachment(att: ChatAttachment): boolean {
  if (att.name.startsWith('sticker_') || att.name.startsWith('gif_') || att.name.startsWith('video-circle_')) return false;
  if (att.type.startsWith('image/') && !att.type.includes('svg')) return true;
  if (att.type.startsWith('video/')) return true;
  const loose =
    !att.type ||
    att.type === 'application/octet-stream' ||
    att.type === 'binary/octet-stream';
  if (loose) {
    if (IMAGE_EXT.test(att.name)) return true;
    if (VIDEO_EXT.test(att.name)) return true;
  }
  return false;
}

export function isGridGalleryVideo(att: ChatAttachment): boolean {
  if (att.name.startsWith('video-circle_')) return false;
  if (att.type.startsWith('video/')) return true;
  const loose =
    !att.type ||
    att.type === 'application/octet-stream' ||
    att.type === 'binary/octet-stream';
  if (loose && VIDEO_EXT.test(att.name)) return true;
  return false;
}
