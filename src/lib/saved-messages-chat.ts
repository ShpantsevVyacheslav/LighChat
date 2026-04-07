import { collection, doc, getDoc, setDoc, type Firestore } from 'firebase/firestore';
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

/**
 * Гарантирует наличие чата «Избранное» и возвращает его id.
 * Индекс userChats дополняется триггером onConversationCreated.
 * Поиск существующего — через `userChats` + точечные getDoc (без list-query по conversations).
 */
export async function ensureSavedMessagesChat(firestore: Firestore, user: User): Promise<string> {
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
      return d.id;
    }
  }

  const newConvRef = doc(collection(firestore, 'conversations'));
  const newConversation: Omit<Conversation, 'id'> = {
    isGroup: false,
    name: 'Избранное',
    participantIds: [user.id],
    adminIds: [],
    participantInfo: {
      [user.id]: { name: user.name, avatar: user.avatar },
    },
    lastMessageTimestamp: new Date().toISOString(),
    lastMessageText: '',
    unreadCounts: { [user.id]: 0 },
    unreadThreadCounts: { [user.id]: 0 },
    typing: {},
  };

  try {
    await setDoc(newConvRef, newConversation);
  } catch (e) {
    if (isFirestorePermissionDeniedError(e)) {
      logFirestorePermissionDenied({
        source: 'ensureSavedMessagesChat',
        operation: 'create (setDoc)',
        path: newConvRef.path,
        firestore,
        failedStep: 'setDoc',
        extra: {
          participantIds: newConversation.participantIds,
          topLevelKeys: Object.keys(newConversation),
        },
        error: e,
      });
    }
    throw e;
  }
  return newConvRef.id;
}
