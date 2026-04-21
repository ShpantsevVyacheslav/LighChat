import {
  collection,
  arrayRemove,
  arrayUnion,
  doc,
  getDoc,
  getDocs,
  query,
  runTransaction,
  setDoc,
  where,
  type Firestore,
} from 'firebase/firestore';
import { participantInfoEntryForWrite } from '@/lib/conversation-participant-info-firestore';
import type { Conversation, User } from '@/lib/types';
import {
  isFirestorePermissionDeniedError,
  logFirestorePermissionDenied,
} from '@/lib/firestore-permission-debug';

/** Личный чат «Избранное»: один участник — текущий пользователь. */
export function isSavedMessagesChat(c: Pick<Conversation, 'isGroup' | 'participantIds'>, userId: string): boolean {
  return (
    !c.isGroup &&
    c.participantIds.length === 1 &&
    c.participantIds[0] === userId
  );
}

function buildSavedMessagesConversationId(userId: string): string {
  const uid = userId.trim();
  return `saved_${uid.length}:${uid}`;
}

/**
 * Гарантирует наличие чата «Избранное» и возвращает его id.
 * Индекс userChats дополняется триггером onConversationCreated.
 * Поиск существующего — через `userChats` + точечные getDoc,
 * с fallback-поиском по `conversations` на случай рассинхрона индекса.
 */
export async function ensureSavedMessagesChat(firestore: Firestore, user: User): Promise<string> {
  const canonicalId = buildSavedMessagesConversationId(user.id);
  const userChatsRef = doc(firestore, 'userChats', user.id);
  let indexSnap;
  try {
    indexSnap = await getDoc(userChatsRef);
  } catch (e) {
    if (isFirestorePermissionDeniedError(e)) {
      logFirestorePermissionDenied({
        source: 'ensureSavedMessagesChat',
        operation: 'getDoc userChats',
        path: userChatsRef.path,
        firestore,
        failedStep: 'getDoc userChats',
        extra: { userProfileId: user.id },
        error: e,
      });
    }
    throw e;
  }

  const ids =
    indexSnap.exists() ? ((indexSnap.data() as { conversationIds?: string[] }).conversationIds ?? []) : [];

  const savedCandidates: Array<{ id: string; ts: number }> = [];
  const seenCandidateIds = new Set<string>();
  const addCandidate = (id: string, ts: number) => {
    if (seenCandidateIds.has(id)) return;
    seenCandidateIds.add(id);
    savedCandidates.push({ id, ts: Number.isFinite(ts) ? ts : 0 });
  };

  let canonicalExists = false;
  for (const convId of ids) {
    const convRef = doc(firestore, 'conversations', convId);
    let d;
    try {
      d = await getDoc(convRef);
    } catch (e) {
      if (isFirestorePermissionDeniedError(e)) {
        logFirestorePermissionDenied({
          source: 'ensureSavedMessagesChat',
          operation: 'getDoc conversation',
          path: convRef.path,
          firestore,
          failedStep: 'getDoc conversations',
          extra: { userProfileId: user.id, convId },
          error: e,
        });
      }
      throw e;
    }
    if (!d.exists()) continue;
    const data = d.data() as Omit<Conversation, 'id'>;
    const p = data.participantIds || [];
    if (isSavedMessagesChat({ ...data, participantIds: p }, user.id)) {
      const ts = data.lastMessageTimestamp ? new Date(data.lastMessageTimestamp).getTime() : 0;
      addCandidate(d.id, ts);
      if (d.id === canonicalId) canonicalExists = true;
    }
  }

  // Fallback: userChats может быть неполным (миграции/ручные правки/гонки триггера).
  // Ищем существующий personal saved-чат напрямую в conversations.
  try {
    const q = query(
      collection(firestore, 'conversations'),
      where('participantIds', 'array-contains', user.id)
    );
    const snap = await getDocs(q);
    for (const d of snap.docs) {
      const data = d.data() as Omit<Conversation, 'id'>;
      const p = (data.participantIds || []).filter(Boolean);
      if (isSavedMessagesChat({ ...data, participantIds: p }, user.id)) {
        const ts = data.lastMessageTimestamp ? new Date(data.lastMessageTimestamp).getTime() : 0;
        addCandidate(d.id, ts);
        if (d.id === canonicalId) canonicalExists = true;
      }
    }
  } catch (e) {
    if (isFirestorePermissionDeniedError(e)) {
      logFirestorePermissionDenied({
        source: 'ensureSavedMessagesChat',
        operation: 'getDocs conversations by participantIds',
        path: 'conversations',
        firestore,
        failedStep: 'getDocs conversations fallback',
        extra: { userProfileId: user.id },
        error: e,
      });
    }
  }

  savedCandidates.sort((a, b) => b.ts - a.ts);
  const preferredExistingId = canonicalExists
    ? canonicalId
    : (savedCandidates[0]?.id ?? null);

  const newConversation: Omit<Conversation, 'id'> = {
    isGroup: false,
    name: 'Избранное',
    participantIds: [user.id],
    adminIds: [],
    participantInfo: {
      [user.id]: participantInfoEntryForWrite(user),
    },
    lastMessageTimestamp: new Date().toISOString(),
    lastMessageText: '',
    unreadCounts: { [user.id]: 0 },
    unreadThreadCounts: { [user.id]: 0 },
    typing: {},
  };

  let ensuredId = preferredExistingId;
  if (!ensuredId) {
    const canonicalRef = doc(firestore, 'conversations', canonicalId);
    try {
      await runTransaction(firestore, async (tx) => {
        const snap = await tx.get(canonicalRef);
        if (snap.exists()) return;
        tx.set(canonicalRef, newConversation);
      });
      ensuredId = canonicalId;
    } catch (e) {
      if (isFirestorePermissionDeniedError(e)) {
        logFirestorePermissionDenied({
          source: 'ensureSavedMessagesChat',
          operation: 'create (runTransaction)',
          path: canonicalRef.path,
          firestore,
          failedStep: 'runTransaction',
          extra: {
            participantIds: newConversation.participantIds,
            topLevelKeys: Object.keys(newConversation),
          },
          error: e,
        });
      }
      throw e;
    }
  }
  if (!ensuredId) {
    throw new Error('Failed to ensure saved messages chat');
  }

  // Подчищаем index: в списке чатов оставляем только один "Избранное".
  const duplicateIds = savedCandidates
    .map((c) => c.id)
    .filter((id) => id !== ensuredId);
  if (duplicateIds.length > 0) {
    try {
      await setDoc(
        userChatsRef,
        {
          conversationIds: arrayRemove(...duplicateIds),
        },
        { merge: true }
      );
    } catch {
      // Не блокируем открытие чата.
    }
  }
  try {
    await setDoc(
      userChatsRef,
      { conversationIds: arrayUnion(ensuredId) },
      { merge: true }
    );
  } catch {
    // Индекс также поддерживает backend-триггер.
  }

  return ensuredId;
}
