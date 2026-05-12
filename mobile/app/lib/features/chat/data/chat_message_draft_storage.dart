import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lighchat_firebase/lighchat_firebase.dart';
import 'package:lighchat_models/lighchat_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../l10n/app_localizations.dart';


/// Префикс как на вебе: [src/lib/chat-message-draft-storage.ts].
const String kChatDraftStoragePrefix = 'lighchat:chatDrafts:v1:';

const int _kMaxHtmlChars = 48000;

String chatDraftStorageKey(String userId) => '$kChatDraftStoragePrefix$userId';

// SECURITY: drafts are user-typed, not-yet-sent message bodies — including
// password discussions, in-progress private conversations, secret-chat
// content. Previously they sat in plaintext SharedPreferences (`drafts.xml`
// inside the app sandbox); on root or via `adb backup` they were directly
// readable. We now AES-256-GCM encrypt the JSON blob before write and
// decrypt on read. The AES key lives in FlutterSecureStorage (Android
// Keystore / iOS Keychain), so on a non-rooted device it can't be lifted
// even with adb access to the sandbox.
//
// Schema: SharedPreferences value is `v2:<base64-iv>:<base64-ct||tag>`.
// On read, we accept both v2 (encrypted) and the legacy raw JSON for
// backward compatibility — the next write encrypts in place.
const String _kDraftCipherPrefix = 'v2:';
const String _kDraftAesKeyName = 'lighchat.chatDrafts.aesKey.v1';
const _kDraftSecureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  // macOS legacy keychain (без entitlement) — см. device_identity.dart.
  mOptions: MacOsOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
    useDataProtectionKeyChain: false,
  ),
);

Uint8List? _draftAesKeyMemo;

Future<Uint8List> _getOrCreateDraftAesKey() async {
  final memo = _draftAesKeyMemo;
  if (memo != null) return memo;
  final existing = await _kDraftSecureStorage.read(key: _kDraftAesKeyName);
  if (existing != null && existing.isNotEmpty) {
    final decoded = base64.decode(existing);
    if (decoded.length == 32) {
      _draftAesKeyMemo = Uint8List.fromList(decoded);
      return _draftAesKeyMemo!;
    }
  }
  final key = randomBytes(32);
  await _kDraftSecureStorage.write(
    key: _kDraftAesKeyName,
    value: base64.encode(key),
  );
  _draftAesKeyMemo = key;
  return key;
}

/// Encrypt arbitrary string -> "v2:<iv>:<ct||tag>". Throws on crypto error.
Future<String> _encryptDraftPayload(String plain) async {
  final key = await _getOrCreateDraftAesKey();
  final iv = randomBytes(gcmIvBytes);
  final ct = await aesGcmEncryptV2(
    key: key,
    iv: iv,
    plaintext: Uint8List.fromList(utf8.encode(plain)),
  );
  return '$_kDraftCipherPrefix${base64.encode(iv)}:${base64.encode(ct)}';
}

/// Decrypt "v2:<iv>:<ct||tag>" -> string. Returns null on any failure
/// (including legacy plain-JSON values that don't carry the v2 prefix).
Future<String?> _decryptDraftPayload(String stored) async {
  if (!stored.startsWith(_kDraftCipherPrefix)) return null;
  final body = stored.substring(_kDraftCipherPrefix.length);
  final i = body.indexOf(':');
  if (i <= 0 || i == body.length - 1) return null;
  try {
    final iv = base64.decode(body.substring(0, i));
    final ct = base64.decode(body.substring(i + 1));
    final key = await _getOrCreateDraftAesKey();
    final pt = await aesGcmDecryptV2(
      key: key,
      iv: Uint8List.fromList(iv),
      ciphertextPlusTag: Uint8List.fromList(ct),
    );
    return utf8.decode(pt);
  } catch (_) {
    return null;
  }
}

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
  // Try v2 envelope first; on failure fall back to legacy plain JSON so
  // existing installs don't lose their drafts on upgrade.
  String? jsonText;
  if (raw.startsWith(_kDraftCipherPrefix)) {
    jsonText = await _decryptDraftPayload(raw);
    if (jsonText == null) {
      // Corrupted ciphertext (e.g. user rotated AES key by clearing secure
      // storage). Drop the drafts rather than crashing the chat list.
      return <String, StoredChatMessageDraft>{};
    }
  } else {
    jsonText = raw;
  }
  try {
    final decoded = jsonDecode(jsonText);
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
  final plain = jsonEncode(jsonMap);
  // SECURITY: always write the encrypted envelope. If for some reason the
  // AES key is unavailable (e.g. secure storage backend unsupported on a
  // weird OEM build), encryption throws — we then fall through to plaintext
  // rather than losing the user's draft entirely. That degrades to the old
  // behaviour, which is no worse than where we started.
  String value;
  try {
    value = await _encryptDraftPayload(plain);
  } catch (_) {
    value = plain;
  }
  await p.setString(chatDraftStorageKey(userId), value);
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
String? chatMainDraftPreviewLine(StoredChatMessageDraft d, AppLocalizations l10n) {
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
  return l10n.chat_draft_reply_fallback;
}
