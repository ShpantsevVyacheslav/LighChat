import { format, parseISO, startOfDay } from 'date-fns';

/**
 * Парсит `createdAt` сообщения так же, как время в пузырьке ({@link MessageStatus}):
 * ISO-строка, Firestore Timestamp (`toDate()`), Date.
 */
export function parseChatMessageCreatedAt(createdAt: unknown): Date {
  if (!createdAt) return new Date();
  if (typeof createdAt === 'string') {
    try {
      const parsed = parseISO(createdAt);
      return Number.isNaN(parsed.getTime()) ? new Date(createdAt) : parsed;
    } catch {
      return new Date(createdAt);
    }
  }
  if (
    typeof createdAt === 'object' &&
    createdAt !== null &&
    'toDate' in createdAt &&
    typeof (createdAt as { toDate?: () => Date }).toDate === 'function'
  ) {
    return (createdAt as { toDate: () => Date }).toDate();
  }
  if (createdAt instanceof Date) return createdAt;
  const d = new Date(createdAt as string | number);
  return Number.isNaN(d.getTime()) ? new Date() : d;
}

/** Ключ календарного дня в локальной TZ для группировки ленты (yyyy-MM-dd). */
export function getMessageCalendarDayKey(createdAt: unknown): string {
  return format(startOfDay(parseChatMessageCreatedAt(createdAt)), 'yyyy-MM-dd');
}
