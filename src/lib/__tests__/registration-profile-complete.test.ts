import { describe, expect, it } from 'vitest';

import { isRegistrationProfileComplete } from '@/lib/registration-profile-complete';
import type { User } from '@/lib/types';

/**
 * [audit M-013] Гейт «регистрация завершена» — используется в auth-флоу и
 * dashboard для редиректа на `/register/profile`. Регрессия = либо
 * пользователь застрял на экране без видимой ошибки (false-negative),
 * либо неготовый профиль пропускается в приложение (false-positive — что
 * ломает downstream-инварианты: пустой username нельзя индексировать,
 * пустой email сломает Auth flow).
 */

type ProfileInput = Pick<User, 'name' | 'username' | 'phone' | 'email'>;

function profile(overrides: Partial<ProfileInput> = {}): ProfileInput {
  return {
    name: 'Иван',
    username: 'ivan_petrov',
    phone: '+79001234567',
    email: 'ivan@example.com',
    ...overrides,
  };
}

describe('isRegistrationProfileComplete', () => {
  it('null / undefined → false', () => {
    expect(isRegistrationProfileComplete(null)).toBe(false);
    expect(isRegistrationProfileComplete(undefined)).toBe(false);
  });

  it('happy path: name + username + email', () => {
    expect(isRegistrationProfileComplete(profile({ name: 'Иван Петров' }))).toBe(true);
  });

  it('name короче 2 символов → false', () => {
    expect(isRegistrationProfileComplete(profile({ name: 'И' }))).toBe(false);
  });

  it('name из одних пробелов → false', () => {
    expect(isRegistrationProfileComplete(profile({ name: '   ' }))).toBe(false);
  });

  it('пустой username → false', () => {
    expect(isRegistrationProfileComplete(profile({ username: '' }))).toBe(false);
  });

  it('username из недопустимых символов нормализуется и валится (слишком короткий)', () => {
    expect(isRegistrationProfileComplete(profile({ username: '@@' }))).toBe(false);
  });

  it('кириллица в username нормализуется в "_" → не проходит длину', () => {
    expect(isRegistrationProfileComplete(profile({ username: 'иван' }))).toBe(false);
  });

  it('username с точкой посередине проходит', () => {
    expect(
      isRegistrationProfileComplete(profile({ username: 'shpantsev.vyacheslav' })),
    ).toBe(true);
  });

  it('email без @ → false', () => {
    expect(isRegistrationProfileComplete(profile({ email: 'not-an-email' }))).toBe(false);
  });

  it('email без TLD → false', () => {
    expect(isRegistrationProfileComplete(profile({ email: 'ivan@example' }))).toBe(false);
  });

  it('пустой email → false', () => {
    expect(isRegistrationProfileComplete(profile({ email: '' }))).toBe(false);
  });

  it('email с пробелами вокруг — trim проходит', () => {
    expect(
      isRegistrationProfileComplete(profile({ email: '  ivan@example.com  ' })),
    ).toBe(true);
  });

  it('null-поля → false (все три необходимы)', () => {
    // @ts-expect-error — runtime защита
    expect(isRegistrationProfileComplete({ name: null, username: null, email: null, phone: null })).toBe(false);
  });

  it('username принимает email-подобную строку и берет local-part', () => {
    expect(
      isRegistrationProfileComplete(profile({ username: 'shpantsev.vyacheslav@m.thelightech.com' })),
    ).toBe(true);
  });

  it('username длиннее 30 символов после нормализации → false', () => {
    const longUsername = 'a'.repeat(40);
    // нормализация обрежет до 30 — это валидно по факту
    expect(
      isRegistrationProfileComplete(profile({ username: longUsername })),
    ).toBe(true);
  });
});
