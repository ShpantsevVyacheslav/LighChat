import { describe, expect, it } from 'vitest';
import { resolveMentionLabelToUserId } from '@/lib/mention-resolve';
import type { Conversation, User, UserContactLocalProfile } from '@/lib/types';

/**
 * [audit M-013] Используется для старых сообщений без `data-user-id` атрибута:
 * при рендере reply-bar / mention pill матчит текст «@Имя» с реальным uid.
 * Регрессия → mention становится «битым» (некуда кликать), или резолвится
 * в чужой uid (когда два юзера с похожим именем).
 */

const ALICE: User = {
  id: 'alice', name: 'Алиса', username: 'alice',
  email: '', avatar: '', phone: '', deletedAt: null,
  createdAt: '2026-05-07T00:00:00.000Z',
};
const BOB: User = {
  id: 'bob', name: 'Боб', username: 'bob_handle',
  email: '', avatar: '', phone: '', deletedAt: null,
  createdAt: '2026-05-07T00:00:00.000Z',
};

const conv: Conversation = {
  id: 'g1',
  isGroup: true,
  adminIds: [],
  participantIds: ['alice', 'bob'],
  participantInfo: {},
};

describe('resolveMentionLabelToUserId', () => {
  it('@Имя → uid', () => {
    expect(resolveMentionLabelToUserId('@Алиса', conv, [ALICE, BOB])).toBe('alice');
  });

  it('case-insensitive имя', () => {
    expect(resolveMentionLabelToUserId('@алиса', conv, [ALICE, BOB])).toBe('alice');
    expect(resolveMentionLabelToUserId('@АЛИСА', conv, [ALICE, BOB])).toBe('alice');
  });

  it('без @ префикса тоже резолвится', () => {
    expect(resolveMentionLabelToUserId('Алиса', conv, [ALICE, BOB])).toBe('alice');
  });

  it('FULL-WIDTH ＠ нормализуется', () => {
    expect(resolveMentionLabelToUserId('＠Алиса', conv, [ALICE, BOB])).toBe('alice');
  });

  it('@username (без @) → uid', () => {
    expect(resolveMentionLabelToUserId('bob_handle', conv, [ALICE, BOB])).toBe('bob');
  });

  it('@username (с @) → uid', () => {
    expect(resolveMentionLabelToUserId('@bob_handle', conv, [ALICE, BOB])).toBe('bob');
  });

  it('contact alias приоритетнее настоящего имени', () => {
    const profiles: Record<string, UserContactLocalProfile> = {
      alice: { displayName: 'Босс', firstName: '', lastName: '' },
    };
    expect(
      resolveMentionLabelToUserId('@Босс', conv, [ALICE, BOB], profiles),
    ).toBe('alice');
  });

  it('contact alias не мешает резолвить настоящее имя (fallback)', () => {
    const profiles: Record<string, UserContactLocalProfile> = {
      alice: { displayName: 'Босс', firstName: '', lastName: '' },
    };
    expect(
      resolveMentionLabelToUserId('@Алиса', conv, [ALICE, BOB], profiles),
    ).toBe('alice');
  });

  it('label не совпадает ни с кем → null', () => {
    expect(resolveMentionLabelToUserId('@неизвестно', conv, [ALICE, BOB])).toBeNull();
  });

  it('пустой label → null', () => {
    expect(resolveMentionLabelToUserId('@', conv, [ALICE, BOB])).toBeNull();
    expect(resolveMentionLabelToUserId('', conv, [ALICE, BOB])).toBeNull();
    expect(resolveMentionLabelToUserId('   ', conv, [ALICE, BOB])).toBeNull();
  });

  it('user не в участниках чата → не резолвится', () => {
    const otherUser: User = { ...ALICE, id: 'other', name: 'Чужой' };
    expect(
      resolveMentionLabelToUserId('@Чужой', conv, [ALICE, BOB, otherUser]),
    ).toBeNull();
  });

  it('user в participantIds но не загружен в allUsers → null', () => {
    expect(
      resolveMentionLabelToUserId('@Алиса', conv, []),
    ).toBeNull();
  });

  it('trim вокруг label', () => {
    expect(
      resolveMentionLabelToUserId('@  Алиса  ', conv, [ALICE, BOB]),
    ).toBe('alice');
  });
});
