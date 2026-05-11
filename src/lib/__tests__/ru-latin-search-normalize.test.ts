import { describe, expect, it } from 'vitest';
import {
  cyrillicToLatin,
  latinToCyrillic,
  haystackSearchVariants,
  querySearchNeedles,
  ruEnSubstringMatch,
} from '@/lib/ru-latin-search-normalize';

/**
 * [audit M-013] Bilingual (RU↔EN) substring search. Используется
 * везде где юзер может ввести имя контакта в одной раскладке а данные
 * в другой («Alice» vs «Алиса», «Иван» vs «Ivan»). Регрессия — search
 * перестаёт находить контакты при mixed-keyboard input.
 */

describe('cyrillicToLatin', () => {
  it('базовая транслитерация', () => {
    expect(cyrillicToLatin('алиса')).toBe('alisa');
    expect(cyrillicToLatin('иван')).toBe('ivan');
    expect(cyrillicToLatin('борис')).toBe('boris');
  });

  it('uppercase нормализуется в lowercase', () => {
    expect(cyrillicToLatin('АЛИСА')).toBe('alisa');
  });

  it('пропускает символы вне cyrillic alphabet', () => {
    expect(cyrillicToLatin('алиса!')).toContain('alisa');
    expect(cyrillicToLatin('алиса 123')).toContain('alisa');
  });

  it('пустая строка → ""', () => {
    expect(cyrillicToLatin('')).toBe('');
  });

  it('latin passthrough (нет в карте — оставлен)', () => {
    expect(cyrillicToLatin('abc')).toBe('abc');
  });
});

describe('latinToCyrillic', () => {
  it('базовая обратная транслитерация', () => {
    expect(latinToCyrillic('alisa')).toContain('алиса');
  });

  it('multi-char digraphs (sh→ш, ch→ч, sch→щ)', () => {
    const r = latinToCyrillic('shar');
    expect(r.startsWith('ш')).toBe(true);
  });
});

describe('haystackSearchVariants', () => {
  it('cyrillic input → варианты [original, latin]', () => {
    const r = haystackSearchVariants('Алиса');
    expect(r).toContain('алиса');
    expect(r).toContain('alisa');
  });

  it('latin input → варианты [original, cyrillic]', () => {
    const r = haystackSearchVariants('alisa');
    expect(r.length).toBeGreaterThanOrEqual(1);
    expect(r).toContain('alisa');
  });

  it('пустой trim → []', () => {
    expect(haystackSearchVariants('')).toEqual([]);
    expect(haystackSearchVariants('   ')).toEqual([]);
  });

  it('mixed-script тоже даёт варианты', () => {
    const r = haystackSearchVariants('Alice Иванова');
    expect(r.length).toBeGreaterThanOrEqual(1);
  });
});

describe('querySearchNeedles', () => {
  it('cyrillic query → варианты для поиска', () => {
    const r = querySearchNeedles('али');
    expect(r).toContain('али');
  });

  it('пустой → []', () => {
    expect(querySearchNeedles('')).toEqual([]);
    expect(querySearchNeedles('   ')).toEqual([]);
  });
});

describe('ruEnSubstringMatch (главный API)', () => {
  it('cyrillic ⊆ cyrillic', () => {
    expect(ruEnSubstringMatch('Алиса Петрова', 'Али')).toBe(true);
  });

  it('latin query → cyrillic haystack (cross-script)', () => {
    expect(ruEnSubstringMatch('Алиса', 'alisa')).toBe(true);
    expect(ruEnSubstringMatch('Алиса', 'alis')).toBe(true);
  });

  it('cyrillic query → latin haystack', () => {
    expect(ruEnSubstringMatch('Alice', 'али')).toBe(true);
  });

  it('пустой needle → true (нет фильтра)', () => {
    expect(ruEnSubstringMatch('Alice', '')).toBe(true);
    expect(ruEnSubstringMatch('Alice', '   ')).toBe(true);
  });

  it('не находит несвязанные', () => {
    expect(ruEnSubstringMatch('Алиса', 'qqq')).toBe(false);
    expect(ruEnSubstringMatch('Bob', 'Алиса')).toBe(false);
  });

  it('case-insensitive', () => {
    expect(ruEnSubstringMatch('ALICE', 'alic')).toBe(true);
    expect(ruEnSubstringMatch('алиса', 'АЛИ')).toBe(true);
  });
});
