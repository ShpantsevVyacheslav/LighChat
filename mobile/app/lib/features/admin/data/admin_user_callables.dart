import 'package:cloud_functions/cloud_functions.dart';

/// Cloud Functions для управления пользователями. Имена совпадают с теми,
/// что вызывает web (`src/actions/admin.ts`), чтобы серверная логика
/// была общей.
class AdminUserCallables {
  AdminUserCallables({String region = 'us-central1'})
    : _functions = FirebaseFunctions.instanceFor(region: region);

  final FirebaseFunctions _functions;

  /// Заблокировать пользователя. Принимает причину и опциональный
  /// timestamp `until`. Аналог `UserBlockDialog.onBlock`.
  Future<void> blockUser({
    required String uid,
    required String reason,
    DateTime? until,
  }) async {
    final callable = _functions.httpsCallable('adminBlockUser');
    await callable.call<dynamic>({
      'uid': uid,
      'reason': reason,
      if (until != null) 'until': until.toUtc().toIso8601String(),
    });
  }

  Future<void> unblockUser(String uid) async {
    final callable = _functions.httpsCallable('adminUnblockUser');
    await callable.call<dynamic>({'uid': uid});
  }

  /// Сбросить пароль пользователя. Отправляет письмо со ссылкой или,
  /// если на бэке настроено, выставляет временный пароль и возвращает его.
  Future<String?> resetPassword(String uid) async {
    final callable = _functions.httpsCallable('adminResetPassword');
    final res = await callable.call<dynamic>({'uid': uid});
    final data = res.data;
    if (data is Map && data['temporaryPassword'] is String) {
      return data['temporaryPassword'] as String;
    }
    return null;
  }

  /// Завершить все активные сессии пользователя (revoke refresh tokens).
  Future<void> revokeSessions(String uid) async {
    final callable = _functions.httpsCallable('adminRevokeSessions');
    await callable.call<dynamic>({'uid': uid});
  }
}
