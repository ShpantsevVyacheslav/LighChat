/**
 * Лимиты пагинации сообщений основного чата и веток.
 *
 * [audit M-002] INITIAL_MESSAGE_LIMIT снижен с 100 до 30: 100 reads на
 * каждый mount чата при 1k DAU × 5 чатов / сессия = 500k reads/день
 * (~$9/мес), линейно растёт с базой. 30 сообщений достаточно для первого
 * paint (Telegram/WhatsApp используют похожие значения), а
 * `HISTORY_PAGE_SIZE=50` уже даёт ленивую дозагрузку при scroll-up.
 */
export const INITIAL_MESSAGE_LIMIT = 30;
export const HISTORY_PAGE_SIZE = 50;
