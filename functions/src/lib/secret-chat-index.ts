/**
 * Secret chats use conversations/{sdm_*} for messages but are indexed separately:
 * userSecretChats/{uid}.conversationIds — not userChats (main list).
 */

export function isSecretConversation(
  conversationId: string,
  data?: Record<string, unknown> | null,
): boolean {
  if (conversationId.startsWith("sdm_")) return true;
  const sc = data?.secretChat;
  if (sc && typeof sc === "object" && sc !== null) {
    const enabled = (sc as Record<string, unknown>).enabled;
    return enabled === true;
  }
  return false;
}
