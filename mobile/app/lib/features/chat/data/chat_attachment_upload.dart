import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:lighchat_models/lighchat_models.dart';

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
  if (n.endsWith('.m4v')) return 'video/x-m4v';
  if (n.endsWith('.pdf')) return 'application/pdf';
  return null;
}

ChatAttachment _attachmentFromUpload({
  required String url,
  required String name,
  required String? mime,
  required Uint8List bytes,
}) {
  int? width;
  int? height;
  final m = mime ?? '';
  if (m.startsWith('image/') && !m.contains('svg')) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded != null) {
        width = decoded.width;
        height = decoded.height;
      }
    } catch (_) {}
  }
  return ChatAttachment(
    url: url,
    name: name,
    type: mime,
    size: bytes.length,
    width: width,
    height: height,
  );
}

/// Загрузка с прогрессом (0..1) для превью в ленте при отправке альбома.
Future<ChatAttachment> uploadChatAttachmentBytesWithProgress({
  required FirebaseStorage storage,
  required String conversationId,
  required Uint8List bytes,
  required String pathUniqueSegment,
  required String displayName,
  String? mimeType,
  void Function(double progress)? onProgress,
  void Function(UploadTask task)? onTaskCreated,
}) async {
  final name =
      displayName.isNotEmpty ? displayName : 'attachment';
  final mime = mimeType ?? _guessMimeFromName(name);
  final path =
      'chat-attachments/$conversationId/${DateTime.now().microsecondsSinceEpoch}-$pathUniqueSegment-${_safeStorageSegment(name)}';
  final ref = storage.ref(path);
  final task = ref.putData(
    bytes,
    SettableMetadata(
      contentType: mime ?? 'application/octet-stream',
    ),
  );
  onTaskCreated?.call(task);
  final sub = task.snapshotEvents.listen((snap) {
    final total = snap.totalBytes;
    if (total > 0) {
      onProgress?.call(
        (snap.bytesTransferred / total).clamp(0.0, 1.0),
      );
    }
  });
  try {
    await task;
    onProgress?.call(1.0);
  } finally {
    await sub.cancel();
  }
  final url = await ref.getDownloadURL();
  return _attachmentFromUpload(url: url, name: name, mime: mime, bytes: bytes);
}

/// Загрузка в `chat-attachments/{conversationId}/…` (как веб `ChatMessageInput.uploadFile`).
Future<ChatAttachment> uploadChatAttachmentFromXFile({
  required FirebaseStorage storage,
  required String conversationId,
  required XFile file,
}) async {
  final bytes = await file.readAsBytes();
  final name = file.name.isNotEmpty ? file.name : file.path.split('/').last;
  final mime = file.mimeType ?? _guessMimeFromName(name);
  return uploadChatAttachmentBytesWithProgress(
    storage: storage,
    conversationId: conversationId,
    bytes: bytes,
    pathUniqueSegment: 'x',
    displayName: name,
    mimeType: mime,
  );
}
