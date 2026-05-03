import type { Firestore } from 'firebase/firestore';
import {
  arrayUnion,
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  runTransaction,
  setDoc,
  where,
} from 'firebase/firestore';
import { participantInfoEntryForWrite } from '@/lib/conversation-participant-info-firestore';
import type { User, Conversation } from '@/lib/types';
import {
  isFirestorePermissionDeniedError,
  logFirestorePermissionDenied,
} from '@/lib/firestore-permission-debug';

function isFirestoreInternalError(error: unknown): boolean {
  return (
    typeof error === 'object' &&
    error !== null &&
    'code' in error &&
    (error as { code: string }).code === 'internal'
  );
}

function buildDirectChatId(a: string, b: string): string {
  const ids = [a.trim(), b.trim()].sort();
  const part = (v: string) => `${v.length}:${v}`;
  return `dm_${part(ids[0])}_${part(ids[1])}`;
}

function isDirectConversationForPair(
  data: Conversation | undefined,
  currentUserId: string,
  otherUserId: string
): boolean {
  if (!data || data.isGroup) return false;
  const p = data.participantIds || [];
  return p.length === 2 && p.includes(currentUserId) && p.includes(otherUserId);
}

/**
 * Найти существующий личный чат с пользователем или создать новый.
 * Гарантия уникальности: conversationId детерминирован по паре uid.
 */
