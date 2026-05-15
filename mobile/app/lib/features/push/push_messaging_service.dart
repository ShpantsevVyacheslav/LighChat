import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:lighchat_firebase/lighchat_firebase.dart';

import '../../app_router.dart';
import '../chat/data/message_notification_player.dart';
import 'push_foreground_suppression.dart';
import 'push_local_notifications_facade.dart';
import 'push_native_call_service.dart';
import 'push_notification_payload.dart';
import 'push_runtime_flags.dart';

/// Регистрация FCM-токена в `users.fcmTokens` (как web `use-notifications`).
class PushMessagingService {
  PushMessagingService._();
  static final PushMessagingService instance = PushMessagingService._();

  String? _activeUid;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onOpenSub;
  StreamSubscription<String>? _tokenRefreshSub;

  Future<void> _saveFcmToken(String uid, String token) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      <String, Object?>{
        'fcmTokens': FieldValue.arrayUnion(<String>[token]),
      },
      SetOptions(merge: true),
    );
  }

  void _navigateFromData(Map<String, dynamic> data) {
    final flat = data.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    final callId = callIdFromPushData(flat);
    if (callId != null && callId.isNotEmpty) {
      appGoRouterRef?.go('/calls/incoming/$callId');
      return;
    }
    final cid = conversationIdFromPushData(flat);
    if (cid != null && cid.isNotEmpty) {
      appGoRouterRef?.go('/chats/$cid');
    }
  }

  void _applyPayloadNavigation(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        final m = decoded.map((k, v) => MapEntry(k.toString(), v));
        _navigateFromData(m);
      }
    } catch (_) {}
  }

  Future<void> _maybeShowForeground(RemoteMessage message, String uid) async {
    final flat = message.data.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    final handledByNativeCallUi = await PushNativeCallService.instance
        .showIncomingFromData(flat);
    if (handledByNativeCallUi) {
      return;
    }
    final convId = conversationIdFromPushData(flat);
    bool playCustomRingtone = false;
    String? customRingtoneId;
    try {
      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final userData = Map<String, dynamic>.from(
        userSnap.data() ?? const <String, dynamic>{},
      );
      Map<String, dynamic>? chatPrefs;
      if (convId != null && convId.isNotEmpty) {
        final prefSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('chatConversationPrefs')
            .doc(convId)
            .get();
        if (prefSnap.exists) {
          chatPrefs = prefSnap.data()?.map((k, v) => MapEntry(k.toString(), v));
        }
      }
      if (shouldSuppressForegroundChatPush(
        userData: userData,
        chatPrefs: chatPrefs,
      )) {
        return;
      }
      final ns = userData['notificationSettings'];
      if (ns is Map) {
        final soundEnabled = ns['soundEnabled'] != false;
        final backendSilent = flat['silent'] == '1' || flat['silent'] == 'true';
        if (soundEnabled && !backendSilent) {
          final rid = ns['messageRingtoneId'];
          customRingtoneId = rid is String && rid.isNotEmpty ? rid : null;
          playCustomRingtone = true;
        }
      }
    } catch (_) {
      // при ошибке чтения — показываем уведомление
    }
    await PushLocalNotificationsFacade.showFromRemoteMessage(
      message,
      forceSilent: playCustomRingtone,
    );
    if (playCustomRingtone) {
      unawaited(
        MessageNotificationPlayer.instance.play(ringtoneId: customRingtoneId),
      );
    }
  }

  Future<void> start({required String uid}) async {
    if (kIsWeb || !isFirebaseReady()) return;
    if (!iosPushRuntimeEnabled) return;
    if (_activeUid == uid && _onMessageSub != null) return;

    await _onMessageSub?.cancel();
    await _onOpenSub?.cancel();
    await _tokenRefreshSub?.cancel();
    _onMessageSub = null;
    _onOpenSub = null;
    _tokenRefreshSub = null;
    _activeUid = uid;
    PushNativeCallService.instance.setActiveUserUid(uid);
    await PushNativeCallService.instance.ensureInitialized();
    PushNativeCallService.instance.flushDeferredNavigation();

    await PushLocalNotificationsFacade.initializeMain(
      onNotificationTap: _applyPayloadNavigation,
    );

    final launchPayload = await PushLocalNotificationsFacade.getLaunchPayload();
    if (launchPayload != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyPayloadNavigation(launchPayload);
      });
    }

    final messaging = FirebaseMessaging.instance;
    await messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: false,
    );

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    try {
      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _saveFcmToken(uid, token);
      }
    } catch (_) {}

    _tokenRefreshSub = messaging.onTokenRefresh.listen((t) {
      if (t.isEmpty || _activeUid == null) return;
      unawaited(_saveFcmToken(_activeUid!, t));
    });

    await _onMessageSub?.cancel();
    _onMessageSub = FirebaseMessaging.onMessage.listen((m) {
      unawaited(_maybeShowForeground(m, uid));
    });

    await _onOpenSub?.cancel();
    _onOpenSub = FirebaseMessaging.onMessageOpenedApp.listen((m) {
      _navigateFromData(m.data);
    });

    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateFromData(initial.data);
      });
    }
  }

  Future<void> stop() async {
    _activeUid = null;
    await _onMessageSub?.cancel();
    _onMessageSub = null;
    await _onOpenSub?.cancel();
    _onOpenSub = null;
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    PushNativeCallService.instance.setActiveUserUid(null);
    await PushNativeCallService.instance.stop();
  }
}
