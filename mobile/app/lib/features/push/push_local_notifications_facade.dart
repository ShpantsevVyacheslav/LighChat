import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'push_notification_payload.dart';

/// Локальные уведомления для FCM data-only (как web `firebase-messaging-sw.js`).
class PushLocalNotificationsFacade {
  PushLocalNotificationsFacade._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _mainReady = false;
  static bool _bgReady = false;

  static const AndroidNotificationChannel _channelSound =
      AndroidNotificationChannel(
    'lighchat_chat',
    'Сообщения',
    description: 'Новые сообщения в чатах',
    importance: Importance.high,
  );

  static const AndroidNotificationChannel _channelSilent =
      AndroidNotificationChannel(
    'lighchat_chat_silent',
    'Сообщения без звука',
    description: 'Push без звука',
    importance: Importance.defaultImportance,
    playSound: false,
    enableVibration: false,
  );

  static Future<void> _ensureAndroidChannels() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;
    await android.createNotificationChannel(_channelSound);
    await android.createNotificationChannel(_channelSilent);
  }

  /// Основной изолят: колбэк при тапе по уведомлению.
  static Future<void> initializeMain({
    required void Function(String? payloadJson) onNotificationTap,
  }) async {
    if (_mainReady) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
        macOS: darwinInit,
      ),
      onDidReceiveNotificationResponse: (NotificationResponse r) {
        onNotificationTap(r.payload);
      },
    );
    await _ensureAndroidChannels();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
    _mainReady = true;
  }

  /// Фоновый изолят FCM (без onTap — cold start через [getLaunchPayload]).
  static Future<void> initializeBackground() async {
    if (_bgReady) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
        macOS: darwinInit,
      ),
    );
    await _ensureAndroidChannels();
    _bgReady = true;
  }

  static String _payloadJson(RemoteMessage message) {
    final m = message.data.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    final cid = conversationIdFromPushData(m);
    return jsonEncode(<String, String?>{
      'conversationId': cid,
      'link': m['link'],
    });
  }

  static int _notificationId(RemoteMessage message) {
    final mid = message.messageId;
    if (mid != null && mid.isNotEmpty) {
      return mid.hashCode & 0x7fffffff;
    }
    return DateTime.now().millisecondsSinceEpoch & 0x7fffffff;
  }

  static Future<void> showFromRemoteMessage(RemoteMessage message) async {
    final m = message.data.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    final title = m['title']?.isNotEmpty == true ? m['title']! : 'LighChat';
    final body = m['body'] ?? '';
    final silent = m['silent'] == '1' || m['silent'] == 'true';
    final channelId =
        silent ? _channelSilent.id : _channelSound.id;

    final android = AndroidNotificationDetails(
      channelId,
      silent ? _channelSilent.name : _channelSound.name,
      channelDescription:
          silent ? _channelSilent.description : _channelSound.description,
      importance: silent ? Importance.defaultImportance : Importance.high,
      priority: silent ? Priority.low : Priority.high,
      playSound: !silent,
      enableVibration: !silent,
    );

    final darwin = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: !silent,
    );

    await _plugin.show(
      id: _notificationId(message),
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: android,
        iOS: darwin,
        macOS: darwin,
      ),
      payload: _payloadJson(message),
    );
  }

  /// Cold start: приложение открыто тапом по локальному уведомлению.
  static Future<String?> getLaunchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return null;
    return details!.notificationResponse?.payload;
  }
}