export async function createOrOpenDirectChat(
  firestore: Firestore,
  currentUser: User,
  otherUser: User
): Promise<string> {
  if (!currentUser.id?.trim() || !otherUser.id?.trim()) {
    throw new Error('createOrOpenDirectChat requires non-empty user ids');
  }
  if (currentUser.id === otherUser.id) {
    throw new Error('createOrOpenDirectChat requires distinct users');
  }

  const canonicalId = buildDirectChatId(currentUser.id, otherUser.id);
  const canonicalRef = doc(firestore, 'conversations', canonicalId);
  let canonicalSnap: Awaited<ReturnType<typeof getDoc>> | null = null;
  try {
    canonicalSnap = await getDoc(canonicalRef);
  } catch (e) {
    if (isFirestorePermissionDeniedError(e)) {
      logFirestorePermissionDenied({
        source: 'createOrOpenDirectChat',
        operation: 'getDoc canonical',
        path: canonicalRef.path,
        firestore,
        failedStep: 'getDoc canonical',
        extra: { currentUserId: currentUser.id, otherUserId: otherUser.id, canonicalId },
        error: e,
      });
    }
    // В полевых условиях иногда приходит FirestoreError(code=internal) на чтении
    // отсутствующего canonical-документа. Не блокируем — попробуем найти/создать чат ниже.
    if (!isFirestoreInternalError(e)) throw e;
    console.warn('[createOrOpenDirectChat] canonical getDoc internal, continue with fallback path', {
      canonicalId,
      currentUserId: currentUser.id,
      otherUserId: otherUser.id,
      error: e,
    });
  }
  if (
    canonicalSnap &&
    canonicalSnap.exists() &&
    isDirectConversationForPair(
      canonicalSnap.data() as Conversation,
      currentUser.id,
      otherUser.id
    )
  ) {
    return canonicalId;
  }

  // Fallback для legacy-чатов с произвольным id (до введения детерминированного id).
  let candidates: Awaited<ReturnType<typeof getDocs>> | null = null;
  try {
    candidates = await getDocs(
      query(
        collection(firestore, 'conversations'),
        where('participantIds', 'array-contains', currentUser.id),
      )
    );
  } catch (e) {
    if (isFirestorePermissionDeniedError(e)) {
      logFirestorePermissionDenied({
        source: 'createOrOpenDirectChat',
        operation: 'getDocs conversations fallback',
        path: 'conversations',
        firestore,
        failedStep: 'fallback query',
        extra: { currentUserId: currentUser.id, otherUserId: otherUser.id, canonicalId },
        error: e,
      });
    }
    // Legacy-поиск не критичен. Если Firestore отдал internal, продолжаем
    // по canonical-пути (dm_*), чтобы не блокировать создание чата.
    if (!isFirestoreInternalError(e)) throw e;
    console.warn('[createOrOpenDirectChat] fallback query internal, continue with canonical create', {
      canonicalId,
      currentUserId: currentUser.id,
      otherUserId: otherUser.id,
      error: e,
    });
  }
  let bestId: string | null = null;
  let bestTs = -1;
  if (candidates) {
    for (const d of candidates.docs) {
      const data = d.data() as Conversation;
      if (!isDirectConversationForPair(data, currentUser.id, otherUser.id)) continue;
      const ts = data.lastMessageTimestamp
        ? new Date(data.lastMessageTimestamp).getTime()
        : 0;
      if (!bestId || ts > bestTs) {
        bestId = d.id;
        bestTs = ts;
      }
    }
  }
  if (bestId) return bestId;

  const nowIso = new Date().toISOString();
  const newConversation: Omit<Conversation, 'id'> = {
    isGroup: false,
    participantIds: [currentUser.id, otherUser.id],
    adminIds: [],
    participantInfo: {
      [currentUser.id]: participantInfoEntryForWrite(currentUser),
      [otherUser.id]: participantInfoEntryForWrite(otherUser),
    },
    lastMessageTimestamp: nowIso,
    lastMessageText: '',
    unreadCounts: { [currentUser.id]: 0, [otherUser.id]: 0 },
    unreadThreadCounts: { [currentUser.id]: 0, [otherUser.id]: 0 },
    typing: {},
  };
  try {
    await runTransaction(firestore, async (tx) => {
      const snap = await tx.get(canonicalRef);
      if (
        snap.exists() &&
        isDirectConversationForPair(
          snap.data() as Conversation,
          currentUser.id,
          otherUser.id
        )
      ) {
        return;
      }
      tx.set(canonicalRef, newConversation);
    });
  } catch (e) {
    if (isFirestorePermissionDeniedError(e)) {
      logFirestorePermissionDenied({
        source: 'createOrOpenDirectChat',
        operation: 'create (runTransaction)',
        path: canonicalRef.path,
        firestore,
        failedStep: 'runTransaction',
        extra: {
          currentUserId: currentUser.id,
          otherUserId: otherUser.id,
          canonicalId,
          participantIds: newConversation.participantIds,
          topLevelKeys: Object.keys(newConversation),
        },
        error: e,
      });
    }
    // Fallback: если транзакция упала внутренней ошибкой, пробуем идемпотентно создать без транзакции.
    if (!isFirestoreInternalError(e)) throw e;
    console.warn('[createOrOpenDirectChat] runTransaction internal, fallback to direct create', {
      canonicalId,
      currentUserId: currentUser.id,
      otherUserId: otherUser.id,
      error: e,
    });
    const fresh = await getDoc(canonicalRef);
    if (
      fresh.exists() &&
      isDirectConversationForPair(
        fresh.data() as Conversation,
        currentUser.id,
        otherUser.id
      )
    ) {
      return canonicalId;
    }
    try {
      await setDoc(canonicalRef, newConversation);
    } catch (setErr) {
      // Возможна гонка: другой клиент успел создать документ между getDoc и setDoc.
      // Перечитываем и возвращаем canonicalId, если это нужный direct-чат.
      const afterSet = await getDoc(canonicalRef);
      if (
        afterSet.exists() &&
        isDirectConversationForPair(
          afterSet.data() as Conversation,
          currentUser.id,
          otherUser.id
        )
      ) {
        return canonicalId;
      }
      throw setErr;
    }
  }

  try {
    await setDoc(
      doc(firestore, 'userChats', currentUser.id),
      { conversationIds: arrayUnion(canonicalId) },
      { merge: true }
    );
  } catch {
    // Индекс также синхронизирует Cloud Function; не блокируем создание чата.
  }
  return canonicalId;
}
