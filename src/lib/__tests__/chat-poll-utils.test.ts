import { describe, expect, it } from 'vitest';
import {
  conversationMembersAsUsers,
  canModerateChatPoll,
} from '@/lib/chat-poll-utils';
import type { Conversation, MeetingPoll, User } from '@/lib/types';

/**
 * [audit M-013] Permission check для модерации опросов в чатах
 * (close poll, удалить опцию). Регрессия → unprivileged user может
 * закрыть чужой опрос в группе, или creator теряет доступ.
 */

const ALICE: User = {
  id: 'alice', name: 'Alice', username: 'alice',
  email: '', avatar: '', phone: '', deletedAt: null,
  createdAt: '2026-05-07T00:00:00.000Z',
};
const BOB: User = {
  id: 'bob', name: 'Bob', username: 'bob',
  email: '', avatar: '', phone: '', deletedAt: null,
  createdAt: '2026-05-07T00:00:00.000Z',
};

function makePoll(creatorId: string): MeetingPoll {
  return {
    id: 'p1',
    question: 'Q',
    options: ['A', 'B'],
    creatorId,
    status: 'active',
    isAnonymous: false,
    createdAt: '2026-05-11T10:00:00.000Z',
    votes: {},
  };
}

describe('conversationMembersAsUsers', () => {
  it('возвращает реальных User когда они в allUsers', () => {
    const conv: Conversation = {
      id: 'g1', isGroup: true, adminIds: [], participantIds: ['alice', 'bob'],
      participantInfo: { alice: { name: 'A' }, bob: { name: 'B' } },
    };
    const r = conversationMembersAsUsers(conv, [ALICE, BOB]);
    expect(r.map((u) => u.id).sort()).toEqual(['alice', 'bob']);
    expect(r.find((u) => u.id === 'alice')?.email).toBe(''); // настоящий ALICE
  });

  it('fallback на participantInfo для незагруженных uid', () => {
    const conv: Conversation = {
      id: 'g1', isGroup: true, adminIds: [], participantIds: ['alice', 'ghost'],
      participantInfo: {
        alice: { name: 'A' },
        ghost: { name: 'Призрак', avatar: 'http://gh' },
      },
    };
    const r = conversationMembersAsUsers(conv, [ALICE]);
    const ghost = r.find((u) => u.id === 'ghost');
    expect(ghost?.name).toBe('Призрак');
    expect(ghost?.avatar).toBe('http://gh');
    expect(ghost?.username).toBe('');
  });

  it('participantInfo без name → fallback на «Участник»', () => {
    const conv: Conversation = {
      id: 'g1', isGroup: true, adminIds: [], participantIds: ['unknown'],
      participantInfo: { unknown: { name: '' } },
    };
    const r = conversationMembersAsUsers(conv, []);
    expect(r[0].name).toBe('Участник');
  });
});

describe('canModerateChatPoll', () => {
  const dmConv: Conversation = {
    id: 'd1', isGroup: false, adminIds: ['alice'], participantIds: ['alice', 'bob'],
    participantInfo: {},
  };

  const groupConv: Conversation = {
    id: 'g1', isGroup: true, adminIds: ['alice'], createdByUserId: 'alice',
    participantIds: ['alice', 'bob', 'carol'], participantInfo: {},
  };

  it('creator опроса всегда может модерить', () => {
    expect(canModerateChatPoll(dmConv, 'alice', makePoll('alice'))).toBe(true);
    expect(canModerateChatPoll(groupConv, 'bob', makePoll('bob'))).toBe(true);
  });

  it('в DM только creator опроса может модерить', () => {
    // не-creator в DM не может, даже если он admin (DM не имеет адмиʔов)
    expect(canModerateChatPoll(dmConv, 'bob', makePoll('alice'))).toBe(false);
  });

  it('в группе creator чата может модерить чужой опрос', () => {
    expect(canModerateChatPoll(groupConv, 'alice', makePoll('bob'))).toBe(true);
  });

  it('в группе admin (adminIds) может модерить чужой опрос', () => {
    const conv = { ...groupConv, createdByUserId: 'someone_else', adminIds: ['carol'] };
    expect(canModerateChatPoll(conv, 'carol', makePoll('bob'))).toBe(true);
  });

  it('в группе обычный участник НЕ может модерить чужой опрос (PRIVILEGE-ESC guard)', () => {
    expect(canModerateChatPoll(groupConv, 'carol', makePoll('bob'))).toBe(false);
  });

  it('adminIds undefined в группе → только creator чата', () => {
    const conv = { ...groupConv, adminIds: undefined as unknown as string[] };
    expect(canModerateChatPoll(conv, 'bob', makePoll('alice'))).toBe(false);
    expect(canModerateChatPoll(conv, 'alice', makePoll('bob'))).toBe(true);
  });
});
