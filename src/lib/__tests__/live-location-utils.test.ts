import { describe, expect, it } from 'vitest';

import {
  isChatLiveLocationMessageStillStreaming,
  isChatLiveLocationShareExpired,
  isLiveShareExpired,
  isLiveShareVisible,
} from '@/lib/live-location-utils';
import type { ChatLocationShare, UserLiveLocationShare } from '@/lib/types';

/**
 * [audit M-013] Live location — UX-критическая логика отображения «живой»
 * трансляции локации в чате. Регрессия = пузырь продолжает показывать карту
 * после «Остановить» / истечения таймера (или наоборот: карта пропадает раньше
 * чем сессия закончилась). Покрываем:
 *  - дедлайн `expiresAt` (включая null = «навсегда»)
 *  - синхронизацию с `users/{senderId}.liveLocationShare.active`
 *  - совпадение `startedAt` (защита от race при перезапуске)
 *  - SLOP 15s (защита от рассинхрона часов клиента / Firestore)
 */

const NOW = Date.parse('2026-05-12T12:00:00Z');

function chatShare(overrides: Partial<ChatLocationShare> = {}): ChatLocationShare {
  return {
    lat: 55.7558,
    lng: 37.6173,
    mapsUrl: 'https://maps.example/abc',
    capturedAt: '2026-05-12T11:55:00Z',
    ...overrides,
  };
}

function userShare(overrides: Partial<UserLiveLocationShare> = {}): UserLiveLocationShare {
  return {
    active: true,
    expiresAt: '2026-05-12T13:00:00Z',
    lat: 55.7558,
    lng: 37.6173,
    updatedAt: '2026-05-12T11:55:00Z',
    startedAt: '2026-05-12T11:50:00Z',
    ...overrides,
  };
}

describe('isChatLiveLocationShareExpired', () => {
  it('share без liveSession → false (это обычная локация)', () => {
    expect(isChatLiveLocationShareExpired(chatShare(), NOW)).toBe(false);
  });

  it('expiresAt null → false (навсегда)', () => {
    expect(
      isChatLiveLocationShareExpired(
        chatShare({ liveSession: { expiresAt: null } }),
        NOW,
      ),
    ).toBe(false);
  });

  it('expiresAt в будущем → false', () => {
    expect(
      isChatLiveLocationShareExpired(
        chatShare({ liveSession: { expiresAt: '2026-05-12T13:00:00Z' } }),
        NOW,
      ),
    ).toBe(false);
  });

  it('expiresAt в прошлом → true', () => {
    expect(
      isChatLiveLocationShareExpired(
        chatShare({ liveSession: { expiresAt: '2026-05-12T11:00:00Z' } }),
        NOW,
      ),
    ).toBe(true);
  });

  it('expiresAt ровно сейчас → true (граница включена)', () => {
    expect(
      isChatLiveLocationShareExpired(
        chatShare({ liveSession: { expiresAt: '2026-05-12T12:00:00Z' } }),
        NOW,
      ),
    ).toBe(true);
  });
});

describe('isLiveShareExpired', () => {
  it('expiresAt null → false', () => {
    expect(isLiveShareExpired(userShare({ expiresAt: null }), NOW)).toBe(false);
  });

  it('expiresAt в прошлом → true', () => {
    expect(
      isLiveShareExpired(userShare({ expiresAt: '2026-05-12T11:00:00Z' }), NOW),
    ).toBe(true);
  });

  it('expiresAt в будущем → false', () => {
    expect(
      isLiveShareExpired(userShare({ expiresAt: '2026-05-12T13:00:00Z' }), NOW),
    ).toBe(false);
  });
});

describe('isLiveShareVisible', () => {
  it('active=false → false', () => {
    expect(isLiveShareVisible(userShare({ active: false }), NOW)).toBe(false);
  });

  it('active=true и в пределах expiresAt → true', () => {
    expect(isLiveShareVisible(userShare(), NOW)).toBe(true);
  });

  it('active=true но истёк → false', () => {
    expect(
      isLiveShareVisible(userShare({ expiresAt: '2026-05-12T11:00:00Z' }), NOW),
    ).toBe(false);
  });

  it('null/undefined → false', () => {
    expect(isLiveShareVisible(null, NOW)).toBe(false);
    expect(isLiveShareVisible(undefined, NOW)).toBe(false);
  });
});

describe('isChatLiveLocationMessageStillStreaming', () => {
  it('сообщение без liveSession → false (обычная локация)', () => {
    expect(
      isChatLiveLocationMessageStillStreaming(
        chatShare(),
        '2026-05-12T11:55:00Z',
        userShare(),
        true,
        NOW,
      ),
    ).toBe(false);
  });

  it('таймер истёк → false (несмотря на active=true)', () => {
    expect(
      isChatLiveLocationMessageStillStreaming(
        chatShare({ liveSession: { expiresAt: '2026-05-12T11:00:00Z' } }),
        '2026-05-12T11:55:00Z',
        userShare(),
        true,
        NOW,
      ),
    ).toBe(false);
  });

  it('senderProfileResolved=false → оптимистично true (ждём загрузки профиля)', () => {
    expect(
      isChatLiveLocationMessageStillStreaming(
        chatShare({ liveSession: { expiresAt: '2026-05-12T13:00:00Z' } }),
        '2026-05-12T11:55:00Z',
        null,
        false,
        NOW,
      ),
    ).toBe(true);
  });

  it('senderProfileResolved=true и senderLiveShare null → false (отозвано)', () => {
    expect(
      isChatLiveLocationMessageStillStreaming(
        chatShare({ liveSession: { expiresAt: '2026-05-12T13:00:00Z' } }),
        '2026-05-12T11:55:00Z',
        null,
        true,
        NOW,
      ),
    ).toBe(false);
  });

  it('senderLiveShare.active=false → false («Остановить»)', () => {
    expect(
      isChatLiveLocationMessageStillStreaming(
        chatShare({ liveSession: { expiresAt: '2026-05-12T13:00:00Z' } }),
        '2026-05-12T11:55:00Z',
        userShare({ active: false }),
        true,
        NOW,
      ),
    ).toBe(false);
  });

  it('сообщение раньше startedAt сессии (> SLOP) → false (старая сессия)', () => {
    expect(
      isChatLiveLocationMessageStillStreaming(
        chatShare({ liveSession: { expiresAt: '2026-05-12T13:00:00Z' } }),
        '2026-05-12T10:00:00Z', // msg за 1ч 50м до startedAt
        userShare({ startedAt: '2026-05-12T11:50:00Z' }),
        true,
        NOW,
      ),
    ).toBe(false);
  });

  it('сообщение чуть раньше startedAt (в пределах SLOP 15s) → true', () => {
    expect(
      isChatLiveLocationMessageStillStreaming(
        chatShare({ liveSession: { expiresAt: '2026-05-12T13:00:00Z' } }),
        '2026-05-12T11:49:55Z', // msg за 5s до startedAt
        userShare({ startedAt: '2026-05-12T11:50:00Z' }),
        true,
        NOW,
      ),
    ).toBe(true);
  });

  it('happy path: всё совпадает → true', () => {
    expect(
      isChatLiveLocationMessageStillStreaming(
        chatShare({ liveSession: { expiresAt: '2026-05-12T13:00:00Z' } }),
        '2026-05-12T11:55:00Z',
        userShare(),
        true,
        NOW,
      ),
    ).toBe(true);
  });
});
