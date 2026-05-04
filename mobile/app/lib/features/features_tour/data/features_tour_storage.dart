import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Per-uid + per-device флаг показа тура «Возможности LighChat».
///
/// По образцу `FirstLoginAnimationStorage`. Отдельный ключ — чтобы тур и
/// welcome-анимация управлялись независимо: анимация показывается каждый
/// раз после нового sign-in, тур — один раз на uid + устройство.
class FeaturesTourStorage {
  static const _kPrefix = 'features_tour_shown_';

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
      return true; // В сомнительном случае не лезем поверх UI повторно.
    }
  }

  static Future<void> markShownFor(String uid) async {
    if (uid.isEmpty) return;
    _shownCache.add(uid);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key(uid), true);
    } catch (_) {}
  }

  static Future<void> markShownForCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    await markShownFor(uid);
  }

  static Future<void> clearForUid(String uid) async {
    if (uid.isEmpty) return;
    _shownCache.remove(uid);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(uid));
    } catch (_) {}
  }
}
