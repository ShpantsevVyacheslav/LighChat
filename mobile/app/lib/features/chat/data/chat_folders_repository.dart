import 'package:cloud_firestore/cloud_firestore.dart';

class ChatFoldersRepository {
  ChatFoldersRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> createFolder({
    required String userId,
    required String name,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final docRef = _firestore.collection('userChats').doc(userId);
    final snap = await docRef.get();
    final data = snap.data() ?? <String, Object?>{};
    final rawFolders = data['folders'];
    final folders = (rawFolders is List ? rawFolders : const <Object?>[])
        .whereType<Map>()
        .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
        .toList();

    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    folders.add(<String, Object?>{
      'id': id,
      'name': trimmed,
      'conversationIds': const <String>[],
      'type': 'custom',
    });

    await docRef.set(<String, Object?>{'folders': folders}, SetOptions(merge: true));
  }
}

