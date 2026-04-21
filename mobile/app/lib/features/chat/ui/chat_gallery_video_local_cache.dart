import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Локальный кэш видео из галереи чата: один файл на URL, повторное открытие без повторной загрузки.
class ChatGalleryVideoLocalCache {
  ChatGalleryVideoLocalCache._();

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

  /// Скачивает по [url] в файл кэша. [onProgress]: 0..1 или `null`, если длина неизвестна.
  static Future<void> downloadToCache({
    required String url,
    required void Function(double? progress) onProgress,
    required bool Function() isCancelled,
  }) async {
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
