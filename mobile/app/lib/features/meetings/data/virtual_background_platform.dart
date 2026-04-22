import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'virtual_background_controller.dart';

/// Реализация [VirtualBackgroundController] поверх MethodChannel.
///
/// Каркас для native ML-pipeline: Dart отправляет команды, native принимает
/// их и применяет обработку к локальному видео-треку (ДО `addTrack` в
/// `RTCPeerConnection`). Native-код живёт в:
///   * Android: `android/app/src/main/kotlin/.../VirtualBackgroundHandler.kt`
///   * iOS: `ios/Runner/VirtualBackgroundBridge.swift`
///
/// Сейчас native-обработчики регистрируют канал и логируют команды, но сам
/// пиксельный pipeline (ML Kit Selfie-Segmentation + Metal/GLES composer)
/// помечен TODO. Смена native-реализации не требует правок Dart/UI.
///
/// Стратегия подключения:
///   * По умолчанию провайдер возвращает [NoopVirtualBackgroundController],
///     чтобы исключить false-positive UX (видимый тумблер, но нет эффекта).
///   * При флаге сборки `LIGHCHAT_VIRTUAL_BG_NATIVE=true` используется этот
///     класс — UI-переключатель становится видимым, native получает команды.
class MethodChannelVirtualBackgroundController
    implements VirtualBackgroundController {
  MethodChannelVirtualBackgroundController({String channelName = _channelName})
      : _channel = MethodChannel(channelName);

  static const String _channelName = 'lighchat/virtual_background';

  final MethodChannel _channel;
  final StreamController<VirtualBackgroundModeUpdate> _stream =
      StreamController<VirtualBackgroundModeUpdate>.broadcast();

  VirtualBackgroundMode _mode = VirtualBackgroundMode.none;
  String? _path;
  bool _disposed = false;

  @override
  VirtualBackgroundMode get currentMode => _mode;

  @override
  String? get currentImageAssetPath => _path;

  @override
  Stream<VirtualBackgroundModeUpdate> get modeStream => _stream.stream;

  @override
  bool get isPlatformBacked => true;

  @override
  Future<void> setMode(
    VirtualBackgroundMode mode, {
    String? imageAssetPath,
  }) async {
    if (_disposed) return;
    if (_mode == mode && _path == imageAssetPath) return;
    try {
      await _channel.invokeMethod<void>('setMode', <String, Object?>{
        'mode': mode.wireName,
        if (imageAssetPath != null) 'imageAssetPath': imageAssetPath,
      });
    } catch (e) {
      // Native не смог применить — логируем и оставляем локальное состояние
      // в noop. UI должен обработать ошибку через Stream (мы эмитим mode=none).
      if (kDebugMode) debugPrint('[virtual-bg] native setMode failed: $e');
      _mode = VirtualBackgroundMode.none;
      _path = null;
      if (!_stream.isClosed) {
        _stream.add(
          const VirtualBackgroundModeUpdate(
            mode: VirtualBackgroundMode.none,
            imageAssetPath: null,
          ),
        );
      }
      rethrow;
    }
    _mode = mode;
    _path = imageAssetPath;
    if (!_stream.isClosed) {
      _stream.add(
        VirtualBackgroundModeUpdate(mode: mode, imageAssetPath: imageAssetPath),
      );
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    try {
      await _channel.invokeMethod<void>('dispose');
    } catch (_) {}
    await _stream.close();
  }
}

extension _VirtualBackgroundModeWire on VirtualBackgroundMode {
  String get wireName {
    switch (this) {
      case VirtualBackgroundMode.none:
        return 'none';
      case VirtualBackgroundMode.blur:
        return 'blur';
      case VirtualBackgroundMode.image:
        return 'image';
    }
  }
}
