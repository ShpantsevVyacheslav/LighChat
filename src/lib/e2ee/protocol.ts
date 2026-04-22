/**
 * Публичные константы E2EE. После Phase 10 cleanup v1 полностью удалён —
 * единственная поддерживаемая версия это `v2-p256-aesgcm-multi`, её константа
 * лежит в `v2/session-firestore-v2.ts::E2EE_V2_PROTOCOL`.
 */

/** Плейсхолдер превью в списке чатов и push (сервер не видит текст). */
export const E2EE_LAST_MESSAGE_PREVIEW = 'Зашифрованное сообщение';
