import 'package:cloud_firestore/cloud_firestore.dart';

/// `userContacts/{userId}` — same shape as web `UserContactsIndex`.
class ContactLocalProfile {
  const ContactLocalProfile({
    this.firstName,
    this.lastName,
    this.displayName,
    this.updatedAtIso,
  });

  final String? firstName;
  final String? lastName;
  final String? displayName;
  final String? updatedAtIso;

  static ContactLocalProfile? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final m = raw.map((k, v) => MapEntry(k.toString(), v));
    String? readTrimmed(String key) {
      final v = m[key];
      if (v is! String) return null;
      final t = v.trim();
      return t.isEmpty ? null : t;
    }

    final firstName = readTrimmed('firstName');
    final lastName = readTrimmed('lastName');
    final displayName = readTrimmed('displayName');
    final updatedAtIso = readTrimmed('updatedAt');
    if (firstName == null && lastName == null && displayName == null) {
      return null;
    }
    return ContactLocalProfile(
      firstName: firstName,
      lastName: lastName,
      displayName: displayName,
      updatedAtIso: updatedAtIso,
    );
  }
}

class UserContactsIndex {
  const UserContactsIndex({
    required this.contactIds,
    this.contactProfiles = const <String, ContactLocalProfile>{},
  });

  final List<String> contactIds;
  final Map<String, ContactLocalProfile> contactProfiles;

  static UserContactsIndex fromSnapshot(
    DocumentSnapshot<Map<String, Object?>> snap,
  ) {
    if (!snap.exists) {
      return const UserContactsIndex(contactIds: <String>[]);
    }
    final data = snap.data();
    final raw = data?['contactIds'];
    final ids = (raw is List ? raw : const <Object?>[])
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList(growable: false);

    final profiles = <String, ContactLocalProfile>{};
    final rawProfiles = data?['contactProfiles'];
    if (rawProfiles is Map) {
      for (final entry in rawProfiles.entries) {
        final key = entry.key.toString().trim();
        if (key.isEmpty) continue;
        final parsed = ContactLocalProfile.fromJson(entry.value);
        if (parsed != null) profiles[key] = parsed;
      }
    }

    return UserContactsIndex(contactIds: ids, contactProfiles: profiles);
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

  Future<void> upsertContactProfile({
    required String ownerId,
    required String contactUserId,
    required String firstName,
    String? lastName,
  }) async {
    final owner = ownerId.trim();
    final contactId = contactUserId.trim();
    final first = firstName.trim();
    final last = (lastName ?? '').trim();
    if (owner.isEmpty || contactId.isEmpty || first.isEmpty) return;

    final displayName = [first, if (last.isNotEmpty) last].join(' ').trim();
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final ref = _firestore.collection('userContacts').doc(owner);

    await ref.set(<String, Object?>{
      'contactIds': FieldValue.arrayUnion([contactId]),
    }, SetOptions(merge: true));

    await ref.update(<String, Object?>{
      'contactProfiles.$contactId.firstName': first,
      'contactProfiles.$contactId.lastName': last.isEmpty
          ? FieldValue.delete()
          : last,
      'contactProfiles.$contactId.displayName': displayName,
      'contactProfiles.$contactId.updatedAt': nowIso,
    });
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
    final ref = _firestore.collection('userContacts').doc(ownerId);
    await ref.set({
      'contactIds': FieldValue.arrayRemove([contactUserId]),
    }, SetOptions(merge: true));
    try {
      await ref.update(<String, Object?>{
        'contactProfiles.$contactUserId': FieldValue.delete(),
      });
    } catch (_) {
      // ignore: there may be no local profile map yet
    }
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

  Future<String?> resolveUserIdByUsername(String username) async {
    final normalized = username
        .trim()
        .replaceFirst(RegExp(r'^@'), '')
        .toLowerCase();
    if (normalized.isEmpty) return null;
    final key = 'u_$normalized';
    final snap = await _firestore
        .collection('registrationIndex')
        .doc(key)
        .get();
    if (!snap.exists) return null;
    final uid = snap.data()?['uid'];
    if (uid is String && uid.trim().isNotEmpty) {
      return uid.trim();
    }
    return null;
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

  /// Число ключей из `deviceLookup`, для которых нет документа в `registrationIndex`.
  /// Используется для кнопки «Пригласить» (параллельные чтения небольшими пачками).
  Future<int> countDeviceLookupsWithoutRegistration(String ownerId) async {
    if (ownerId.trim().isEmpty) return 0;
    final snap = await _firestore
        .collection('userContacts')
        .doc(ownerId)
        .collection('deviceLookup')
        .get();
    final keys = snap.docs
        .map((d) => d.id.trim())
        .where((k) => k.isNotEmpty)
        .toList(growable: false);
    if (keys.isEmpty) return 0;
    const batchSize = 24;
    var missing = 0;
    for (var i = 0; i < keys.length; i += batchSize) {
      final chunk = keys.sublist(
        i,
        i + batchSize > keys.length ? keys.length : i + batchSize,
      );
      final results = await Future.wait(
        chunk.map(
          (k) => _firestore.collection('registrationIndex').doc(k).get(),
        ),
      );
      for (final d in results) {
        if (!d.exists) missing++;
      }
    }
    return missing;
  }
}
