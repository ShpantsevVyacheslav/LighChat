import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lighchat_models/lighchat_models.dart';

import '../data/live_location_utils.dart';

const int _kLiveLocationThrottleMs = 15000;

/// Паритет `LiveLocationProvider.tsx`: при активной `users/{uid}.liveLocationShare`
/// подписка на геопозицию с троттлингом записи в Firestore ~15 с.
class LiveLocationFirestoreSync extends StatefulWidget {
  const LiveLocationFirestoreSync({super.key, required this.child});

  final Widget child;

  @override
  State<LiveLocationFirestoreSync> createState() =>
      _LiveLocationFirestoreSyncState();
}

class _LiveLocationFirestoreSyncState extends State<LiveLocationFirestoreSync> {
  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSub;
  StreamSubscription<Position>? _posSub;
  String? _uid;
  String? _watchStartedAt;
  int _lastWriteMs = 0;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((_) {
      if (mounted) _restartUserDocListener();
    });
    _restartUserDocListener();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _userDocSub?.cancel();
    _posSub?.cancel();
    super.dispose();
  }

  void _restartUserDocListener() {
    _userDocSub?.cancel();
    _userDocSub = null;
    _stopPositionWatch(clearStartedAt: true);
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) {
      _uid = null;
      return;
    }
    _uid = u.uid;
    _userDocSub = FirebaseFirestore.instance
        .collection('users')
        .doc(u.uid)
        .snapshots()
        .listen(_onUserDocument, onError: (_) {});
  }

  void _stopPositionWatch({bool clearStartedAt = false}) {
    _posSub?.cancel();
    _posSub = null;
    if (clearStartedAt) _watchStartedAt = null;
  }

  Future<void> _clearExpiredShare(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update(
        <String, Object?>{'liveLocationShare': FieldValue.delete()},
      );
    } catch (_) {}
  }

  void _onUserDocument(DocumentSnapshot<Map<String, dynamic>> snap) {
    final uid = _uid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final data = snap.data();
    final share = UserLiveLocationShare.fromJson(data?['liveLocationShare']);

    if (share == null || !share.active) {
      _stopPositionWatch(clearStartedAt: true);
      return;
    }

    if (isLiveShareExpired(share)) {
      _stopPositionWatch(clearStartedAt: true);
      unawaited(_clearExpiredShare(uid));
      return;
    }

    if (_watchStartedAt != share.startedAt) {
      _watchStartedAt = share.startedAt;
      _lastWriteMs = 0;
      _startPositionWatch(uid);
    }
  }

  void _startPositionWatch(String uid) {
    _posSub?.cancel();
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(
      (pos) async {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        final raw = snap.data()?['liveLocationShare'];
        final share = UserLiveLocationShare.fromJson(raw);
        if (share == null || !share.active || isLiveShareExpired(share)) {
          if (mounted) {
            _stopPositionWatch(clearStartedAt: true);
          }
          if (share != null && isLiveShareExpired(share)) {
            await _clearExpiredShare(uid);
          }
          return;
        }

        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - _lastWriteMs < _kLiveLocationThrottleMs) return;
        _lastWriteMs = now;

        final acc = pos.accuracy;
        final payload = <String, Object?>{
          'liveLocationShare.lat': pos.latitude,
          'liveLocationShare.lng': pos.longitude,
          'liveLocationShare.updatedAt':
              DateTime.now().toUtc().toIso8601String(),
        };
        if (acc.isFinite) {
          payload['liveLocationShare.accuracyM'] = acc;
        }
        try {
          await FirebaseFirestore.instance.collection('users').doc(uid).update(
                payload,
              );
        } catch (_) {}
      },
      onError: (_) {},
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
