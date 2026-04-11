import 'package:lighchat_models/lighchat_models.dart';

/// Личный чат «Избранное»: один участник — текущий пользователь (web `isSavedMessagesChat`).
bool isSavedMessagesConversation(Conversation c, String userId) {
  if (c.isGroup) return false;
  if (c.participantIds.length != 1) return false;
  return c.participantIds.first == userId;
}
