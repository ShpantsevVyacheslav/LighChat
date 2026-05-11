import { describe, expect, it } from 'vitest';
import {
  isOnlyEmojis,
  getReplyPreview,
  getFirstStickerOrGifAttachment,
  getFirstGridGalleryImageForStickerCreation,
} from '@/lib/chat-utils';
import type { ChatAttachment, ChatMessage, User } from '@/lib/types';

/**
 * [audit M-013 / regression b498852] `chat-utils` напрямую дёргается
 * в reply-bar / context-menu / sticker-save flow. До b498852
 * `getReplyPreview` и `getFirstStickerOrGifAttachment` напрямую вызывали
 * `att.name.startsWith(...)` без guard'а и валили reply-preview если
 * пришло E2EE/optimistic/legacy вложение с undefined name/type.
 */

function att(overrides: Partial<ChatAttachment> = {}): ChatAttachment {
  return {
    url: 'https://cdn.example.com/file',
    name: 'file.bin',
    type: 'application/octet-stream',
    size: 1,
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

const ALICE: User = {
  id: 'u1',
  name: 'Alice',
  username: 'alice',
  email: 'alice@x',
  avatar: '',
  phone: '',
  deletedAt: null,
  createdAt: '2026-05-07T00:00:00.000Z',
};

describe('isOnlyEmojis', () => {
  it('возвращает true для одного эмодзи', () => {
    expect(isOnlyEmojis('🎉')).toBe(true);
  });

  it('возвращает true для нескольких эмодзи', () => {
    expect(isOnlyEmojis('🎉🎊✨')).toBe(true);
  });

  it('возвращает false если есть текст', () => {
    expect(isOnlyEmojis('hi 🎉')).toBe(false);
  });

  it('возвращает false для пустой строки', () => {
    expect(isOnlyEmojis('')).toBe(false);
  });
});

describe('getReplyPreview', () => {
  it('возвращает text как preview для текстового сообщения', () => {
    const m = msg({ text: 'Hello world' });
    const r = getReplyPreview(m, [ALICE]);
    expect(r.text).toBe('Hello world');
    expect(r.senderName).toBe('Alice');
    expect(r.mediaPreviewUrl).toBeNull();
  });

  it('strip HTML из текста', () => {
    const m = msg({ text: '<p>Hello <strong>world</strong></p>' });
    const r = getReplyPreview(m, [ALICE]);
    expect(r.text).toBe('Hello world');
  });

  it('возвращает «Стикер» для sticker_ вложения', () => {
    const m = msg({
      attachments: [att({ type: 'image/png', name: 'sticker_x.png', url: 'su1' })],
    });
    const r = getReplyPreview(m, [ALICE]);
    expect(r.text).toBe('Стикер');
    expect(r.mediaType).toBe('sticker');
    expect(r.mediaPreviewUrl).toBe('su1');
  });

  it('GIF для gif_*', () => {
    const m = msg({
      attachments: [att({ type: 'image/gif', name: 'gif_a.gif', url: 'gu1' })],
    });
    const r = getReplyPreview(m, [ALICE]);
    expect(r.text).toBe('GIF');
    expect(r.mediaType).toBe('image');
  });

  it('«Кружок» для video-circle_*', () => {
    const m = msg({
      attachments: [att({ type: 'video/mp4', name: 'video-circle_y.mp4', url: 'vu' })],
    });
    const r = getReplyPreview(m, [ALICE]);
    expect(r.text).toBe('Кружок');
    expect(r.mediaType).toBe('video-circle');
  });

  it('«Файл» для документов', () => {
    const m = msg({
      attachments: [att({ type: 'application/pdf', name: 'doc.pdf', url: 'fu' })],
    });
    const r = getReplyPreview(m, [ALICE]);
    expect(r.text).toBe('Файл');
    expect(r.mediaType).toBe('file');
  });

  it('preserves text caption поверх media', () => {
    const m = msg({
      text: 'My caption',
      attachments: [att({ type: 'image/jpeg', name: 'p.jpg', url: 'pu' })],
    });
    const r = getReplyPreview(m, [ALICE]);
    expect(r.text).toBe('My caption');
    expect(r.mediaPreviewUrl).toBe('pu');
  });

  it('«Участник» если sender unknown', () => {
    const m = msg({ senderId: 'unknown-uid', text: 'hi' });
    const r = getReplyPreview(m, []);
    expect(r.senderName).toBe('Участник');
  });

  // ─── regression: undefined att fields не должны валить ───
  it('не валится на att.name/type === undefined', () => {
    const m = msg({
      attachments: [brokenAtt({ name: undefined, type: undefined, url: 'bu' })],
    });
    expect(() => getReplyPreview(m, [ALICE])).not.toThrow();
    const r = getReplyPreview(m, [ALICE]);
    expect(r.text).toBe('Файл'); // fallback
  });
});

describe('getFirstStickerOrGifAttachment', () => {
  it('returns null если нет attachments', () => {
    expect(getFirstStickerOrGifAttachment(msg())).toBeNull();
  });

  it('находит gif_ attachment', () => {
    const m = msg({
      attachments: [
        att({ name: 'photo.jpg', type: 'image/jpeg' }),
        att({ name: 'gif_a.gif', type: 'image/gif', url: 'gu1' }),
      ],
    });
    expect(getFirstStickerOrGifAttachment(m)?.url).toBe('gu1');
  });

  it('находит sticker_ attachment', () => {
    const m = msg({
      attachments: [att({ name: 'sticker_x.png', type: 'image/png', url: 'su1' })],
    });
    expect(getFirstStickerOrGifAttachment(m)?.url).toBe('su1');
  });

  it('returns null для обычных файлов', () => {
    const m = msg({
      attachments: [att({ name: 'doc.pdf', type: 'application/pdf' })],
    });
    expect(getFirstStickerOrGifAttachment(m)).toBeNull();
  });

  it('не валится на broken attachment с undefined name', () => {
    const m = msg({
      attachments: [brokenAtt({ name: undefined })],
    });
    expect(() => getFirstStickerOrGifAttachment(m)).not.toThrow();
    expect(getFirstStickerOrGifAttachment(m)).toBeNull();
  });
});

describe('getFirstGridGalleryImageForStickerCreation', () => {
  it('returns null если нет attachments', () => {
    expect(getFirstGridGalleryImageForStickerCreation(msg())).toBeNull();
  });

  it('возвращает первое image-attachment', () => {
    const m = msg({
      attachments: [
        att({ name: 'doc.pdf', type: 'application/pdf' }),
        att({ name: 'photo.jpg', type: 'image/jpeg', url: 'iu1' }),
      ],
    });
    expect(getFirstGridGalleryImageForStickerCreation(m)?.url).toBe('iu1');
  });

  it('пропускает video', () => {
    const m = msg({
      attachments: [att({ name: 'clip.mp4', type: 'video/mp4' })],
    });
    expect(getFirstGridGalleryImageForStickerCreation(m)).toBeNull();
  });

  it('пропускает sticker_', () => {
    const m = msg({
      attachments: [att({ name: 'sticker_x.png', type: 'image/png' })],
    });
    expect(getFirstGridGalleryImageForStickerCreation(m)).toBeNull();
  });

  it('не валится на broken attachment', () => {
    const m = msg({
      attachments: [brokenAtt({ name: undefined, type: undefined })],
    });
    expect(() => getFirstGridGalleryImageForStickerCreation(m)).not.toThrow();
  });
});
