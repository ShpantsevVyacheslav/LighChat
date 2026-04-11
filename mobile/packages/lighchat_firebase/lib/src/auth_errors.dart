import 'package:firebase_auth/firebase_auth.dart';

/// Mirrors web error mapping in `src/hooks/use-auth.tsx`.
String friendlyAuthError(Object error) {
  if (error is FirebaseAuthException) {
    // FirebaseAuthException.code comes without `auth/` prefix on some platforms.
    final code = error.code.startsWith('auth/') ? error.code : 'auth/${error.code}';
    switch (code) {
      case 'auth/user-not-found':
      case 'auth/invalid-credential':
        return 'Неверный email или пароль.';
      case 'auth/wrong-password':
        return 'Неверный пароль.';
      case 'auth/invalid-email':
        return 'Некорректный формат email.';
      case 'auth/user-disabled':
        return 'Эта учётная запись заблокирована.';
      case 'auth/too-many-requests':
        return 'Слишком много попыток. Подождите и попробуйте снова.';
      case 'auth/network-request-failed':
        return 'Не удалось связаться с серверами входа. Проверьте интернет и VPN; на симуляторе попробуйте устройство или повторите через несколько секунд.';
      case 'auth/email-already-in-use':
        return 'Этот email уже зарегистрирован.';
      case 'auth/weak-password':
        return 'Пароль слишком простой.';
      default:
        return error.message ?? 'Ошибка авторизации.';
    }
  }
  return 'Ошибка авторизации.';
}

