import 'package:flutter/services.dart';

/// Bridge для Live Activity голосового плеера (iOS 16.1+).
///
/// Когда пользователь нажимает play на голосовом сообщении в чате —
/// в Dynamic Island / на Lock Screen появляется мини-плеер с
/// прогрессом и именем отправителя.
///
/// Без Widget Extension target в Xcode (см. `ios/VoiceActivity/README.md`)
/// `start()` тихо возвращает `null` и работа в чате идёт как обычно.
class VoiceLiveActivity {
  VoiceLiveActivity._();
  static final VoiceLiveActivity instance = VoiceLiveActivity._();

  static const MethodChannel _channel =
      MethodChannel('lighchat/live_activity');

  bool? _supportedCache;

  Future<bool> isSupported() async {
    final cached = _supportedCache;
    if (cached != null) return cached;
    try {
      final v = await _channel.invokeMethod<bool>('isSupported');
      _supportedCache = v == true;
    } on MissingPluginException {
      _supportedCache = false;
    } on PlatformException {
      _supportedCache = false;
    }
    return _supportedCache!;
  }

  /// Запустить Live Activity. Возвращает `activityId` или `null`, если
  /// не запустилась (нет Widget Extension / отключено пользователем).
  Future<String?> start({
    required String senderName,
    required Duration total,
    required Duration position,
    required bool isPlaying,
  }) async {
    if (!await isSupported()) return null;
    try {
      final id = await _channel.invokeMethod<String>('start', {
        'senderName': senderName,
        'totalSeconds': total.inMilliseconds / 1000.0,
        'positionSeconds': position.inMilliseconds / 1000.0,
        'isPlaying': isPlaying,
      });
      return id;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  Future<void> update({
    required String activityId,
    required Duration position,
    required bool isPlaying,
  }) async {
    if (activityId.isEmpty) return;
    try {
      await _channel.invokeMethod<void>('update', {
        'activityId': activityId,
        'positionSeconds': position.inMilliseconds / 1000.0,
        'isPlaying': isPlaying,
      });
    } on MissingPluginException {
      /* ignore */
    } on PlatformException {
      /* ignore */
    }
  }

  Future<void> end(String activityId) async {
    if (activityId.isEmpty) return;
    try {
      await _channel.invokeMethod<void>('end', {'activityId': activityId});
    } on MissingPluginException {
      /* ignore */
    } on PlatformException {
      /* ignore */
    }
  }
}
