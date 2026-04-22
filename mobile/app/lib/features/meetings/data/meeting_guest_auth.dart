import 'package:firebase_auth/firebase_auth.dart';

/// Гостевой режим: анонимная аутентификация для пользователя, открывшего
/// публичную ссылку на митинг и не имеющего LighChat-аккаунта.
///
/// Web-эквивалент — `src/app/meetings/[meetingId]/page.tsx` (`signInAnonymously`).
/// Правила Firestore разрешают анонимному:
///   - читать `meetings/{id}`;
///   - писать свой `participants/{uid}` (для открытого митинга) или
///     `requests/{uid}` (для приватного, через callable `requestMeetingAccess`).
///
/// После выхода из митинга приложение НЕ разлогинивает гостя автоматически:
/// FirebaseAuth сохраняет анонимную сессию, чтобы при возврате на ссылку не
/// создавать новый UID. При явном desire залогиниться/зарегистрироваться —
/// клиент должен сам вызвать `signOut()`.
class MeetingGuestAuth {
  MeetingGuestAuth({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Текущий пользователь: либо уже вошедший в основной LighChat-аккаунт,
  /// либо анонимный. Если нет вообще — подписываемся анонимно.
  Future<User> ensureSignedIn() async {
    final current = _auth.currentUser;
    if (current != null) return current;
    final cred = await _auth.signInAnonymously();
    final user = cred.user;
    if (user == null) {
      throw StateError('signInAnonymously returned null user');
    }
    return user;
  }

  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? false;
}
