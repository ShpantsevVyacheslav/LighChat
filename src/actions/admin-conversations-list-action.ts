'use server';

import { adminDb } from '@/firebase/admin';
import { assertAdminByIdToken } from '@/actions/admin-actions';
import { interpretAdminAccessError } from '@/lib/admin-access-errors';
import { logger } from '@/lib/logger';

export type AdminConversationParticipant = {
  id: string;
  name: string;
};

export type AdminConversationListItem = {
  id: string;
  name?: string;
  isGroup: boolean;
  participantCount: number;
  /** До 4 участников с именами — для подписи в UI (личный чат -> имена обоих). */
  participants: AdminConversationParticipant[];
};

/**
 * Список диалогов для админ-панели (например выбор чатов во «Хранилище»).
 * Обходит ограничения клиентских list-запросов к `conversations` через Admin SDK.
 */
export async function listAdminConversationsAction(input: {
  idToken: string;
}): Promise<
  { ok: true; conversations: AdminConversationListItem[] } | { ok: false; error: string }
> {
  try {
    await assertAdminByIdToken(input.idToken);
  } catch (e) {
    return { ok: false, error: interpretAdminAccessError(e) };
  }

  try {
    const snap = await adminDb.collection('conversations').get();
    const conversations: AdminConversationListItem[] = snap.docs.map((d) => {
      const data = d.data();
      const isGroup = Boolean(data.isGroup);
      const participantIds = Array.isArray(data.participantIds)
        ? (data.participantIds as unknown[]).filter((x): x is string => typeof x === 'string')
        : [];
      const info = (data.participantInfo ?? {}) as Record<string, { name?: string }>;
      const seen = new Set<string>();
      const participants: AdminConversationParticipant[] = [];
      for (const pid of participantIds) {
        if (seen.has(pid)) continue;
        seen.add(pid);
        const name = info[pid]?.name?.trim();
        participants.push({ id: pid, name: name && name.length > 0 ? name : pid });
        if (participants.length >= 4) break;
      }
      return {
        id: d.id,
        name: typeof data.name === 'string' ? data.name : undefined,
        isGroup,
        participantCount: participantIds.length,
        participants,
      };
    });
    conversations.sort((a, b) => (a.name || a.id).localeCompare(b.name || b.id, 'ru'));
    return { ok: true, conversations };
  } catch (e) {
    logger.error('admin-conv', 'listAdminConversationsAction', e);
    return { ok: false, error: 'Не удалось загрузить список чатов' };
  }
}
