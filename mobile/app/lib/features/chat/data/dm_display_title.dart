import 'package:lighchat_models/lighchat_models.dart';

import 'user_profile.dart';

/// Заголовок личного чата для списка и модалок: никогда не показываем сырой UID.
String dmConversationDisplayTitle({
  required String currentUserId,
  required ConversationWithId conversation,
  required String otherUserId,
  Map<String, UserProfile> profiles = const {},
}) {
  if (otherUserId.trim().isEmpty) return 'Чат';
  final data = conversation.data;
  final fromConv = (data.participantInfo?[otherUserId]?.name ?? '').trim();
  if (fromConv.isNotEmpty) return fromConv;
  final fromProfile = (profiles[otherUserId]?.name ?? '').trim();
  if (fromProfile.isNotEmpty) return fromProfile;
  final convName = (data.name ?? '').trim();
  if (convName.isNotEmpty) return convName;
  return 'Собеседник';
}

/// Группа: имя или нейтральная подпись без сырого id.
String groupConversationDisplayTitle(ConversationWithId conversation) {
  final n = (conversation.data.name ?? '').trim();
  if (n.isNotEmpty) return n;
  return 'Групповой чат';
}
