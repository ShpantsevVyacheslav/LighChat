import 'dart:async';
import 'dart:io' show Platform;

import 'package:shared_preferences/shared_preferences.dart';

/// Feature flag для нативного iOS composer'а (Phase 1+2+3 готовы).
///
/// **ON по умолчанию на iOS.** Native UITextView даёт системное меню
/// Cut/Copy/Paste/Replace/AutoFill, Writing Tools (iOS 26+), диктовку,
/// QuickType bar — без него composer теряет много нативной UX. Group
/// mentions через token-rendering работают, paste-файлов из буфера
/// перехватывается через override `paste(_:)`.
///
/// Что НЕ покрыто Phase 1-3 и работает только в Flutter TextField:
///  - Bold/Italic из formatting toolbar (отключаем native когда юзер
///    активирует toolbar — Phase 4),
///  - Sticker search mode (single-line, нативная UX не нужна),
///  - Android и desktop (там вообще нет нативного аналога — fallback).
///
/// Toggle для отключения — в Chat Settings → раздел «Композер». Ключ в
/// preferences: `chat.use_native_composer`.
class NativeComposerFlag {
  NativeComposerFlag._();
  static final NativeComposerFlag instance = NativeComposerFlag._();

  static const _key = 'chat.use_native_composer';
  static const _defaultOnIos = true;

  bool? _cached;
  Future<bool>? _inflight;

  /// Дефолт для UI-toggle'а — true на iOS, false иначе.
  bool get defaultValue => Platform.isIOS ? _defaultOnIos : false;

  /// Возвращает true только на iOS И если флаг (с дефолтом) включён.
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
      return prefs.getBool(_key) ?? _defaultOnIos;
    } catch (_) {
      return _defaultOnIos;
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
