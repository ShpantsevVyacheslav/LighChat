import type { Firestore } from 'firebase/firestore';
import {
  arrayRemove,
  doc,
  runTransaction,
  setDoc,
} from 'firebase/firestore';

import type {
  Conversation,
  SecretChatMediaViewPolicy,
  SecretChatRestrictions,
  SecretChatTtlPresetSec,
  User,
} from '@/lib/types';
import { participantInfoEntryForWrite } from '@/lib/conversation-participant-info-firestore';
import { autoEnableE2eeForNewDirectChat } from '@/lib/e2ee';

export function buildSecretDirectConversationId(userA: string, userB: string): string {
  const ids = [userA.trim(), userB.trim()].sort();
  const part = (v: string) => `${v.length}:${v}`;
  return `sdm_${part(ids[0])}_${part(ids[1])}`;
}

type CreateSecretDirectChatOptions = {
  ttlPresetSec?: SecretChatTtlPresetSec;
  restrictions?: SecretChatRestrictions;
  lockRequired?: boolean;
  mediaViewPolicy?: SecretChatMediaViewPolicy | null;
};

const DEFAULT_RESTRICTIONS: SecretChatRestrictions = {
  noForward: true,
  noCopy: true,
  noSave: true,
  screenshotProtection: true,
};

export async function createOrOpenSecretDirectChat(
  firestore: Firestore,
  currentUser: User,
  otherUser: User,
  opts: CreateSecretDirectChatOptions = {}
): Promise<string> {
  const a = currentUser.id.trim();
  const b = otherUser.id.trim();
  if (!a || !b || a === b) {
    throw new Error('createOrOpenSecretDirectChat requires two distinct users');
  }

  const conversationId = buildSecretDirectConversationId(a, b);
  const ref = doc(firestore, 'conversations', conversationId);
  const now = new Date();
  const nowIso = now.toISOString();
  const ttlPresetSec = opts.ttlPresetSec ?? 3600;
  const expiresAtIso = new Date(now.getTime() + ttlPresetSec * 1000).toISOString();
  const restrictions = opts.restrictions ?? DEFAULT_RESTRICTIONS;
  const lockRequired = opts.lockRequired === true;

  const newConversation: Omit<Conversation, 'id'> = {
    isGroup: false,
    participantIds: [a, b],
    adminIds: [],
    participantInfo: {
      [a]: participantInfoEntryForWrite(currentUser),
      [b]: participantInfoEntryForWrite(otherUser),
    },
    lastMessageTimestamp: nowIso,
    lastMessageText: '',
    unreadCounts: { [a]: 0, [b]: 0 },
    unreadThreadCounts: { [a]: 0, [b]: 0 },
    clearedAt: { [a]: nowIso, [b]: nowIso },
    typing: {},
    secretChat: {
      enabled: true,
      createdAt: nowIso,
      createdBy: a,
      expiresAt: expiresAtIso,
      ttlPresetSec,
      lockPolicy: { required: lockRequired },
      restrictions,
      mediaViewPolicy: opts.mediaViewPolicy ?? null,
    },
  };

  await runTransaction(firestore, async (tx) => {
    const snap = await tx.get(ref);
    if (snap.exists()) return;
    tx.set(ref, newConversation);
  });

  // Best-effort: secret chats are always E2EE-enabled by product policy.
  try {
    await autoEnableE2eeForNewDirectChat(firestore, conversationId, a, {
      userWants: true,
      platformWants: true,
    });
  } catch {
    // Non-fatal: chat creation should not fail because of delayed E2EE setup.
  }

  // Best-effort cleanup: secret chat id should not remain in main userChats index.
  try {
    await setDoc(
      doc(firestore, 'userChats', a),
      { conversationIds: arrayRemove(conversationId) },
      { merge: true }
    );
  } catch {
    // Triggers also keep the index in sync; ignore client-side cleanup errors.
  }

  return conversationId;
}
