import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalCacheEntryContext {
  const LocalCacheEntryContext({
    required this.conversationId,
    this.messageId,
    this.attachmentName,
    this.updatedAtIso,
  });

  final String conversationId;
  final String? messageId;
  final String? attachmentName;
  final String? updatedAtIso;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'conversationId': conversationId,
      if (messageId != null && messageId!.trim().isNotEmpty)
        'messageId': messageId,
      if (attachmentName != null && attachmentName!.trim().isNotEmpty)
        'attachmentName': attachmentName,
      'updatedAtIso': updatedAtIso ?? DateTime.now().toUtc().toIso8601String(),
    };
  }

  factory LocalCacheEntryContext.fromJson(Map<String, Object?> raw) {
    final cid = _readStringCompat(raw['conversationId']);
    return LocalCacheEntryContext(
      conversationId: cid,
      messageId: _readStringCompat(raw['messageId']),
      attachmentName: _readStringCompat(raw['attachmentName']),
      updatedAtIso: _readStringCompat(raw['updatedAtIso']),
    );
  }

  static String _readStringCompat(Object? raw) {
    if (raw is String) return raw.trim();
    if (raw is List) {
      for (final item in raw) {
        if (item is String && item.trim().isNotEmpty) return item.trim();
      }
    }
    return '';
  }
}

class LocalCacheEntryRegistry {
  LocalCacheEntryRegistry._();

  static const String _videoKeyPrefix = 'mobile_video_cache_ctx_v1_';
  static const String _videoThumbKeyPrefix = 'mobile_video_thumb_cache_ctx_v1_';
  static const String _imageKeyPrefix = 'mobile_image_cache_ctx_v1_';

  static String imageFileIdForUrl(String url) => _thumbSha32(url.trim());

  static String _fnv32Id(String url) {
    const prime = 0x01000193;
    const offset = 0x811c9dc5;
    var h = offset;
    for (var i = 0; i < url.length; i++) {
      h ^= url.codeUnitAt(i);
      h = (h * prime) & 0xffffffff;
    }
    return h.toRadixString(16).padLeft(8, '0');
  }

  static String _thumbSha32(String url) =>
      sha256.convert(utf8.encode(url)).toString().substring(0, 32);

