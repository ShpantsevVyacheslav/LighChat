import 'package:cloud_firestore/cloud_firestore.dart';

Future<bool> _isTakenByKey({
  required FirebaseFirestore firestore,
  required String? key,
  String? exceptUid,
}) async {
  if (key == null) return false;
  final snap = await firestore.collection('registrationIndex').doc(key).get();
  if (!snap.exists) return false;
  final owner = snap.data()?['uid'] as String?;
  if (exceptUid != null && owner == exceptUid) return false;
  return true;
}

Future<bool> isRegistrationPhoneTaken({
  required FirebaseFirestore firestore,
  required String? key,
  String? exceptUid,
}) =>
    _isTakenByKey(firestore: firestore, key: key, exceptUid: exceptUid);

Future<bool> isRegistrationEmailTaken({
  required FirebaseFirestore firestore,
  required String? key,
  String? exceptUid,
}) =>
    _isTakenByKey(firestore: firestore, key: key, exceptUid: exceptUid);

Future<bool> isRegistrationUsernameTaken({
  required FirebaseFirestore firestore,
  required String? key,
  String? exceptUid,
}) =>
    _isTakenByKey(firestore: firestore, key: key, exceptUid: exceptUid);

