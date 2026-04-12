import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lighchat_models/lighchat_models.dart';

String _isoFromFirestoreField(Object? v) {
  if (v is String) return v;
  if (v is Timestamp) return v.toDate().toUtc().toIso8601String();
  return '';
}

/// Паритет `src/lib/user-sticker-packs.ts` — расширение по MIME для имени файла.
String extensionForStickerMime(String mime) {
  if (mime == 'image/png') return 'png';
  if (mime == 'image/jpeg' || mime == 'image/jpg') return 'jpg';
  if (mime == 'image/webp') return 'webp';
  if (mime == 'image/gif') return 'gif';
  if (mime == 'image/svg+xml') return 'svg';
  if (mime == 'video/mp4') return 'mp4';
  if (mime == 'video/webm') return 'webm';
  if (mime == 'video/quicktime') return 'mov';
  return 'img';
}

/// Элемент пака (личного или публичного) → вложение для отправки в чат.
ChatAttachment userStickerItemToAttachment(StickerItemRow item) {
  final ext = extensionForStickerMime(item.contentType);
  final isGifLike =
      item.contentType == 'image/gif' || item.contentType.startsWith('video/');
  final prefix = isGifLike ? 'gif' : 'sticker';
  final w = item.width;
  final h = item.height;
  return ChatAttachment(
    url: item.downloadUrl,
    name: '${prefix}_${item.id}_${DateTime.now().millisecondsSinceEpoch}.$ext',
    type: item.contentType,
    size: item.size,
    width: (w != null && w > 0) ? w : null,
    height: (h != null && h > 0) ? h : null,
  );
}

/// Строка из Firestore для сетки стикеров.
class StickerItemRow {
  const StickerItemRow({
    required this.id,
    required this.downloadUrl,
    required this.storagePath,
    required this.contentType,
    required this.size,
    required this.createdAt,
    this.width,
    this.height,
  });

  final String id;
  final String downloadUrl;
  final String storagePath;
  final String contentType;
  final int size;
  final String createdAt;
  final int? width;
  final int? height;

  static StickerItemRow? fromDoc(String id, Map<String, dynamic> d) {
    final url = d['downloadUrl'];
    final path = d['storagePath'];
    final ct = d['contentType'];
    final sizeRaw = d['size'];
    if (url is! String ||
        url.isEmpty ||
        path is! String ||
        ct is! String ||
        ct.isEmpty) {
      return null;
    }
    final size = sizeRaw is int
        ? sizeRaw
        : (sizeRaw is num ? sizeRaw.toInt() : 0);
    final w = d['width'];
    final h = d['height'];
    final createdAt = _isoFromFirestoreField(d['createdAt']);
    return StickerItemRow(
      id: id,
      downloadUrl: url,
      storagePath: path,
      contentType: ct,
      size: size,
      createdAt: createdAt,
      width: w is int ? w : (w is num ? w.toInt() : null),
      height: h is int ? h : (h is num ? h.toInt() : null),
    );
  }
}

class UserStickerPackRow {
  const UserStickerPackRow({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String createdAt;
  final String updatedAt;

  static UserStickerPackRow? fromDoc(String id, Map<String, dynamic> d) {
    final name = d['name'];
    if (name is! String) return null;
    final c = d['createdAt'];
    final u = d['updatedAt'];
    return UserStickerPackRow(
      id: id,
      name: name,
      createdAt: _isoFromFirestoreField(c),
      updatedAt: _isoFromFirestoreField(u),
    );
  }
}

class PublicStickerPackRow {
  const PublicStickerPackRow({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final int sortOrder;
  final String createdAt;
  final String updatedAt;

  static PublicStickerPackRow? fromDoc(String id, Map<String, dynamic> d) {
    final name = d['name'];
    if (name is! String) return null;
    final so = d['sortOrder'];
    final order = so is int ? so : (so is num ? so.toInt() : 0);
    final c = d['createdAt'];
    final u = d['updatedAt'];
    return PublicStickerPackRow(
      id: id,
      name: name,
      sortOrder: order,
      createdAt: _isoFromFirestoreField(c),
      updatedAt: _isoFromFirestoreField(u),
    );
  }
}
