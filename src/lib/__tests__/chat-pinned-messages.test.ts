import { describe, expect, it } from 'vitest';
import {
  conversationPinnedList,
  sortPinnedMessagesByTime,
  pickPinnedBarIndexForViewport,
  MAX_PINNED_MESSAGES,
  type PinnedBarFlatRow,
} from '@/lib/chat-pinned-messages';
import type { ChatMessage, Conversation, PinnedMessage } from '@/lib/types';

/**
 * [audit M-013] Pinned messages — UX-критичная логика для chat-header bar.
 * Регрессия → закреп показывается невпопад / дубли / падает на legacy
 * полях (`pinnedMessage` vs новое `pinnedMessages[]`).
 */

function pin(id: string, extra: Partial<PinnedMessage> = {}): PinnedMessage {
  return {
    messageId: id,
    text: `Pinned ${id}`,
    senderId: 'u1',
    senderName: 'U',
    ...extra,
  } as PinnedMessage;
}

function conv(p: Partial<Conversation>): Conversation {
  return {
    id: 'c1',
    isGroup: false,
    adminIds: [],
    participantIds: ['u1'],
    participantInfo: {},
    ...p,
  };
}

describe('MAX_PINNED_MESSAGES', () => {
  it('константа = 20', () => {
    expect(MAX_PINNED_MESSAGES).toBe(20);
  });
});

describe('conversationPinnedList', () => {
  it('пустой массив для conversation без закрепов', () => {
    expect(conversationPinnedList(conv({}))).toEqual([]);
  });

  it('возвращает pinnedMessages[] если есть', () => {
    const r = conversationPinnedList(
      conv({ pinnedMessages: [pin('m1'), pin('m2')] }),
    );
    expect(r.map((p) => p.messageId)).toEqual(['m1', 'm2']);
  });

  it('дедуп по messageId, сохраняя порядок', () => {
    const r = conversationPinnedList(
      conv({ pinnedMessages: [pin('m1'), pin('m2'), pin('m1'), pin('m3')] }),
    );
    expect(r.map((p) => p.messageId)).toEqual(['m1', 'm2', 'm3']);
  });

  it('legacy `pinnedMessage` (одиночный) → массив с 1', () => {
    const r = conversationPinnedList(conv({ pinnedMessage: pin('legacy_x') }));
    expect(r.map((p) => p.messageId)).toEqual(['legacy_x']);
  });

  it('pinnedMessages[] приоритетнее legacy pinnedMessage', () => {
    const r = conversationPinnedList(
      conv({
        pinnedMessages: [pin('new1')],
        pinnedMessage: pin('legacy_x'),
      }),
    );
    expect(r.map((p) => p.messageId)).toEqual(['new1']);
  });

  it('пропускает закреп без messageId', () => {
    const broken = [{ ...pin('m1'), messageId: '' }, pin('m2')];
    const r = conversationPinnedList(
      conv({ pinnedMessages: broken as PinnedMessage[] }),
    );
    expect(r.map((p) => p.messageId)).toEqual(['m2']);
  });
});

describe('sortPinnedMessagesByTime', () => {
  it('сортирует по времени из messagesById (старые первыми)', () => {
    const pins = [pin('m1'), pin('m2'), pin('m3')];
    const msgsById = new Map<string, Pick<ChatMessage, 'createdAt'>>([
      ['m1', { createdAt: '2026-05-11T12:00:00.000Z' }],
      ['m2', { createdAt: '2026-05-11T10:00:00.000Z' }],
      ['m3', { createdAt: '2026-05-11T11:00:00.000Z' }],
    ]);
    const r = sortPinnedMessagesByTime(pins, msgsById);
    expect(r.map((p) => p.messageId)).toEqual(['m2', 'm3', 'm1']);
  });

  it('fallback на messageCreatedAt если в map нет', () => {
    const pins = [
      pin('m1', { messageCreatedAt: '2026-05-11T15:00:00.000Z' }),
      pin('m2', { messageCreatedAt: '2026-05-11T10:00:00.000Z' }),
    ];
    const r = sortPinnedMessagesByTime(pins, new Map());
    expect(r.map((p) => p.messageId)).toEqual(['m2', 'm1']);
  });

  it('не мутирует входной массив', () => {
    const pins = [pin('m1'), pin('m2')];
    const before = [...pins];
    sortPinnedMessagesByTime(pins, new Map());
    expect(pins).toEqual(before);
  });
});

describe('pickPinnedBarIndexForViewport', () => {
  const flat: PinnedBarFlatRow[] = [
    { type: 'message', message: { id: 'm0' } }, // idx 0
    { type: 'message', message: { id: 'm1' } }, // idx 1
    { type: 'date' },                            // idx 2 (non-message)
    { type: 'message', message: { id: 'm2' } }, // idx 3
    { type: 'message', message: { id: 'm3' } }, // idx 4
    { type: 'message', message: { id: 'm4' } }, // idx 5
    { type: 'message', message: { id: 'm5' } }, // idx 6
  ];

  it('пустой pinsSorted → 0', () => {
    expect(pickPinnedBarIndexForViewport([], flat, 0, 5)).toBe(0);
  });

  it('viewport покрывает все pins — выбирает первый в окне', () => {
    const pins = [pin('m1'), pin('m3'), pin('m4')];
    expect(pickPinnedBarIndexForViewport(pins, flat, 0, 6)).toBe(0); // m1 первый
  });

  it('есть закреп выше окна → самый ближайший сверху (макс idx среди older)', () => {
    const pins = [pin('m0'), pin('m1'), pin('m4')]; // m0,m1 idx<3; m4 idx>3
    // rangeStart=3 → strictlyOlder = m0(0), m1(1) → max idx = m1 (idx=1)
    expect(pickPinnedBarIndexForViewport(pins, flat, 3, 6)).toBe(1); // index в pinsSorted
  });

  it('окно ниже всех pins → самый старый (мин idx)', () => {
    const pins = [pin('m4'), pin('m5')]; // оба idx >=5
    expect(pickPinnedBarIndexForViewport(pins, flat, 0, 1)).toBe(0); // m4 (idx 5) минимум
  });

  it('закреп не в ленте (старый ушёл) → возвращает последний валидный', () => {
    const pins = [pin('m1'), pin('not_in_flat')];
    // m1 idx=1, not_in_flat idx=-1 (отфильтрован). withIdx=[m1].
    expect(pickPinnedBarIndexForViewport(pins, flat, 0, 6)).toBe(0);
  });

  it('все pins вне ленты → возвращает pinsSorted.length-1', () => {
    const pins = [pin('zzz1'), pin('zzz2')];
    expect(pickPinnedBarIndexForViewport(pins, flat, 0, 6)).toBe(1);
  });
});
