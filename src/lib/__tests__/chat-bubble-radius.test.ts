import { describe, expect, it } from 'vitest';
import {
  normalizeBubbleRadius,
  bubbleRadiusToClass,
  BUBBLE_RADIUS_OPTIONS,
} from '@/lib/chat-bubble-radius';

/**
 * [audit M-013] Bubble radius normaliser: переводит legacy keys из
 * Firestore (`square`/`sharp`/`soft`/`compact`/`rounded`/`loose`/...)
 * на canonical 2 значения `rounded` | `square`. Регрессия → у старых
 * пользователей сбивается визуал чатов.
 */

describe('normalizeBubbleRadius', () => {
  it('null/undefined/empty → "rounded" (default)', () => {
    expect(normalizeBubbleRadius(null)).toBe('rounded');
    expect(normalizeBubbleRadius(undefined)).toBe('rounded');
    expect(normalizeBubbleRadius('')).toBe('rounded');
  });

  it('canonical "rounded" / "square" passthrough', () => {
    expect(normalizeBubbleRadius('rounded')).toBe('rounded');
    expect(normalizeBubbleRadius('square')).toBe('square');
  });

  it('legacy keys → square', () => {
    expect(normalizeBubbleRadius('sharp')).toBe('square');
    expect(normalizeBubbleRadius('soft')).toBe('square');
    expect(normalizeBubbleRadius('compact')).toBe('square');
  });

  it('legacy keys → rounded', () => {
    expect(normalizeBubbleRadius('loose')).toBe('rounded');
    expect(normalizeBubbleRadius('extra-rounded')).toBe('rounded');
    expect(normalizeBubbleRadius('bubble')).toBe('rounded');
    expect(normalizeBubbleRadius('pill')).toBe('rounded');
  });

  it('unknown key → fallback "rounded"', () => {
    expect(normalizeBubbleRadius('foobar')).toBe('rounded');
    expect(normalizeBubbleRadius('something-new')).toBe('rounded');
  });
});

describe('bubbleRadiusToClass', () => {
  it('"rounded" → tailwind rounded-2xl', () => {
    expect(bubbleRadiusToClass('rounded')).toBe('rounded-2xl');
  });

  it('"square" → rounded-none', () => {
    expect(bubbleRadiusToClass('square')).toBe('rounded-none');
  });

  it('legacy через normalize→class chain', () => {
    expect(bubbleRadiusToClass('pill')).toBe('rounded-2xl');
    expect(bubbleRadiusToClass('sharp')).toBe('rounded-none');
  });

  it('null/undefined → rounded-2xl (default)', () => {
    expect(bubbleRadiusToClass(null)).toBe('rounded-2xl');
    expect(bubbleRadiusToClass(undefined)).toBe('rounded-2xl');
  });
});

describe('BUBBLE_RADIUS_OPTIONS', () => {
  it('содержит ровно 2 варианта (rounded + square)', () => {
    expect(BUBBLE_RADIUS_OPTIONS).toHaveLength(2);
    expect(BUBBLE_RADIUS_OPTIONS.map((o) => o.value).sort()).toEqual(['rounded', 'square']);
  });

  it('каждый option имеет valid radius class', () => {
    for (const opt of BUBBLE_RADIUS_OPTIONS) {
      expect(opt.radius).toMatch(/^rounded-/);
    }
  });
});
