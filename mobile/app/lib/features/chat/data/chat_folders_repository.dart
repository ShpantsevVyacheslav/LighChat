import 'package:cloud_firestore/cloud_firestore.dart';

class ChatFoldersRepository {
  ChatFoldersRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> createFolder({
    required String userId,
    required String name,
    List<String> conversationIds = const <String>[],
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final ids = conversationIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);

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
      'conversationIds': ids,
      'type': 'custom',
    });

    await docRef.set(<String, Object?>{
      'folders': folders,
    }, SetOptions(merge: true));
  }

  Future<void> deleteFolder({
    required String userId,
    required String folderId,
  }) async {
    final trimmedId = folderId.trim();
    if (trimmedId.isEmpty) return;

    final docRef = _firestore.collection('userChats').doc(userId);
    final snap = await docRef.get();
    final data = snap.data() ?? <String, Object?>{};
    final rawFolders = data['folders'];
    final folders = (rawFolders is List ? rawFolders : const <Object?>[])
        .whereType<Map>()
        .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
        .where((m) => (m['id']?.toString() ?? '') != trimmedId)
        .toList(growable: false);

    await docRef.set(<String, Object?>{
      'folders': folders,
    }, SetOptions(merge: true));
  }

  Future<void> toggleConversationInFolder({
    required String userId,
    required String folderId,
    required String conversationId,
  }) async {
    final folderKey = folderId.trim();
    final conversationKey = conversationId.trim();
    if (folderKey.isEmpty || conversationKey.isEmpty) return;

    final docRef = _firestore.collection('userChats').doc(userId);
    final snap = await docRef.get();
    final data = snap.data() ?? <String, Object?>{};
    final rawFolders = data['folders'];
    final folders = (rawFolders is List ? rawFolders : const <Object?>[])
        .whereType<Map>()
        .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
        .toList(growable: false);

    final updatedFolders = folders
        .map((folder) {
          if ((folder['id']?.toString() ?? '') != folderKey) return folder;
          final rawIds = folder['conversationIds'];
          final ids = (rawIds is List ? rawIds : const <Object?>[])
              .whereType<String>()
              .where((id) => id.isNotEmpty)
              .toList(growable: true);
          if (ids.contains(conversationKey)) {
            ids.removeWhere((id) => id == conversationKey);
          } else {
            ids.add(conversationKey);
          }
          return <String, Object?>{...folder, 'conversationIds': ids};
        })
        .toList(growable: false);

    await docRef.set(<String, Object?>{
      'folders': updatedFolders,
    }, SetOptions(merge: true));
  }

  Future<bool> toggleFolderPin({
    required String userId,
    required String folderId,
    required String conversationId,
  }) async {
    final folderKey = folderId.trim();
    final conversationKey = conversationId.trim();
    if (folderKey.isEmpty || conversationKey.isEmpty) return false;

    final docRef = _firestore.collection('userChats').doc(userId);
    final snap = await docRef.get();
    final data = snap.data() ?? <String, Object?>{};
    final rawPins = data['folderPins'];
    final folderPins = <String, List<String>>{};
    if (rawPins is Map) {
      for (final entry in rawPins.entries) {
        final key = entry.key.toString();
        final ids =
            (entry.value is List ? entry.value as List : const <Object?>[])
                .whereType<String>()
                .where((id) => id.isNotEmpty)
                .toList(growable: true);
        folderPins[key] = ids;
      }
    }

    final list = (folderPins[folderKey] ?? <String>[]).toList(growable: true);
    final idx = list.indexOf(conversationKey);
    final pinned = idx < 0;
    if (pinned) {
      list.insert(0, conversationKey);
    } else {
      list.removeAt(idx);
    }
    folderPins[folderKey] = list;

    await docRef.set(<String, Object?>{
      'folderPins': folderPins,
    }, SetOptions(merge: true));
    return pinned;
  }
}
