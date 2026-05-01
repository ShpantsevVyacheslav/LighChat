import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:lighchat_models/lighchat_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'local_storage_preferences.dart';

/// Префикс как на вебе: [src/lib/chat-message-draft-storage.ts].
const String kChatDraftStoragePrefix = 'lighchat:chatDrafts:v1:';

const int _kMaxHtmlChars = 48000;

String chatDraftStorageKey(String userId) => '$kChatDraftStoragePrefix$userId';

/// Уведомление списка чатов без вызова защищённого [ChangeNotifier.notifyListeners] снаружи.
final ValueNotifier<int> chatDraftListRevision = ValueNotifier<int>(0);

void _bumpDraftRevision() {
  chatDraftListRevision.value = chatDraftListRevision.value + 1;
}

Map<String, Object?> _replyToJson(ReplyContext r) => <String, Object?>{
  'messageId': r.messageId,
  'senderName': r.senderName,
  if (r.text != null) 'text': r.text,
  if (r.mediaPreviewUrl != null) 'mediaPreviewUrl': r.mediaPreviewUrl,
  if (r.mediaType != null) 'mediaType': r.mediaType,
};

/// Паритет веб [StoredChatMessageDraft].
class StoredChatMessageDraft {
  const StoredChatMessageDraft({
    required this.html,
    this.replyTo,
    required this.updatedAt,
  });

  final String html;
  final ReplyContext? replyTo;
  final int updatedAt;

  Map<String, Object?> toJson() => <String, Object?>{
    'html': html,
    'replyTo': replyTo == null ? null : _replyToJson(replyTo!),
    'updatedAt': updatedAt,
  };

  static StoredChatMessageDraft? fromMapEntry(Object? raw) {
    if (raw is! Map) return null;
    final m = raw.map((k, v) => MapEntry(k.toString(), v));
    final html = m['html'];
    if (html is! String) return null;
    final u = m['updatedAt'];
    final updatedAt = u is int
        ? u
        : u is num
        ? u.toInt()
        : DateTime.now().millisecondsSinceEpoch;
    final replyTo = ReplyContext.fromJson(m['replyTo']);
    return StoredChatMessageDraft(
      html: html,
      replyTo: replyTo,
      updatedAt: updatedAt,
    );
  }
}

/// Плоский превью для списка чатов (паритет [chatDraftPlainFromHtml] на вебе).
String chatDraftPlainFromHtml(String html) {
  if (html.isEmpty) return '';
  var s = html.replaceAll(RegExp('<[^>]*>'), ' ');
  s = s.replaceAll(RegExp('&nbsp;', caseSensitive: false), ' ');
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  return s;
}

Future<Map<String, StoredChatMessageDraft>> _readMap(String userId) async {
  final p = await SharedPreferences.getInstance();
  final raw = p.getString(chatDraftStorageKey(userId));
  if (raw == null || raw.trim().isEmpty) {
    return <String, StoredChatMessageDraft>{};
  }
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return <String, StoredChatMessageDraft>{};
    final out = <String, StoredChatMessageDraft>{};
    for (final e in decoded.entries) {
      final k = e.key.toString();
      final d = StoredChatMessageDraft.fromMapEntry(e.value);
      if (d != null) out[k] = d;
    }
    return out;
  } catch (_) {
    return <String, StoredChatMessageDraft>{};
  }
}

Future<void> _writeMap(
  String userId,
  Map<String, StoredChatMessageDraft> map,
) async {
  final p = await SharedPreferences.getInstance();
  final jsonMap = map.map((k, v) => MapEntry(k, v.toJson()));
  await p.setString(chatDraftStorageKey(userId), jsonEncode(jsonMap));
}

Future<StoredChatMessageDraft?> getChatMessageDraft(
  String userId,
  String scopeKey,
) async {
  final map = await _readMap(userId);
  return map[scopeKey];
}

Future<void> saveChatMessageDraft(
  String userId,
  String scopeKey,
  StoredChatMessageDraft draft,
) async {
  final localPrefs = await LocalStoragePreferencesStore.load();
  if (!localPrefs.chatDraftsEnabled) return;
  final map = await _readMap(userId);
  var html = draft.html;
  if (html.length > _kMaxHtmlChars) {
    html = html.substring(0, _kMaxHtmlChars);
  }
  map[scopeKey] = StoredChatMessageDraft(
    html: html,
    replyTo: draft.replyTo,
    updatedAt: draft.updatedAt,
  );
  await _writeMap(userId, map);
  _bumpDraftRevision();
}

Future<void> clearChatMessageDraft(String userId, String scopeKey) async {
  final map = await _readMap(userId);
  if (!map.containsKey(scopeKey)) return;
  map.remove(scopeKey);
  await _writeMap(userId, map);
  _bumpDraftRevision();
}

Future<StoredChatMessageDraft?> getMainChatDraftForList(
  String userId,
  String conversationId,
) => getChatMessageDraft(userId, conversationId);

/// Все черновики пользователя (для списка чатов).
Future<Map<String, StoredChatMessageDraft>> loadAllChatDraftsForUser(
  String userId,
) => _readMap(userId);

/// Короткая строка превью (паритет [useChatMainDraftPreview] на вебе).
String? chatMainDraftPreviewLine(StoredChatMessageDraft d) {
  final plain = chatDraftPlainFromHtml(d.html);
  final hasReply = d.replyTo != null;
  if (plain.isEmpty && !hasReply) return null;
  if (plain.isNotEmpty) {
    return plain.length > 72 ? '${plain.substring(0, 72)}…' : plain;
  }
  final rt = d.replyTo?.text;
  if (rt != null && rt.trim().isNotEmpty) {
    final p = chatDraftPlainFromHtml(rt);
    return p.length > 72 ? '${p.substring(0, 72)}…' : p;
  }
  return 'Ответ';
}
