import { describe, expect, it } from 'vitest';
import {
  buildContactDisplayName,
  resolveContactDisplayName,
  splitNameForContactForm,
} from '@/lib/contact-display-name';
import type { UserContactLocalProfile } from '@/lib/types';

/**
 * [audit M-013] Resolve display name через локальный контакт-профиль —
 * UX-критическая логика (как имена пользователей отображаются в чатах /
 * mention'ах / профиле). Регрессия → wrong имя у собеседника, или
 * leak настоящего имени когда юзер сохранил под своим псевдонимом.
 */

describe('buildContactDisplayName', () => {
  it('first + last', () => {
    expect(buildContactDisplayName({ firstName: 'Иван', lastName: 'Петров' })).toBe('Иван Петров');
  });

  it('только first', () => {
    expect(buildContactDisplayName({ firstName: 'Иван' })).toBe('Иван');
  });

  it('только last', () => {
    expect(buildContactDisplayName({ lastName: 'Петров' })).toBe('Петров');
  });

  it('обе null → пустая строка', () => {
    expect(buildContactDisplayName({})).toBe('');
    expect(buildContactDisplayName({ firstName: null, lastName: null })).toBe('');
  });

  it('whitespace trim', () => {
    expect(buildContactDisplayName({ firstName: '  Иван  ', lastName: ' ' })).toBe('Иван');
  });
});

describe('resolveContactDisplayName', () => {
  const profiles: Record<string, UserContactLocalProfile> = {
    u1: { displayName: 'Босс', firstName: 'Иван', lastName: 'Петров' },
    u2: { displayName: '', firstName: 'Анна', lastName: '' },
    u3: { displayName: '', firstName: '', lastName: '' },
  };

  it('displayName приоритетнее first/last/fallback', () => {
    expect(resolveContactDisplayName(profiles, 'u1', 'Real Name')).toBe('Босс');
  });

  it('пустой displayName → composed из first/last', () => {
    expect(resolveContactDisplayName(profiles, 'u2', 'Real Name')).toBe('Анна');
  });

  it('всё пустое → fallback', () => {
    expect(resolveContactDisplayName(profiles, 'u3', 'Real Name')).toBe('Real Name');
  });

  it('id не в профилях → fallback', () => {
    expect(resolveContactDisplayName(profiles, 'unknown', 'Real Name')).toBe('Real Name');
  });

  it('null/undefined contactProfiles → fallback', () => {
    expect(resolveContactDisplayName(null, 'u1', 'Real Name')).toBe('Real Name');
    expect(resolveContactDisplayName(undefined, 'u1', 'Real Name')).toBe('Real Name');
  });

  it('пустой id → fallback', () => {
    expect(resolveContactDisplayName(profiles, '', 'Real Name')).toBe('Real Name');
    expect(resolveContactDisplayName(profiles, null, 'Real Name')).toBe('Real Name');
  });

  it('id с whitespace → trimmed', () => {
    expect(resolveContactDisplayName(profiles, '  u1  ', 'Real Name')).toBe('Босс');
  });
});

describe('splitNameForContactForm', () => {
  it('"Иван Петров" → {Иван, Петров}', () => {
    expect(splitNameForContactForm('Иван Петров')).toEqual({
      firstName: 'Иван',
      lastName: 'Петров',
    });
  });

  it('"Иван" → {Иван, ""}', () => {
    expect(splitNameForContactForm('Иван')).toEqual({
      firstName: 'Иван',
      lastName: '',
    });
  });

  it('"" → пустые', () => {
    expect(splitNameForContactForm('')).toEqual({ firstName: '', lastName: '' });
  });

  it('только whitespace → пустые', () => {
    expect(splitNameForContactForm('   ')).toEqual({ firstName: '', lastName: '' });
  });

  it('3-словное имя — first слово в firstName, остальное в lastName', () => {
    expect(splitNameForContactForm('Хосе Мария Гарсия')).toEqual({
      firstName: 'Хосе',
      lastName: 'Мария Гарсия',
    });
  });

  it('коллапс множественных пробелов', () => {
    expect(splitNameForContactForm('Иван    Петров')).toEqual({
      firstName: 'Иван',
      lastName: 'Петров',
    });
  });
});
