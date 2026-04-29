import type { User } from '@/lib/types';
import { ruEnSubstringMatch } from '@/lib/ru-latin-search-normalize';

/** Строка «@login» для списков выбора собеседника или null, если логина нет. */
export function atUsernameLabel(username: string | undefined | null): string | null {
  const h = username?.trim().replace(/^@/, '');
  return h ? `@${h}` : null;
}

/** Безопасное имя для списков пользователей: Firestore-документы после OAuth могут быть неполными. */
export function chatUserDisplayName(
  user: Pick<User, 'id' | 'name' | 'username' | 'email'>,
  displayNameOverride?: string | null
): string {
  const local = (displayNameOverride ?? '').trim();
  if (local) return local;
  const name = String(user.name ?? '').trim();
  if (name) return name;
  const username = String(user.username ?? '').trim().replace(/^@/, '');
  if (username) return `@${username}`;
  const email = String(user.email ?? '').trim();
  if (email) return email;
  const id = String(user.id ?? '').trim();
  return id ? `Пользователь ${id.slice(0, 6)}` : 'Пользователь';
}

export function chatUserInitial(displayName: string | null | undefined): string {
  return (String(displayName ?? '').trim() || '?').charAt(0).toUpperCase();
}

/** Совпадение по имени или @username (подстрока; кириллица ↔ латиница). */
export function userMatchesChatSearchQuery(
  user: User,
  query: string,
  displayNameOverride?: string | null
): boolean {
  const q = query.trim();
  if (!q) return true;
  const displayName = (displayNameOverride ?? '').trim();
  if (displayName && ruEnSubstringMatch(displayName, q)) return true;
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

function resolveUserSortName(
  user: User,
  displayNameById?: Record<string, string>
): string {
  return chatUserDisplayName(user, displayNameById?.[user.id]);
}

export function sortUsersByNameRu(
  a: User,
  b: User,
  displayNameById?: Record<string, string>
): number {
  const left = resolveUserSortName(a, displayNameById) || '';
  const right = resolveUserSortName(b, displayNameById) || '';
  return left.localeCompare(right, 'ru', { sensitivity: 'base' });
}

/**
 * Разделяет уже отфильтрованных по политике чата пользователей: контакты выше, затем глобальный поиск с учётом privacy.
 */
export function splitUsersByContactsAndGlobalVisibility(
  matched: User[],
  viewer: User,
  contactIds: string[],
  displayNameById?: Record<string, string>
): { fromContacts: User[]; fromGlobal: User[] } {
  const set = new Set(contactIds);
  const fromContacts = matched
    .filter((u) => set.has(u.id))
    .sort((a, b) => sortUsersByNameRu(a, b, displayNameById));
  const fromGlobal = matched
    .filter((u) => !set.has(u.id) && isUserListedInGlobalChatSearch(viewer, u))
    .sort((a, b) => sortUsersByNameRu(a, b, displayNameById));
  return { fromContacts, fromGlobal };
}
