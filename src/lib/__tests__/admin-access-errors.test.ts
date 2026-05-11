import { describe, expect, it, vi, beforeEach, afterEach } from 'vitest';
import { interpretAdminAccessError } from '@/lib/admin-access-errors';

/**
 * [audit M-013] Error message resolver для admin-actions. Возвращает
 * user-facing описание ошибки. Регрессия → юзер видит «Не удалось
 * проверить права» вместо понятного «Сессия устарела» / «Недостаточно
 * прав».
 *
 * SECURITY: всегда возвращает generic message — не утекает stack trace
 * или внутренние коды в браузер. Это контракт, регрессию которого
 * фиксируем тестом.
 */

describe('interpretAdminAccessError', () => {
  let consoleSpy: ReturnType<typeof vi.spyOn>;
  beforeEach(() => {
    // Suppress noisy console.error during tests
    consoleSpy = vi.spyOn(console, 'error').mockImplementation(() => {});
  });
  afterEach(() => {
    consoleSpy.mockRestore();
  });

  it('Error("FORBIDDEN") → «Недостаточно прав»', () => {
    expect(interpretAdminAccessError(new Error('FORBIDDEN'))).toBe('Недостаточно прав');
  });

  it('Error("UNAUTHORIZED") → «Недостаточно прав»', () => {
    expect(interpretAdminAccessError(new Error('UNAUTHORIZED'))).toBe('Недостаточно прав');
  });

  it('id-token-expired → «Сессия устарела»', () => {
    expect(
      interpretAdminAccessError({ code: 'auth/id-token-expired' }),
    ).toContain('Сессия устарела');
  });

  it('argument-error / invalid-id-token → «Сессия устарела»', () => {
    expect(
      interpretAdminAccessError({ code: 'auth/argument-error' }),
    ).toContain('Сессия устарела');
    expect(
      interpretAdminAccessError({ code: 'auth/invalid-id-token' }),
    ).toContain('Сессия устарела');
  });

  it('сообщение содержит "token has expired" → «Сессия устарела»', () => {
    expect(
      interpretAdminAccessError({ message: 'Firebase ID token has expired.' }),
    ).toContain('Сессия устарела');
  });

  it('credential error → инструкция про admin-credentials', () => {
    const r = interpretAdminAccessError({ code: 'app/no-app' });
    expect(r).toContain('Firebase Admin');
    expect(r).toContain('GOOGLE_APPLICATION_CREDENTIALS');
  });

  it('message про service account → инструкция про admin-credentials', () => {
    expect(
      interpretAdminAccessError({ message: 'Could not load the default credentials' }),
    ).toContain('GOOGLE_APPLICATION_CREDENTIALS');
  });

  it('unknown error → generic fallback', () => {
    expect(interpretAdminAccessError(new Error('some unrelated error'))).toContain(
      'Не удалось проверить права',
    );
  });

  it('non-Error (string/number) → generic fallback', () => {
    expect(interpretAdminAccessError('boom')).toContain('Не удалось проверить права');
    expect(interpretAdminAccessError(42)).toContain('Не удалось проверить права');
    expect(interpretAdminAccessError(null)).toContain('Не удалось проверить права');
  });

  it('SECURITY: не утекает stack trace / raw сообщение в результат', () => {
    // Even with sensitive internal message, output должен быть generic.
    const r = interpretAdminAccessError(new Error('Internal database connection failed at db.ts:42'));
    expect(r).not.toContain('db.ts');
    expect(r).not.toContain('Internal database');
  });
});
