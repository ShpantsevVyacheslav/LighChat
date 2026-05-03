import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

import '../../app_router.dart';
import '../../l10n/app_localizations.dart';
import 'push_notification_payload.dart';

/// Native incoming-call UI bridge (Android full-screen / iOS CallKit wrapper).
///
/// Phase 1: driven by current FCM call payload (`callId`) to provide
/// system-level incoming call affordances and actions (accept/decline).
class PushNativeCallService {
  PushNativeCallService._();
  static final PushNativeCallService instance = PushNativeCallService._();

  StreamSubscription<CallEvent?>? _eventSub;
  bool _eventsBound = false;
  final Map<String, String> _callIdByCallkitId = <String, String>{};
  String? _deferredOpenCallId;
  String? _activeUid;
  String? _lastVoipToken;

  String _callkitIdFromCallId(String callId) {
    final hash = md5.convert(utf8.encode(callId)).toString();
    return '${hash.substring(0, 8)}-${hash.substring(8, 12)}-${hash.substring(12, 16)}-${hash.substring(16, 20)}-${hash.substring(20, 32)}';
  }

  Future<void> ensureInitialized() async {
    if (kIsWeb || _eventsBound) return;
    _eventsBound = true;
    _eventSub = FlutterCallkitIncoming.onEvent.listen(
      (event) => unawaited(_handleEvent(event)),
      onError: (_) {},
    );
    try {
      final l10n = lookupAppLocalizations(PlatformDispatcher.instance.locale);
      await FlutterCallkitIncoming.requestNotificationPermission(
        <String, dynamic>{
          'title': l10n.push_notification_title,
          'rationaleMessagePermission': l10n.push_notification_rationale,
          'postNotificationMessageRequired': l10n.push_notification_required,
          'actionGranted': l10n.push_notification_grant,
          'actionDenied': l10n.common_cancel,
        },
      );
    } catch (_) {}
    try {
      await FlutterCallkitIncoming.requestFullIntentPermission();
    } catch (_) {}
    await _syncCurrentVoipToken();
  }

  Future<void> stop() async {
    await _eventSub?.cancel();
    _eventSub = null;
    _eventsBound = false;
    _activeUid = null;
    _lastVoipToken = null;
  }

  void flushDeferredNavigation() {
    final callId = _deferredOpenCallId;
    if (callId == null || callId.trim().isEmpty) return;
    if (appGoRouterRef == null) return;
    _deferredOpenCallId = null;
    appGoRouterRef?.go('/calls/incoming/$callId');
  }

  void setActiveUserUid(String? uid) {
    final prevUid = _activeUid;
    final prevToken = _lastVoipToken;
    _activeUid = uid?.trim().isEmpty ?? true ? null : uid?.trim();
    final nextUid = _activeUid;
    if (prevUid != null &&
        prevToken != null &&
        prevToken.isNotEmpty &&
        prevUid != nextUid) {
      unawaited(
        FirebaseFirestore.instance.collection('users').doc(prevUid).set(
          <String, Object?>{
            'voipTokens': FieldValue.arrayRemove(<String>[prevToken]),
          },
          SetOptions(merge: true),
        ),
      );
    }
    if (nextUid == null) {
      _lastVoipToken = null;
      return;
    }
    unawaited(_syncCurrentVoipToken());
  }

  Future<bool> showIncomingFromData(Map<String, dynamic> rawData) async {
    if (kIsWeb) return false;
    final data = rawData.map((k, v) => MapEntry(k.toString(), v));
    final callId = callIdFromPushData(data);
    if (callId == null || callId.trim().isEmpty) return false;

    await ensureInitialized();

    final cleanCallId = callId.trim();
    final callkitId = _callkitIdFromCallId(cleanCallId);
    _callIdByCallkitId[callkitId] = cleanCallId;

    final callerName = callerNameFromPushData(data);
    final isVideo = isVideoCallFromPushData(data);

    final l10n = lookupAppLocalizations(PlatformDispatcher.instance.locale);

    final params = CallKitParams(
      id: callkitId,
      nameCaller: callerName,
      appName: 'LighChat',
      handle: callerName,
      type: isVideo ? 1 : 0,
      normalHandle: 1,
      duration: 45000,
      textAccept: l10n.push_call_accept,
      textDecline: l10n.push_call_decline,
      extra: <String, dynamic>{
        'callId': cleanCallId,
        'callkitId': callkitId,
        'isVideo': isVideo ? '1' : '0',
      },
      headers: <String, dynamic>{'callId': cleanCallId},
      android: AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'ringtone_default',
        backgroundColor: '#0F172A',
        actionColor: '#38BDF8',
        textColor: '#FFFFFF',
        incomingCallNotificationChannelName: l10n.push_channel_incoming_calls,
        missedCallNotificationChannelName: l10n.push_channel_missed_calls,
        isShowFullLockedScreen: true,
        isImportant: true,
      ),
      ios: const IOSParams(
        iconName: 'AppIcon',
        handleType: 'generic',
        supportsVideo: true,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: false,
        supportsHolding: false,
        supportsGrouping: false,
        supportsUngrouping: false,
      ),
    );

