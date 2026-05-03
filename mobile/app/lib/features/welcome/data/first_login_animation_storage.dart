import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Per-uid + per-device флаг показа welcome-анимации.
///
/// Хранится локально в [SharedPreferences]: ключ
/// `first_login_animation_shown_<uid>`. На новом устройстве (или для нового
/// uid на том же устройстве) флага нет, и анимация будет показана.
class FirstLoginAnimationStorage {
  static const _kPrefix = 'first_login_animation_shown_';

  // In-memory кэш, чтобы redirect-колбэк роутера не ходил в SharedPreferences
  // на каждую навигацию.
  static final Set<String> _shownCache = <String>{};

  static String _key(String uid) => '$_kPrefix$uid';

  static Future<bool> isShownFor(String uid) async {
    if (uid.isEmpty) return true;
    if (_shownCache.contains(uid)) return true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final shown = prefs.getBool(_key(uid)) ?? false;
      if (shown) _shownCache.add(uid);
      return shown;
    } catch (_) {
      // Если SharedPreferences недоступен — лучше показать анимацию
      // (худший случай: показ дважды).
      return false;
    }
  }

  static Future<void> markShownFor(String uid) async {
    if (uid.isEmpty) return;
    _shownCache.add(uid);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key(uid), true);
    } catch (_) {
      // swallow — повторный показ приемлем.
    }
  }

  /// Сбрасывает флаг для текущего пользователя. Используется debug-only
  /// репеатом из настроек.
  static Future<void> clearForCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    _shownCache.remove(uid);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(uid));
    } catch (_) {}
  }
}
