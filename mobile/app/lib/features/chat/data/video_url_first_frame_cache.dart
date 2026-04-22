import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:ffmpeg_kit_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_min_gpl/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Кэш первого кадра сетевого видео (jpg) для превью в ленте и сетке «Медиа».
class VideoUrlFirstFrameCache {
  VideoUrlFirstFrameCache._();
  static final VideoUrlFirstFrameCache instance = VideoUrlFirstFrameCache._();

  final Map<String, Future<File?>> _inFlight = <String, Future<File?>>{};
  final Map<String, File?> _memory = <String, File?>{};

  String _hashUrl(String url) =>
      sha256.convert(utf8.encode(url)).toString().substring(0, 32);

  Future<File?> getOrCreate(String videoUrl) {
    final trimmed = videoUrl.trim();
    if (trimmed.isEmpty) {
      return Future<File?>.value(null);
    }
    if (_memory.containsKey(trimmed)) {
      return Future<File?>.value(_memory[trimmed]);
    }
    return _inFlight.putIfAbsent(trimmed, () => _createOnce(trimmed));
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

      final quotedIn = '"${videoUrl.replaceAll('"', '\\"')}"';
      final quotedOut = '"${outPath.replaceAll('"', '\\"')}"';
      final cmd =
          '-y -hide_banner -loglevel error -ss 0.05 -i $quotedIn -frames:v 1 -q:v 5 $quotedOut';
      final session = await FFmpegKit.execute(cmd);
      final code = await session.getReturnCode();
      if (!ReturnCode.isSuccess(code)) {
        if (kDebugMode) {
          debugPrint('VideoUrlFirstFrameCache ffmpeg failed for $videoUrl code=$code');
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
}
