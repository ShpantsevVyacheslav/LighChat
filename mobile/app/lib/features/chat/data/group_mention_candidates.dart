import 'package:lighchat_models/lighchat_models.dart';

import '../../../l10n/app_localizations.dart';
import 'contact_display_name.dart';
import 'user_contacts_repository.dart';
import 'user_profile.dart';

class GroupMentionCandidate {
  const GroupMentionCandidate({
    required this.id,
    required this.name,
    required this.username,
    required this.avatarUrl,
  });

  final String id;
  final String name;
  final String username;
  final String? avatarUrl;
}

List<GroupMentionCandidate> buildGroupMentionCandidates({
  required Conversation conversation,
  required String currentUserId,
  required Map<String, UserProfile>? profileMap,
  Map<String, ContactLocalProfile>? contactProfiles,
  AppLocalizations? l10n,
}) {
  if (!conversation.isGroup) return const [];
  final ids = {...conversation.participantIds}.toList();
  final out = <GroupMentionCandidate>[];
  for (final id in ids) {
    if (id.trim().isEmpty) continue;
    if (id == currentUserId) continue;

    final p = profileMap?[id];
    final info = conversation.participantInfo?[id];
    final profileName = (p?.name ?? '').trim();
    final infoName = (info?.name ?? '').trim();
    final fallbackName = profileName.isNotEmpty
        ? profileName
        : (infoName.isNotEmpty ? infoName : (l10n?.mention_fallback_label_capitalized ?? 'Member'));
    final displayName = resolveContactDisplayName(
      contactProfiles: contactProfiles ?? const <String, ContactLocalProfile>{},
      contactUserId: id,
      fallbackName: fallbackName,
    );
    if (p != null && (p.deletedAt ?? '').trim().isEmpty) {
      out.add(
        GroupMentionCandidate(
          id: id,
          name: displayName,
          username: (p.username ?? '').trim(),
          avatarUrl: (p.avatarThumb ?? p.avatar),
        ),
      );
      continue;
    }

    out.add(
      GroupMentionCandidate(
        id: id,
        name: displayName,
        username: '',
        avatarUrl: (info?.avatarThumb ?? info?.avatar),
      ),
    );
  }
  return out;
}
