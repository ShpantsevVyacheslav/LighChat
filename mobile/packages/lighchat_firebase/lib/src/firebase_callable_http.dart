/// Прямой HTTPS-POST к Firebase Callable Function, минуя плагин
/// `cloud_functions`.
///
/// # Зачем этот модуль
///
/// `FirebaseFunctions` iOS-SDK (12.9.0) в [`FunctionsContext.context(options:)`]
/// собирает токены тремя параллельными `async let`:
///
/// ```swift
/// async let authToken             = auth?.getToken(forcingRefresh: false)
/// async let appCheckToken         = getAppCheckToken(options: options)
/// async let limitedUseAppCheckToken = getLimitedUseAppCheckToken(options: options)
/// ```
///
/// На Release-сборках iOS Swift-рантайм в этой конструкции воспроизводимо
/// крашит процесс в `_swift_task_dealloc_specific (.cold.2)` («freed pointer
/// was not the last allocation», SIGABRT из `libsystem_pthread`). Падение
/// нативное — поймать его из Dart нельзя. Апгрейд SDK или правка `Pods/` не
/// подходят: обновления Pod перетрут fix (см. правило «No Hidden Changes»),
/// а версия SDK у нас уже последняя на момент фикса.
///
/// Обходим только точечно — для iOS-путей, где callable вызывается из
/// пользовательских сценариев с известным Release-crash риском. Android и
/// остальные платформы продолжают использовать штатный SDK.
///
/// # Контракт
///
/// Полностью повторяет стандартный протокол Firebase Callable v1/v2
/// (v2 `onCall` имеет стабильный alias `cloudfunctions.net/{name}`,
/// поэтому URL-форма одинаковая).
///
/// * Запрос:
///   `POST https://{region}-{projectId}.cloudfunctions.net/{name}`
///   headers: `Content-Type: application/json`,
///             `Authorization: Bearer {idToken}` (если пользователь залогинен)
///   body:     `{"data": <request>}`
/// * Ответ 2xx: `{"result": <response>}`
/// * Ответ 4xx/5xx: `{"error": {"status": "...", "message": "...", ...}}`
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logger/logger.dart';

/// Ошибка при прямом HTTP-вызове callable. Несёт тот же `status`-код, что
/// отдал Firebase Functions (`unauthenticated`, `invalid-argument`, `internal`
/// и т.п.), либо синтетический код для клиентской стороны.
class FirebaseCallableHttpException implements Exception {
  const FirebaseCallableHttpException({
    required this.code,
    required this.message,
    this.statusCode,
  });

  /// Firebase-style status code (`unauthenticated`, `internal`, и т.п.) или
  /// клиентский синтетический (`network`, `no-firebase-app`, `timeout`,
  /// `auth-token-failed`, `missing-project`).
  final String code;

  /// Человекочитаемое сообщение (как правило — то, что вернул Functions).
  final String message;

  /// HTTP-код, если ответ дошёл. `null` при сетевых/локальных сбоях.
  final int? statusCode;

  @override
  String toString() =>
      'FirebaseCallableHttpException($code, http=$statusCode): $message';
}

/// Вызывает Callable Function напрямую через HTTPS, используя Firebase
/// ID-token текущего пользователя (получается через нативный ObjC-колбэк
/// `FLTFirebaseAuthPlugin.getIdToken` — Swift `async let` не задействован).
///
/// Возвращает `result` из ответа (обычно `Map<String, dynamic>`).
/// При любом сбое бросает [FirebaseCallableHttpException].
///
/// [allowUnauthenticated] — для callable'ов, которые сервер сознательно
/// разрешает вызывать без auth (например, `requestQrLogin` от ещё не
/// залогиненного нового устройства). Если true и `currentUser == null`,
/// запрос идёт без `Authorization` заголовка.
Future<Object?> callFirebaseCallableHttp({
  required String name,
  required String region,
  required Map<String, dynamic> data,
  Duration timeout = const Duration(seconds: 40),
  Logger? logger,
  bool allowUnauthenticated = false,
}) async {
  final FirebaseApp app;
  try {
    app = Firebase.app();
  } catch (e, st) {
    logger?.w(
      'callFirebaseCallableHttp: no Firebase app',
      error: e,
      stackTrace: st,
    );
    throw const FirebaseCallableHttpException(
      code: 'no-firebase-app',
      message:
          'Firebase не инициализирован. Перезапустите приложение или проверьте '
          'настройки FlutterFire.',
    );
  }

  final projectId = app.options.projectId.trim();
  if (projectId.isEmpty) {
    throw const FirebaseCallableHttpException(
      code: 'missing-project',
      message: 'Firebase projectId пустой. Проверьте firebase_options.dart.',
    );
  }

  final auth = FirebaseAuth.instanceFor(app: app);
  final user = auth.currentUser;
  if (user == null && !allowUnauthenticated) {
    throw const FirebaseCallableHttpException(
      code: 'unauthenticated',
      message: 'Пользователь не авторизован.',
    );
  }

  String? idToken;
  if (user != null) {
    try {
      idToken = await user.getIdToken();
    } catch (e, st) {
      logger?.w(
        'callFirebaseCallableHttp: getIdToken failed',
        error: e,
        stackTrace: st,
      );
      throw const FirebaseCallableHttpException(
        code: 'auth-token-failed',
        message: 'Не удалось получить токен авторизации.',
      );
    }
  }

  final url = Uri.parse('https://$region-$projectId.cloudfunctions.net/$name');

  final client = HttpClient();
  client.connectionTimeout = timeout;
  try {
    final HttpClientRequest req;
    try {
      req = await client.postUrl(url).timeout(timeout);
    } on TimeoutException {
      throw const FirebaseCallableHttpException(
        code: 'timeout',
        message: 'Таймаут подключения к Cloud Function.',
      );
    } on SocketException catch (e) {
      throw FirebaseCallableHttpException(
        code: 'network',
        message: 'Нет связи: ${e.message}',
      );
    }

    req.headers.set(
      HttpHeaders.contentTypeHeader,
      'application/json; charset=UTF-8',
    );
    if (idToken != null && idToken.isNotEmpty) {
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $idToken');
    }
    req.add(utf8.encode(jsonEncode(<String, Object?>{'data': data})));

    final HttpClientResponse res;
    try {
      res = await req.close().timeout(timeout);
    } on TimeoutException {
      throw const FirebaseCallableHttpException(
        code: 'timeout',
        message: 'Таймаут ожидания ответа от Cloud Function.',
      );
    } on SocketException catch (e) {
      throw FirebaseCallableHttpException(
        code: 'network',
        message: 'Нет связи: ${e.message}',
      );
    }

    final bodyStr = await utf8.decoder
        .bind(res)
        .join()
        .timeout(timeout, onTimeout: () => '');
    Object? parsed;
    if (bodyStr.isNotEmpty) {
      try {
        parsed = jsonDecode(bodyStr);
      } catch (_) {
        parsed = null;
      }
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (parsed is Map) return parsed['result'];
      return null;
    }

    String code = 'internal';
    String message = 'HTTP ${res.statusCode}';
    if (parsed is Map && parsed['error'] is Map) {
      final err = (parsed['error'] as Map).map(
        (k, v) => MapEntry(k.toString(), v),
      );
      final s = err['status'];
      final m = err['message'];
      if (s is String && s.isNotEmpty) code = s;
      if (m is String && m.isNotEmpty) message = m;
    }
    throw FirebaseCallableHttpException(
      code: code,
      message: message,
      statusCode: res.statusCode,
    );
  } finally {
    client.close(force: false);
  }
}
