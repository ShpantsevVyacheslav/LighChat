import type { Firestore } from 'firebase/firestore';
import { collection, doc, getDoc, setDoc } from 'firebase/firestore';
import { participantInfoEntryForWrite } from '@/lib/conversation-participant-info-firestore';
import type { User, Conversation } from '@/lib/types';

/**
 * Найти существующий личный чат с пользователем или создать новый.
 * Индексы userChats обновляет Cloud Function onConversationCreated.
 * Поиск — через `userChats` + точечные getDoc (без list-query по conversations).
 */
export async function createOrOpenDirectChat(
  firestore: Firestore,
  currentUser: User,
  otherUser: User
): Promise<string> {
  const userChatsRef = doc(firestore, 'userChats', currentUser.id);
  const indexSnap = await getDoc(userChatsRef);
  const ids = indexSnap.exists()
    ? ((indexSnap.data() as { conversationIds?: string[] }).conversationIds ?? [])
    : [];

  for (const convId of ids) {
    const d = await getDoc(doc(firestore, 'conversations', convId));
    if (!d.exists()) continue;
    const data = d.data() as Conversation;
    const p = data.participantIds || [];
    if (
      !data.isGroup &&
      p.length === 2 &&
      p.includes(otherUser.id) &&
      p.includes(currentUser.id)
    ) {
      return d.id;
    }
  }

  const newConvRef = doc(collection(firestore, 'conversations'));
  const newConversation: Omit<Conversation, 'id'> = {
    isGroup: false,
    participantIds: [currentUser.id, otherUser.id],
    adminIds: [],
    participantInfo: {
      [currentUser.id]: participantInfoEntryForWrite(currentUser),
      [otherUser.id]: participantInfoEntryForWrite(otherUser),
    },
    lastMessageTimestamp: new Date().toISOString(),
    lastMessageText: 'Чат создан',
    unreadCounts: { [currentUser.id]: 0, [otherUser.id]: 0 },
    unreadThreadCounts: { [currentUser.id]: 0, [otherUser.id]: 0 },
    typing: {},
  };
  await setDoc(newConvRef, newConversation);
  return newConvRef.id;
}
