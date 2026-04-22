import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

/// Обёртки над callable функциями митингов.
///
/// Почему отдельный модуль: чтобы и зарегистрированный пользователь, и гость
/// (после анонимной аутентификации) вызывали их одинаково, не тянули в UI
/// детали `FirebaseFunctions.instanceFor(...)`, и можно было моков подставить
/// в тестах.
///
/// Регион совпадает с web-деплоем CF: `us-central1`.
class MeetingCallables {
  MeetingCallables({String region = 'us-central1'})
      : _functions = FirebaseFunctions.instanceFor(
          app: Firebase.app(),
          region: region,
        );

  final FirebaseFunctions _functions;

  /// Запросить доступ в приватный митинг (waiting-room).
  /// При повторном вызове заявка пересоздаётся — сервер идемпотентен.
  Future<void> requestMeetingAccess({
    required String meetingId,
    required String name,
    String? avatar,
    String? requestId,
  }) async {
    final callable = _functions.httpsCallable(
      'requestMeetingAccess',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 20)),
    );
    await callable.call<void>(<String, Object?>{
      'meetingId': meetingId,
      'name': name,
      if (avatar != null) 'avatar': avatar,
      if (requestId != null) 'requestId': requestId,
    });
  }

  /// Ответ хоста на заявку: одобрить или отклонить.
  Future<void> respondToMeetingRequest({
    required String meetingId,
    required String userId,
    required bool approve,
  }) async {
    final callable = _functions.httpsCallable(
      'respondToMeetingRequest',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 20)),
    );
    await callable.call<void>(<String, Object?>{
      'meetingId': meetingId,
      'userId': userId,
      'approve': approve,
    });
  }
}
