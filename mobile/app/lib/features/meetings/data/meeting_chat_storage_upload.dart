import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;

import 'meeting_chat_attachment.dart';
import 'meeting_chat_image_compress.dart';

String _safeStorageSegment(String name) {
  return name
      .replaceAll(RegExp(r'\s+'), '_')
      .replaceAll(RegExp(r'[/\\]'), '_');
}

String? _guessMimeFromName(String name) {
  final n = name.toLowerCase();
  if (n.endsWith('.jpg') || n.endsWith('.jpeg')) return 'image/jpeg';
  if (n.endsWith('.png')) return 'image/png';
  if (n.endsWith('.gif')) return 'image/gif';
  if (n.endsWith('.webp')) return 'image/webp';
  if (n.endsWith('.heic')) return 'image/heic';
  if (n.endsWith('.mp4')) return 'video/mp4';
  if (n.endsWith('.mov')) return 'video/quicktime';
  if (n.endsWith('.webm')) return 'video/webm';
  if (n.endsWith('.pdf')) return 'application/pdf';
  return null;
}

bool _isStorageAuthIssue(FirebaseException e) {
  final code = e.code.toLowerCase();
  if (code == 'unauthenticated' ||
      code == 'permission-denied' ||
      code == 'unauthorized') {
    return true;
  }
  final message = (e.message ?? '').toLowerCase();
  return code == 'unknown' && message.contains('-13020');
}

Future<T> _withAuthRefreshRetry<T>(Future<T> Function() op) async {
  try {
    return await op();
  } on FirebaseException catch (e) {
    if (!_isStorageAuthIssue(e)) rethrow;
    await fb_auth.FirebaseAuth.instance.currentUser?.getIdToken(true);
    return op();
  }
}

/// Загрузка файла в `meeting-attachments/{meetingId}/...` — путь как на web
/// (`MeetingSidebar.tsx`).
Future<MeetingChatAttachment> uploadMeetingChatBytes({
  required FirebaseStorage storage,
  required String meetingId,
  required Uint8List bytes,
  required String displayName,
  String? mimeType,
}) {
  final prepared = prepareMeetingChatImageForUpload(
    bytes: bytes,
    displayName: displayName,
    mimeType: mimeType,
  );
  final uploadBytes = prepared.bytes;
  final name =
      prepared.displayName.isNotEmpty ? prepared.displayName : 'attachment';
  final mime = prepared.mimeType.isNotEmpty
      ? prepared.mimeType
      : (_guessMimeFromName(name) ?? 'application/octet-stream');
  final path =
      'meeting-attachments/$meetingId/${DateTime.now().millisecondsSinceEpoch}_${_safeStorageSegment(name)}';

  int? width;
  int? height;
  if (mime.startsWith('image/') && !mime.contains('svg')) {
    try {
      final decoded = img.decodeImage(uploadBytes);
      if (decoded != null) {
        width = decoded.width;
        height = decoded.height;
      }
    } catch (_) {}
  }

  return _withAuthRefreshRetry(() async {
    final ref = storage.ref(path);
    await ref.putData(uploadBytes, SettableMetadata(contentType: mime));
    final url = await ref.getDownloadURL();
    return MeetingChatAttachment(
      url: url,
      name: name,
      type: mime,
      size: uploadBytes.length,
      width: width,
      height: height,
    );
  });
}
