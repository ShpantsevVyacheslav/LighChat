import { describe, expect, it } from 'vitest';
import { isGridGalleryAttachment, isGridGalleryVideo } from '@/components/chat/attachment-visual';
import type { ChatAttachment } from '@/lib/types';

/**
 * [audit M-013 / regression b498852] Эти функции вызываются из nested
 * useMemo в `ConversationMediaPanel` / `ThreadWindow.threadMediaItems` /
 * `ChatWindow.allMediaItems`. До b498852 они напрямую звали
 * `att.name.startsWith(...)` и валили весь профиль чата, если хотя бы один
 * attachment приходил с `name === undefined` или `type === undefined`
 * (E2EE / оптимистичные / legacy). Этот файл фиксирует поведение, чтобы
 * регрессия в guard'ах не прошла в main.
 */

function att(overrides: Partial<ChatAttachment> = {}): ChatAttachment {
  return {
    url: 'https://example.com/file.bin',
    name: 'file.bin',
    type: 'application/octet-stream',
    size: 100,
    ...overrides,
  };
}

// Cast helper для эджкейсов где runtime приходит с broken shape.
const broken = (overrides: Record<string, unknown>): ChatAttachment =>
  ({ ...att(), ...overrides } as unknown as ChatAttachment);

describe('attachment-visual.isGridGalleryAttachment', () => {
  it('пропускает обычное изображение в галерею', () => {
    expect(isGridGalleryAttachment(att({ type: 'image/jpeg', name: 'photo.jpg' }))).toBe(true);
  });

  it('пропускает видео в галерею', () => {
    expect(isGridGalleryAttachment(att({ type: 'video/mp4', name: 'clip.mp4' }))).toBe(true);
  });

  it('исключает sticker_ из галереи', () => {
    expect(isGridGalleryAttachment(att({ type: 'image/png', name: 'sticker_giphy_1.png' }))).toBe(false);
  });

  it('исключает gif_ из галереи', () => {
    expect(isGridGalleryAttachment(att({ type: 'image/gif', name: 'gif_abc.gif' }))).toBe(false);
  });

  it('исключает video-circle_ из галереи', () => {
    expect(isGridGalleryAttachment(att({ type: 'video/mp4', name: 'video-circle_42.mp4' }))).toBe(false);
  });

  it('SVG как image/svg+xml не идёт в галерею', () => {
    expect(isGridGalleryAttachment(att({ type: 'image/svg+xml', name: 'icon.svg' }))).toBe(false);
  });

  it('octet-stream с image-расширением попадает в галерею (loose MIME)', () => {
    expect(isGridGalleryAttachment(att({ type: 'application/octet-stream', name: 'photo.heic' }))).toBe(true);
  });

  it('обычный pdf не идёт в галерею', () => {
    expect(isGridGalleryAttachment(att({ type: 'application/pdf', name: 'doc.pdf' }))).toBe(false);
  });

  // ─── crash-vector regression: undefined name/type не должны валить ───
  it('не валится на name === undefined', () => {
    expect(() => isGridGalleryAttachment(broken({ name: undefined }))).not.toThrow();
  });

  it('не валится на type === undefined', () => {
    expect(() => isGridGalleryAttachment(broken({ type: undefined }))).not.toThrow();
  });

  it('не валится когда обе name/type === undefined', () => {
    expect(() => isGridGalleryAttachment(broken({ name: undefined, type: undefined }))).not.toThrow();
  });

  it('broken attachment с расширением .jpg в name=undefined → false (no extension match)', () => {
    expect(isGridGalleryAttachment(broken({ name: undefined, type: undefined }))).toBe(false);
  });
});

describe('attachment-visual.isGridGalleryVideo', () => {
  it('распознаёт video/mp4', () => {
    expect(isGridGalleryVideo(att({ type: 'video/mp4', name: 'clip.mp4' }))).toBe(true);
  });

  it('исключает video-circle_', () => {
    expect(isGridGalleryVideo(att({ type: 'video/mp4', name: 'video-circle_x.mp4' }))).toBe(false);
  });

  it('octet-stream с .mp4 — true (loose)', () => {
    expect(isGridGalleryVideo(att({ type: 'application/octet-stream', name: 'clip.mp4' }))).toBe(true);
  });

  it('image не считается видео', () => {
    expect(isGridGalleryVideo(att({ type: 'image/jpeg', name: 'pic.jpg' }))).toBe(false);
  });

  it('не валится на undefined name/type', () => {
    expect(() => isGridGalleryVideo(broken({ name: undefined, type: undefined }))).not.toThrow();
    expect(isGridGalleryVideo(broken({ name: undefined, type: undefined }))).toBe(false);
  });
});
