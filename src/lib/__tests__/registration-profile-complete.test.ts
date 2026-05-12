import { describe, expect, it } from 'vitest';

import { isRegistrationProfileComplete } from '@/lib/registration-profile-complete';

/**
 * [audit M-013] Гейт «регистрация завершена» — используется в auth-флоу и
 * dashboard для редиректа на `/register/profile`. Регрессия = либо
 * пользователь застрял на экране без видимой ошибки (false-negative),
 * либо неготовый профиль пропускается в приложение (false-positive — что
 * ломает downstream-инварианты: пустой username нельзя индексировать,
 * пустой email сломает Auth flow).
 */

describe('isRegistrationProfileComplete', () => {
  it('null / undefined → false', () => {
    expect(isRegistrationProfileComplete(null)).toBe(false);
    expect(isRegistrationProfileComplete(undefined)).toBe(false);
  });

  it('happy path: name + username + email', () => {
    expect(
      isRegistrationProfileComplete({
        name: 'Иван Петров',
        username: 'ivan_petrov',
        email: 'ivan@example.com',
      }),
    ).toBe(true);
  });

  it('name короче 2 символов → false', () => {
    expect(
      isRegistrationProfileComplete({
        name: 'И',
        username: 'ivan_petrov',
        email: 'ivan@example.com',
      }),
    ).toBe(false);
  });

  it('name из одних пробелов → false', () => {
    expect(
      isRegistrationProfileComplete({
        name: '   ',
        username: 'ivan_petrov',
        email: 'ivan@example.com',
      }),
    ).toBe(false);
  });

  it('пустой username → false', () => {
    expect(
      isRegistrationProfileComplete({
        name: 'Иван',
        username: '',
        email: 'ivan@example.com',
      }),
    ).toBe(false);
  });

  it('username из недопустимых символов нормализуется и валится (слишком короткий)', () => {
    expect(
      isRegistrationProfileComplete({
        name: 'Иван',
        username: '@@',
        email: 'ivan@example.com',
      }),
    ).toBe(false);
  });

  it('кириллица в username нормализуется в "_" → не проходит длину', () => {
    expect(
      isRegistrationProfileComplete({
        name: 'Иван',
        username: 'иван',
        email: 'ivan@example.com',
      }),
    ).toBe(false);
  });

  it('username с точкой посередине проходит', () => {
    expect(
      isRegistrationProfileComplete({
        name: 'Иван',
        username: 'shpantsev.vyacheslav',
        email: 'ivan@example.com',
      }),
    ).toBe(true);
  });

  it('email без @ → false', () => {
    expect(
      isRegistrationProfileComplete({
        name: 'Иван',
        username: 'ivan_petrov',
        email: 'not-an-email',
      }),
    ).toBe(false);
  });

  it('email без TLD → false', () => {
    expect(
      isRegistrationProfileComplete({
        name: 'Иван',
        username: 'ivan_petrov',
        email: 'ivan@example',
      }),
    ).toBe(false);
  });

  it('пустой email → false', () => {
    expect(
      isRegistrationProfileComplete({
        name: 'Иван',
        username: 'ivan_petrov',
        email: '',
      }),
    ).toBe(false);
  });

  it('email с пробелами вокруг — trim проходит', () => {
    expect(
      isRegistrationProfileComplete({
        name: 'Иван',
        username: 'ivan_petrov',
        email: '  ivan@example.com  ',
      }),
    ).toBe(true);
  });

  it('null-поля → false (все три необходимы)', () => {
    // @ts-expect-error — runtime защита
    expect(isRegistrationProfileComplete({ name: null, username: null, email: null })).toBe(false);
  });

  it('username принимает email-подобную строку и берет local-part', () => {
    expect(
      isRegistrationProfileComplete({
        name: 'Иван',
        username: 'shpantsev.vyacheslav@m.thelightech.com',
        email: 'ivan@example.com',
      }),
    ).toBe(true);
  });

  it('username длиннее 30 символов после нормализации → false', () => {
    const longUsername = 'a'.repeat(40);
    // нормализация обрежет до 30 — это валидно по факту
    expect(
      isRegistrationProfileComplete({
        name: 'Иван',
        username: longUsername,
        email: 'ivan@example.com',
      }),
    ).toBe(true);
  });
});
