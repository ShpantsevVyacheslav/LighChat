import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../l10n/app_localizations.dart';
import 'communication_notification_helper.dart';
import 'push_notification_payload.dart';

/// Локальные уведомления для FCM data-only (как web `firebase-messaging-sw.js`).
class PushLocalNotificationsFacade {
  PushLocalNotificationsFacade._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _mainReady = false;
  static bool _bgReady = false;

  /// Публичные id каналов (Android): см. шторку «типы уведомлений» в настройках.
  static const String channelSoundId = 'lighchat_chat';
  static const String channelSilentId = 'lighchat_chat_silent';

  static AndroidNotificationChannel get _channelSound {
    final l10n = lookupAppLocalizations(PlatformDispatcher.instance.locale);
    return AndroidNotificationChannel(
      channelSoundId,
      l10n.push_channel_messages,
      description: l10n.push_channel_messages_desc,
      importance: Importance.high,
    );
  }

  static AndroidNotificationChannel get _channelSilent {
    final l10n = lookupAppLocalizations(PlatformDispatcher.instance.locale);
    return AndroidNotificationChannel(
      channelSilentId,
      l10n.push_channel_silent,
      description: l10n.push_channel_silent_desc,
      importance: Importance.defaultImportance,
      playSound: false,
      enableVibration: false,
    );
  }

  static Future<void> _ensureAndroidChannels() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
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
            AndroidFlutterLocalNotificationsPlugin
          >()
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
    final callId = callIdFromPushData(m);
    return jsonEncode(<String, String?>{
      'conversationId': cid,
      'callId': callId,
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

  static Future<void> showFromRemoteMessage(
    RemoteMessage message, {
    bool forceSilent = false,
  }) async {
    final m = message.data.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    final title = m['title']?.isNotEmpty == true ? m['title']! : 'LighChat';
    final body = m['body'] ?? '';
    final silent = forceSilent || m['silent'] == '1' || m['silent'] == 'true';
    final channelId = silent ? _channelSilent.id : _channelSound.id;
    final conversationId = m['conversationId'] ?? '';
    final senderUid = m['senderUid'] ?? '';
    final isGroup = m['isGroup'] == '1' || m['isGroup'] == 'true';
    final avatarUrl = m['icon'] ?? '';

    // Скачиваем аватар в кэш (best-effort, ~5 секунд timeout).
    final avatarPath =
        await CommunicationNotificationHelper.downloadAvatar(avatarUrl);

    final messagingStyle =
        CommunicationNotificationHelper.buildAndroidMessagingStyle(
      senderName: title,
      body: body,
      avatarLocalPath: avatarPath,
      conversationTitle: isGroup ? null : title,
      isGroup: isGroup,
    );

    final android = AndroidNotificationDetails(
      channelId,
      silent ? _channelSilent.name : _channelSound.name,
      channelDescription: silent
          ? _channelSilent.description
          : _channelSound.description,
      importance: silent ? Importance.defaultImportance : Importance.high,
      priority: silent ? Priority.low : Priority.high,
      playSound: !silent,
      enableVibration: !silent,
      styleInformation: messagingStyle,
      // Иконка-аватар крупно слева на лок-скрине (Android 12+ pill row).
      largeIcon: avatarPath != null
          ? FilePathAndroidBitmap(avatarPath)
          : null,
    );

    final darwin = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: !silent,
      threadIdentifier: conversationId.isNotEmpty ? conversationId : null,
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

    // iOS Communication Notifications: donate intent чтобы Siri/Spotlight
    // знали о собеседнике (на лок-скрин без NSE богатая карточка не
    // докатится, но «продолжить с X» в Share Sheet / Suggestions — да).
    if (senderUid.isNotEmpty && conversationId.isNotEmpty) {
      unawaited(
        CommunicationNotificationHelper.donateIosIntent(
          senderUid: senderUid,
          senderName: title,
          avatarLocalPath: avatarPath,
          conversationId: conversationId,
          body: body,
          isGroup: isGroup,
        ),
      );
    }
  }

  /// Cold start: приложение открыто тапом по локальному уведомлению.
  static Future<String?> getLaunchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return null;
    return details!.notificationResponse?.payload;
  }
}
