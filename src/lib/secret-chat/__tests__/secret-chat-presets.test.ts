import { describe, expect, it } from 'vitest';
import {
  SECRET_CHAT_TTL_PRESETS_SEC,
  isSecretChatTtlPresetSec,
} from '@/lib/secret-chat/secret-chat-presets';

/**
 * [audit M-013] Whitelist TTL пресетов secret-чата. SECURITY: значения
 * валидируются в `isSecretChatTtlPresetSec` перед записью в Firestore;
 * правила (firestore.rules) тоже проверяют allowlist — но клиентский
 * guard защищает от случайной отправки arbitrary number, который admin-
 * level пропустил бы.
 */

describe('SECRET_CHAT_TTL_PRESETS_SEC', () => {
  it('содержит 8 пресетов (5 min..1 day)', () => {
    expect(SECRET_CHAT_TTL_PRESETS_SEC).toHaveLength(8);
  });

  it('значения отсортированы по возрастанию', () => {
    const arr = [...SECRET_CHAT_TTL_PRESETS_SEC];
    const sorted = [...arr].sort((a, b) => a - b);
    expect(arr).toEqual(sorted);
  });

  it('все значения положительные кратные минуте', () => {
    for (const v of SECRET_CHAT_TTL_PRESETS_SEC) {
      expect(v).toBeGreaterThan(0);
      expect(v % 60).toBe(0);
    }
  });

  it('минимум 5 минут, максимум 1 сутки', () => {
    const arr = [...SECRET_CHAT_TTL_PRESETS_SEC];
    expect(Math.min(...arr)).toBe(300); // 5 min
    expect(Math.max(...arr)).toBe(86400); // 24h
  });
});

describe('isSecretChatTtlPresetSec', () => {
  it('true для каждого валидного значения из whitelist', () => {
    for (const v of SECRET_CHAT_TTL_PRESETS_SEC) {
      expect(isSecretChatTtlPresetSec(v)).toBe(true);
    }
  });

  it('false для значений вне whitelist', () => {
    expect(isSecretChatTtlPresetSec(0)).toBe(false);
    expect(isSecretChatTtlPresetSec(1)).toBe(false);
    expect(isSecretChatTtlPresetSec(60)).toBe(false); // 1 min — НЕ в пресетах
    expect(isSecretChatTtlPresetSec(500)).toBe(false);
    expect(isSecretChatTtlPresetSec(100_000)).toBe(false);
  });

  it('false для отрицательных', () => {
    expect(isSecretChatTtlPresetSec(-300)).toBe(false);
    expect(isSecretChatTtlPresetSec(-1)).toBe(false);
  });

  it('false для NaN / Infinity', () => {
    expect(isSecretChatTtlPresetSec(NaN)).toBe(false);
    expect(isSecretChatTtlPresetSec(Infinity)).toBe(false);
    expect(isSecretChatTtlPresetSec(-Infinity)).toBe(false);
  });

  it('SECURITY: type-guard защищает от arbitrary number в Firestore', () => {
    // Пример типичного использования в коде:
    // if (isSecretChatTtlPresetSec(input)) await updateDoc(..., { ttl: input });
    // Если функция пропустит произвольное число — Firestore-правило ещё может
    // помочь, но контракт unit-теста фиксирует первую линию обороны.
    const malicious = 999_999_999; // 31 год
    expect(isSecretChatTtlPresetSec(malicious)).toBe(false);
  });
});