  static Future<void> registerVideoContext({
    required String url,
    required String conversationId,
    String? messageId,
    String? attachmentName,
  }) async {
    final cid = conversationId.trim();
    if (url.trim().isEmpty || cid.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final key = '$_videoKeyPrefix${_fnv32Id(url.trim())}';
    final ctx = LocalCacheEntryContext(
      conversationId: cid,
      messageId: messageId?.trim(),
      attachmentName: attachmentName?.trim(),
    );
    await prefs.setString(key, jsonEncode(ctx.toJson()));
  }

  static Future<void> registerVideoThumbContext({
    required String url,
    required String conversationId,
    String? messageId,
    String? attachmentName,
  }) async {
    final cid = conversationId.trim();
    if (url.trim().isEmpty || cid.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final key = '$_videoThumbKeyPrefix${_thumbSha32(url.trim())}';
    final ctx = LocalCacheEntryContext(
      conversationId: cid,
      messageId: messageId?.trim(),
      attachmentName: attachmentName?.trim(),
    );
    await prefs.setString(key, jsonEncode(ctx.toJson()));
  }

  static Future<void> registerImageContext({
    required String url,
    required String conversationId,
    String? messageId,
    String? attachmentName,
  }) async {
    final cid = conversationId.trim();
    if (url.trim().isEmpty || cid.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final key = '$_imageKeyPrefix${imageFileIdForUrl(url)}';
    if (prefs.getString(key) != null) return; // already registered
    final ctx = LocalCacheEntryContext(
      conversationId: cid,
      messageId: messageId?.trim(),
      attachmentName: attachmentName?.trim(),
    );
    await prefs.setString(key, jsonEncode(ctx.toJson()));
  }

  /// Проактивно регистрирует все три варианта (image/video/videoThumb) для URL
  /// — экран «Хранилище» сможет привязать файл к чату вне зависимости от того,
  /// в какой кэш он в итоге попадёт. Идемпотентно: если запись уже есть, не
  /// перезаписывает.
  static Future<void> registerAttachmentContext({
    required String url,
    required String conversationId,
    String? messageId,
    String? attachmentName,
  }) async {
    final cid = conversationId.trim();
    final trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty || cid.isEmpty) return;
    final uri = Uri.tryParse(trimmedUrl);
    if (uri == null || !uri.hasScheme || uri.scheme == 'file') return;
    final prefs = await SharedPreferences.getInstance();
    final imageKey = '$_imageKeyPrefix${imageFileIdForUrl(trimmedUrl)}';
    final videoKey = '$_videoKeyPrefix${_fnv32Id(trimmedUrl)}';
    final thumbKey = '$_videoThumbKeyPrefix${_thumbSha32(trimmedUrl)}';
    final mid = messageId?.trim();
    final name = attachmentName?.trim();
    final ctxJson = jsonEncode(
      LocalCacheEntryContext(
        conversationId: cid,
        messageId: mid,
        attachmentName: name,
      ).toJson(),
    );
    if (prefs.getString(imageKey) == null) {
      await prefs.setString(imageKey, ctxJson);
    }
    if (prefs.getString(videoKey) == null) {
      await prefs.setString(videoKey, ctxJson);
    }
    if (prefs.getString(thumbKey) == null) {
      await prefs.setString(thumbKey, ctxJson);
    }
  }

  static LocalCacheEntryContext? readImageContextSyncForFileName({
    required SharedPreferences prefs,
    required String fileName,
  }) {
    final id = _extractHex32Id(fileName);
    if (id == null) return null;
    return _readContext(prefs: prefs, key: '$_imageKeyPrefix$id');
  }

  static String? _extractHex32Id(String fileName) {
    final lower = fileName.toLowerCase();
    final dot = lower.indexOf('.');
    final id = dot <= 0 ? lower : lower.substring(0, dot);
    if (id.length != 32) return null;
    final isHex = RegExp(r'^[0-9a-f]{32}$').hasMatch(id);
    return isHex ? id : null;
  }

  static LocalCacheEntryContext? readVideoContextSyncForFileName({
    required SharedPreferences prefs,
    required String fileName,
  }) {
    final id = _extractVideoFileId(fileName);
    if (id == null) return null;
    return _readContext(prefs: prefs, key: '$_videoKeyPrefix$id');
  }

  static LocalCacheEntryContext? readVideoThumbContextSyncForFileName({
    required SharedPreferences prefs,
    required String fileName,
  }) {
    final id = _extractVideoThumbId(fileName);
    if (id == null) return null;
    return _readContext(prefs: prefs, key: '$_videoThumbKeyPrefix$id');
  }

  static LocalCacheEntryContext? _readContext({
    required SharedPreferences prefs,
    required String key,
  }) {
    final rawValue = prefs.get(key);
    final raw = rawValue is String ? rawValue : null;
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final mapped = decoded.map((k, v) => MapEntry(k.toString(), v));
      final ctx = LocalCacheEntryContext.fromJson(mapped);
      if (ctx.conversationId.isEmpty) return null;
      return ctx;
    } catch (_) {
      return null;
    }
  }

  static String? _extractVideoFileId(String fileName) {
    final lower = fileName.toLowerCase();
    if (!lower.startsWith('v_')) return null;
    final dot = lower.indexOf('.');
    if (dot <= 2) return null;
    final id = lower.substring(2, dot);
    if (id.isEmpty) return null;
    return id;
  }

  static String? _extractVideoThumbId(String fileName) {
    final lower = fileName.toLowerCase();
    final dot = lower.indexOf('.');
    final id = dot <= 0 ? lower : lower.substring(0, dot);
    if (id.length != 32) return null;
    final isHex = RegExp(r'^[0-9a-f]{32}$').hasMatch(id);
    return isHex ? id : null;
  }
}
