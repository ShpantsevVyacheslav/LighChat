import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:lighchat_models/lighchat_models.dart';

import 'user_sticker_item_attachment.dart';
import 'user_sticker_packs_constants.dart';

/// Firestore + Storage для пользовательских стикерпаков (паритет
/// `src/lib/user-sticker-packs-client.ts` и `use-user-sticker-packs`).
class UserStickerPacksRepository {
  UserStickerPacksRepository({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _db = firestore,
        _storage = storage;

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> _userPacks(String userId) =>
      _db.collection('users').doc(userId).collection('stickerPacks');

  Stream<List<UserStickerPackRow>> watchMyPacks(String userId) {
    return _userPacks(userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) {
      final out = <UserStickerPackRow>[];
      for (final d in snap.docs) {
        final row = UserStickerPackRow.fromDoc(d.id, d.data());
        if (row != null) out.add(row);
      }
      return out;
    });
  }

  Stream<List<StickerItemRow>> watchMyPackItems(String userId, String packId) {
    return _userPacks(userId)
        .doc(packId)
        .collection('items')
        .orderBy('createdAt')
        .snapshots()
        .map((snap) {
      final out = <StickerItemRow>[];
      for (final d in snap.docs) {
        final row = StickerItemRow.fromDoc(d.id, d.data());
        if (row != null) out.add(row);
      }
      return out;
    });
  }

  Stream<List<PublicStickerPackRow>> watchPublicPacks() {
    return _db
        .collection('publicStickerPacks')
        .orderBy('sortOrder')
        .snapshots()
        .map((snap) {
      final out = <PublicStickerPackRow>[];
      for (final d in snap.docs) {
        final row = PublicStickerPackRow.fromDoc(d.id, d.data());
        if (row != null) out.add(row);
      }
      return out;
    });
  }

  Stream<List<StickerItemRow>> watchPublicPackItems(String packId) {
    return _db
        .collection('publicStickerPacks')
        .doc(packId)
        .collection('items')
        .orderBy('createdAt')
        .snapshots()
        .map((snap) {
      final out = <StickerItemRow>[];
      for (final d in snap.docs) {
        final row = StickerItemRow.fromDoc(d.id, d.data());
        if (row != null) out.add(row);
      }
      return out;
    });
  }

  Future<String?> createPack(String userId, String rawName) async {
    final name = rawName.trim().isEmpty ? 'Мой пак' : rawName.trim();
    final now = DateTime.now().toUtc().toIso8601String();
    final ref = await _userPacks(userId).add(<String, Object?>{
      'name': name,
      'createdAt': now,
      'updatedAt': now,
    });
    return ref.id;
  }

  Future<void> deleteItem(String userId, String packId, String itemId) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _userPacks(userId).doc(packId).collection('items').doc(itemId).delete();
    await _userPacks(userId).doc(packId).update(<String, Object?>{'updatedAt': now});
  }

  Future<Map<String, int>> _countStoragePathsAcrossPacks(String userId) async {
    final counts = <String, int>{};
    final packs = await _userPacks(userId).get();
    for (final p in packs.docs) {
      final items = await p.reference.collection('items').get();
      for (final it in items.docs) {
        final sp = it.data()['storagePath'];
        if (sp is String && sp.isNotEmpty) {
          counts[sp] = (counts[sp] ?? 0) + 1;
        }
      }
    }
    return counts;
  }

