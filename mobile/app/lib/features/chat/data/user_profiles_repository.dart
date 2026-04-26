import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_profile.dart';
import 'user_profiles_disk_cache.dart';

class UserProfilesRepository {
  UserProfilesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<Map<String, UserProfile>> watchUsersByIds(List<String> userIds) {
    final ids = userIds.where((s) => s.isNotEmpty).toSet().toList()..sort();
    if (ids.isEmpty) return Stream.value(const <String, UserProfile>{});

    final controller = StreamController<Map<String, UserProfile>>();
    final byId = <String, UserProfile>{};
    final subs = <StreamSubscription<DocumentSnapshot<Map<String, Object?>>>>[];

    void publish() => controller.add(Map.unmodifiable(byId));

    unawaited((() async {
      final cached = await loadCachedProfiles(ids);
      if (controller.isClosed) return;
      if (cached.isEmpty) return;
      for (final e in cached.entries) {
        byId.putIfAbsent(e.key, () => e.value);
      }
      publish();
    })());

    for (final id in ids) {
      final ref = _firestore.collection('users').doc(id);
      subs.add(ref.snapshots().listen(
        (snap) {
          final data = snap.data();
          final profile = data == null ? null : UserProfile.fromJson(snap.id, data);
          if (profile == null) {
            byId.remove(id);
          } else {
            byId[id] = profile;
            unawaited(persistProfile(profile));
          }
          publish();
        },
        onError: (_) {
          byId.remove(id);
          publish();
        },
      ));
    }

    controller.onCancel = () async {
      for (final s in subs) {
        try {
          await s.cancel();
        } catch (_) {}
      }
    };
    scheduleMicrotask(publish);
    return controller.stream;
  }

  /// One-shot reads for a small id set (e.g. device sync eligibility). Avoids
  /// [listAllUsers] which does not scale.
  Future<Map<String, UserProfile>> getUsersByIdsOnce(
    Iterable<String> userIds,
  ) async {
    final ids = userIds.map((s) => s.trim()).where((s) => s.isNotEmpty).toSet();
    if (ids.isEmpty) return const {};
    final out = <String, UserProfile>{};
    await Future.wait(ids.map((id) async {
      try {
        final snap = await _firestore.collection('users').doc(id).get();
        if (!snap.exists) return;
        final data = snap.data();
        final p = data == null ? null : UserProfile.fromJson(snap.id, data);
        if (p != null) out[id] = p;
      } catch (_) {
        // Skip missing/forbidden docs; caller treats as absent.
      }
    }));
    return Map.unmodifiable(out);
  }

  Future<List<UserProfile>> listAllUsers() async {
    final snap = await _firestore.collection('users').get();
    return snap.docs
        .map((d) => UserProfile.fromJson(d.id, d.data()))
        .whereType<UserProfile>()
        .toList(growable: false);
  }
}

