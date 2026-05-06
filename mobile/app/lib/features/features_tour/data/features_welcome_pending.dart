import 'package:firebase_auth/firebase_auth.dart';

/// Сессионный флаг «нужно показать `FeaturesWelcomeSheet` при следующем
/// заходе на `/chats`».
///
/// Помечается из `_AuthRefreshNotifier` на каждый успешный sign-in
/// (включая повторный логин в этот же uid после logout). Сбрасывается
/// при показе модалки. Не персистится — это in-memory состояние сессии,
/// поэтому cold-start с уже восстановленной session НЕ выставляет флаг.
class FeaturesWelcomePending {
  static bool _pending = false;

  /// Помечает, что модалка должна быть показана при следующем заходе
  /// на `/chats`. Идемпотентно — повторные вызовы безопасны.
  static void markPending() {
    _pending = true;
  }

  /// Атомарно «потребляет» флаг: возвращает `true` один раз после
  /// `markPending`, дальше — `false`, пока снова не пометят.
  static bool consume() {
    if (!_pending) return false;
    _pending = false;
    return true;
  }

  /// Сбрасывает флаг (например, при logout, чтобы повторный sign-in
  /// в тот же uid начинался с чистого состояния — это поведение уже
  /// обеспечивается тем, что `markPending()` вызывается на каждый
  /// sign-in).
  static void clear() {
    _pending = false;
  }

  /// Помечает «pending» для текущего пользователя (если есть).
  static void markPendingForCurrentUser() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      markPending();
    }
  }
}
