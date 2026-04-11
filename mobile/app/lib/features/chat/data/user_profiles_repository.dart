import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_profile.dart';

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

  Future<List<UserProfile>> listAllUsers() async {
    final snap = await _firestore.collection('users').get();
    return snap.docs
        .map((d) => UserProfile.fromJson(d.id, d.data()))
        .whereType<UserProfile>()
        .toList(growable: false);
  }
}

