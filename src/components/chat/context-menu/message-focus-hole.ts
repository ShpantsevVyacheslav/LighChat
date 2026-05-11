import type { ChatMessage } from '@/lib/types';
import { isAttachmentLikelyIosStickerCutout } from '@/lib/ios-sticker-detect';

/**
 * Одиночный стикер/вырез без подписи и без ответа — меню: круглый вырез под blur
 * (как Telegram/iMessage), без тёмного «квадрата» по периметру контейнера.
 */
export function shouldUseCircularStickerMenuHole(message: ChatMessage, captionPlainOverride?: string): boolean {
  if (message.isDeleted) return false;
  const att = message.attachments;
  if (!att || att.length !== 1) return false;
  const a = att[0];
  // Defensive: E2EE/optimistic/legacy attachments могут иметь undefined name/type.
  const aName = a.name ?? '';
  const aType = a.type ?? '';
  if (aName.startsWith('gif_') || aName.startsWith('video-circle_') || aType.startsWith('video/') || aType.startsWith('audio/'))
    return false;
  if (!isAttachmentLikelyIosStickerCutout(a)) return false;
  if (message.replyTo || message.locationShare || message.chatPollId) return false;
  const plain =
    captionPlainOverride !== undefined
      ? captionPlainOverride
      : (message.text || '').replace(/<[^>]*>/g, '').replace(/&nbsp;/g, ' ').trim();
  if (plain.length > 0) return false;
  return true;
}

export type FocusCircleHole = { cx: number; cy: number; r: number };

/** Круг с лёгким inset, чтобы по краю не оставалась кайма незаблюренного фона. */
export function readStickerCircleHoleFromRect(el: HTMLElement, insetRatio = 0.96): FocusCircleHole {
  const br = el.getBoundingClientRect();
  const r = (Math.min(br.width, br.height) / 2) * insetRatio;
  return {
    cx: br.left + br.width / 2,
    cy: br.top + br.height / 2,
    r,
  };
}
