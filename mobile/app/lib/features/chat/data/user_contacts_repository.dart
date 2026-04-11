import 'package:cloud_firestore/cloud_firestore.dart';

/// `userContacts/{userId}` — same shape as web `UserContactsIndex`.
class UserContactsIndex {
  const UserContactsIndex({required this.contactIds});

  final List<String> contactIds;

  static UserContactsIndex fromSnapshot(DocumentSnapshot<Map<String, Object?>> snap) {
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
    if (userId.isEmpty) return Stream.value(const UserContactsIndex(contactIds: <String>[]));
    return _firestore.collection('userContacts').doc(userId).snapshots().map(UserContactsIndex.fromSnapshot);
  }

  /// Как web `addContactId` (`arrayUnion`).
  Future<void> addContactId(String ownerId, String contactUserId) async {
    if (ownerId.isEmpty || contactUserId.isEmpty) return;
    await _firestore.collection('userContacts').doc(ownerId).set(
          {'contactIds': FieldValue.arrayUnion([contactUserId])},
          SetOptions(merge: true),
        );
  }
}
