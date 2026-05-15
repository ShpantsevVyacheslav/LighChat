import 'dart:async';

import 'package:just_audio/just_audio.dart';

import 'ringtone_presets.dart';

/// Лёгкий синглтон-плеер для звука нового сообщения в foreground.
///
/// Используется когда приходит чужое сообщение и пользователь не в открытом
/// чате с этим автором. Не отвечает за background push (там играет дефолтный
/// системный звук канала уведомлений).
class MessageNotificationPlayer {
  MessageNotificationPlayer._();

  static final MessageNotificationPlayer instance =
      MessageNotificationPlayer._();

  final AudioPlayer _player = AudioPlayer();
  String? _loadedAssetPath;
  bool _disposed = false;

  /// Проиграть выбранную мелодию. Если ringtoneId не задан или неизвестен,
  /// используется пресет по умолчанию.
  Future<void> play({String? ringtoneId}) async {
    if (_disposed) return;
    final preset = ringtonePresetById(ringtoneId) ??
        ringtonePresetById(kDefaultMessageRingtoneId);
    if (preset == null) return;
    final assetPath = preset.assetPath(RingtoneVariant.messages);
    try {
      if (_loadedAssetPath != assetPath) {
        await _player.setAsset(assetPath);
        _loadedAssetPath = assetPath;
      }
      await _player.seek(Duration.zero);
      await _player.play();
    } catch (_) {
      // Тихо игнорируем — звук уведомления не критичен.
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    try {
      await _player.dispose();
    } catch (_) {}
  }
}
