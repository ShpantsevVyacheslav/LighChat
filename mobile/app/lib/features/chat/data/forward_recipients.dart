import 'package:lighchat_models/lighchat_models.dart';

import 'saved_messages_chat.dart';
import 'user_profile.dart';

const String kContactSelectionPrefix = 'contact:';

String contactSelectionKey(String userId) => '$kContactSelectionPrefix$userId';

bool isContactSelectionKey(String key) =>
    key.startsWith(kContactSelectionPrefix);

String? peerUserIdFromContactSelectionKey(String key) {
  if (!isContactSelectionKey(key)) return null;
  return key.substring(kContactSelectionPrefix.length);
}

/// Строка списка получателей на экране пересылки.
class ForwardRecipientRow {
  const ForwardRecipientRow({
    required this.selectionKey,
    required this.displayName,
    required this.avatarUrl,
    required this.subtitle,
    this.username,
    this.conversation,
    this.isContactOnly = false,
  });

  /// `conversations/{id}` или `contact:{userId}` для открытия DM через [ChatRepository.createOrOpenDirectChat].
  final String selectionKey;
  final String displayName;
  final String? avatarUrl;
  final String subtitle;
  final String? username;
  final ConversationWithId? conversation;
  final bool isContactOnly;
}

bool _newerConversation(Conversation a, Conversation b) {
  final ta = a.lastMessageTimestamp ?? '';
  final tb = b.lastMessageTimestamp ?? '';
  return ta.compareTo(tb) > 0;
}

String _atUsernameOrEmpty(String? username) {
  var h = (username ?? '').trim();
  if (h.isEmpty) return '';
  if (h.startsWith('@')) h = h.substring(1);
  if (h.isEmpty) return '';
  return '@$h';
}

String _subtitleWithUsernameOnly(String? username) {
  return _atUsernameOrEmpty(username);
}

/// Дедупликация личных чатов и фильтр:
/// - без «Избранного»
/// - личные: пользователи из открытых чатов + контакты
/// - группы: только если пользователь всё ещё в `participantIds`.
List<ForwardRecipientRow> buildForwardRecipientRows({
  required String currentUserId,
  required List<ConversationWithId> convs,
  required Set<String> allowedPeerIds,
  required Map<String, UserProfile> profiles,
}) {
  final dmByPeer = <String, ConversationWithId>{};
  final groups = <ConversationWithId>[];

  for (final c in convs) {
    final data = c.data;
    if (!data.participantIds.contains(currentUserId)) continue;
    if (isSavedMessagesConversation(data, currentUserId)) continue;

    if (data.isGroup) {
      groups.add(c);
      continue;
    }

    final others = data.participantIds
        .where((id) => id != currentUserId)
        .toList();
    if (others.isEmpty) continue;
    final otherId = others.first;
    if (otherId.isEmpty) continue;

    final prof = profiles[otherId];
    final pin = data.participantInfo?[otherId];
    final resolvedName = prof?.name ?? pin?.name;
    if (resolvedName == null || resolvedName.isEmpty) continue;

    final existing = dmByPeer[otherId];
    if (existing == null || _newerConversation(data, existing.data)) {
      dmByPeer[otherId] = c;
    }
  }

  final rows = <ForwardRecipientRow>[];

  for (final c in groups) {
    final data = c.data;
    final title = (data.name ?? '').trim().isNotEmpty
        ? data.name!.trim()
        : 'Группа';
    rows.add(
      ForwardRecipientRow(
        selectionKey: c.id,
        displayName: title,
        avatarUrl: data.photoUrl,
        subtitle: '',
        username: null,
        conversation: c,
      ),
    );
  }

  for (final entry in dmByPeer.entries) {
    final c = entry.value;
    final data = c.data;
    final otherId = entry.key;
    final prof = profiles[otherId];
    final pin = data.participantInfo?[otherId];
    final name = prof?.name ?? pin?.name ?? 'Неизвестный';
    final avatar =
        prof?.avatarThumb ?? prof?.avatar ?? pin?.avatarThumb ?? pin?.avatar;
    final username = (prof?.username ?? '').trim().isEmpty
        ? null
        : (prof?.username ?? '').trim();
    final uname = _subtitleWithUsernameOnly(username);
    rows.add(
      ForwardRecipientRow(
        selectionKey: c.id,
        displayName: name,
        avatarUrl: avatar,
        subtitle: uname,
        username: username,
        conversation: c,
      ),
    );
  }

  final dmPeers = dmByPeer.keys.toSet();
  for (final cid in allowedPeerIds) {
    if (cid == currentUserId) continue;
    if (dmPeers.contains(cid)) continue;
    final u = profiles[cid];
    if (u == null) continue;
    rows.add(
      ForwardRecipientRow(
        selectionKey: contactSelectionKey(cid),
        displayName: u.name,
        avatarUrl: u.avatarThumb ?? u.avatar,
        subtitle: _subtitleWithUsernameOnly(u.username),
        username: (u.username ?? '').trim().isEmpty ? null : u.username,
        isContactOnly: true,
      ),
    );
  }

  rows.sort(
    (a, b) =>
        a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
  );
  return rows;
}
