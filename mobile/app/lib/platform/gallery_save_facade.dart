import 'dart:io' show File, Platform;

import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Сохранение медиа в системную галерею (mobile) или в папку Downloads
/// (desktop). Возвращает абсолютный путь к сохранённому файлу либо null
/// при ошибке.
class GallerySaveFacade {
  GallerySaveFacade._();
  static final GallerySaveFacade instance = GallerySaveFacade._();

  /// Сохранить файл (image/video/audio/document) в нативную галерею или
  /// Downloads. `originalPath` — путь к локальному файлу. `suggestedName` —
  /// имя без extension; реальное имя получит уникальный суффикс.
  Future<String?> save(String originalPath,
      {String? suggestedName, bool isImage = false, bool isVideo = false}) async {
    if (originalPath.trim().isEmpty) return null;
    final src = File(originalPath);
    if (!await src.exists()) return null;

    try {
      if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
        // gal сам выбирает image vs video по mime/extension.
        if (isImage) {
          await Gal.putImage(originalPath);
        } else if (isVideo) {
          await Gal.putVideo(originalPath);
        } else {
          // Документы — gal не поддерживает; падаем на shared_storage путь
          // (path_provider.getApplicationDocumentsDirectory).
          return _saveToAppDocs(src, suggestedName);
        }
        return originalPath; // оригинал; gal копирует внутрь Photos
      }

      // Desktop: пишем в Downloads.
      if (!kIsWeb &&
          (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
        final dir = await getDownloadsDirectory();
        if (dir == null) return _saveToAppDocs(src, suggestedName);
        final target = await _uniqueTarget(dir.path, suggestedName, originalPath);
        await src.copy(target);
        return target;
      }

      return _saveToAppDocs(src, suggestedName);
    } catch (e) {
      if (kDebugMode) debugPrint('[gallery-save] failed: $e');
      return null;
    }
  }

  Future<String?> _saveToAppDocs(File src, String? suggestedName) async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final target = await _uniqueTarget(docs.path, suggestedName, src.path);
      await src.copy(target);
      return target;
    } catch (_) {
      return null;
    }
  }

  Future<String> _uniqueTarget(
      String dirPath, String? suggestedName, String originalPath) async {
    final ext = p.extension(originalPath);
    final base = (suggestedName ?? p.basenameWithoutExtension(originalPath))
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    var candidate = p.join(dirPath, '$base$ext');
    var counter = 1;
    while (await File(candidate).exists()) {
      candidate = p.join(dirPath, '$base ($counter)$ext');
      counter += 1;
    }
    return candidate;
  }
}
