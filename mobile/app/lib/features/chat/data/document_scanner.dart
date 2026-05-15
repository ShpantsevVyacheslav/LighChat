import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Нативный сканер документов: edge-detection + perspective correction.
/// iOS: VisionKit `VNDocumentCameraViewController` (iOS 13+).
/// Android: Google ML Kit Document Scanner (Play Services).
///
/// Возвращает список абсолютных путей к JPEG-страницам в tmp/cacheDir.
/// Caller сам перемещает их в нужное хранилище или сразу аттачит к
/// сообщению как обычные image-attachments.
class DocumentScanner {
  DocumentScanner._();
  static final DocumentScanner instance = DocumentScanner._();

  static const _channel = MethodChannel('lighchat/document_scanner');

  /// `true` на iOS 13+ (если устройство поддерживает VisionKit) и на
  /// Android с установленными Play Services. На desktop/web — `false`.
  Future<bool> isAvailable() async {
    if (!(Platform.isIOS || Platform.isAndroid)) return false;
    try {
      final v = await _channel.invokeMethod<bool>('isAvailable');
      return v ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Открывает нативный сканер. Возвращает пути к страницам.
  /// Пустой список — пользователь отменил.
  Future<List<String>> scan() async {
    try {
      final raw = await _channel.invokeMethod<List<dynamic>>('scan');
      if (raw == null) return const [];
      return raw.whereType<String>().toList(growable: false);
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('[DocumentScanner] scan error: ${e.code} ${e.message}');
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }
}
