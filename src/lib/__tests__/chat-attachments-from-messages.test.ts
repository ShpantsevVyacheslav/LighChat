import { describe, expect, it } from 'vitest';
import { categorizeAttachmentsFromMessages } from '@/lib/chat-attachments-from-messages';
import type { ChatAttachment, ChatMessage } from '@/lib/types';

/**
 * [audit M-013 / regression 4955b64] До 4955b64 функция падала на
 * `att.name.startsWith(...)` если хотя бы один attachment приходил с
 * `name === undefined` или `type === undefined`. Это валило весь
 * useMemo `ChatParticipantProfile.{media,files,links,threadMessages}`
 * и крашило /dashboard полностью. Тесты закрывают регрессию.
 */

function att(overrides: Partial<ChatAttachment> = {}): ChatAttachment {
  return {
    url: 'https://cdn.example.com/' + (overrides.name ?? 'a.bin'),
    name: 'a.bin',
    type: 'application/octet-stream',
    size: 1,
    ...overrides,
  };
}

function msg(overrides: Partial<ChatMessage> = {}): ChatMessage {
  return {
    id: 'm-' + Math.random().toString(36).slice(2),
    senderId: 'u1',
    createdAt: '2026-05-11T10:00:00.000Z',
    readAt: null,
    ...overrides,
  };
}

// Helper для broken attachments (runtime приносит broken shape от E2EE / legacy).
const brokenAtt = (overrides: Record<string, unknown>): ChatAttachment =>
  ({ ...att(), ...overrides } as unknown as ChatAttachment);

describe('categorizeAttachmentsFromMessages', () => {
  it('возвращает пустые категории на пустом массиве', () => {
    const result = categorizeAttachmentsFromMessages([]);
    expect(result.media).toEqual([]);
    expect(result.files).toEqual([]);
    expect(result.links).toEqual([]);
    expect(result.audios).toEqual([]);
    expect(result.stickers).toEqual([]);
    expect(result.circles).toEqual([]);
    expect(result.threadMessages).toEqual([]);
  });

  it('пропускает удалённые сообщения', () => {
    const result = categorizeAttachmentsFromMessages([
      msg({ isDeleted: true, attachments: [att({ type: 'image/jpeg', name: 'p.jpg' })] }),
    ]);
    expect(result.media).toEqual([]);
  });

  it('категоризирует image как media', () => {
    const a = att({ type: 'image/jpeg', name: 'photo.jpg', url: 'u1' });
    const result = categorizeAttachmentsFromMessages([msg({ attachments: [a] })]);
    expect(result.media).toHaveLength(1);
    expect(result.media[0].url).toBe('u1');
  });

  it('категоризирует video как media', () => {
    const a = att({ type: 'video/mp4', name: 'clip.mp4', url: 'u2' });
    const result = categorizeAttachmentsFromMessages([msg({ attachments: [a] })]);
    expect(result.media).toHaveLength(1);
  });

  it('категоризирует audio отдельно', () => {
    const a = att({ type: 'audio/mp4', name: 'voice.m4a', url: 'u3' });
    const result = categorizeAttachmentsFromMessages([msg({ attachments: [a] })]);
    expect(result.audios).toHaveLength(1);
    expect(result.media).toEqual([]);
  });

  it('category stickers по name=sticker_*', () => {
    const a = att({ type: 'image/png', name: 'sticker_x.png', url: 'u4' });
    const result = categorizeAttachmentsFromMessages([msg({ attachments: [a] })]);
    expect(result.stickers).toHaveLength(1);
    expect(result.media).toEqual([]);
  });

  it('category circles по name=video-circle_*', () => {
    const a = att({ type: 'video/mp4', name: 'video-circle_y.mp4', url: 'u5' });
    const result = categorizeAttachmentsFromMessages([
      msg({ attachments: [a], senderId: 's1', createdAt: '2026-01-01T00:00:00.000Z' }),
    ]);
    expect(result.circles).toHaveLength(1);
    expect(result.circles[0].senderId).toBe('s1');
  });

  it('files для не-media MIME', () => {
    const a = att({ type: 'application/pdf', name: 'doc.pdf', url: 'u6' });
    const result = categorizeAttachmentsFromMessages([msg({ attachments: [a] })]);
    expect(result.files).toHaveLength(1);
  });

  it('извлекает links из текста', () => {
    const result = categorizeAttachmentsFromMessages([
      msg({ id: 'mX', text: 'Smотри это https://example.com/a и https://example.com/b' }),
    ]);
    expect(result.links).toHaveLength(2);
    expect(result.links[0].messageId).toBe('mX');
  });

  it('сообщение с emoji-only пропускается из извлечения', () => {
    // emoji-only сообщения не должны быть категоризированы, но дубль защита:
    // attachments если есть, всё равно подсчитаются (текущая ветка `return`
    // exits до attachments). Проверяем что media остаётся пустым.
    const result = categorizeAttachmentsFromMessages([msg({ text: '🎉🎊' })]);
    expect(result.media).toEqual([]);
    expect(result.links).toEqual([]);
  });

  it('threadMessages собирает только то, у которого threadCount > 0', () => {
    const result = categorizeAttachmentsFromMessages([
      msg({ id: 'a', threadCount: 3 }),
      msg({ id: 'b' }),
      msg({ id: 'c', threadCount: 0 }),
    ]);
    expect(result.threadMessages).toHaveLength(1);
    expect(result.threadMessages[0].id).toBe('a');
  });

  it('дедуплицирует media по url', () => {
    const u = 'https://cdn/dup.jpg';
    const a = att({ type: 'image/jpeg', name: 'one.jpg', url: u });
    const b = att({ type: 'image/jpeg', name: 'two.jpg', url: u });
    const result = categorizeAttachmentsFromMessages([
      msg({ id: 'm1', attachments: [a] }),
      msg({ id: 'm2', attachments: [b] }),
    ]);
    expect(result.media).toHaveLength(1);
  });

  // ─── crash-vector regression ───
  it('не валится на att.name === undefined', () => {
    expect(() =>
      categorizeAttachmentsFromMessages([
        msg({ attachments: [brokenAtt({ name: undefined, type: 'image/jpeg' })] }),
      ]),
    ).not.toThrow();
  });

  it('не валится на att.type === undefined', () => {
    expect(() =>
      categorizeAttachmentsFromMessages([
        msg({ attachments: [brokenAtt({ name: 'x.bin', type: undefined })] }),
      ]),
    ).not.toThrow();
  });

  it('attachment c обоими undefined попадает в files (fallback)', () => {
    const a = brokenAtt({ name: undefined, type: undefined, url: 'broken' });
    const result = categorizeAttachmentsFromMessages([msg({ attachments: [a] })]);
    expect(result.files).toHaveLength(1);
    expect(result.media).toEqual([]);
    expect(result.stickers).toEqual([]);
  });

  it('mix из broken и normal — не валится, обрабатывает normal', () => {
    const ok = att({ type: 'image/jpeg', name: 'ok.jpg', url: 'ok' });
    const broken1 = brokenAtt({ name: undefined, url: 'b1' });
    const result = categorizeAttachmentsFromMessages([
      msg({ attachments: [broken1, ok] }),
    ]);
    expect(result.media.map((m) => m.url)).toContain('ok');
    expect(result.files.map((f) => f.url)).toContain('b1');
  });
});
