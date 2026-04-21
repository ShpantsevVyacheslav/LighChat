import 'package:cloud_firestore/cloud_firestore.dart';

/// `userContacts/{userId}` — same shape as web `UserContactsIndex`.
class UserContactsIndex {
  const UserContactsIndex({required this.contactIds});

  final List<String> contactIds;

  static UserContactsIndex fromSnapshot(
    DocumentSnapshot<Map<String, Object?>> snap,
  ) {
    if (!snap.exists) return const UserContactsIndex(contactIds: <String>[]);
    final data = snap.data();
    final raw = data?['contactIds'];
    final ids = (raw is List ? raw : const <Object?>[])
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
    return UserContactsIndex(contactIds: ids);
  }
}

class UserContactsRepository {
  UserContactsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<UserContactsIndex> watchContacts(String userId) {
    if (userId.isEmpty) {
      return Stream.value(const UserContactsIndex(contactIds: <String>[]));
    }
    return _firestore
        .collection('userContacts')
        .doc(userId)
        .snapshots()
        .map(UserContactsIndex.fromSnapshot);
  }

  Future<UserContactsIndex> getContacts(String userId) async {
    if (userId.isEmpty) return const UserContactsIndex(contactIds: <String>[]);
    final snap = await _firestore.collection('userContacts').doc(userId).get();
    return UserContactsIndex.fromSnapshot(snap);
  }

  /// Как web `addContactId` (`arrayUnion`).
  Future<void> addContactId(String ownerId, String contactUserId) async {
    if (ownerId.isEmpty || contactUserId.isEmpty) return;
    await _firestore.collection('userContacts').doc(ownerId).set({
      'contactIds': FieldValue.arrayUnion([contactUserId]),
    }, SetOptions(merge: true));
  }

  Future<void> addContactIds(
    String ownerId,
    List<String> contactUserIds,
  ) async {
    final unique = contactUserIds
        .where((x) => x.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (ownerId.isEmpty || unique.isEmpty) return;
    await _firestore.collection('userContacts').doc(ownerId).set({
      'contactIds': FieldValue.arrayUnion(unique),
    }, SetOptions(merge: true));
  }

  Future<void> removeContactId(String ownerId, String contactUserId) async {
    if (ownerId.isEmpty || contactUserId.isEmpty) return;
    await _firestore.collection('userContacts').doc(ownerId).set({
      'contactIds': FieldValue.arrayRemove([contactUserId]),
    }, SetOptions(merge: true));
  }

  Future<void> saveDeviceContactsConsent({
    required String ownerId,
    required bool granted,
  }) async {
    if (ownerId.isEmpty) return;
    await _firestore.collection('userContacts').doc(ownerId).set({
      'deviceSyncConsentAt': granted
          ? DateTime.now().toUtc().toIso8601String()
          : null,
    }, SetOptions(merge: true));
  }

  Future<Set<String>> resolveUserIdsByRegistrationLookupKeys(
    Iterable<String> lookupKeys,
  ) async {
    final keys = lookupKeys
        .where((x) => x.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (keys.isEmpty) return <String>{};

    final out = <String>{};
    for (final key in keys) {
      final snap = await _firestore
          .collection('registrationIndex')
          .doc(key)
          .get();
      if (!snap.exists) continue;
      final uid = snap.data()?['uid'];
      if (uid is String && uid.isNotEmpty) out.add(uid);
    }
    return out;
  }

  Future<void> syncDeviceLookupKeys({
    required String ownerId,
    required Map<String, String> lookupKeyToField,
  }) async {
    if (ownerId.isEmpty) return;
    final normalized = <String, String>{};
    lookupKeyToField.forEach((k, v) {
      final key = k.trim();
      if (key.isEmpty) return;
      normalized[key] = v == 'email' ? 'email' : 'phone';
    });

    final userContactRef = _firestore.collection('userContacts').doc(ownerId);
    final lookupCol = userContactRef.collection('deviceLookup');
    final existingSnap = await lookupCol.get();
    final existingKeys = existingSnap.docs.map((d) => d.id).toSet();
    final nextKeys = normalized.keys.toSet();

    final toDelete = existingKeys.difference(nextKeys);
    final toUpsert = nextKeys;
    final nowIso = DateTime.now().toUtc().toIso8601String();

    final writes = <Future<void>>[];
    const chunk = 350;
    final tasks = <void Function(WriteBatch batch)>[];

    for (final key in toUpsert) {
      tasks.add((batch) {
        batch.set(lookupCol.doc(key), <String, Object?>{
          'key': key,
          'field': normalized[key] ?? 'phone',
          'ownerId': ownerId,
          'updatedAt': nowIso,
        }, SetOptions(merge: true));
      });
    }
    for (final key in toDelete) {
      tasks.add((batch) {
        batch.delete(lookupCol.doc(key));
      });
    }

    for (var i = 0; i < tasks.length; i += chunk) {
      final batch = _firestore.batch();
      final end = (i + chunk > tasks.length) ? tasks.length : i + chunk;
      for (var j = i; j < end; j++) {
        tasks[j](batch);
      }
      writes.add(batch.commit());
    }
    await Future.wait(writes);
  }
}
