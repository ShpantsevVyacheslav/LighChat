import { describe, expect, it } from 'vitest';

import {
  canShowLastSeen,
  canShowOnlineStatus,
  resolvePresenceLabel,
} from '@/lib/presence-visibility';

/**
 * [audit M-013] Presence — privacy gate: пользователь может скрыть «онлайн» и «был(а)»
 * в `privacySettings.showOnlineStatus / showLastSeen`. Регрессия = leak статуса.
 * Поэтому ключевые инварианты:
 *  - default open (обратная совместимость со старыми профилями)
 *  - явное false выключает
 *  - resolvePresenceLabel НИКОГДА не возвращает «В сети» при выключенном showOnlineStatus
 *  - битый lastSeen не падает, а отдает «Не в сети»
 */

describe('canShowOnlineStatus', () => {
  it('default true для старого профиля без privacySettings', () => {
    expect(canShowOnlineStatus({})).toBe(true);
    expect(canShowOnlineStatus(null)).toBe(true);
    expect(canShowOnlineStatus(undefined)).toBe(true);
  });

  it('default true когда privacySettings есть, но флаг не задан', () => {
    expect(canShowOnlineStatus({ privacySettings: {} })).toBe(true);
    expect(canShowOnlineStatus({ privacySettings: { showOnlineStatus: null } })).toBe(true);
  });

  it('явное true', () => {
    expect(canShowOnlineStatus({ privacySettings: { showOnlineStatus: true } })).toBe(true);
  });

  it('явное false → false', () => {
    expect(canShowOnlineStatus({ privacySettings: { showOnlineStatus: false } })).toBe(false);
  });
});

describe('canShowLastSeen', () => {
  it('default true для старого профиля', () => {
    expect(canShowLastSeen({})).toBe(true);
    expect(canShowLastSeen(null)).toBe(true);
  });

  it('явное false → false', () => {
    expect(canShowLastSeen({ privacySettings: { showLastSeen: false } })).toBe(false);
  });

  it('null трактуется как default true', () => {
    expect(canShowLastSeen({ privacySettings: { showLastSeen: null } })).toBe(true);
  });
});

describe('resolvePresenceLabel', () => {
  it('null → "Не в сети"', () => {
    expect(resolvePresenceLabel(null)).toBe('Не в сети');
    expect(resolvePresenceLabel(undefined)).toBe('Не в сети');
  });

  it('online=true и privacy открыт → "В сети"', () => {
    expect(resolvePresenceLabel({ online: true })).toBe('В сети');
  });

  it('online=true но privacy выключен → НИКОГДА не "В сети"', () => {
    const label = resolvePresenceLabel({
      online: true,
      privacySettings: { showOnlineStatus: false },
    });
    expect(label).not.toBe('В сети');
  });

  it('online=true privacy выключен, нет lastSeen → "Не в сети"', () => {
    expect(
      resolvePresenceLabel({
        online: true,
        privacySettings: { showOnlineStatus: false },
      }),
    ).toBe('Не в сети');
  });

  it('online=false и lastSeen скрыт → "Не в сети"', () => {
    expect(
      resolvePresenceLabel({
        online: false,
        lastSeen: '2026-05-01T10:00:00Z',
        privacySettings: { showLastSeen: false },
      }),
    ).toBe('Не в сети');
  });

  it('online=false, lastSeen открыт и валиден → relative-строка', () => {
    const label = resolvePresenceLabel({
      online: false,
      lastSeen: '2020-01-01T00:00:00Z',
    });
    expect(label.startsWith('Был(а) ')).toBe(true);
    expect(label).not.toBe('Не в сети');
  });

  it('битый lastSeen → "Не в сети"', () => {
    expect(
      resolvePresenceLabel({
        online: false,
        lastSeen: 'not a date',
      }),
    ).toBe('Не в сети');
  });

  it('пустая lastSeen строка → "Не в сети"', () => {
    expect(
      resolvePresenceLabel({
        online: false,
        lastSeen: '   ',
      }),
    ).toBe('Не в сети');
  });
});
