import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kDeviceIdPrefsKey = 'lighchat_device_id_v1';
const Duration _kDeviceHeartbeat = Duration(seconds: 30);

class DeviceSessionFirestoreSync extends StatefulWidget {
  const DeviceSessionFirestoreSync({super.key, required this.child});

  final Widget child;

  @override
  State<DeviceSessionFirestoreSync> createState() =>
      _DeviceSessionFirestoreSyncState();
}

class _DeviceSessionFirestoreSyncState extends State<DeviceSessionFirestoreSync>
    with WidgetsBindingObserver {
  StreamSubscription<User?>? _authSub;
  Timer? _heartbeat;
  String? _activeUid;
  String? _cachedDeviceId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
    _onAuthChanged(FirebaseAuth.instance.currentUser);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _heartbeat?.cancel();
    _authSub?.cancel();
    final uid = _activeUid;
    if (uid != null) {
      unawaited(_writeDeviceSession(uid: uid, active: false));
    }
    super.dispose();
  }

  String _platformLabel() {
    if (kIsWeb) return 'flutter_web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      default:
        return 'unknown';
    }
  }

  Future<String> _deviceId() async {
    if (_cachedDeviceId != null && _cachedDeviceId!.isNotEmpty) {
      return _cachedDeviceId!;
    }
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_kDeviceIdPrefsKey);
    if (existing != null && existing.trim().isNotEmpty) {
      _cachedDeviceId = existing.trim();
      return _cachedDeviceId!;
    }
    final rnd = Random.secure();
    final suffix = List<int>.generate(
      10,
      (_) => rnd.nextInt(36),
      growable: false,
    ).map((n) => n.toRadixString(36)).join();
    final created =
        'mob_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}_$suffix';
    await prefs.setString(_kDeviceIdPrefsKey, created);
    _cachedDeviceId = created;
    return created;
  }

  Future<void> _writeDeviceSession({
    required String uid,
    required bool active,
    bool markLogin = false,
  }) async {
    try {
      final deviceId = await _deviceId();
      final now = DateTime.now().toUtc().toIso8601String();
      final firestore = FirebaseFirestore.instance;
      final userRef = firestore.collection('users').doc(uid);
      final deviceRef = userRef.collection('devices').doc(deviceId);
      final batch = firestore.batch();
      batch.set(deviceRef, <String, Object?>{
        'deviceId': deviceId,
        'platform': _platformLabel(),
        'app': 'mobile',
        'isActive': active,
        'lastSeenAt': now,
        if (markLogin) 'lastLoginAt': now,
        'updatedAt': now,
      }, SetOptions(merge: true));
      batch.set(userRef, <String, Object?>{
        'online': active,
        'lastSeen': now,
      }, SetOptions(merge: true));
      await batch.commit();
    } catch (_) {}
  }

  void _startHeartbeat(String uid) {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(_kDeviceHeartbeat, (_) {
      unawaited(_writeDeviceSession(uid: uid, active: true));
    });
  }

  void _onAuthChanged(User? user) {
    final prevUid = _activeUid;
    final nextUid = user?.uid;
    if (prevUid != null && prevUid != nextUid) {
      unawaited(_writeDeviceSession(uid: prevUid, active: false));
    }
    _activeUid = nextUid;
    _heartbeat?.cancel();
    if (nextUid == null) return;
    unawaited(_writeDeviceSession(uid: nextUid, active: true, markLogin: true));
    _startHeartbeat(nextUid);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final uid = _activeUid;
    if (uid == null) return;
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_writeDeviceSession(uid: uid, active: true));
        _startHeartbeat(uid);
        return;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _heartbeat?.cancel();
        unawaited(_writeDeviceSession(uid: uid, active: false));
        return;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
