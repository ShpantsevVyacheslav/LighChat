/**
 * Открытие ветки после утилитных экранов: {@link buildDashboardChatOpenUrl} с `threadRootMessageId`
 * (параметр в URL; `ChatWindow` читает его через `DashboardOpenChatView`).
 */
import { logger } from '@/lib/logger';

export const LIGHCHAT_THREAD_OPEN_CONVERSATION_KEY = 'lighchatOpenThreadConversationId';
export const LIGHCHAT_THREAD_OPEN_MESSAGE_KEY = 'lighchatOpenThreadMessageId';

/** @deprecated Используйте `router.push(buildDashboardChatOpenUrl(id, { threadRootMessageId }))`. */
export function scheduleOpenThreadFromUtilityPage(_conversationId: string, _rootMessageId: string) {
  logger.warn(
    'thread-open',
    'scheduleOpenThreadFromUtilityPage: устарело — используйте buildDashboardChatOpenUrl с threadRootMessageId',
  );
}
