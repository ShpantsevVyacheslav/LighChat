import 'package:flutter/services.dart';

/// Семантические haptic-события для чата.
///
/// iOS: Core Haptics с богатыми transient-паттернами (fallback на
/// UIImpactFeedbackGenerator для старых устройств).
/// Android: VibrationEffect с waveform-ами (или одиночный impulse для
/// Android < 8).
///
/// Один Singleton; вызовы не блокируют UI (асинхронный invoke).
class ChatHaptics {
  ChatHaptics._();
  static final ChatHaptics instance = ChatHaptics._();

  static const MethodChannel _channel = MethodChannel('lighchat/haptics');

  /// Лёгкий «pop» при отправке сообщения.
  Future<void> sendMessage() => _play('sendMessage');

  /// Мягкий двойной tap при входящем сообщении.
  Future<void> receiveMessage() => _play('receiveMessage');

  /// Средний impact при долгом нажатии (контекст-меню, drag-handle).
  Future<void> longPress() => _play('longPress');

  /// Три нарастающих tap-а — «успех», «галочка».
  Future<void> success() => _play('success');

  /// Двойной средний — предупреждение / warning.
  Future<void> warning() => _play('warning');

  /// Три резких tap-а — ошибка.
  Future<void> error() => _play('error');

  /// Резкий мини-tick — переключение чего-то небольшого.
  Future<void> tick() => _play('tick');

  /// Смена выбора (как у системного picker / segmented control).
  Future<void> selectionChanged() => _play('selectionChanged');

  /// Праздничный салют — «реакция отправлена» / эмодзи-burst.
  Future<void> reactionBurst() => _play('reactionBurst');

  Future<void> _play(String event) async {
    try {
      await _channel.invokeMethod<void>('play', {'event': event});
    } on MissingPluginException {
      /* ignore */
    } on PlatformException {
      /* ignore */
    }
  }
}
