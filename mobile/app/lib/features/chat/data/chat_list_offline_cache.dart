import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:lighchat_models/lighchat_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lighchat_mobile/core/app_logger.dart';


/// Локальный снимок `userChats/{uid}` + последних известных `conversations/{id}`
/// для мгновенного списка чатов без сети (после хотя бы одного успешного онлайн-сеанса).
const kChatListOfflineSnapshotKeyPrefix = 'mobile_chat_list_cache_v1_';

String chatListOfflineSnapshotPrefsKey(String userId) =>
    '$kChatListOfflineSnapshotKeyPrefix$userId';

Map<String, Object?> _userChatIndexToJson(UserChatIndex idx) {
  return <String, Object?>{
    'conversationIds': idx.conversationIds,
    if (idx.folders != null && idx.folders!.isNotEmpty)
      'folders': idx.folders!
          .map(
            (f) => <String, Object?>{
              'id': f.id,
              'name': f.name,
              'conversationIds': f.conversationIds,
            },
          )
          .toList(growable: false),
    if (idx.sidebarFolderOrder != null && idx.sidebarFolderOrder!.isNotEmpty)
      'sidebarFolderOrder': idx.sidebarFolderOrder,
    if (idx.folderPins != null && idx.folderPins!.isNotEmpty)
      'folderPins': idx.folderPins,
  };
}

Map<String, Object?> _conversationToFirestoreShape(Conversation c) {
  Map<String, Object?>? participantInfo;
  if (c.participantInfo != null && c.participantInfo!.isNotEmpty) {
    participantInfo = <String, Object?>{};
    for (final e in c.participantInfo!.entries) {
      participantInfo[e.key] = <String, Object?>{
        'name': e.value.name,
        if (e.value.avatar != null && e.value.avatar!.isNotEmpty)
          'avatar': e.value.avatar,
        if (e.value.avatarThumb != null && e.value.avatarThumb!.isNotEmpty)
          'avatarThumb': e.value.avatarThumb,
      };
    }
  }

  Map<String, Object?>? counts(Map<String, int>? m) {
    if (m == null || m.isEmpty) return null;
    return m.map((k, v) => MapEntry(k, v));
  }

  List<Object?>? pins() {
    final p = c.pinnedMessages;
    if (p == null || p.isEmpty) return null;
    return p.map((x) => x.toFirestoreMap()).toList(growable: false);
  }

  return <String, Object?>{
    'isGroup': c.isGroup,
    'participantIds': c.participantIds,
    if (c.name != null && c.name!.trim().isNotEmpty) 'name': c.name,
    if (c.description != null && c.description!.trim().isNotEmpty)
      'description': c.description,
    if (c.photoUrl != null && c.photoUrl!.trim().isNotEmpty)
      'photoUrl': c.photoUrl,
    if (c.createdByUserId != null && c.createdByUserId!.trim().isNotEmpty)
      'createdByUserId': c.createdByUserId,
    if (c.adminIds.isNotEmpty) 'adminIds': c.adminIds,
    if (participantInfo != null && participantInfo.isNotEmpty)
      'participantInfo': participantInfo,
    if (c.lastMessageText != null && c.lastMessageText!.trim().isNotEmpty)
      'lastMessageText': c.lastMessageText,
    if (c.lastMessageTimestamp != null &&
        c.lastMessageTimestamp!.trim().isNotEmpty)
      'lastMessageTimestamp': c.lastMessageTimestamp,
    if (counts(c.unreadCounts) != null) 'unreadCounts': counts(c.unreadCounts),
    if (counts(c.unreadThreadCounts) != null)
      'unreadThreadCounts': counts(c.unreadThreadCounts),
    if (c.lastReactionEmoji != null && c.lastReactionEmoji!.isNotEmpty)
      'lastReactionEmoji': c.lastReactionEmoji,
    if (c.lastReactionTimestamp != null &&
        c.lastReactionTimestamp!.trim().isNotEmpty)
      'lastReactionTimestamp': c.lastReactionTimestamp,
    if (c.lastReactionSenderId != null &&
        c.lastReactionSenderId!.trim().isNotEmpty)
      'lastReactionSenderId': c.lastReactionSenderId,
    if (c.lastReactionMessageId != null &&
        c.lastReactionMessageId!.trim().isNotEmpty)
      'lastReactionMessageId': c.lastReactionMessageId,
    if (c.lastReactionParentId != null &&
        c.lastReactionParentId!.trim().isNotEmpty)
      'lastReactionParentId': c.lastReactionParentId,
    if (c.lastReactionSeenAt != null && c.lastReactionSeenAt!.isNotEmpty)
      'lastReactionSeenAt': c.lastReactionSeenAt,
    if (c.clearedAt != null && c.clearedAt!.isNotEmpty)
      'clearedAt': c.clearedAt,
    if (pins() != null) 'pinnedMessages': pins(),
    if (c.legacyPinnedMessage != null)
      'pinnedMessage': c.legacyPinnedMessage!.toFirestoreMap(),
    if (c.e2eeEnabled != null) 'e2eeEnabled': c.e2eeEnabled,
    if (c.e2eeKeyEpoch != null) 'e2eeKeyEpoch': c.e2eeKeyEpoch,
  };
}

