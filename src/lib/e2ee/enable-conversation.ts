import { doc, getDoc, updateDoc, type Firestore } from 'firebase/firestore';
import type { Conversation } from '@/lib/types';
import { getOrCreateDeviceIdentity } from '@/lib/e2ee/device-identity';
import {
  createE2eeSessionDoc,
  fetchUserE2eePublicKeySpki,
  publishE2eePublicKey,
} from '@/lib/e2ee/session-firestore';

/**
 * Включает E2E для чата: новая эпоха ключа и обёртки для всех участников.
 * Требует опубликованных ключей у каждого участника.
 */
export async function enableE2eeOnConversation(
  firestore: Firestore,
  conversation: Conversation,
  currentUserId: string
): Promise<void> {
  const { privateKey: _, publicKeySpkiB64 } = await getOrCreateDeviceIdentity();
  await publishE2eePublicKey(firestore, currentUserId, publicKeySpkiB64);

  const participants = conversation.participantIds ?? [];
  /** Локальный SPKI совпадает с приватным ключом в IndexedDB; чтение себя из Firestore сразу после publish может отдать устаревший кэш — тогда unwrap на отправке падает. */
  const fetchPublicSpkiForWrap = async (uid: string) => {
    if (uid === currentUserId) return publicKeySpkiB64;
    return fetchUserE2eePublicKeySpki(firestore, uid);
  };

  for (const uid of participants) {
    const pk = await fetchPublicSpkiForWrap(uid);
    if (!pk) {
      throw new Error(
        `E2EE: у участника нет ключа (нужен хотя бы один вход в приложение на этом устройстве): ${uid}`
      );
    }
  }

  const nextEpoch = (conversation.e2eeKeyEpoch ?? 0) + 1;
  await createE2eeSessionDoc(
    firestore,
    conversation.id,
    nextEpoch,
    participants,
    currentUserId,
    fetchPublicSpkiForWrap
  );

  await updateDoc(doc(firestore, 'conversations', conversation.id), {
    e2eeEnabled: true,
    e2eeKeyEpoch: nextEpoch,
    e2eeEnabledAt: new Date().toISOString(),
  });
}

/**
 * После создания личного чата — попытка включить E2E, если пользователь или платформа запросили.
 */
export async function tryAutoEnableE2eeNewDirectChat(
  firestore: Firestore,
  conversationId: string,
  currentUserId: string,
  options: { userWants: boolean; platformWants: boolean }
): Promise<void> {
  if (!options.userWants && !options.platformWants) return;
  const snap = await getDoc(doc(firestore, 'conversations', conversationId));
  if (!snap.exists()) return;
  const data = snap.data() as Omit<Conversation, 'id'>;
  if (data.isGroup) return;
  const conv: Conversation = { ...data, id: conversationId };
  try {
    await enableE2eeOnConversation(firestore, conv, currentUserId);
  } catch (e) {
    console.warn('[e2ee] tryAutoEnableE2eeNewDirectChat skipped:', e);
  }
}
