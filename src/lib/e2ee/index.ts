export {
  E2EE_PROTOCOL_VERSION,
  E2EE_DEVICE_DOC_ID,
  E2EE_LAST_MESSAGE_PREVIEW,
} from '@/lib/e2ee/protocol';
export { getOrCreateDeviceIdentity } from '@/lib/e2ee/device-identity';
export {
  publishE2eePublicKey,
  fetchUserE2eePublicKeySpki,
  fetchE2eeSession,
  createE2eeSessionDoc,
  unwrapConversationChatKey,
} from '@/lib/e2ee/session-firestore';
export { encryptUtf8WithAesGcm, decryptUtf8WithAesGcm } from '@/lib/e2ee/webcrypto';

import type { ChatMessage } from '@/lib/types';

export function isChatMessageE2ee(msg: Pick<ChatMessage, 'e2ee'>): boolean {
  return !!(msg.e2ee?.ciphertext && msg.e2ee?.iv && msg.e2ee.epoch != null);
}

export { enableE2eeOnConversation, tryAutoEnableE2eeNewDirectChat } from '@/lib/e2ee/enable-conversation';
export { disableE2eeOnConversation } from '@/lib/e2ee/disable-conversation-e2ee';
