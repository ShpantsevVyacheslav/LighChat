import { describe, expect, it } from 'vitest';
import { isAccountBlocked } from '@/lib/account-block-utils';

/**
 * [audit M-013] Account block check — security: гейт для всего UI
 * (видимость профиля, отправка сообщений, регистрация). Регрессия →
 * заблокированные юзеры снова получают доступ ИЛИ нормальные юзеры
 * случайно блочатся.
 */

const NOW = Date.parse('2026-05-11T12:00:00.000Z');

describe('isAccountBlocked', () => {
  it('null/undefined user → false', () => {
    expect(isAccountBlocked(null, NOW)).toBe(false);
    expect(isAccountBlocked(undefined, NOW)).toBe(false);
  });

  it('user без accountBlock → false', () => {
    expect(isAccountBlocked({}, NOW)).toBe(false);
    expect(isAccountBlocked({ accountBlock: undefined }, NOW)).toBe(false);
  });

  it('accountBlock.active=false → false', () => {
    expect(
      isAccountBlocked(
        { accountBlock: { active: false, blockedBy: 'admin', blockedAt: '2026-01-01T00:00:00.000Z', until: null } },
        NOW,
      ),
    ).toBe(false);
  });

  it('accountBlock.active=true без until → бессрочно blocked', () => {
    expect(
      isAccountBlocked(
        { accountBlock: { active: true, blockedBy: 'admin', blockedAt: '2026-01-01T00:00:00.000Z', until: null } },
        NOW,
      ),
    ).toBe(true);
  });

  it('accountBlock.until в будущем → blocked', () => {
    expect(
      isAccountBlocked(
        {
          accountBlock: {
            active: true,
            blockedBy: 'admin',
            blockedAt: '2026-01-01T00:00:00.000Z',
            until: '2026-06-01T00:00:00.000Z',
          },
        },
        NOW,
      ),
    ).toBe(true);
  });

  it('accountBlock.until в прошлом → НЕ blocked (срок истёк)', () => {
    expect(
      isAccountBlocked(
        {
          accountBlock: {
            active: true,
            blockedBy: 'admin',
            blockedAt: '2026-01-01T00:00:00.000Z',
            until: '2026-04-01T00:00:00.000Z',
          },
        },
        NOW,
      ),
    ).toBe(false);
  });

  it('accountBlock.until ровно сейчас → НЕ blocked (строгое >)', () => {
    expect(
      isAccountBlocked(
        {
          accountBlock: {
            active: true,
            blockedBy: 'admin',
            blockedAt: '2026-01-01T00:00:00.000Z',
            until: '2026-05-11T12:00:00.000Z',
          },
        },
        NOW,
      ),
    ).toBe(false);
  });
});
