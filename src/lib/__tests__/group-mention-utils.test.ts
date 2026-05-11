import { describe, expect, it } from 'vitest';
import {
  buildGroupMentionCandidates,
  extractMentionedUserIdsFromPlainText,
  type GroupMentionCandidate,
} from '@/lib/group-mention-utils';
import type { Conversation, User } from '@/lib/types';

/**
 * [audit M-013] @mention parser — security-критическая логика: результат
 * напрямую попадает в `usersWithPendingGroupMention` Firestore-поле и
 * триггерит push-уведомления. Регрессия → ложные / пропущенные нотификации
 * целым группам. Также `extractMentionedUserIdsFromPlainText` принимает
 * user-controlled `name`, который попадает в `new RegExp(...)` — должна
 * быть защита от regex injection (см. `escapeRegExp`).
 */

const ALICE: User = {
  id: 'alice',
  name: 'Алиса',
  username: 'alice',
  email: '', avatar: '', phone: '', deletedAt: null,
  createdAt: '2026-05-07T00:00:00.000Z',
};
const BOB: User = {
  id: 'bob',
  name: 'Боб',
  username: 'bob',
  email: '', avatar: '', phone: '', deletedAt: null,
  createdAt: '2026-05-07T00:00:00.000Z',
};
const CAROL: User = {
  id: 'carol',
  name: 'Кэрол Иванова',  // длинное имя — должно матчиться раньше «Кэрол»
  username: 'carol',
  email: '', avatar: '', phone: '', deletedAt: null,
  createdAt: '2026-05-07T00:00:00.000Z',
};
const DELETED: User = {
  ...ALICE,
  id: 'deleted',
  name: 'Удалённый',
  username: 'deleted',
  deletedAt: '2026-01-01T00:00:00.000Z',
};

function groupConv(participantIds: string[]): Conversation {
  return {
    id: 'g1',
    isGroup: true,
    adminIds: ['alice'],
    participantIds,
    participantInfo: Object.fromEntries(
      participantIds.map((id) => [id, { name: id }]),
    ),
  };
}

describe('buildGroupMentionCandidates', () => {
  it('возвращает [] для не-группы (DM)', () => {
    const dm: Conversation = {
      id: 'd1',
      isGroup: false,
      adminIds: ['alice'],
      participantIds: ['alice', 'bob'],
      participantInfo: { alice: { name: 'Alice' }, bob: { name: 'Bob' } },
    };
    expect(buildGroupMentionCandidates(dm, [ALICE, BOB], 'alice')).toEqual([]);
  });

  it('исключает currentUser (нельзя упомянуть себя)', () => {
    const conv = groupConv(['alice', 'bob']);
    const r = buildGroupMentionCandidates(conv, [ALICE, BOB], 'alice');
    expect(r.map((c) => c.id)).toEqual(['bob']);
  });

  it('deletedAt user → fallback на participantInfo (не исчезает из mention-списка)', () => {
    // Это сознательно: «удалённый аккаунт» лучше показать с placeholder именем,
    // чем спрятать из списка и сбить unread-counter / mention-парсер.
    const conv = groupConv(['alice', 'bob', 'deleted']);
    const r = buildGroupMentionCandidates(conv, [ALICE, BOB, DELETED], 'alice');
    expect(r.map((c) => c.id).sort()).toEqual(['bob', 'deleted']);
    const del = r.find((c) => c.id === 'deleted');
    expect(del?.username).toBe(''); // participantInfo не содержит username
  });

  it('fallback на participantInfo если User не загружен', () => {
    const conv = groupConv(['alice', 'unknown_uid']);
    const r = buildGroupMentionCandidates(conv, [ALICE], 'alice');
    expect(r.map((c) => c.id)).toEqual(['unknown_uid']);
    expect(r[0].name).toBe('unknown_uid'); // из participantInfo
  });

  it('пропускает участника без name (broken participantInfo)', () => {
    const conv: Conversation = {
      ...groupConv(['alice', 'broken']),
      participantInfo: { alice: { name: 'Alice' }, broken: { name: '' } },
    };
    const r = buildGroupMentionCandidates(conv, [ALICE], 'alice');
    expect(r.map((c) => c.id)).toEqual([]);
  });
});

