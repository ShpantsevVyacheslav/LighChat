import { describe, expect, it } from 'vitest';
import {
  atUsernameLabel,
  chatUserDisplayName,
  chatUserInitial,
  userMatchesChatSearchQuery,
} from '@/lib/chat-user-search';
import type { User } from '@/lib/types';

/**
 * [audit M-013] User display + search в списках выбора собеседника
 * (forward, new chat, mention picker). Регрессия — `Пользователь`
 * вместо имени, или search не находит контакт по latin-набору
 * кириллического имени.
 */

const ALICE: User = {
  id: 'alice_uid_long', name: 'Алиса', username: 'alice',
  email: 'alice@example.com', avatar: '', phone: '', deletedAt: null,
  createdAt: '2026-05-07T00:00:00.000Z',
};

describe('atUsernameLabel', () => {
  it('добавляет @ если отсутствует', () => {
    expect(atUsernameLabel('alice')).toBe('@alice');
  });

  it('сохраняет @ если уже есть', () => {
    expect(atUsernameLabel('@alice')).toBe('@alice');
  });

  it('null если пустой', () => {
    expect(atUsernameLabel('')).toBeNull();
    expect(atUsernameLabel(null)).toBeNull();
    expect(atUsernameLabel(undefined)).toBeNull();
    expect(atUsernameLabel('   ')).toBeNull();
  });

  it('trim вокруг', () => {
    expect(atUsernameLabel('  alice  ')).toBe('@alice');
  });
});

describe('chatUserDisplayName', () => {
  it('override приоритетнее name', () => {
    expect(chatUserDisplayName(ALICE, 'Боссина')).toBe('Боссина');
  });

  it('name fallback', () => {
    expect(chatUserDisplayName(ALICE)).toBe('Алиса');
  });

  it('@username если нет name', () => {
    expect(chatUserDisplayName({ ...ALICE, name: '' })).toBe('@alice');
  });

  it('email если нет name и username', () => {
    expect(chatUserDisplayName({ ...ALICE, name: '', username: '' })).toBe('alice@example.com');
  });

  it('"Пользователь {id6}" в самом крайнем случае', () => {
    expect(
      chatUserDisplayName({ id: 'abc123def', name: '', username: '', email: '' }),
    ).toBe('Пользователь abc123');
  });

  it('"Пользователь" если id пустой', () => {
    expect(
      chatUserDisplayName({ id: '', name: '', username: '', email: '' }),
    ).toBe('Пользователь');
  });

  it('whitespace в полях игнорируется', () => {
    expect(chatUserDisplayName({ ...ALICE, name: '   ' })).toBe('@alice');
  });
});

describe('chatUserInitial', () => {
  it('первая буква имени, uppercase', () => {
    expect(chatUserInitial('Алиса')).toBe('А');
    expect(chatUserInitial('bob')).toBe('B');
  });

  it('"?" если пустое', () => {
    expect(chatUserInitial('')).toBe('?');
    expect(chatUserInitial(null)).toBe('?');
    expect(chatUserInitial(undefined)).toBe('?');
    expect(chatUserInitial('   ')).toBe('?');
  });

  it('emoji в имени берёт первую codepoint', () => {
    expect(chatUserInitial('🎉Alice')).not.toBe('');
  });
});

describe('userMatchesChatSearchQuery', () => {
  it('пустой query → всех показывает', () => {
    expect(userMatchesChatSearchQuery(ALICE, '')).toBe(true);
    expect(userMatchesChatSearchQuery(ALICE, '   ')).toBe(true);
  });

  it('substring по name', () => {
    expect(userMatchesChatSearchQuery(ALICE, 'лис')).toBe(true);
    expect(userMatchesChatSearchQuery(ALICE, 'Алиса')).toBe(true);
  });

  it('match по @username с @ префиксом', () => {
    expect(userMatchesChatSearchQuery(ALICE, '@alic')).toBe(true);
  });

  it('match по username без @', () => {
    expect(userMatchesChatSearchQuery(ALICE, 'alic')).toBe(true);
  });

  it('override priorityов name (для contact aliases)', () => {
    expect(userMatchesChatSearchQuery(ALICE, 'Босс', 'Боссина')).toBe(true);
  });

  it('не находит несуществующее', () => {
    expect(userMatchesChatSearchQuery(ALICE, 'zzznoсуществуют')).toBe(false);
  });
});
