import type { Conversation } from '@/lib/types';

/**
 * Поля для updateDoc при исключении участника из группы (клиент).
 * Не удаляет создателя — вызывающий код должен проверить.
 */
export function buildGroupMemberRemovalUpdate(
  conv: Conversation,
  memberId: string
): Record<string, unknown> {
  if (memberId === conv.createdByUserId) {
    throw new Error('cannot_remove_creator');
  }
  const participantIds = conv.participantIds.filter((id) => id !== memberId);
  const participantInfo = { ...conv.participantInfo };
  delete participantInfo[memberId];
  const adminIds = (conv.adminIds || []).filter((id) => id !== memberId);
  const unreadCounts = { ...(conv.unreadCounts || {}) };
  delete unreadCounts[memberId];
  const unreadThreadCounts = { ...(conv.unreadThreadCounts || {}) };
  delete unreadThreadCounts[memberId];
  const typing = { ...(conv.typing || {}) };
  delete typing[memberId];

  const out: Record<string, unknown> = {
    participantIds,
    participantInfo,
    adminIds,
    unreadCounts,
    unreadThreadCounts,
    typing,
  };
  if (conv.e2eeEnabled) {
    out.e2eeKeyEpoch = (conv.e2eeKeyEpoch ?? 0) + 1;
  }
  return out;
}

/** Админы в UI: создатель + записанные в adminIds. */
export function effectiveGroupAdminIds(conv: Conversation): Set<string> {
  const s = new Set<string>(conv.adminIds || []);
  if (conv.createdByUserId) s.add(conv.createdByUserId);
  return s;
}

/** Список adminIds для записи в Firestore (создатель не дублируется). */
export function adminIdsForFirestoreWrite(conv: Conversation, adminSet: Set<string>): string[] {
  const c = conv.createdByUserId;
  return [...adminSet].filter((id) => id !== c);
}