describe('extractMentionedUserIdsFromPlainText', () => {
  const candidates: GroupMentionCandidate[] = [
    { id: 'alice', name: 'Алиса', username: 'alice' },
    { id: 'bob', name: 'Боб', username: 'bob' },
    { id: 'carol', name: 'Кэрол Иванова', username: 'carol' },
  ];

  it('простой @name матч', () => {
    expect(
      extractMentionedUserIdsFromPlainText('Привет @Алиса!', candidates, 'sender_x'),
    ).toEqual(['alice']);
  });

  it('@username тоже матчится', () => {
    expect(
      extractMentionedUserIdsFromPlainText('Глянь @bob', candidates, 'sender_x'),
    ).toEqual(['bob']);
  });

  it('sender себя не упоминает (anti-self-notify)', () => {
    expect(
      extractMentionedUserIdsFromPlainText('@Алиса меня позвала', candidates, 'alice'),
    ).toEqual([]);
  });

  it('длинное имя матчится раньше короткого префикса', () => {
    // Если бы @Кэрол совпадало первым, оно бы заняло range и @Кэрол Иванова
    // не нашлось бы. Тест что приоритет длинное → короткое работает.
    const ext: GroupMentionCandidate[] = [
      ...candidates,
      { id: 'short_carol', name: 'Кэрол', username: 'shortcarol' },
    ];
    const r = extractMentionedUserIdsFromPlainText(
      'Привет @Кэрол Иванова',
      ext,
      'sender_x',
    );
    expect(r).toEqual(['carol']);
    expect(r).not.toContain('short_carol');
  });

  it('boundary check: @алисабобик не матчит «Алиса»', () => {
    // Sufficient: после @имя должен быть пробел/конец/пунктуация
    const r = extractMentionedUserIdsFromPlainText('@алисабобик мяу', candidates, 's');
    expect(r).not.toContain('alice');
  });

  it('@name с пунктуацией после — матчится', () => {
    expect(
      extractMentionedUserIdsFromPlainText('@Алиса, привет!', candidates, 's'),
    ).toEqual(['alice']);
  });

  it('несколько @mention в одном тексте', () => {
    const r = extractMentionedUserIdsFromPlainText(
      'Привет @Алиса и @Боб',
      candidates,
      'sender_x',
    );
    expect(r.sort()).toEqual(['alice', 'bob']);
  });

  it('дубль @Алиса не дублирует id в результате (Set)', () => {
    expect(
      extractMentionedUserIdsFromPlainText('@Алиса @Алиса', candidates, 's'),
    ).toEqual(['alice']);
  });

  it('SECURITY: regex-meta в имени не валит парсер', () => {
    // Если имя содержит .*+, escapeRegExp должен экранировать.
    const dangerous: GroupMentionCandidate[] = [
      { id: 'evil', name: '.*', username: 'evil' },
    ];
    expect(() =>
      extractMentionedUserIdsFromPlainText('тест @.* xx', dangerous, 'sender_x'),
    ).not.toThrow();
    // И не должно ложно матчить любой @ + один символ:
    const r = extractMentionedUserIdsFromPlainText('@ab', dangerous, 'sender_x');
    expect(r).toEqual([]);
  });

  it('SECURITY: ReDoS-vector — длинный текст с повторяющимся @ не вешает', () => {
    const veryLong = '@'.repeat(10_000);
    const t0 = Date.now();
    extractMentionedUserIdsFromPlainText(veryLong, candidates, 's');
    expect(Date.now() - t0).toBeLessThan(500); // должно быть мгновенно
  });

  it('пустой текст — []', () => {
    expect(extractMentionedUserIdsFromPlainText('', candidates, 's')).toEqual([]);
  });

  it('кандидаты с пустым name пропускаются', () => {
    const partial: GroupMentionCandidate[] = [
      { id: 'noname', name: '', username: '' },
      { id: 'alice', name: 'Алиса', username: 'alice' },
    ];
    expect(
      extractMentionedUserIdsFromPlainText('@Алиса', partial, 's'),
    ).toEqual(['alice']);
  });
});