List<ConversationWithId>? _parseConversationsList(Object? raw) {
  if (raw is! List) return null;
  final out = <ConversationWithId>[];
  for (final item in raw) {
    if (item is! Map) continue;
    final m = item.map((k, v) => MapEntry(k.toString(), v));
    final id = m['id'];
    final dataRaw = m['data'];
    if (id is! String || id.isEmpty) continue;
    if (dataRaw is! Map) continue;
    final dataMap = dataRaw.map((k, v) => MapEntry(k.toString(), v));
    try {
      out.add(ConversationWithId(id: id, data: Conversation.fromJson(dataMap)));
    } catch (_) {}
  }
  return out.isEmpty ? null : out;
}

/// Читает последний сохранённый снимок для пользователя.
Future<({UserChatIndex? index, List<ConversationWithId> conversations})?>
loadChatListOfflineSnapshot(String userId) async {
  final uid = userId.trim();
  if (uid.isEmpty) return null;
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(chatListOfflineSnapshotPrefsKey(uid));
    if (raw == null || raw.trim().isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    final root = decoded.map((k, v) => MapEntry(k.toString(), v));
    UserChatIndex? idx;
    final idxRaw = root['index'];
    if (idxRaw is Map) {
      try {
        idx = UserChatIndex.fromJson(
          idxRaw.map((k, v) => MapEntry(k.toString(), v)),
        );
      } catch (_) {}
    }
    final convs =
        _parseConversationsList(root['conversations']) ??
        const <ConversationWithId>[];
    return (index: idx, conversations: convs);
  } catch (e, st) {
    if (kDebugMode) {
      appLogger.w('loadChatListOfflineSnapshot failed', error: e, stackTrace: st);
    }
    return null;
  }
}

/// Сохраняет снимок после успешной синхронизации с Firestore.
Future<void> persistChatListOfflineSnapshot({
  required String userId,
  required UserChatIndex? index,
  required List<ConversationWithId> conversations,
}) async {
  final uid = userId.trim();
  if (uid.isEmpty) return;
  if (index == null) return;
  try {
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, Object?>{
      'index': _userChatIndexToJson(index),
      'conversations': conversations
          .map(
            (c) => <String, Object?>{
              'id': c.id,
              'data': _conversationToFirestoreShape(c.data),
            },
          )
          .toList(growable: false),
    };
    await prefs.setString(
      chatListOfflineSnapshotPrefsKey(uid),
      jsonEncode(payload),
    );
  } catch (e, st) {
    if (kDebugMode) {
      appLogger.w('persistChatListOfflineSnapshot failed', error: e, stackTrace: st);
    }
  }
}
