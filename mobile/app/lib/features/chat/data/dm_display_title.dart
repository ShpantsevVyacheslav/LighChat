import 'package:lighchat_models/lighchat_models.dart';

import 'contact_display_name.dart';
import 'user_contacts_repository.dart';
import 'user_profile.dart';

/// Заголовок личного чата для списка и модалок: никогда не показываем сырой UID.
String dmConversationDisplayTitle({
  required String currentUserId,
  required ConversationWithId conversation,
  required String otherUserId,
  Map<String, UserProfile> profiles = const {},
  Map<String, ContactLocalProfile> contactProfiles = const {},
}) {
  if (otherUserId.trim().isEmpty) return 'Чат';
  final data = conversation.data;
  final fromProfile = (profiles[otherUserId]?.name ?? '').trim();
  final fromConv = (data.participantInfo?[otherUserId]?.name ?? '').trim();
  final convName = (data.name ?? '').trim();
  final fallback = fromProfile.isNotEmpty
      ? fromProfile
      : fromConv.isNotEmpty
      ? fromConv
      : convName.isNotEmpty
      ? convName
      : 'Собеседник';
  return resolveContactDisplayName(
    contactProfiles: contactProfiles,
    contactUserId: otherUserId,
    fallbackName: fallback,
  );
}

/// Группа: имя или нейтральная подпись без сырого id.
String groupConversationDisplayTitle(ConversationWithId conversation) {
  final n = (conversation.data.name ?? '').trim();
  if (n.isNotEmpty) return n;
  return 'Групповой чат';
}
