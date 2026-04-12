import 'package:lighchat_models/lighchat_models.dart';

import 'video_circle_utils.dart';

final _imageExt = RegExp(
  r'\.(jpe?g|png|gif|webp|avif|heic|heif|bmp|jfif)(\?|#|$)',
  caseSensitive: false,
);
final _videoExt = RegExp(
  r'\.(mp4|webm|mov|mkv|m4v|ogv)(\?|#|$)',
  caseSensitive: false,
);

bool _looseMime(String? t) {
  final x = (t ?? '').toLowerCase();
  return x.isEmpty ||
      x == 'application/octet-stream' ||
      x == 'binary/octet-stream';
}

/// Паритет веба: `attachment-visual.ts` → `isGridGalleryAttachment`.
bool isChatGridGalleryAttachment(ChatAttachment att) {
  final n = att.name.toLowerCase();
  if (n.startsWith('sticker_') || n.startsWith('gif_')) return false;
  if (isVideoCircleAttachment(att)) return false;
  final type = (att.type ?? '').toLowerCase();
  if (type.startsWith('image/') && !type.contains('svg')) return true;
  if (type.startsWith('video/')) return true;
  if (_looseMime(att.type)) {
    if (_imageExt.hasMatch(att.name)) return true;
    if (_videoExt.hasMatch(att.name)) return true;
  }
  return false;
}

bool isChatGridGalleryVideo(ChatAttachment att) {
  if (isVideoCircleAttachment(att)) return false;
  final type = (att.type ?? '').toLowerCase();
  if (type.startsWith('video/')) return true;
  if (_looseMime(att.type) && _videoExt.hasMatch(att.name)) return true;
  return false;
}

class ChatMediaGalleryItem {
  const ChatMediaGalleryItem({
    required this.attachment,
    required this.message,
  });

  final ChatAttachment attachment;
  final ChatMessage message;
}

/// Сообщения в хронологическом порядке (старые → новые), как `_sortedAscCache` в чате.
List<ChatMediaGalleryItem> collectChatMediaGalleryItems(
  Iterable<ChatMessage> messagesChronological,
) {
  final seen = <String>{};
  final out = <ChatMediaGalleryItem>[];
  for (final m in messagesChronological) {
    if (m.isDeleted) continue;
    for (final a in m.attachments) {
      if (!isChatGridGalleryAttachment(a)) continue;
      if (!seen.add(a.url)) continue;
      out.add(ChatMediaGalleryItem(attachment: a, message: m));
    }
  }
  return out;
}

int indexInChatMediaGallery(
  List<ChatMediaGalleryItem> items,
  String attachmentUrl,
) {
  final i = items.indexWhere((e) => e.attachment.url == attachmentUrl);
  return i < 0 ? 0 : i;
}
