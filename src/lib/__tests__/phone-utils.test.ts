import { describe, expect, it } from 'vitest';

import {
  applyPhoneMask,
  formatPhoneNumberForDisplay,
  normalizePhoneDigits,
  phoneFormValueFromStored,
  phoneLookupVariants,
  phoneStorageFromFormatted,
} from '@/lib/phone-utils';

/**
 * [audit M-013] Регресс-сценарии для phone-utils. Поле `users.phone` —
 * registration-index key (см. `registrationIndex` collection и поиск по контактам).
 * Регрессия в нормализации = либо невозможность найти пользователя по контакту,
 * либо коллизия / leak номера в lookup-запросе. Поэтому покрываем:
 *  - канонизацию 8 → 7 / 10-digit → 7+10
 *  - дедуп через Set в `phoneLookupVariants`
 *  - граничные случаи маски (пустая строка, неполный номер, передёрнутый ввод)
 */

describe('normalizePhoneDigits', () => {
  it('+7 (900) 123-45-67 → 79001234567', () => {
    expect(normalizePhoneDigits('+7 (900) 123-45-67')).toBe('79001234567');
  });

  it('8 (900) 123-45-67 → 79001234567 (8 на 7)', () => {
    expect(normalizePhoneDigits('8 (900) 123-45-67')).toBe('79001234567');
  });

  it('10 цифр 9001234567 → 79001234567 (дописывает 7)', () => {
    expect(normalizePhoneDigits('9001234567')).toBe('79001234567');
  });

  it('15-значный международный остаётся без суффиксов 7', () => {
    expect(normalizePhoneDigits('+12025550123')).toBe('12025550123');
  });

  it('пустая строка → пустая', () => {
    expect(normalizePhoneDigits('')).toBe('');
  });

  it('не трогает уже 11-значный с 7', () => {
    expect(normalizePhoneDigits('79001234567')).toBe('79001234567');
  });

  it('8-начало, но не 11 цифр → не подменяет на 7 (защита от мусора)', () => {
    expect(normalizePhoneDigits('8900')).toBe('8900');
  });
});

describe('phoneLookupVariants', () => {
  it('РФ ввод дает несколько форматных вариантов (lookup в users.phone)', () => {
    const v = phoneLookupVariants('+79001234567');
    expect(v).toContain('+79001234567');
    expect(v).toContain('79001234567');
    expect(v).toContain('89001234567');
    expect(v).toContain('+89001234567');
    expect(v).toContain('9001234567');
    // Маска как в PhoneInput:
    expect(v).toContain('+7(900)123-45-67');
  });

  it('варианты уникальны (Set)', () => {
    const v = phoneLookupVariants('+79001234567');
    expect(new Set(v).size).toBe(v.length);
  });

  it('менее 10 цифр → []', () => {
    expect(phoneLookupVariants('+790')).toEqual([]);
    expect(phoneLookupVariants('')).toEqual([]);
  });

  it('8-формат на входе равен +7-формату на выходе', () => {
    const a = phoneLookupVariants('89001234567');
    const b = phoneLookupVariants('+79001234567');
    expect(new Set(a)).toEqual(new Set(b));
  });

  it('включает форматные строки с пробелами/скобками для legacy профилей', () => {
    const v = phoneLookupVariants('+79001234567');
    expect(v).toContain('+7 (900) 123-45-67');
    expect(v).toContain('+7 900 123-45-67');
    expect(v).toContain('8 (900) 123-45-67');
  });
});

describe('applyPhoneMask', () => {
  it('накладывает маску на 11 цифр', () => {
    expect(applyPhoneMask('79001234567')).toBe('+7(900)123-45-67');
  });

  it('8 → 7 в маске', () => {
    expect(applyPhoneMask('89001234567')).toBe('+7(900)123-45-67');
  });

  it('частичный ввод', () => {
    expect(applyPhoneMask('+7900')).toBe('+7(900)');
    expect(applyPhoneMask('+79001')).toBe('+7(900)1');
    expect(applyPhoneMask('+790012')).toBe('+7(900)12');
    expect(applyPhoneMask('+7900123')).toBe('+7(900)123');
    expect(applyPhoneMask('+79001234')).toBe('+7(900)123-4');
  });

  it('пустая строка → "+7"', () => {
    expect(applyPhoneMask('')).toBe('+7');
  });
});

describe('phoneFormValueFromStored', () => {
  it('канонизует к +7XXXXXXXXXX (без маски, как ждёт PhoneInput)', () => {
    expect(phoneFormValueFromStored('+7 (900) 123-45-67')).toBe('+79001234567');
    expect(phoneFormValueFromStored('89001234567')).toBe('+79001234567');
    expect(phoneFormValueFromStored('9001234567')).toBe('+79001234567');
  });

  it('пустое / undefined → пустая строка', () => {
    expect(phoneFormValueFromStored(undefined)).toBe('');
    expect(phoneFormValueFromStored('')).toBe('');
    expect(phoneFormValueFromStored('   ')).toBe('');
  });

  it('менее 10 цифр → возвращает trimmed raw без подмены', () => {
    expect(phoneFormValueFromStored('  +123  ')).toBe('+123');
  });

  it('обрезает до 11 цифр после 7', () => {
    expect(phoneFormValueFromStored('+79001234567890')).toBe('+79001234567');
  });
});

describe('phoneStorageFromFormatted', () => {
  it('убирает маску и оставляет +DDDDDDDDDDD', () => {
    expect(phoneStorageFromFormatted('+7(900) 123-45-67')).toBe('+79001234567');
  });

  it('пустое → пустое', () => {
    expect(phoneStorageFromFormatted('')).toBe('');
  });

  it('обрезает свыше 11 цифр', () => {
    expect(phoneStorageFromFormatted('+790012345678999')).toBe('+79001234567');
  });

  it('строка из мусора без цифр → ""', () => {
    expect(phoneStorageFromFormatted('---()')).toBe('');
  });
});

describe('formatPhoneNumberForDisplay', () => {
  it('форматирует с маской для таблиц', () => {
    expect(formatPhoneNumberForDisplay('+79001234567')).toBe('+7(900)123-45-67');
  });

  it('пусто → длинное тире', () => {
    expect(formatPhoneNumberForDisplay('')).toBe('—');
    expect(formatPhoneNumberForDisplay('   ')).toBe('—');
  });
});
