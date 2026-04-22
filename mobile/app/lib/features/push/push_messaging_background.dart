import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import 'push_local_notifications_facade.dart';

/// Top-level для `FirebaseMessaging.onBackgroundMessage` (отдельный изолят).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kIsWeb) return;
  if (Firebase.apps.isEmpty) {
    try {
      final opts = DefaultFirebaseOptions.currentPlatform;
      if (opts.appId.contains(':web:')) return;
      await Firebase.initializeApp(options: opts);
    } catch (_) {
      return;
    }
  }
  await PushLocalNotificationsFacade.initializeBackground();
  await PushLocalNotificationsFacade.showFromRemoteMessage(message);
}
