/**
 * Общие классы «стекла» для чата (шапка, опрос и т.п.).
 * Согласованы с подложкой имени в `ChatWindow`.
 */
export const CHAT_GLASS_PANEL =
  'rounded-2xl bg-background/32 dark:bg-background/24 backdrop-blur-md shadow-sm';

/**
 * Подложка полосы шапки чата под статус-бар (safe-area padding не оставляет «дырку» с обоями).
 */
export const CHAT_HEADER_SAFE_AREA_STRIP =
  'border-b border-black/10 dark:border-white/10 bg-gradient-to-b from-black/50 via-black/25 to-transparent dark:from-black/60 dark:via-black/35 backdrop-blur-md';

/**
 * Тот же уровень непрозрачности и blur, что у списка @-упоминаний (`GroupMentionSuggestions`).
 * Используется для опросов в ленте, чтобы карточка не «просвечивала» сильнее подсказки.
 */
export const CHAT_GLASS_MENTION_LIST =
  'rounded-2xl border border-white/30 dark:border-white/15 bg-background/50 dark:bg-background/40 backdrop-blur-xl backdrop-saturate-150 shadow-[0_12px_40px_-8px_rgba(0,0,0,0.25)] dark:shadow-[0_12px_48px_-8px_rgba(0,0,0,0.65)] ring-1 ring-black/5 dark:ring-white/10';

/**
 * Левая колонка списка чатов на дашборде (`DashboardChatListColumn`): тот же стеклянный язык, что и в `ChatWindow`.
 */
export const CHAT_SIDEBAR_SHELL =
  'border-r border-black/10 bg-background/30 backdrop-blur-xl dark:border-white/10 dark:bg-background/22';

/** Узкая рейка папок слева внутри сайдбара. */
export const CHAT_SIDEBAR_RAIL_GLASS = 'bg-background/16 dark:bg-background/10 backdrop-blur-md';
