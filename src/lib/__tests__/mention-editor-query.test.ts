import { describe, expect, it } from 'vitest';
import {
  resolveMentionQueryFromAfterAt,
  buildMentionBoundaryNameList,
} from '@/lib/mention-editor-query';

/**
 * [audit M-013] @-режим composer'а. После полного имени + пробел список
 * подсказок гасится (null), иначе показывается. Регрессия → список
 * висит навечно ИЛИ не появляется после @.
 */

describe('resolveMentionQueryFromAfterAt', () => {
  const names = ['Кэрол Иванова', 'Алиса', 'Боб', 'alice'];

  it('пустая граничная список → query = afterAt', () => {
    expect(resolveMentionQueryFromAfterAt('alic', [])).toBe('alic');
    expect(resolveMentionQueryFromAfterAt('', [])).toBe('');
  });

  it('частичный ввод (substring имени) → afterAt (показать подсказки)', () => {
    expect(resolveMentionQueryFromAfterAt('Али', names)).toBe('Али');
    expect(resolveMentionQueryFromAfterAt('', names)).toBe('');
  });

  it('точное совпадение без пробела → null (упоминание завершено)', () => {
    expect(resolveMentionQueryFromAfterAt('Алиса', names)).toBeNull();
  });

  it('полное имя + пробел + текст → null', () => {
    expect(resolveMentionQueryFromAfterAt('Алиса привет', names)).toBeNull();
    expect(resolveMentionQueryFromAfterAt('Кэрол Иванова привет', names)).toBeNull();
  });

  it('частичный ввод после полного — упоминание ещё открыто', () => {
    // Если в namesSortedLongestFirst есть «Кэрол Иванова», то «Кэрол» отдельно
    // должно ещё показывать подсказки (substring не = полное имя).
    expect(resolveMentionQueryFromAfterAt('Кэрол', names)).toBe('Кэрол');
  });

  it('пустое имя в списке (broken) игнорируется', () => {
    expect(resolveMentionQueryFromAfterAt('a', ['', '   ', 'Алиса'])).toBe('a');
  });
});

describe('buildMentionBoundaryNameList', () => {
  it('dedupe + trim + сортировка по длине (descending)', () => {
    const r = buildMentionBoundaryNameList([
      'Алиса',
      '   Алиса   ',
      'Кэрол Иванова',
      'Боб',
      '',
      'Кэрол Иванова',
    ]);
    expect(r).toEqual(['Кэрол Иванова', 'Алиса', 'Боб']);
  });

  it('пустой input → пустой массив', () => {
    expect(buildMentionBoundaryNameList([])).toEqual([]);
  });

  it('только whitespace → пустой массив', () => {
    expect(buildMentionBoundaryNameList(['', '   ', '\n'])).toEqual([]);
  });

  it('сортировка стабильна для равных длин', () => {
    const r = buildMentionBoundaryNameList(['abc', 'xyz', 'qrs']);
    expect(r).toHaveLength(3);
    expect(r.every((s) => s.length === 3)).toBe(true);
  });
});
