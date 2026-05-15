import 'dart:async';
import 'dart:io' show Platform;

import 'package:shared_preferences/shared_preferences.dart';

/// Feature flag для нативного iOS composer'а (Phase 1).
///
/// **OFF по умолчанию.** Пока нативный путь не достиг feature-parity с
/// Flutter `TextField` (mentions, formatting toolbar, attach-paste,
/// sticker keyboard accessory) — основной путь остаётся Flutter. Toggle
/// нужен для разработки и QA на устройстве.
///
/// Включается из debug-меню или через ручную правку preferences (ключ
/// `chat.use_native_composer`).
class NativeComposerFlag {
  NativeComposerFlag._();
  static final NativeComposerFlag instance = NativeComposerFlag._();

  static const _key = 'chat.use_native_composer';

  bool? _cached;
  Future<bool>? _inflight;

  /// Возвращает true только на iOS И если флаг явно включён.
  Future<bool> isEnabled() async {
    if (!Platform.isIOS) return false;
    final c = _cached;
    if (c != null) return c;
    final pending = _inflight;
    if (pending != null) return pending;
    final fut = _read();
    _inflight = fut;
    try {
      final v = await fut;
      _cached = v;
      return v;
    } finally {
      _inflight = null;
    }
  }

  Future<bool> _read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_key) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> setEnabled(bool value) async {
    _cached = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, value);
    } catch (_) {}
  }
}
