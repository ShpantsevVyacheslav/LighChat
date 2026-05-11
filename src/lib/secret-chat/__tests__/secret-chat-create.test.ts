import { describe, expect, it } from 'vitest';
import { buildSecretDirectConversationId } from '@/lib/secret-chat/secret-chat-create';

/**
 * [audit M-013] Secret DM conversation id builder. SECURITY: id фиксирует
 * пару юзеров детерминированно, поэтому A→B и B→A дают тот же id (один
 * чат, не два разных). Регрессия → дубли secret-chat'ов, потеря
 * сообщений между ними.
 *
 * Формат `sdm_<lenA>:<uidA>_<lenB>:<uidB>` где (uidA, uidB) сортируются
 * лексикографически. Префикс `sdm_` и length-encoding защищают от
 * id-collision если uid содержит `:` или `_`.
 */

describe('buildSecretDirectConversationId', () => {
  it('возвращает id с префиксом sdm_', () => {
    expect(buildSecretDirectConversationId('a', 'b')).toMatch(/^sdm_/);
  });

  it('SECURITY: симметрично — A→B и B→A дают тот же id', () => {
    const ab = buildSecretDirectConversationId('alice', 'bob');
    const ba = buildSecretDirectConversationId('bob', 'alice');
    expect(ab).toBe(ba);
  });

  it('lex-сортировка участников (детерминизм)', () => {
    expect(buildSecretDirectConversationId('alice', 'bob')).toBe(
      'sdm_5:alice_3:bob',
    );
    expect(buildSecretDirectConversationId('bob', 'alice')).toBe(
      'sdm_5:alice_3:bob',
    );
  });

  it('length-prefix защищает от collision с `:` в uid', () => {
    // Если бы id был просто `sdm_uidA_uidB`, то ('a', 'b:c') и ('a_b', 'c')
    // могли бы давать одинаковый результат. Length-prefix предотвращает.
    const a = buildSecretDirectConversationId('a', 'b:c');
    const b = buildSecretDirectConversationId('a:b', 'c');
    expect(a).not.toBe(b);
  });

  it('length-prefix защищает от collision с `_` в uid', () => {
    const a = buildSecretDirectConversationId('a', 'b_c');
    const b = buildSecretDirectConversationId('a_b', 'c');
    expect(a).not.toBe(b);
  });

  it('trim пробелов в uid (защита от leading/trailing space)', () => {
    expect(buildSecretDirectConversationId('  alice  ', 'bob')).toBe(
      buildSecretDirectConversationId('alice', 'bob'),
    );
  });

  it('тот же uid дважды → id с дублирующимся участником (self-chat)', () => {
    // Технически это "secret saved messages" сценарий. Функция должна
    // не падать.
    expect(() => buildSecretDirectConversationId('alice', 'alice')).not.toThrow();
    const r = buildSecretDirectConversationId('alice', 'alice');
    expect(r.startsWith('sdm_')).toBe(true);
  });

  it('детерминизм при повторных вызовах', () => {
    const a = buildSecretDirectConversationId('alice', 'bob');
    const b = buildSecretDirectConversationId('alice', 'bob');
    const c = buildSecretDirectConversationId('alice', 'bob');
    expect(a).toBe(b);
    expect(b).toBe(c);
  });
});
