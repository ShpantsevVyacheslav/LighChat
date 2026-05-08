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

/// `true`, если URL — служебный плейсхолдер «E2EE-вложение в процессе
/// расшифровки» (см. `e2eePendingUrlScheme` в `e2ee_decryption_orchestrator`).
bool isE2eePendingAttachment(ChatAttachment att) {
  final scheme = Uri.tryParse(att.url)?.scheme;
  return scheme == 'e2ee-pending';
}

/// Паритет веба: `attachment-visual.ts` → `isGridGalleryAttachment`.
bool isChatGridGalleryAttachment(ChatAttachment att) {
  if (isE2eePendingAttachment(att)) return false;
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

/// Одно вложение для пересылки из полноэкранной галереи (альбом не уходит целиком).
ChatMessage chatMessageForSingleAttachmentForward(
  ChatMessage source,
  ChatAttachment attachment,
) {
  final multi = source.attachments.length > 1;
  return ChatMessage(
    id: source.id,
    senderId: source.senderId,
    text: multi ? null : source.text,
    attachments: [attachment],
    replyTo: source.replyTo,
    isDeleted: source.isDeleted,
    reactions: source.reactions,
    createdAt: source.createdAt,
    readAt: source.readAt,
    updatedAt: source.updatedAt,
    forwardedFrom: source.forwardedFrom,
    deliveryStatus: source.deliveryStatus,
    chatPollId: multi ? null : source.chatPollId,
    locationShare: multi ? null : source.locationShare,
    threadCount: source.threadCount,
    unreadThreadCounts: source.unreadThreadCounts,
    lastThreadMessageText: source.lastThreadMessageText,
    lastThreadMessageSenderId: source.lastThreadMessageSenderId,
    lastThreadMessageTimestamp: source.lastThreadMessageTimestamp,
  );
}
