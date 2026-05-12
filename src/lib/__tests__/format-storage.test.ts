import { describe, expect, it } from 'vitest';

import { bytesToGiB, formatStorageBytes } from '@/lib/format-storage';

/**
 * [audit M-013] formatStorageBytes — UX-критический рендер квоты в admin / settings.
 * Регрессия = пользователь видит неверный размер своего хранилища.
 * Проверяем границы (1024, 0, отрицательные, NaN), и что для маленьких значений
 * нет дробной части ("Б"), а для крупных — одно знак после запятой.
 */

describe('formatStorageBytes', () => {
  it('0 → "0 Б"', () => {
    expect(formatStorageBytes(0)).toBe('0 Б');
  });

  it('отрицательное → "0 Б" (защита от мусора)', () => {
    expect(formatStorageBytes(-100)).toBe('0 Б');
  });

  it('NaN → "0 Б"', () => {
    expect(formatStorageBytes(Number.NaN)).toBe('0 Б');
  });

  it('Infinity → "0 Б"', () => {
    expect(formatStorageBytes(Number.POSITIVE_INFINITY)).toBe('0 Б');
  });

  it('байты без десятичных знаков', () => {
    expect(formatStorageBytes(500)).toBe('500 Б');
    expect(formatStorageBytes(1023)).toBe('1023 Б');
  });

  it('1024 = 1.00 КиБ (две десятичных знака для значений <10)', () => {
    expect(formatStorageBytes(1024)).toBe('1.00 КиБ');
  });

  it('5 КиБ = 5.00 КиБ (значение <10)', () => {
    expect(formatStorageBytes(5 * 1024)).toBe('5.00 КиБ');
  });

  it('значения >=10 — одна десятичная', () => {
    expect(formatStorageBytes(10 * 1024)).toBe('10.0 КиБ');
    expect(formatStorageBytes(100 * 1024)).toBe('100.0 КиБ');
  });

  it('1 МиБ', () => {
    expect(formatStorageBytes(1024 ** 2)).toBe('1.00 МиБ');
  });

  it('гигабайты (юнит "Гб" по соглашению UI)', () => {
    expect(formatStorageBytes(1024 ** 3)).toBe('1.00 Гб');
    expect(formatStorageBytes(15 * 1024 ** 3)).toBe('15.0 Гб');
  });

  it('ТиБ — последний юнит, никогда не переходит дальше', () => {
    expect(formatStorageBytes(1024 ** 4)).toBe('1.00 ТиБ');
    expect(formatStorageBytes(2048 * 1024 ** 4)).toMatch(/ТиБ$/);
  });
});

describe('bytesToGiB', () => {
  it('1 ГиБ → 1', () => {
    expect(bytesToGiB(1024 ** 3)).toBe(1);
  });

  it('0 → 0', () => {
    expect(bytesToGiB(0)).toBe(0);
  });

  it('512 МиБ → 0.5', () => {
    expect(bytesToGiB(512 * 1024 ** 2)).toBeCloseTo(0.5, 5);
  });
});
