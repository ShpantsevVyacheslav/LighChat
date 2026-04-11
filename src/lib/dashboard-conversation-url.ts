/** Query-параметр открытого чата на дашборде (совпадает с прежним `?conversationId=`). */
export const DASHBOARD_CONVERSATION_QUERY = 'conversationId';

/** После открытия чата — прокрутить и подсветить сообщение (список избранного и т.п.). */
export const DASHBOARD_FOCUS_MESSAGE_QUERY = 'focusMessageId';

/**
 * Ссылка на открытый чат с опциональным переходом к сообщению.
 */
export function buildDashboardChatOpenUrl(
  conversationId: string,
  options?: { focusMessageId?: string | null }
): string {
  const p = new URLSearchParams();
  p.set(DASHBOARD_CONVERSATION_QUERY, conversationId);
  if (options?.focusMessageId) {
    p.set(DASHBOARD_FOCUS_MESSAGE_QUERY, options.focusMessageId);
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
