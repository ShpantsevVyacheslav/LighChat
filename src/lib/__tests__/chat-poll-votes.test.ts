import { describe, expect, it } from 'vitest';
import {
  normalizeUserVote,
  countVotesForOption,
  userHasVoted,
  userSelectedOption,
  displayOptionIndices,
} from '@/lib/chat-poll-votes';

/**
 * [audit M-013] Голосование в чат-опросах. Регрессия — потеря голосов
 * или дубликаты счётчиков. `normalizeUserVote` принимает untrusted
 * Firestore-shape (single-choice `number` ИЛИ multi-choice `number[]`,
 * иногда из mobile приходит `string` — все эти случаи фиксируем).
 */

describe('normalizeUserVote', () => {
  it('null/undefined → []', () => {
    expect(normalizeUserVote(null)).toEqual([]);
    expect(normalizeUserVote(undefined)).toEqual([]);
  });

  it('число → [n]', () => {
    expect(normalizeUserVote(2)).toEqual([2]);
    expect(normalizeUserVote(0)).toEqual([0]);
  });

  it('float → floor', () => {
    expect(normalizeUserVote(2.7)).toEqual([2]);
  });

  it('Infinity/NaN → []', () => {
    expect(normalizeUserVote(Infinity)).toEqual([]);
    expect(normalizeUserVote(NaN)).toEqual([]);
  });

  it('строковое число (mobile fallback) → [n]', () => {
    expect(normalizeUserVote('3')).toEqual([3]);
  });

  it('некорректная строка → []', () => {
    expect(normalizeUserVote('abc')).toEqual([]);
  });

  it('массив чисел → отсортирован и дедуплицирован', () => {
    expect(normalizeUserVote([3, 1, 2, 1, 3])).toEqual([1, 2, 3]);
  });

  it('массив со строками — нормализуется', () => {
    expect(normalizeUserVote(['2', 1, '3'])).toEqual([1, 2, 3]);
  });

  it('массив с мусором — мусор отфильтрован', () => {
    expect(normalizeUserVote([1, null, 'abc', 2, NaN])).toEqual([1, 2]);
  });

  it('неподходящий тип → []', () => {
    expect(normalizeUserVote({})).toEqual([]);
    expect(normalizeUserVote(true)).toEqual([]);
  });
});

describe('countVotesForOption', () => {
  it('count = 0 если votes отсутствуют', () => {
    expect(countVotesForOption(undefined, 0)).toBe(0);
    expect(countVotesForOption({}, 0)).toBe(0);
  });

  it('счёт single-choice голосов', () => {
    const votes = { u1: 0, u2: 1, u3: 0 };
    expect(countVotesForOption(votes, 0)).toBe(2);
    expect(countVotesForOption(votes, 1)).toBe(1);
    expect(countVotesForOption(votes, 2)).toBe(0);
  });

  it('счёт multi-choice голосов', () => {
    const votes = { u1: [0, 1], u2: [1], u3: [0, 2] };
    expect(countVotesForOption(votes, 0)).toBe(2);
    expect(countVotesForOption(votes, 1)).toBe(2);
    expect(countVotesForOption(votes, 2)).toBe(1);
  });
});

describe('userHasVoted', () => {
  it('false без votes / без userId', () => {
    expect(userHasVoted(undefined, 'u1')).toBe(false);
    expect(userHasVoted({ u1: 0 }, '')).toBe(false);
  });

  it('true если есть голос', () => {
    expect(userHasVoted({ u1: 0 }, 'u1')).toBe(true);
    expect(userHasVoted({ u1: [0, 1] }, 'u1')).toBe(true);
  });

  it('false если userId не в votes', () => {
    expect(userHasVoted({ u1: 0 }, 'u2')).toBe(false);
  });
});

describe('userSelectedOption', () => {
  it('single-choice', () => {
    expect(userSelectedOption({ u1: 1 }, 'u1', 1)).toBe(true);
    expect(userSelectedOption({ u1: 1 }, 'u1', 0)).toBe(false);
  });

  it('multi-choice', () => {
    expect(userSelectedOption({ u1: [0, 2] }, 'u1', 0)).toBe(true);
    expect(userSelectedOption({ u1: [0, 2] }, 'u1', 1)).toBe(false);
    expect(userSelectedOption({ u1: [0, 2] }, 'u1', 2)).toBe(true);
  });
});

describe('displayOptionIndices', () => {
  it('shuffle=false → identity [0..n-1]', () => {
    expect(displayOptionIndices('p1', 'u1', 4, false)).toEqual([0, 1, 2, 3]);
  });

  it('optionCount=0 → []', () => {
    expect(displayOptionIndices('p1', 'u1', 0, true)).toEqual([]);
  });

  it('optionCount=1 → [0] независимо от shuffle', () => {
    expect(displayOptionIndices('p1', 'u1', 1, true)).toEqual([0]);
  });

  it('пустой userId → identity (нет shuffle)', () => {
    expect(displayOptionIndices('p1', '', 3, true)).toEqual([0, 1, 2]);
  });

  it('детерминизм: тот же seed → тот же порядок', () => {
    const a = displayOptionIndices('p1', 'u1', 5, true);
    const b = displayOptionIndices('p1', 'u1', 5, true);
    expect(a).toEqual(b);
  });

  it('разные userId → разный порядок (с высокой вероятностью)', () => {
    const a = displayOptionIndices('p1', 'u1', 8, true);
    const b = displayOptionIndices('p1', 'u2', 8, true);
    // Не гарантированно но почти всегда — крайне маловероятно совпасть в полном перестановочном виде.
    expect(JSON.stringify(a)).not.toBe(JSON.stringify(b));
  });

  it('после shuffle — все исходные индексы присутствуют (permutation)', () => {
    const r = displayOptionIndices('p1', 'u1', 5, true);
    expect(r).toHaveLength(5);
    expect([...r].sort((a, b) => a - b)).toEqual([0, 1, 2, 3, 4]);
  });
});
