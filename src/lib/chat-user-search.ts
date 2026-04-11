import type { User } from '@/lib/types';
import { ruEnSubstringMatch } from '@/lib/ru-latin-search-normalize';

/** Строка «@login» для списков выбора собеседника или null, если логина нет. */
export function atUsernameLabel(username: string | undefined | null): string | null {
  const h = username?.trim().replace(/^@/, '');
  return h ? `@${h}` : null;
}

/** Совпадение по имени или @username (подстрока; кириллица ↔ латиница). */
export function userMatchesChatSearchQuery(user: User, query: string): boolean {
  const q = query.trim();
  if (!q) return true;
  if (user.name && ruEnSubstringMatch(user.name, q)) return true;
  const un = user.username?.trim().toLowerCase();
  if (un) {
    const needle = (q.startsWith('@') ? q.slice(1) : q).trim();
    if (needle && ruEnSubstringMatch(un, needle)) return true;
  }
  return false;
}

/**
 * Показывать ли пользователя в блоке глобального поиска (все пользователи, не контакты).
 * Не скрывает профиль у тех, кто уже добавил в контакты — см. список контактов.
 * Администраторы видят всех для модерации.
 */
export function isUserListedInGlobalChatSearch(viewer: User, candidate: User): boolean {
  if (viewer.role === 'admin') return true;
  return candidate.privacySettings?.showInGlobalUserSearch !== false;
}

export function sortUsersByNameRu(a: User, b: User): number {
  return a.name.localeCompare(b.name, 'ru', { sensitivity: 'base' });
}

/**
 * Разделяет уже отфильтрованных по политике чата пользователей: контакты выше, затем глобальный поиск с учётом privacy.
 */
export function splitUsersByContactsAndGlobalVisibility(
  matched: User[],
  viewer: User,
  contactIds: string[]
): { fromContacts: User[]; fromGlobal: User[] } {
  const set = new Set(contactIds);
  const fromContacts = matched.filter((u) => set.has(u.id)).sort(sortUsersByNameRu);
  const fromGlobal = matched
    .filter((u) => !set.has(u.id) && isUserListedInGlobalChatSearch(viewer, u))
    .sort(sortUsersByNameRu);
  return { fromContacts, fromGlobal };
}
