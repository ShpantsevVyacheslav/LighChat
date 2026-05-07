export { E2EE_LAST_MESSAGE_PREVIEW } from '@/lib/e2ee/protocol';

import type { ChatMessage } from '@/lib/types';

export function isChatMessageE2ee(msg: Pick<ChatMessage, 'e2ee'>): boolean {
  return !!(msg.e2ee?.ciphertext && msg.e2ee?.iv && msg.e2ee.epoch != null);
}

export { disableE2eeOnConversation } from '@/lib/e2ee/disable-conversation-e2ee';

// v2 multi-device (Phase 2+). Импорт через полный путь
// `@/lib/e2ee/v2/*` оставлен для чистоты code-split; здесь реэкспортируем
// наиболее часто используемые публичные API.
export {
  E2EE_V2_PROTOCOL,
  E2EE_V2_WRAP_CONTEXT,
  collectParticipantDevicesV2,
  createE2eeSessionDocV2,
  fetchE2eeSessionAny,
  unwrapChatKeyForMeV2,
  unwrapChatKeyRawForMeV2,
} from '@/lib/e2ee/v2/session-firestore-v2';
export {
  getOrCreateDeviceIdentityV2,
  publishE2eeDeviceV2,
  listActiveE2eeDevicesV2,
  listAllE2eeDevicesV2,
  revokeE2eeDeviceV2,
  computeUserFingerprintV2,
  replaceIdentityFromBackupV2,
  readStoredIdentityPkcs8V2,
  type DeviceIdentityV2,
} from '@/lib/e2ee/v2/device-identity-v2';
export {
  enableE2eeOnConversationV2,
  tryAutoEnableE2eeV2NewDirectChat,
} from '@/lib/e2ee/v2/enable-conversation-v2';
export {
  encryptUtf8WithAesGcmV2,
  decryptUtf8WithAesGcmV2,
  type V2MessageAadContext,
} from '@/lib/e2ee/v2/webcrypto-v2';
export {
  revokeDeviceAndRekeyV2,
  renameE2eeDeviceV2,
  type RevokeProgress,
  type RevokeOptions,
} from '@/lib/e2ee/v2/revoke-device';
// Phase 6: recovery paths
export {
  createPasswordBackupV2,
  restorePasswordBackupV2,
  hasAnyPasswordBackupV2,
  getPasswordBackupV2,
  E2EE_BACKUP_MIN_PASSWORD_LENGTH,
  type CreateBackupOptions,
  type RestoreBackupOptions,
  type RestoredBackup,
} from '@/lib/e2ee/v2/password-backup';
export {
  E2EE_PAIRING_QR_VERSION,
  E2EE_PAIRING_TTL_MS,
  buildQrPayload,
  parseQrPayload,
  initiatePairingSessionV2,
  watchPairingSessionV2,
  consumeDonorPayloadV2,
  donorRespondToPairingV2,
  rejectPairingSessionV2,
  listActivePairingSessionsV2,
  type PairingQrPayload,
  type InitiatorSession,
  type DonorRespondOptions,
} from '@/lib/e2ee/v2/pairing-qr';
// Phase 7: media encryption (chunked AES-GCM, per-file keys, wrap под ChatKey эпохи).
export {
  encryptMediaFileV2,
  decryptMediaFileV2,
  decryptMediaFileStreamV2,
  E2EE_MEDIA_V2_CHUNK_SIZE,
  E2EE_MEDIA_V2_THUMB_INLINE_MAX,
  type EncryptMediaInput,
  type EncryptMediaResult,
  type EncryptedMediaChunk,
  type DecryptMediaResult,
  type FetchEncryptedChunk,
} from '@/lib/e2ee/v2/media-crypto-v2';
export {
  encryptAndUploadMediaFileV2,
  downloadAndDecryptMediaFileV2,
  randomFileIdV2,
  isEncryptableMimeV2,
  E2EE_MEDIA_V2_STORAGE_PREFIX,
  type EncryptUploadInput,
  type EncryptUploadResult,
  type DownloadDecryptInput,
} from '@/lib/e2ee/v2/media-upload-v2';
// Phase 8: system-маркеры E2EE в timeline.
export {
  postChatSystemEventV2,
  chatSystemEvents,
  CHAT_SYSTEM_SENDER_ID,
  type PostSystemEventOptions,
} from '@/lib/e2ee/v2/system-events';
// Phase 9: лёгкая телеметрия rollout'а. Sink по умолчанию пуст.
export {
  logE2eeEvent,
  setE2eeTelemetrySink,
  normalizeErrorCode,
  type E2eeTelemetryEventType,
  type E2eeTelemetryPayload,
  type E2eeTelemetrySink,
} from '@/lib/e2ee/v2/telemetry';
// Phase 9 rollout helper (auto-enable routing по platformSettings-флагу).
export {
  autoEnableE2eeForNewDirectChat,
  readE2eeProtocolFlag,
  type AutoEnableRolloutOptions,
} from '@/lib/e2ee/v2/rollout';
// Phase 9 post-launch: self-heal session при добавлении/смене устройств.
export {
  diagnoseSessionCoverageV2,
  healSessionForCurrentDevicesV2,
  forceRotateEpochV2,
  type HealReason,
  type HealResult,
} from '@/lib/e2ee/v2/heal-session';
// Persistent-кэш расшифрованного содержимого (text + media) — IndexedDB.
export {
  getCachedPlaintext,
  putCachedPlaintext,
  getCachedMedia,
  putCachedMedia,
  getCachedConversationPreview,
  putCachedConversationPreview,
  subscribeConversationPreviewChanges,
  clearAllE2eeCache,
  clearConversationE2eeCache,
  type ConversationPreviewRecord,
  type ConversationPreviewListener,
} from '@/lib/e2ee/plaintext-cache';
