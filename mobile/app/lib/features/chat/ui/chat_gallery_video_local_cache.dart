import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../data/local_cache_entry_registry.dart';
import '../data/local_storage_preferences.dart';
import '../data/media_load_scheduler.dart';

/// Локальный кэш видео из галереи чата: один файл на URL, повторное открытие без повторной загрузки.
class ChatGalleryVideoLocalCache {
  ChatGalleryVideoLocalCache._();

  static final Map<String, Future<void>> _warmUpInFlight =
      <String, Future<void>>{};

  /// FNV-1a 32-bit — стабильный короткий идентификатор без зависимости `crypto`.
  static String _idForUrl(String url) {
    const prime = 0x01000193;
    const offset = 0x811c9dc5;
    var h = offset;
    for (var i = 0; i < url.length; i++) {
      h ^= url.codeUnitAt(i);
      h = (h * prime) & 0xffffffff;
    }
    return h.toRadixString(16).padLeft(8, '0');
  }

  static String _extensionHint(String url) {
    final path = Uri.tryParse(url)?.path ?? '';
    final lower = path.toLowerCase();
    if (lower.endsWith('.mp4')) return '.mp4';
    if (lower.endsWith('.webm')) return '.webm';
    if (lower.endsWith('.mov')) return '.mov';
    if (lower.endsWith('.m4v')) return '.m4v';
    return '.bin';
  }

  static Future<File> fileForUrl(String url) async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/chat_video_cache');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return File('${dir.path}/v_${_idForUrl(url)}${_extensionHint(url)}');
  }

  static Future<bool> hasCachedFile(String url) async {
    final f = await fileForUrl(url);
    if (!await f.exists()) return false;
    return f.lengthSync() > 0;
  }

  static Future<File?> cachedFileIfExists(String url) async {
    final f = await fileForUrl(url);
    if (!await f.exists()) return null;
    if (f.lengthSync() <= 0) return null;
    return f;
  }

  /// Фоновый подогрев кэша без прогресса и без проброса ошибки в UI.
  /// Дедуплицирует одновременные запросы по одному URL.
  static Future<void> warmUp(
    String url, {
    String? conversationId,
    String? messageId,
    String? attachmentName,
  }) {
    return () async {
      final prefs = await LocalStoragePreferencesStore.load();
      if (!prefs.videoDownloadsEnabled) return;
      final cid = conversationId?.trim();
      if (cid != null && cid.isNotEmpty) {
        await LocalCacheEntryRegistry.registerVideoContext(
          url: url,
          conversationId: cid,
          messageId: messageId,
          attachmentName: attachmentName,
        );
      }
      final trimmed = url.trim();
      if (trimmed.isEmpty) return;
      if (_warmUpInFlight.containsKey(trimmed)) {
        return _warmUpInFlight[trimmed]!;
      }
      final task = () async {
        // Фоновый прогрев — через общий лимитер параллельных загрузок, чтобы
        // 20 видео в ленте не запустили 20 одновременных HTTP-стримов.
        final ticket = MediaLoadScheduler.instance.enqueue();
        try {
          await ticket.granted;
        } on MediaLoadCancelled {
          return;
        }
        try {
          await downloadToCache(
            url: trimmed,
            onProgress: (_) {},
            isCancelled: () => false,
          );
        } catch (_) {
          // best-effort: при ошибке просто оставляем без локального файла.
        } finally {
          ticket.release();
          _warmUpInFlight.remove(trimmed);
        }
      }();
      _warmUpInFlight[trimmed] = task;
      return task;
    }();
  }

  /// Скачивает по [url] в файл кэша. [onProgress]: 0..1 или `null`, если длина неизвестна.
  static Future<void> downloadToCache({
    required String url,
    required void Function(double? progress) onProgress,
    required bool Function() isCancelled,
    String? conversationId,
    String? messageId,
    String? attachmentName,
  }) async {
    final prefs = await LocalStoragePreferencesStore.load();
    if (!prefs.videoDownloadsEnabled) {
      onProgress(null);
      return;
    }
    final cid = conversationId?.trim();
    if (cid != null && cid.isNotEmpty) {
      await LocalCacheEntryRegistry.registerVideoContext(
        url: url,
        conversationId: cid,
        messageId: messageId,
        attachmentName: attachmentName,
      );
    }
    if (await hasCachedFile(url)) {
      onProgress(1);
      return;
    }
    final uri = Uri.parse(url);
    final target = await fileForUrl(url);
    final part = File('${target.path}.part');
    if (part.existsSync()) {
      await part.delete();
    }
    final client = http.Client();
    try {
      final req = http.Request('GET', uri);
      final stream = await client.send(req);
      if (stream.statusCode < 200 || stream.statusCode >= 300) {
        throw HttpException('HTTP ${stream.statusCode}', uri: uri);
      }
      final total = stream.contentLength;
      var received = 0;
      final sink = part.openWrite();
      await for (final chunk in stream.stream) {
        if (isCancelled()) {
          await sink.close();
          if (part.existsSync()) await part.delete();
          return;
        }
        received += chunk.length;
        sink.add(chunk);
        if (total != null && total > 0) {
          onProgress((received / total).clamp(0.0, 1.0));
        } else {
          onProgress(null);
        }
      }
      await sink.close();
      if (await target.exists()) {
        await target.delete();
      }
      await part.rename(target.path);
      onProgress(1);
    } catch (_) {
      if (part.existsSync()) {
        await part.delete();
      }
      rethrow;
    } finally {
      client.close();
    }
  }
}
