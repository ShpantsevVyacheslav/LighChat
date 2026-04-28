/** Query-параметр открытого чата на дашборде (совпадает с прежним `?conversationId=`). */
export const DASHBOARD_CONVERSATION_QUERY = 'conversationId';

/** После открытия чата — прокрутить и подсветить сообщение (список избранного и т.п.). */
export const DASHBOARD_FOCUS_MESSAGE_QUERY = 'focusMessageId';

/** Открыть ветку обсуждения корневого сообщения (список обсуждений / профиль чата). */
export const DASHBOARD_THREAD_ROOT_MESSAGE_QUERY = 'threadRootMessageId';

/** Программно открыть профиль в `ChatParticipantProfile` после загрузки чата. */
export const DASHBOARD_OPEN_PROFILE_QUERY = 'openProfile';
export const DASHBOARD_PROFILE_USER_QUERY = 'profileUserId';
export const DASHBOARD_PROFILE_SOURCE_QUERY = 'profileSource';

/** Открыть игру (лобби/экран) внутри чата. */
export const DASHBOARD_GAME_ID_QUERY = 'gameId';

export type DashboardChatProfileSource = 'contacts' | 'mention' | 'sender' | 'chat';

function normalizeDashboardProfileSource(
  raw: string | null | undefined
): DashboardChatProfileSource | null {
  if (raw === 'contacts' || raw === 'mention' || raw === 'sender' || raw === 'chat') return raw;
  return null;
}

/**
 * Ссылка на открытый чат с опциональным переходом к сообщению или открытием ветки.
 */
export function buildDashboardChatOpenUrl(
  conversationId: string,
  options?: {
    focusMessageId?: string | null;
    threadRootMessageId?: string | null;
    openProfile?: boolean;
    profileUserId?: string | null;
    profileSource?: DashboardChatProfileSource | null;
    gameId?: string | null;
  }
): string {
  const p = new URLSearchParams();
  p.set(DASHBOARD_CONVERSATION_QUERY, conversationId);
  if (options?.focusMessageId) {
    p.set(DASHBOARD_FOCUS_MESSAGE_QUERY, options.focusMessageId);
  }
  if (options?.threadRootMessageId) {
    p.set(DASHBOARD_THREAD_ROOT_MESSAGE_QUERY, options.threadRootMessageId);
  }
  if (options?.openProfile) {
    p.set(DASHBOARD_OPEN_PROFILE_QUERY, '1');
  }
  if (options?.profileUserId) {
    p.set(DASHBOARD_PROFILE_USER_QUERY, options.profileUserId);
  }
  const source = normalizeDashboardProfileSource(options?.profileSource ?? null);
  if (source) {
    p.set(DASHBOARD_PROFILE_SOURCE_QUERY, source);
  }
  if (options?.gameId) {
    p.set(DASHBOARD_GAME_ID_QUERY, options.gameId);
  }
  return `/dashboard/chat?${p.toString()}`;
}

/** Маршруты вида `/dashboard/chat/forward`, `/dashboard/chat/:id/delete` — левая колонка только `children`, без оверлея чата по query. */
export function isDashboardChatUtilityPath(pathname: string): boolean {
  return pathname.startsWith('/dashboard/chat/') && pathname !== '/dashboard/chat';
}

/**
 * Id открытого чата из query при текущем pathname (utility-маршруты дают null).
 */
export function getEffectiveDashboardConversationId(
  pathname: string,
  searchParams: Pick<URLSearchParams, 'get'>,
): string | null {
  const raw = searchParams.get(DASHBOARD_CONVERSATION_QUERY);
  if (isDashboardChatUtilityPath(pathname)) return null;
  return raw || null;
}

export function buildPathWithConversation(
  pathname: string,
  currentSearch: string,
  conversationId: string | null
): string {
  const p = new URLSearchParams(currentSearch || '');
  if (conversationId) {
    p.set(DASHBOARD_CONVERSATION_QUERY, conversationId);
  } else {
    p.delete(DASHBOARD_CONVERSATION_QUERY);
  }
  const q = p.toString();
  return q ? `${pathname}?${q}` : pathname;
}
