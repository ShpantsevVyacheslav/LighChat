import 'dart:async';

import 'package:flutter/foundation.dart';

/// Режим виртуального фона.
///
/// Совместимость с web (`src/lib/webrtc/virtual-background.ts`):
/// те же три состояния, но mobile хранит выбор локально и не зеркалит его в
/// Firestore — фон клиент-локален и не влияет на wire-протокол.
enum VirtualBackgroundMode { none, blur, image }

/// Контроллер виртуального фона для mobile-митинга.
///
/// Архитектурный смысл — изолировать UI/WebRTC-слой от конкретной
/// реализации (noop / MethodChannel / будущий native ML-pipeline).
///
/// Правила Firestore и wire-протокол не меняются: фон применяется к
/// локальному видео-треку ДО `RTCPeerConnection.addTrack`. Удалённые клиенты
/// видят уже готовый композит.
///
/// Текущая реализация каркаса:
///   * [NoopVirtualBackgroundController] — по умолчанию, ничего не делает;
///   * [MethodChannelVirtualBackgroundController] — транслирует команды в
///     native-слой (iOS / Android). Сам ML-pipeline на нативной стороне
///     делается отдельными PR (см. `docs/mobile/meetings-virtual-background.md`).
///
/// Контракт:
///   * [setMode] — идемпотентная; повторный вызов с тем же аргументом должен
///     быть no-op с точки зрения native (чтобы UI дребезг не пересоздавал pipeline).
///   * [imageAssetPath] — путь к локальному ассету (например, «assets/bg1.jpg»);
///     для `.blur` / `.none` игнорируется.
///   * [currentMode] — синхронное чтение последнего применённого режима.
///   * [modeStream] — broadcast-стрим обновлений для UI.
abstract class VirtualBackgroundController {
  VirtualBackgroundMode get currentMode;
  String? get currentImageAssetPath;
  Stream<VirtualBackgroundModeUpdate> get modeStream;

  /// Включено ли native-взаимодействие: если `false`, UI-переключатель должен
  /// быть скрыт (noop-контроллер только занимает место).
  bool get isPlatformBacked;

  Future<void> setMode(VirtualBackgroundMode mode, {String? imageAssetPath});

  Future<void> dispose();
}

/// Событие смены режима для подписок UI.
class VirtualBackgroundModeUpdate {
  const VirtualBackgroundModeUpdate({
    required this.mode,
    required this.imageAssetPath,
  });

  final VirtualBackgroundMode mode;
  final String? imageAssetPath;
}

/// Реализация по умолчанию: ничего не делает, UI-переключатель скрыт.
///
/// Выбирается провайдером, пока нет собранной native-библиотеки с
/// ML-сегментацией. Гарантия: поведение митинга идентично предыдущей версии
/// (zero regression).
class NoopVirtualBackgroundController implements VirtualBackgroundController {
  NoopVirtualBackgroundController();

  final StreamController<VirtualBackgroundModeUpdate> _controller =
      StreamController<VirtualBackgroundModeUpdate>.broadcast();

  VirtualBackgroundMode _mode = VirtualBackgroundMode.none;
  String? _path;
  bool _disposed = false;

  @override
  VirtualBackgroundMode get currentMode => _mode;

  @override
  String? get currentImageAssetPath => _path;

  @override
  Stream<VirtualBackgroundModeUpdate> get modeStream => _controller.stream;

  @override
  bool get isPlatformBacked => false;

  @override
  Future<void> setMode(
    VirtualBackgroundMode mode, {
    String? imageAssetPath,
  }) async {
    if (_disposed) return;
    if (_mode == mode && _path == imageAssetPath) return;
    _mode = mode;
    _path = imageAssetPath;
    if (!_controller.isClosed) {
      _controller.add(
        VirtualBackgroundModeUpdate(mode: mode, imageAssetPath: imageAssetPath),
      );
    }
    if (kDebugMode) {
      debugPrint('[virtual-bg] noop setMode($mode, $imageAssetPath)');
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _controller.close();
  }
}
