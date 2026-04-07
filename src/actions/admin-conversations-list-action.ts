'use server';

import { adminDb } from '@/firebase/admin';
import { assertAdminByIdToken } from '@/actions/admin-actions';
import { interpretAdminAccessError } from '@/lib/admin-access-errors';

export type AdminConversationListItem = {
  id: string;
  name?: string;
  isGroup: boolean;
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
      return {
        id: d.id,
        name: typeof data.name === 'string' ? data.name : undefined,
        isGroup: Boolean(data.isGroup),
      };
    });
    conversations.sort((a, b) => (a.name || a.id).localeCompare(b.name || b.id, 'ru'));
    return { ok: true, conversations };
  } catch (e) {
    console.error('[listAdminConversationsAction]', e);
    return { ok: false, error: 'Не удалось загрузить список чатов' };
  }
}
