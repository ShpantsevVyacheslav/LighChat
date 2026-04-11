import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ChatSettingsRepository {
  ChatSettingsRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  Future<Map<String, dynamic>> loadUserDoc(String uid) async {
    final snap = await _firestore.collection('users').doc(uid).get();
    return Map<String, dynamic>.from(snap.data() ?? const <String, dynamic>{});
  }

  Stream<Map<String, dynamic>> watchUserDoc(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map(
          (snap) => Map<String, dynamic>.from(
            snap.data() ?? const <String, dynamic>{},
          ),
        );
  }

  Future<void> patchChatSettings(String uid, Map<String, Object?> patch) async {
    await _firestore.collection('users').doc(uid).set(<String, Object?>{
      'chatSettings': patch,
    }, SetOptions(merge: true));
  }

  Future<void> setChatSettings(String uid, Map<String, Object?> value) async {
    await _firestore.collection('users').doc(uid).set(<String, Object?>{
      'chatSettings': value,
    }, SetOptions(merge: true));
  }

  Future<String> uploadWallpaper(String uid, Uint8List bytes) async {
    final ref = _storage.ref(
      'wallpapers/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<void> addCustomBackground(String uid, String url) async {
    await _firestore.collection('users').doc(uid).set(<String, Object?>{
      'customBackgrounds': FieldValue.arrayUnion(<String>[url]),
    }, SetOptions(merge: true));
  }

  Future<void> removeCustomBackground(
    String uid,
    String url, {
    required bool wasActive,
  }) async {
    await _firestore.collection('users').doc(uid).set(<String, Object?>{
      'customBackgrounds': FieldValue.arrayRemove(<String>[url]),
      if (wasActive) 'chatSettings': <String, Object?>{'chatWallpaper': null},
    }, SetOptions(merge: true));
  }
}
