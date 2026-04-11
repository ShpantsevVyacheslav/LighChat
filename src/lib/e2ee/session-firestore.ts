import { doc, getDoc, setDoc, type Firestore } from 'firebase/firestore';
import type { E2eeSessionDoc, UserE2eePublicDoc } from '@/lib/types';
import { E2EE_DEVICE_DOC_ID, E2EE_PROTOCOL_VERSION } from '@/lib/e2ee/protocol';
import {
  importAesGcmKeyFromRaw,
  randomChatKeyRaw,
  unwrapRawChatKey,
  unwrapRawChatKeyWithRecipientPrivateKey,
  wrapRawChatKeyForRecipient,
} from '@/lib/e2ee/webcrypto';
import { fromBase64 } from '@/lib/e2ee/b64';

export async function publishE2eePublicKey(
  firestore: Firestore,
  userId: string,
  publicKeySpkiB64: string
): Promise<void> {
  await setDoc(
    doc(firestore, 'users', userId, 'e2ee', E2EE_DEVICE_DOC_ID),
    { publicKeySpki: publicKeySpkiB64, updatedAt: new Date().toISOString() } satisfies UserE2eePublicDoc,
    { merge: true }
  );
}

export async function fetchUserE2eePublicKeySpki(firestore: Firestore, userId: string): Promise<string | null> {
  const s = await getDoc(doc(firestore, 'users', userId, 'e2ee', E2EE_DEVICE_DOC_ID));
  if (!s.exists()) return null;
  const d = s.data() as UserE2eePublicDoc;
  return typeof d.publicKeySpki === 'string' ? d.publicKeySpki : null;
}

export async function fetchE2eeSession(
  firestore: Firestore,
  conversationId: string,
  epoch: number
): Promise<E2eeSessionDoc | null> {
  const s = await getDoc(doc(firestore, 'conversations', conversationId, 'e2eeSessions', String(epoch)));
  if (!s.exists()) return null;
  return s.data() as E2eeSessionDoc;
}

/**
 * Создаёт документ эпохи с обёртками ключа для каждого участника.
 */
export async function createE2eeSessionDoc(
  firestore: Firestore,
  conversationId: string,
  epoch: number,
  participantIds: string[],
  currentUserId: string,
  fetchPublicSpki: (uid: string) => Promise<string | null>
): Promise<void> {
  const chatKeyRaw = randomChatKeyRaw();
  const wraps: E2eeSessionDoc['wraps'] = {};
  for (const uid of participantIds) {
    const pubB64 = await fetchPublicSpki(uid);
    if (!pubB64) {
      throw new Error(`E2EE_NO_PUBLIC_KEY:${uid}`);
    }
    const pubU8 = fromBase64(pubB64);
    const pubCopy = new Uint8Array(pubU8.length);
    pubCopy.set(pubU8);
    const w = await wrapRawChatKeyForRecipient(chatKeyRaw, pubCopy.buffer);
    wraps[uid] = { ephPub: w.ephPub, iv: w.iv, ct: w.ct };
  }
  const payload: E2eeSessionDoc = {
    epoch,
    protocolVersion: E2EE_PROTOCOL_VERSION,
    createdAt: new Date().toISOString(),
    createdByUserId: currentUserId,
    wraps,
  };
  await setDoc(doc(firestore, 'conversations', conversationId, 'e2eeSessions', String(epoch)), payload);
}

export async function unwrapConversationChatKey(
  session: E2eeSessionDoc,
  userId: string,
  identityPrivateKey: CryptoKey
): Promise<CryptoKey> {
  const entry = session.wraps[userId];
  if (!entry) {
    throw new Error('E2EE_NO_WRAP_FOR_USER');
  }
  const raw = await unwrapRawChatKeyWithRecipientPrivateKey(entry, identityPrivateKey);
  return importAesGcmKeyFromRaw(raw);
}
