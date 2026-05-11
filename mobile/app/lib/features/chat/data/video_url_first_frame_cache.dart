import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:ffmpeg_kit_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_min_gpl/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../ui/chat_gallery_video_local_cache.dart';
import 'local_cache_entry_registry.dart';

/// Кэш первого кадра сетевого видео (jpg) для превью в ленте и сетке «Медиа».
class VideoUrlFirstFrameCache {
  VideoUrlFirstFrameCache._();
  static final VideoUrlFirstFrameCache instance = VideoUrlFirstFrameCache._();

  final Map<String, Future<File?>> _inFlight = <String, Future<File?>>{};
  final Map<String, File?> _memory = <String, File?>{};

  String _hashUrl(String url) =>
      sha256.convert(utf8.encode(url)).toString().substring(0, 32);

  String _resolveInputForFfmpeg(String raw) {
    final trimmed = raw.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.scheme == 'file') {
      try {
        return uri.toFilePath();
      } catch (_) {
        return trimmed;
      }
    }
    return trimmed;
  }

  Future<File?> getOrCreate(
    String videoUrl, {
    String? conversationId,
    String? messageId,
    String? attachmentName,
  }) {
    return () async {
      final trimmed = videoUrl.trim();
      if (trimmed.isEmpty) {
        return null;
      }
      final cid = conversationId?.trim();
      if (cid != null && cid.isNotEmpty) {
        await LocalCacheEntryRegistry.registerVideoThumbContext(
          url: trimmed,
          conversationId: cid,
          messageId: messageId,
          attachmentName: attachmentName,
        );
      }
      if (_memory.containsKey(trimmed)) {
        return _memory[trimmed];
      }
      return _inFlight.putIfAbsent(trimmed, () => _createOnce(trimmed));
    }();
  }

  Future<File?> _createOnce(String videoUrl) async {
    try {
      // Не `getTemporaryDirectory()` — ОС часто чистит temp; превью «пропадало»
      // после перезапуска / нехватки места. Support directory сохраняется между сессиями.
      final base = await getApplicationSupportDirectory();
      final cacheDir = Directory('${base.path}/video_first_frame_cache');
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }
      final outPath = '${cacheDir.path}/${_hashUrl(videoUrl)}.jpg';
      final existing = File(outPath);
      if (await existing.exists() && await existing.length() > 32) {
        _memory[videoUrl] = existing;
        return existing;
      }

      // `ffmpeg_kit_min_gpl` собран без HTTPS-протоколов → дёргать кадр прямо из
      // сетевого URL надёжно не получится. Поэтому если есть уже скачанный
      // локальный файл из `chat_video_cache/`, берём его как input — это и
      // быстрее, и работает офлайн.
      final localCached = await ChatGalleryVideoLocalCache.cachedFileIfExists(
        videoUrl,
      );
      final input = localCached?.path ?? _resolveInputForFfmpeg(videoUrl);
      final quotedIn = '"${input.replaceAll('"', '\\"')}"';
      final quotedOut = '"${outPath.replaceAll('"', '\\"')}"';
      final cmd =
          '-y -hide_banner -loglevel error -ss 0.05 -i $quotedIn -frames:v 1 -q:v 5 $quotedOut';
      final session = await FFmpegKit.execute(cmd);
      final code = await session.getReturnCode();
      if (!ReturnCode.isSuccess(code)) {
        if (kDebugMode) {
          debugPrint(
            'VideoUrlFirstFrameCache ffmpeg failed for $videoUrl code=$code'
            ' (input=${localCached == null ? 'network' : 'local'})',
          );
        }
        return null;
      }
      if (!await existing.exists() || await existing.length() < 32) {
        return null;
      }
      _memory[videoUrl] = existing;
      return existing;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('VideoUrlFirstFrameCache failed: $e\n$st');
      }
      // Не кэшируем «ошибку» в _memory: иначе getOrCreate навсегда возвращает null
      // до перезапуска приложения (см. containsKey в getOrCreate).
      return null;
    } finally {
      _inFlight.remove(videoUrl);
    }
  }

  /// Сбросить in-memory negative result, чтобы следующий `getOrCreate` снова
  /// попытался сгенерировать превью (например, после того как видео доскачалось
  /// в локальный кэш через `ChatGalleryVideoLocalCache.warmUp`).
  void invalidate(String videoUrl) {
    final trimmed = videoUrl.trim();
    _memory.remove(trimmed);
  }
}