  Future<bool> deletePack(String userId, String packId) async {
    try {
      final pathCounts = await _countStoragePathsAcrossPacks(userId);
      final itemsCol = _userPacks(userId).doc(packId).collection('items');
      final itemsSnap = await itemsCol.get();
      final toRemove = <String>[];

      for (final d in itemsSnap.docs) {
        final path = d.data()['storagePath'];
        if (path is String &&
            path.isNotEmpty &&
            (pathCounts[path] ?? 0) == 1) {
          toRemove.add(path);
        }
      }

      for (final path in toRemove) {
        try {
          await _storage.ref(path).delete();
        } catch (_) {}
      }

      const batchSize = 500;
      final refs = itemsSnap.docs.map((d) => d.reference).toList();
      for (var i = 0; i < refs.length; i += batchSize) {
        final batch = _db.batch();
        final chunk = refs.skip(i).take(batchSize);
        for (final r in chunk) {
          batch.delete(r);
        }
        await batch.commit();
      }

      await _userPacks(userId).doc(packId).delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  static String _guessMime(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.svg')) return 'image/svg+xml';
    if (lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.webm')) return 'video/webm';
    if (lower.endsWith('.mov')) return 'video/quicktime';
    return 'application/octet-stream';
  }

  static String _randomIdPart() =>
      '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1 << 20)}';

  Future<({int ok, int skipped, List<String> errors})> addXFilesToPack({
    required String userId,
    required String packId,
    required List<XFile> files,
  }) async {
    var ok = 0;
    var skipped = 0;
    final errors = <String>[];

    for (final file in files) {
      Uint8List bytes;
      try {
        bytes = await file.readAsBytes();
      } catch (_) {
        errors.add('read_failed');
        skipped++;
        continue;
      }

      var mime = file.mimeType?.toLowerCase();
      if (mime == null || mime.isEmpty) {
        mime = _guessMime(file.name);
      }

      final isVideo = mime.startsWith('video/');
      final isImage = mime.startsWith('image/');
      if (!isVideo && !isImage) {
        skipped++;
        continue;
      }

      if (bytes.length > kUserStickerMaxFileBytes) {
        errors.add('file_too_large');
        skipped++;
        continue;
      }

      try {
        final ext = file.name.split('.').last.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
        final fallback = mime.split('/').last.replaceAll('+xml', '');
        final useExt = ext.isNotEmpty ? ext : fallback;
        final path =
            'users/$userId/sticker-packs/$packId/${_randomIdPart()}.$useExt';
        final ref = _storage.ref(path);
        await ref.putData(
          bytes,
          SettableMetadata(contentType: mime),
        );
        final downloadUrl = await ref.getDownloadURL();
        final now = DateTime.now().toUtc().toIso8601String();
        await _userPacks(userId).doc(packId).collection('items').add(<String, Object?>{
          'downloadUrl': downloadUrl,
          'storagePath': path,
          'contentType': mime,
          'size': bytes.length,
          'createdAt': now,
        });
        await _userPacks(userId).doc(packId).update(<String, Object?>{'updatedAt': now});
        ok++;
      } catch (_) {
        errors.add('upload_failed');
        skipped++;
      }
    }

    return (ok: ok, skipped: skipped, errors: errors);
  }

  /// Скачать по URL (как `addChatAttachmentToUserStickerPack` на вебе) и положить в пак.
  Future<bool> addRemoteImageToPack({
    required String userId,
    required String packId,
    required ChatAttachment att,
  }) async {
    final url = att.url.trim();
    if (url.isEmpty) return false;
    try {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
      if (res.statusCode < 200 || res.statusCode >= 300) return false;
      final bytes = res.bodyBytes;
      if (bytes.length > kUserStickerMaxFileBytes) return false;

      var type = res.headers['content-type']?.split(';').first.trim().toLowerCase();
      if (type == null || type.isEmpty || !type.startsWith('image/')) {
        final fromAtt = att.type?.toLowerCase();
        type = (fromAtt != null && fromAtt.startsWith('image/'))
            ? fromAtt
            : 'image/gif';
      }
      if (!type.startsWith('image/')) return false;

      final ext = extensionForStickerMime(type);
      final path =
          'users/$userId/sticker-packs/$packId/${_randomIdPart()}.$ext';
      final ref = _storage.ref(path);
      await ref.putData(bytes, SettableMetadata(contentType: type));
      final downloadUrl = await ref.getDownloadURL();
      final now = DateTime.now().toUtc().toIso8601String();

      int? w;
      int? h;
      if (att.width != null && att.width! > 0) w = att.width;
      if (att.height != null && att.height! > 0) h = att.height;

      await _userPacks(userId).doc(packId).collection('items').add(<String, Object?>{
        'downloadUrl': downloadUrl,
        'storagePath': path,
        'contentType': type,
        'size': bytes.length,
        'createdAt': now,
        if (w != null && h != null) ...<String, Object?>{'width': w, 'height': h},
      });
      await _userPacks(userId).doc(packId).update(<String, Object?>{'updatedAt': now});
      return true;
    } catch (_) {
      return false;
    }
  }
}
