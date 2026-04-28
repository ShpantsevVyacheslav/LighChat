import 'package:cloud_firestore/cloud_firestore.dart';

Stream<bool> watchSecretChatAccessActive({
  required FirebaseFirestore firestore,
  required String conversationId,
  required String userId,
}) {
  final ref = firestore
      .collection('conversations')
      .doc(conversationId)
      .collection('secretAccess')
      .doc(userId);
  return ref.snapshots().map((snap) {
    if (!snap.exists) return false;
    final d = snap.data();
    if (d == null) return false;
    final expTs = d['expiresAtTs'];
    if (expTs is Timestamp) {
      return expTs.toDate().isAfter(DateTime.now());
    }
    final expIso = d['expiresAt'];
    if (expIso is String && expIso.trim().isNotEmpty) {
      final dt = DateTime.tryParse(expIso.trim());
      if (dt != null) return dt.toUtc().isAfter(DateTime.now().toUtc());
    }
    return false;
  });
}

