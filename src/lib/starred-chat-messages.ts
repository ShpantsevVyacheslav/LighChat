/**
 * Избранные сообщения в чате (Firestore: users/{uid}/starredChatMessages).
 */

export function buildStarredMessageDocId(conversationId: string, messageId: string): string {
  return `s_${conversationId}_${messageId}`;
}
