import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../app_router.dart';

/// Fallback incoming-call navigation when the app is already open.
///
/// This covers the case when system push/CallKit delivery is unavailable:
/// we still observe `calls` and open `/calls/incoming/:callId` for the callee.
class InAppIncomingCallScope extends ConsumerStatefulWidget {
  const InAppIncomingCallScope({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<InAppIncomingCallScope> createState() =>
      _InAppIncomingCallScopeState();
}

class _InAppIncomingCallScopeState
    extends ConsumerState<InAppIncomingCallScope> {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _callsSub;
  String? _activeUid;
  String? _lastOpenedCallId;
  DateTime? _lastOpenedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFromAuth());
  }

  @override
  void dispose() {
    _callsSub?.cancel();
    _callsSub = null;
    super.dispose();
  }

  void _syncFromAuth() {
    ref
        .read(authUserProvider)
        .when(
          data: (user) => _bindForUser(user?.uid),
          loading: () {},
          error: (_, _) => _bindForUser(null),
        );
  }

  Future<void> _bindForUser(String? uid) async {
    final nextUid = uid?.trim();
    if ((_activeUid == nextUid) &&
        ((_activeUid == null && _callsSub == null) ||
            (_activeUid != null && _callsSub != null))) {
      return;
    }

    await _callsSub?.cancel();
    _callsSub = null;
    _activeUid = nextUid;

    if (kIsWeb || nextUid == null || nextUid.isEmpty) {
      return;
    }

    _callsSub = FirebaseFirestore.instance
        .collection('calls')
        .where('receiverId', isEqualTo: nextUid)
        .snapshots()
        .listen(_handleCallsSnapshot);
  }

  DateTime _parseCreatedAt(Map<String, dynamic> data) {
    final raw = data['createdAt'];
    if (raw is Timestamp) return raw.toDate().toUtc();
    if (raw is String) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return parsed.toUtc();
    }
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  bool _isActiveIncomingStatus(String status) {
    return status == 'calling' || status == 'ongoing';
  }

  void _handleCallsSnapshot(QuerySnapshot<Map<String, dynamic>> snap) {
    final uid = _activeUid;
    if (uid == null || uid.isEmpty) return;
    if (appGoRouterRef == null) return;

    final activeIncoming =
        snap.docs.where((doc) {
          final data = doc.data();
          final status = ((data['status'] as String?) ?? '')
              .trim()
              .toLowerCase();
          if (!_isActiveIncomingStatus(status)) return false;
          final callerId = ((data['callerId'] as String?) ?? '').trim();
          return callerId.isNotEmpty && callerId != uid;
        }).toList()..sort((a, b) {
          final ta = _parseCreatedAt(a.data());
          final tb = _parseCreatedAt(b.data());
          return tb.compareTo(ta);
        });

    if (activeIncoming.isEmpty) return;
    final callId = activeIncoming.first.id.trim();
    if (callId.isEmpty) return;

    final currentPath =
        appGoRouterRef?.routeInformationProvider.value.uri.path ?? '';
    if (currentPath == '/calls/incoming/$callId') return;

    final now = DateTime.now().toUtc();
    final lastId = _lastOpenedCallId;
    final lastAt = _lastOpenedAt;
    if (lastId == callId &&
        lastAt != null &&
        now.difference(lastAt) < const Duration(seconds: 2)) {
      return;
    }

    _lastOpenedCallId = callId;
    _lastOpenedAt = now;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      appGoRouterRef?.go('/calls/incoming/$callId');
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authUserProvider, (previous, next) {
      next.when(
        data: (user) => unawaited(_bindForUser(user?.uid)),
        loading: () {},
        error: (_, _) => unawaited(_bindForUser(null)),
      );
    });
    return widget.child;
  }
}
