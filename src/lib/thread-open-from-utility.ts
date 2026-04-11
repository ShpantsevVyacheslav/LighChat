/** Со страницы «Обсуждения»: открыть чат и ветку по корневому сообщению. */
export const LIGHCHAT_THREAD_OPEN_CONVERSATION_KEY = 'lighchatOpenThreadConversationId';
export const LIGHCHAT_THREAD_OPEN_MESSAGE_KEY = 'lighchatOpenThreadMessageId';

export function scheduleOpenThreadFromUtilityPage(conversationId: string, rootMessageId: string) {
  try {
    sessionStorage.setItem(LIGHCHAT_THREAD_OPEN_CONVERSATION_KEY, conversationId);
    sessionStorage.setItem(LIGHCHAT_THREAD_OPEN_MESSAGE_KEY, rootMessageId);
  } catch (e) {
    console.warn('[LighChat] scheduleOpenThreadFromUtilityPage', e);
  }
}
