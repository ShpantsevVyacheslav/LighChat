import 'package:lighchat_models/lighchat_models.dart';

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
}) {
  if (!conversation.isGroup) return const [];
  final ids = {...conversation.participantIds}.toList();
  final out = <GroupMentionCandidate>[];
  for (final id in ids) {
    if (id.trim().isEmpty) continue;
    if (id == currentUserId) continue;

    final p = profileMap?[id];
    if (p != null && (p.deletedAt ?? '').trim().isEmpty) {
      out.add(
        GroupMentionCandidate(
          id: id,
          name: p.name,
          username: (p.username ?? '').trim(),
          avatarUrl: (p.avatarThumb ?? p.avatar),
        ),
      );
      continue;
    }

    final info = conversation.participantInfo?[id];
    final name = (info?.name ?? '').trim();
    if (name.isEmpty) continue;
    out.add(
      GroupMentionCandidate(
        id: id,
        name: name,
        username: '',
        avatarUrl: (info?.avatarThumb ?? info?.avatar),
      ),
    );
  }
  return out;
}

