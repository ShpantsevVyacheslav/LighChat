import 'package:flutter/services.dart';

/// Bridge для iOS Live Text — нативной OCR (iOS 16+).
///
/// Открывает полноэкранный нативный viewer с фото, поверх которого
/// `ImageAnalysisInteraction`: пользователь может выделить текст,
/// скопировать, нажать на номер телефона / email / адрес → data
/// detectors показывают системное меню действий.
///
/// На Android и старых iOS методы возвращают `false` / no-op без
/// падений — UI должен скрывать кнопку при `isAvailable == false`.
class LiveTextViewer {
  LiveTextViewer._();
  static final LiveTextViewer instance = LiveTextViewer._();

  static const MethodChannel _channel = MethodChannel('lighchat/live_text');

  bool? _availableCache;

  Future<bool> isAvailable() async {
    final cached = _availableCache;
    if (cached != null) return cached;
    try {
      final v = await _channel.invokeMethod<bool>('isAvailable');
      _availableCache = v == true;
    } on MissingPluginException {
      _availableCache = false;
    } on PlatformException {
      _availableCache = false;
    }
    return _availableCache!;
  }

  /// Открывает нативный fullscreen-viewer с Live Text на изображении.
  /// [imageUrl] — `file://` или `http(s)://` URL.
  Future<void> present({required String imageUrl}) async {
    try {
      await _channel.invokeMethod<void>('present', <String, dynamic>{
        'imageUrl': imageUrl,
      });
    } on MissingPluginException {
      /* ignore */
    } on PlatformException {
      /* ignore */
    }
  }
}
