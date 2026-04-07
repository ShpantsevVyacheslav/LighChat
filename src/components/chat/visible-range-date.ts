import { format, parseISO, startOfDay } from 'date-fns';

/** Элементы плоского списка чата/ветки, несущие календарный день. */
export type FlatItemForDateAnchor =
  | { type: 'date'; date: string }
  | { type: 'message'; message: { createdAt: string } }
  | { type: 'unread-separator' }
  | { type: 'parent' };

function clampVisibleIndex(index: number, len: number): number {
  if (len <= 0) return 0;
  return Math.max(0, Math.min(index, len - 1));
}

function calendarDayFromFlatItem(
  item: FlatItemForDateAnchor,
  options?: { parentCreatedAt?: string }
): string | null {
  if (item.type === 'unread-separator') return null;
  if (item.type === 'date') return item.date;
  if (item.type === 'message') {
    return format(startOfDay(parseISO(item.message.createdAt)), 'yyyy-MM-dd');
  }
  if (item.type === 'parent' && options?.parentCreatedAt) {
    return format(startOfDay(parseISO(options.parentCreatedAt)), 'yyyy-MM-dd');
  }
  return null;
}

/**
 * Календарный день для плавающей подписи у верха viewport.
 *
 * Среди **видимых** индексов сначала берётся самое верхнее (минимальный индекс)
 * **сообщение** — его локальный день совпадает с пузырьками над разделителем.
 * Строка `type: 'date'` — это заголовок блока *ниже* себя; если брать её первой,
 * при одновременно видимых вчерашних сообщениях и теге «сегодня» подпись ошибочно
 * показывала бы «сегодня». Если в диапазоне нет сообщений — используем первую
 * видимую строку `date` / `parent`, затем шаг назад по списку.
 */
export function firstCalendarDayInViewport(
  items: FlatItemForDateAnchor[],
  startIndex: number,
  endIndex: number,
  options?: { parentCreatedAt?: string }
): string | null {
  const len = items.length;
  if (len === 0) return null;
  const start = clampVisibleIndex(startIndex, len);
  const end = clampVisibleIndex(endIndex, len);
  if (start > end) return null;

  let topMessageDay: string | null = null;
  let topMessageIndex = Infinity;
  for (let i = start; i <= end; i++) {
    const item = items[i];
    if (item.type !== 'message') continue;
    const d = calendarDayFromFlatItem(item, options);
    if (d !== null && i < topMessageIndex) {
      topMessageIndex = i;
      topMessageDay = d;
    }
  }
  if (topMessageDay !== null) {
    return topMessageDay;
  }

  for (let i = start; i <= end; i++) {
    const item = items[i];
    if (item.type === 'date') {
      return item.date;
    }
    if (item.type === 'parent') {
      const d = calendarDayFromFlatItem(item, options);
      if (d) return d;
    }
  }

  for (let i = start - 1; i >= 0; i--) {
    const d = calendarDayFromFlatItem(items[i], options);
    if (d) return d;
  }
  return null;
}

/**
 * Самая поздняя календарная дата среди видимых элементов (локальный день).
 * Не использовать для плавающей подписи даты при скролле — для этого {@link firstCalendarDayInViewport}.
 */
export function newestCalendarDayInVisibleItems(
  visibleItems: FlatItemForDateAnchor[],
  options?: { parentCreatedAt?: string }
): string | null {
  let newest: Date | null = null;
  const bump = (iso: string) => {
    if (!iso) return;
    const day = startOfDay(parseISO(iso));
    if (!newest || day.getTime() > newest.getTime()) newest = day;
  };
  for (const item of visibleItems) {
    if (item.type === 'message') bump(item.message.createdAt);
    else if (item.type === 'date') bump(item.date);
    else if (item.type === 'parent' && options?.parentCreatedAt) bump(options.parentCreatedAt);
  }
  return newest ? format(newest, 'yyyy-MM-dd') : null;
}
