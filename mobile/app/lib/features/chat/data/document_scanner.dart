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

  /// Объединяет JPEG-страницы в один PDF в tmp/cacheDir. Возвращает путь
  /// к PDF файлу или `null` при ошибке (нет страниц / write failed).
  ///
  /// iOS использует `PDFKit.PDFDocument` + `PDFPage(image:)`, Android —
  /// `android.graphics.pdf.PdfDocument`. Размер каждой страницы PDF
  /// берётся из размера исходной картинки (aspect ratio сохраняется).
  ///
  /// [filename] — опциональное имя файла. Если не задано, используется
  /// `scan_<timestamp>.pdf`. Расширение `.pdf` добавляется автоматически.
  Future<String?> imagesToPdf(
    List<String> paths, {
    String? filename,
  }) async {
    if (paths.isEmpty) return null;
    if (!(Platform.isIOS || Platform.isAndroid)) return null;
    try {
      final args = <String, dynamic>{'paths': paths};
      if (filename != null) args['filename'] = filename;
      final result = await _channel.invokeMethod<String>('imagesToPdf', args);
      return (result == null || result.isEmpty) ? null : result;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('[DocumentScanner] imagesToPdf error: ${e.code} ${e.message}');
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
