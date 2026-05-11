import { describe, expect, it } from 'vitest';
import { shouldUseCircularStickerMenuHole } from '@/components/chat/context-menu/message-focus-hole';
import type { ChatAttachment, ChatMessage } from '@/lib/types';

/**
 * [audit M-013 / regression b498852] Эта функция вызывается из
 * ChatMessageItem.circularStickerMenuHole useMemo. До b498852 валилась
 * на `a.name.startsWith(...)` если broken attachment → context-menu
 * не открывалось для целого чата.
 */

function att(overrides: Partial<ChatAttachment> = {}): ChatAttachment {
  return {
    url: 'https://cdn/file',
    name: 'sticker_x.png',
    type: 'image/png',
    size: 100_000,
    width: 400,
    height: 400,
    ...overrides,
  };
}

const brokenAtt = (overrides: Record<string, unknown>): ChatAttachment =>
  ({ ...att(), ...overrides } as unknown as ChatAttachment);

function msg(overrides: Partial<ChatMessage> = {}): ChatMessage {
  return {
    id: 'm1',
    senderId: 'u1',
    createdAt: '2026-05-11T10:00:00.000Z',
    readAt: null,
    ...overrides,
  };
}

describe('shouldUseCircularStickerMenuHole', () => {
  it('единичный стикер без caption → true', () => {
    expect(
      shouldUseCircularStickerMenuHole(msg({ attachments: [att()] })),
    ).toBe(true);
  });

  it('deleted сообщение → false', () => {
    expect(
      shouldUseCircularStickerMenuHole(msg({ isDeleted: true, attachments: [att()] })),
    ).toBe(false);
  });

  it('два attachments → false (только single sticker)', () => {
    expect(
      shouldUseCircularStickerMenuHole(msg({ attachments: [att(), att()] })),
    ).toBe(false);
  });

  it('gif_ → false (не стикер)', () => {
    expect(
      shouldUseCircularStickerMenuHole(
        msg({ attachments: [att({ name: 'gif_a.gif', type: 'image/gif' })] }),
      ),
    ).toBe(false);
  });

  it('video-circle_ → false', () => {
    expect(
      shouldUseCircularStickerMenuHole(
        msg({ attachments: [att({ name: 'video-circle_a.mp4', type: 'video/mp4' })] }),
      ),
    ).toBe(false);
  });

  it('video MIME → false', () => {
    expect(
      shouldUseCircularStickerMenuHole(
        msg({ attachments: [att({ type: 'video/mp4', name: 'clip.mp4' })] }),
      ),
    ).toBe(false);
  });

  it('audio → false', () => {
    expect(
      shouldUseCircularStickerMenuHole(
        msg({ attachments: [att({ type: 'audio/mp4', name: 'voice.m4a' })] }),
      ),
    ).toBe(false);
  });

  it('стикер с caption → false', () => {
    expect(
      shouldUseCircularStickerMenuHole(
        msg({ text: 'Привет!', attachments: [att()] }),
      ),
    ).toBe(false);
  });

  it('captionPlainOverride передан — приоритет над message.text', () => {
    // override='' → caption считается пустым → true
    expect(
      shouldUseCircularStickerMenuHole(
        msg({ text: 'фактический caption', attachments: [att()] }),
        '',
      ),
    ).toBe(true);
  });

  it('стикер с reply → false', () => {
    expect(
      shouldUseCircularStickerMenuHole(
        msg({
          attachments: [att()],
          replyTo: {
            messageId: 'm0',
            senderName: 'X',
            text: 'reply',
            mediaPreviewUrl: null,
            mediaType: null,
          },
        }),
      ),
    ).toBe(false);
  });

  // ─── regression: undefined name/type ───
  it('не валится на att.name === undefined', () => {
    expect(() =>
      shouldUseCircularStickerMenuHole(
        msg({ attachments: [brokenAtt({ name: undefined })] }),
      ),
    ).not.toThrow();
  });

  it('обе undefined — false без throw', () => {
    expect(
      shouldUseCircularStickerMenuHole(
        msg({ attachments: [brokenAtt({ name: undefined, type: undefined })] }),
      ),
    ).toBe(false);
  });
});
