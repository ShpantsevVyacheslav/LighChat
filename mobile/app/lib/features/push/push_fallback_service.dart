import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:lighchat_mobile/core/app_logger.dart';
import 'push_runtime_flags.dart';

/// Подмена `firebase_messaging` на Windows/Linux, где нативного FCM SDK нет.
///
/// Серверная сторона (Cloud Function `mirrorPushToFirestore`) дублирует
/// каждый исходящий push в коллекцию `users/{uid}/incomingNotifications/{id}`
/// с тем же data-payload что и FCM. Этот сервис слушает её, показывает
/// локальное уведомление и помечает документ как доставленный, чтобы при
/// следующем подключении не было дубля.
class PushFallbackService {
  PushFallbackService._();
  static final PushFallbackService instance = PushFallbackService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _pluginInitialized = false;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  StreamSubscription<User?>? _authSub;
  String? _activeUid;

  Future<void> start() async {
    if (!pushFallbackEnabled || _authSub != null) return;
    await _ensurePluginInitialized();
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    await _authSub?.cancel();
    _authSub = null;
    _activeUid = null;
  }

  Future<void> _ensurePluginInitialized() async {
    if (_pluginInitialized) return;
    // На desktop (Windows/Linux) Android/Darwin init не используются;
    // плагин требует MIN-init, чтобы `show()` работал. Каждая из платформ
    // в `flutter_local_notifications` валидирует свой *обязательный*
    // settings-объект — пропуск приводит к
    // `Invalid argument(s): <Platform> settings must be set...`.
    await _plugin.initialize(
      settings: const InitializationSettings(
        linux: LinuxInitializationSettings(defaultActionName: 'Open LighChat'),
        windows: WindowsInitializationSettings(
          appName: 'LighChat',
          appUserModelId: 'com.lighchat.app',
          // GUID для toast activation — сгенерирован один раз и зафиксирован
          // в коде. Менять только при изменении appUserModelId.
          guid: 'a8d4f0e2-3a1b-4d6c-9f5e-7b2c8d9e0f1a',
        ),
      ),
    );
    _pluginInitialized = true;
  }

  void _onAuthChanged(User? user) {
    final nextUid = user?.uid;
    if (nextUid == _activeUid) return;
    _activeUid = nextUid;
    unawaited(_resubscribe());
  }

  Future<void> _resubscribe() async {
    await _sub?.cancel();
    _sub = null;
    final uid = _activeUid;
    if (uid == null) return;

    final query = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('incomingNotifications')
        .where('delivered', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(20);

    _sub = query.snapshots().listen(
      (snap) {
        for (final change in snap.docChanges) {
          if (change.type != DocumentChangeType.added) continue;
          unawaited(_handleDoc(change.doc));
        }
      },
      onError: (Object e, StackTrace st) {
        appLogger.w('[push-fallback] listen error', error: e);
      },
    );
  }

  Future<void> _handleDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data() ?? const <String, dynamic>{};
    final title = (data['title'] as String?)?.trim() ?? 'LighChat';
    final body = (data['body'] as String?)?.trim() ?? '';
    final payload = (data['data'] as Map?)?.cast<String, Object?>() ??
        const <String, Object?>{};

    try {
      await _plugin.show(
        id: doc.id.hashCode & 0x7FFFFFFF,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          linux: LinuxNotificationDetails(),
        ),
        payload: jsonEncode(payload),
      );
    } catch (e) {
      appLogger.w('[push-fallback] notify failed', error: e);
    }

    try {
      await doc.reference.update(<String, dynamic>{
        'delivered': true,
        'deliveredAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {/* нет прав / гонка — не критично */}
  }
}
