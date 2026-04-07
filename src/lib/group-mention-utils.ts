import type { Conversation, User } from '@/lib/types';

/** Участник группы для подбора @ и разбора текста сообщения. */
export type GroupMentionCandidate = {
  id: string;
  name: string;
  username: string;
  avatar?: string;
};

function escapeRegExp(s: string): string {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

/**
 * Собирает кандидатов для @ в группе (как в поле ввода): живые User + participantInfo.
 */
export function buildGroupMentionCandidates(
  conversation: Conversation,
  allUsers: User[],
  currentUserId: string
): GroupMentionCandidate[] {
  if (!conversation.isGroup) return [];
  const ids = [...new Set(conversation.participantIds)];
  const out: GroupMentionCandidate[] = [];
  for (const id of ids) {
    if (id === currentUserId) continue;
    const u = allUsers.find((x) => x.id === id);
    if (u && !u.deletedAt) {
      out.push({ id: u.id, name: u.name || '', username: u.username || '', avatar: u.avatar || '' });
      continue;
    }
    const info = conversation.participantInfo[id];
    if (!info?.name) continue;
    out.push({ id, name: info.name, username: '', avatar: info.avatar || '' });
  }
  return out;
}

/**
 * По plain-тексту сообщения (без HTML) находит id участников, чьи имена или @username
 * встречаются как @метка. Длинные имена проверяются раньше, чтобы не путать «Иван» и «Иван Петров».
 */
export function extractMentionedUserIdsFromPlainText(
  plainText: string,
  candidates: GroupMentionCandidate[],
  senderId: string
): string[] {
  const found = new Set<string>();
  const usedRanges: [number, number][] = [];

  const overlaps = (from: number, to: number) =>
    usedRanges.some(([s, e]) => !(to <= s || from >= e));

  const markRange = (from: number, to: number) => {
    usedRanges.push([from, to]);
  };

  const tryName = (rawName: string, userId: string) => {
    const name = rawName.trim();
    if (!name || userId === senderId) return;
    const re = new RegExp(`@${escapeRegExp(name)}(?=\\s|$|[\\n.,!?;:])`, 'gu');
    let m: RegExpExecArray | null;
    while ((m = re.exec(plainText)) !== null) {
      const from = m.index;
      const to = from + m[0].length;
      if (!overlaps(from, to)) {
        found.add(userId);
        markRange(from, to);
      }
    }
  };

  const byName = [...candidates]
    .filter((c) => c.id !== senderId && c.name.trim())
    .sort((a, b) => b.name.trim().length - a.name.trim().length);

  for (const c of byName) {
    tryName(c.name, c.id);
  }

  const byUsername = [...candidates]
    .filter((c) => c.id !== senderId && (c.username || '').trim())
    .sort((a, b) => (b.username || '').length - (a.username || '').length);

  for (const c of byUsername) {
    const un = (c.username || '').trim();
    tryName(un, c.id);
  }

  return Array.from(found);
}