    try {
      await FlutterCallkitIncoming.showCallkitIncoming(params);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _handleEvent(CallEvent? event) async {
    if (event == null) return;
    final body = event.body is Map
        ? Map<String, dynamic>.from(event.body as Map)
        : const <String, dynamic>{};

    final callId = _extractCallId(body);
    final callkitId =
        _extractCallkitId(body) ??
        (callId == null || callId.isEmpty
            ? null
            : _callkitIdFromCallId(callId));

    switch (event.event) {
      case Event.actionDidUpdateDevicePushTokenVoip:
        await _updateVoipTokenForActiveUser(_extractVoipToken(body));
        break;
      case Event.actionCallAccept:
      case Event.actionCallStart:
      case Event.actionCallConnected:
        if (callkitId != null) {
          try {
            await FlutterCallkitIncoming.endCall(callkitId);
          } catch (_) {}
          _callIdByCallkitId.remove(callkitId);
        }
        _openIncomingCallRoute(callId);
        break;
      case Event.actionCallDecline:
      case Event.actionCallEnded:
      case Event.actionCallTimeout:
        if (callId != null && callId.isNotEmpty) {
          await _markCallRejectedOrEnded(callId);
        }
        if (callkitId != null) {
          _callIdByCallkitId.remove(callkitId);
        }
        break;
      default:
        break;
    }
  }

  String? _extractCallId(Map<String, dynamic> body) {
    String? pick(dynamic value) {
      if (value == null) return null;
      final t = value.toString().trim();
      if (t.isEmpty) return null;
      return t;
    }

    final direct = pick(body['callId']);
    if (direct != null) return direct;

    final extraRaw = body['extra'];
    if (extraRaw is Map) {
      final extra = Map<String, dynamic>.from(extraRaw);
      final fromExtra = pick(extra['callId']);
      if (fromExtra != null) return fromExtra;
    }

    final headersRaw = body['headers'];
    if (headersRaw is Map) {
      final headers = Map<String, dynamic>.from(headersRaw);
      final fromHeaders = pick(headers['callId']);
      if (fromHeaders != null) return fromHeaders;
    }

    final callkitId = _extractCallkitId(body);
    if (callkitId != null) {
      return _callIdByCallkitId[callkitId];
    }
    return null;
  }

  String? _extractCallkitId(Map<String, dynamic> body) {
    final raw = body['id'];
    if (raw == null) return null;
    final t = raw.toString().trim();
    if (t.isEmpty) return null;
    return t;
  }

  String? _extractVoipToken(Map<String, dynamic> body) {
    String? pick(dynamic value) {
      if (value == null) return null;
      final t = value.toString().trim();
      if (t.isEmpty) return null;
      return t;
    }

    final direct = pick(body['deviceTokenVoIP']);
    if (direct != null) return direct;
    final lower = pick(body['deviceTokenVoip']);
    if (lower != null) return lower;
    return pick(body['token']);
  }

  void _openIncomingCallRoute(String? callId) {
    if (callId == null || callId.trim().isEmpty) return;
    final path = '/calls/incoming/${callId.trim()}';
    if (appGoRouterRef == null) {
      _deferredOpenCallId = callId.trim();
      return;
    }
    appGoRouterRef?.go(path);
  }

  Future<void> _markCallRejectedOrEnded(String callId) async {
    try {
      final ref = FirebaseFirestore.instance.collection('calls').doc(callId);
      final snap = await ref.get();
      if (!snap.exists) return;
      final data = snap.data() ?? const <String, dynamic>{};
      final status = (data['status'] as String?) ?? '';
      if (status == 'ended' ||
          status == 'missed' ||
          status == 'cancelled' ||
          status == 'rejected') {
        return;
      }
      final callerId = (data['callerId'] as String?) ?? '';
      final actedByCaller = callerId.isNotEmpty && callerId == _activeUid;
      final nextStatus = status == 'calling'
          ? (actedByCaller ? 'missed' : 'cancelled')
          : 'ended';
      final endedBy = _activeUid;
      await ref.update(<String, Object?>{
        'status': nextStatus,
        'endedAt': DateTime.now().toUtc().toIso8601String(),
        if (endedBy != null && endedBy.isNotEmpty) 'endedBy': endedBy,
      });
    } catch (_) {}
  }

  Future<void> _syncCurrentVoipToken() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    final uid = _activeUid;
    if (uid == null || uid.isEmpty) return;
    try {
      final token = await FlutterCallkitIncoming.getDevicePushTokenVoIP();
      await _updateVoipTokenForActiveUser(token?.toString());
    } catch (_) {}
  }

  Future<void> _updateVoipTokenForActiveUser(String? rawToken) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    final uid = _activeUid;
    if (uid == null || uid.isEmpty) return;

    final token = rawToken?.trim() ?? '';
    if (token.isEmpty) {
      final prev = _lastVoipToken;
      if (prev != null && prev.isNotEmpty) {
        try {
          await FirebaseFirestore.instance.collection('users').doc(uid).set(
            <String, Object?>{
              'voipTokens': FieldValue.arrayRemove(<String>[prev]),
            },
            SetOptions(merge: true),
          );
        } catch (_) {}
      }
      _lastVoipToken = null;
      return;
    }

    if (_lastVoipToken == token) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        <String, Object?>{
          'voipTokens': FieldValue.arrayUnion(<String>[token]),
        },
        SetOptions(merge: true),
      );
      final prev = _lastVoipToken;
      if (prev != null && prev.isNotEmpty && prev != token) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set(
          <String, Object?>{
            'voipTokens': FieldValue.arrayRemove(<String>[prev]),
          },
          SetOptions(merge: true),
        );
      }
      _lastVoipToken = token;
    } catch (_) {}
  }
}
