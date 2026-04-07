import type { Conversation, User } from '@/lib/types';

/**
 * Сопоставляет текст упоминания из HTML (например «@Иван Иванов») с участником чата.
 * Используется для старых сообщений без `data-user-id`.
 */
export function resolveMentionLabelToUserId(
  rawLabel: string,
  conversation: Conversation,
  allUsers: User[]
): string | null {
  const label = rawLabel.replace(/^[@＠]/u, '').trim();
  if (!label) return null;
  const norm = (s: string) => s.trim().toLowerCase();
  const l = norm(label);
  const ids = [...new Set(conversation.participantIds)];
  for (const id of ids) {
    const u = allUsers.find((x) => x.id === id);
    if (!u) continue;
    if (norm(u.name || '') === l) return u.id;
    if (u.username && norm(u.username) === l) return u.id;
    if (u.username && norm(`@${u.username}`) === l) return u.id;
  }
  return null;
}
