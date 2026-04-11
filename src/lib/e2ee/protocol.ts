import type { E2eeProtocolVersion } from '@/lib/types';

/**
 * MVP E2E: P-256 ECDH для обёртки симметричного ключа чата + AES-256-GCM для сообщений.
 * Не Signal Protocol; поле protocolVersion позволяет сменить движок позже.
 */
export const E2EE_PROTOCOL_VERSION: E2eeProtocolVersion = 'v1-p256-aesgcm';

export const E2EE_DEVICE_DOC_ID = 'device';

/** Плейсхолдер превью в списке чатов и push (сервер не видит текст). */
export const E2EE_LAST_MESSAGE_PREVIEW = 'Зашифрованное сообщение';
