import { describe, expect, it } from 'vitest';
import { isAttachmentLikelyIosStickerCutout } from '@/lib/ios-sticker-detect';

/**
 * [audit M-013 / regression b498852] Эта функция тоже была без guard'а на
 * `att.name === undefined` / `att.type === undefined` и валила
 * `ChatMessageItem.isSticker` useMemo → /dashboard crash. Защищаем
 * guard'ы тестом и заодно фиксируем эвристику «iOS sticker cutout»,
 * которая используется для отдельной отрисовки прозрачных PNG/WebP
 * (как Telegram sticker), даже если их name не начинается с `sticker_`.
 */

type AttArg = Parameters<typeof isAttachmentLikelyIosStickerCutout>[0];

function att(overrides: Partial<AttArg> = {}): AttArg {
  return {
    name: 'photo.png',
    type: 'image/png',
    size: 200_000,
    width: 400,
    height: 400,
    ...overrides,
  };
}

// Helper для broken shape (runtime приносит без name/type).
const broken = (overrides: Record<string, unknown>): AttArg =>
  ({ ...att(), ...overrides } as unknown as AttArg);

describe('isAttachmentLikelyIosStickerCutout', () => {
  it('фиксирует name=sticker_* как стикер сразу', () => {
    expect(isAttachmentLikelyIosStickerCutout(att({ name: 'sticker_foo.png' }))).toBe(true);
  });

  it('фиксирует image/svg+xml как стикер сразу', () => {
    expect(isAttachmentLikelyIosStickerCutout(att({ type: 'image/svg+xml' }))).toBe(true);
  });

  it('отбрасывает gif_*', () => {
    expect(isAttachmentLikelyIosStickerCutout(att({ name: 'gif_x.gif', type: 'image/gif' }))).toBe(false);
  });

  it('не считает jpeg стикером (нет альфа-канала)', () => {
    expect(isAttachmentLikelyIosStickerCutout(att({ type: 'image/jpeg' }))).toBe(false);
  });

  it('маленький квадратный PNG в пределах STICKER_MAX_* — true', () => {
    expect(
      isAttachmentLikelyIosStickerCutout(
        att({ width: 512, height: 512, size: 200_000 }),
      ),
    ).toBe(true);
  });

  it('PNG без width/height — false (геометрия неизвестна)', () => {
    expect(
      isAttachmentLikelyIosStickerCutout(
        att({ width: undefined, height: undefined }),
      ),
    ).toBe(false);
  });

  it('PNG слишком большой (3000x3000) — false', () => {
    expect(
      isAttachmentLikelyIosStickerCutout(
        att({ width: 3000, height: 3000, size: 1_500_000 }),
      ),
    ).toBe(false);
  });

  it('PNG слишком тонкий ratio < 0.4 — false', () => {
    // 800 wide, 100 tall → ratio = 100/800 = 0.125
    expect(
      isAttachmentLikelyIosStickerCutout(
        att({ width: 800, height: 100, size: 200_000 }),
      ),
    ).toBe(false);
  });

  it('WebP с правильной геометрией — true', () => {
    expect(
      isAttachmentLikelyIosStickerCutout(
        att({ type: 'image/webp', width: 400, height: 400, size: 100_000 }),
      ),
    ).toBe(true);
  });

  // ─── regression: undefined name/type не должны валить ───
  it('не валится на name === undefined', () => {
    expect(() =>
      isAttachmentLikelyIosStickerCutout(broken({ name: undefined })),
    ).not.toThrow();
  });

  it('не валится на type === undefined', () => {
    expect(() =>
      isAttachmentLikelyIosStickerCutout(broken({ type: undefined })),
    ).not.toThrow();
    expect(isAttachmentLikelyIosStickerCutout(broken({ type: undefined }))).toBe(false);
  });

  it('обе undefined — false без throw', () => {
    expect(() =>
      isAttachmentLikelyIosStickerCutout(broken({ name: undefined, type: undefined })),
    ).not.toThrow();
    expect(
      isAttachmentLikelyIosStickerCutout(broken({ name: undefined, type: undefined })),
    ).toBe(false);
  });
});
