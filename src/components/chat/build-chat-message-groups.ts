import type { ChatMessage } from '@/lib/types';
import { getMessageCalendarDayKey } from '@/lib/message-calendar-day';

/** Строка виртуального списка основного чата (плоский {@link Virtuoso}). */
export type ChatListRow =
  | { type: 'date'; dateKey: string; dayStickyOrder: number }
  | { type: 'unread-separator' }
  | { type: 'message'; message: ChatMessage };

/**
 * Строит плоский список для Virtuoso: перед первым сообщением каждого календарного дня — строка `date`
 * (липкий заголовок через {@link ChatDateSeparatorRow}), затем сообщения и при необходимости разделитель непрочитанного.
 * Одна система индексов с `rangeChanged` — без отдельных «виртуальных» строк группы, как у GroupedVirtuoso.
 */
export function buildChatListRows(
  messagesForList: ChatMessage[],
  unreadSeparatorId: string | null
): ChatListRow[] {
  const rows: ChatListRow[] = [];
  let lastDate = '';
  let dayStickyOrder = 0;

  for (const msg of messagesForList) {
    const dateKey = getMessageCalendarDayKey(msg.createdAt);
    if (dateKey !== lastDate) {
      rows.push({ type: 'date', dateKey, dayStickyOrder });
      dayStickyOrder += 1;
      lastDate = dateKey;
    }
    if (msg.id === unreadSeparatorId) {
      rows.push({ type: 'unread-separator' });
    }
    rows.push({ type: 'message', message: msg });
  }

  return rows;
}
