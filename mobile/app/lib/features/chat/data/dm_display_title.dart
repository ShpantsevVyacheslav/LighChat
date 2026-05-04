import 'package:lighchat_models/lighchat_models.dart';

import '../../../l10n/app_localizations.dart';
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
  AppLocalizations? l10n,
}) {
  if (otherUserId.trim().isEmpty) return l10n?.dm_title_chat ?? 'Chat';
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
      : l10n?.dm_title_partner ?? 'Contact';
  return resolveContactDisplayName(
    contactProfiles: contactProfiles,
    contactUserId: otherUserId,
    fallbackName: fallback,
  );
}

/// Группа: имя или нейтральная подпись без сырого id.
String groupConversationDisplayTitle(ConversationWithId conversation, {AppLocalizations? l10n}) {
  final n = (conversation.data.name ?? '').trim();
  if (n.isNotEmpty) return n;
  return l10n?.dm_title_group ?? 'Group chat';
}
