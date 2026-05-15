import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

/// Кэш последней замеренной высоты системной клавиатуры в dp.
///
/// Нужен, чтобы при ПЕРВОМ открытии панели стикеров (когда клавиатура ещё
/// не поднималась в этой сессии) шторка имела правильную высоту, совпадающую
/// с реальной клавиатурой iOS. Без этого кэша приходилось ставить fallback
/// `mq.size.height * 0.42`, который немного выше реальной iOS-клавиатуры,
/// и шторка визуально «торчала» над клавиатурой при первом открытии.
class KeyboardHeightCache {
  KeyboardHeightCache._();
  static final KeyboardHeightCache instance = KeyboardHeightCache._();

  static const _key = 'chat.last_keyboard_height_dp';

  double? _cached;
  Future<double?>? _inflight;

  /// Возвращает сохранённую высоту (dp) или null, если ничего не запоминалось.
  Future<double?> read() async {
    final c = _cached;
    if (c != null) return c;
    final pending = _inflight;
    if (pending != null) return pending;
    final fut = _readImpl();
    _inflight = fut;
    try {
      final v = await fut;
      _cached = v;
      return v;
    } finally {
      _inflight = null;
    }
  }

  Future<double?> _readImpl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getDouble(_key);
      return (v != null && v > 0) ? v : null;
    } catch (_) {
      return null;
    }
  }

  /// Записывает новую высоту. Перезаписывает только если новое значение
  /// заметно отличается от сохранённого — fingerprint клавиатуры на одном
  /// устройстве стабилен.
  Future<void> write(double heightDp) async {
    if (heightDp <= 0) return;
    final prev = _cached ?? await read();
    if (prev != null && (prev - heightDp).abs() < 1.0) return;
    _cached = heightDp;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_key, heightDp);
    } catch (_) {}
  }
}
