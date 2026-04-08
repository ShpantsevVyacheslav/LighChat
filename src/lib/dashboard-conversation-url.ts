/** Query-параметр открытого чата на дашборде (совпадает с прежним `?conversationId=`). */
export const DASHBOARD_CONVERSATION_QUERY = 'conversationId';

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
