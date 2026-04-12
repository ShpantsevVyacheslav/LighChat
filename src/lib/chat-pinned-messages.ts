import type { ChatMessage, Conversation, PinnedMessage } from '@/lib/types';
import { parseChatMessageCreatedAt } from '@/lib/message-calendar-day';

export const MAX_PINNED_MESSAGES = 20;

/** Минимальный тип строки ленты для привязки закрепа к индексу Virtuoso. */
export type PinnedBarFlatRow = { type: string; message?: { id: string } };

/**
 * Актуальный список закрепов: массив `pinnedMessages` или устаревшее поле `pinnedMessage`.
 */
export function conversationPinnedList(conv: Conversation): PinnedMessage[] {
  const arr = conv.pinnedMessages;
  if (Array.isArray(arr) && arr.length > 0) {
    return dedupePinsPreserveOrder(arr);
  }
  if (conv.pinnedMessage?.messageId) {
    return [{ ...conv.pinnedMessage }];
  }
  return [];
}

function dedupePinsPreserveOrder(pins: PinnedMessage[]): PinnedMessage[] {
  const seen = new Set<string>();
  const out: PinnedMessage[] = [];
  for (const p of pins) {
    if (!p?.messageId || seen.has(p.messageId)) continue;
    seen.add(p.messageId);
    out.push(p);
  }
  return out;
}

/** Миллисекунды для сортировки; `createdAt` может быть ISO-строкой или Firestore Timestamp с мобильных клиентов. */
function pinnedSortTimeMs(createdAt: unknown): number {
  if (createdAt === '' || createdAt == null) return 0;
  const d = parseChatMessageCreatedAt(createdAt);
  const t = d.getTime();
  return Number.isNaN(t) ? 0 : t;
}

/** Порядок по времени сообщения (старые первыми — вверху истории). */
export function sortPinnedMessagesByTime(
  pins: PinnedMessage[],
  messagesById: Map<string, Pick<ChatMessage, 'createdAt'>>
): PinnedMessage[] {
  return [...pins].sort((a, b) => {
    const ta = messagesById.get(a.messageId)?.createdAt ?? a.messageCreatedAt ?? '';
    const tb = messagesById.get(b.messageId)?.createdAt ?? b.messageCreatedAt ?? '';
    return pinnedSortTimeMs(ta) - pinnedSortTimeMs(tb);
  });
}

/**
 * Какой закреп показывать в шапке: только в сторону **более старых** сообщений (индекс в ленте меньше =
 * выше в Virtuoso при chronology oldest→newest).
 *
 * 1) Есть закрепы строго **выше** окна (`idx < rangeStart`) — берём **следующий** к верху экрана при
 *    прокрутке к старым: максимальный `idx` среди них (не «ближайший снизу окна», не закреп внутри).
 * 2) Иначе среди закрепов **в** окне — самый «верхний» (минимальный `idx`): следующий к более старому внутри окна.
 * 3) Иначе все закрепы ниже окна — показываем самый старый закреп в загруженной ленте (минимальный `idx`).
 *
 * Возвращает индекс в `pinsSorted`.
 */
export function pickPinnedBarIndexForViewport(
  pinsSorted: PinnedMessage[],
  flatItems: readonly PinnedBarFlatRow[],
  rangeStart: number,
  rangeEnd: number
): number {
  if (pinsSorted.length === 0) return 0;

  const indexInFlat = (msgId: string) =>
    flatItems.findIndex((it) => it.type === 'message' && it.message?.id === msgId);

  const withIdx = pinsSorted
    .map((p, i) => ({ i, idx: indexInFlat(p.messageId) }))
    .filter((x) => x.idx !== -1);

  if (!withIdx.length) return pinsSorted.length - 1;

  const strictlyOlderThanTop = withIdx.filter((x) => x.idx < rangeStart);
  if (strictlyOlderThanTop.length) {
    return strictlyOlderThanTop.reduce((a, b) => (a.idx > b.idx ? a : b)).i;
  }

  const inView = withIdx.filter((x) => x.idx >= rangeStart && x.idx <= rangeEnd);
  if (inView.length) {
    return inView.reduce((a, b) => (a.idx < b.idx ? a : b)).i;
  }

  return withIdx.reduce((a, b) => (a.idx < b.idx ? a : b)).i;
}
