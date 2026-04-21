import 'package:lighchat_models/lighchat_models.dart';

import '../ui/message_html_text.dart';

/// Mirrors web `getReplyPreview` ([src/lib/chat-utils.ts]) for mobile.
ReplyContext buildReplyPreview({
  required ChatMessage message,
  required String currentUserId,
  required bool isGroup,
  String? otherUserId,
  String? otherUserName,
}) {
  final senderName = _resolveSenderName(
    message.senderId,
    currentUserId: currentUserId,
    isGroup: isGroup,
    otherUserId: otherUserId,
    otherUserName: otherUserName,
  );

  var text = '';
  String? mediaPreviewUrl;
  String? mediaType;
  final hasPoll = (message.chatPollId ?? '').trim().isNotEmpty;
  final hasLocation = message.locationShare != null;

  final raw = message.text ?? '';
  if (raw.trim().isNotEmpty) {
    text = raw.contains('<') ? messageHtmlToPlainText(raw) : raw.trim();
  }

  final atts = message.attachments;
  if (atts.isNotEmpty) {
    final att = atts.first;
    final isSticker =
        att.name.startsWith('sticker_') || att.type == 'image/svg+xml';
    final isGif = att.name.startsWith('gif_');
    final isVideoCircle = att.name.startsWith('video-circle_');
    final t = (att.type ?? '').toLowerCase();
    final isAudio =
        t.startsWith('audio/') || att.name.toLowerCase().startsWith('audio_');
    final isVideo = t.startsWith('video/');
    final isImage = t.startsWith('image/');

    if (text.isEmpty) {
      if (isSticker) {
        text = 'Стикер';
      } else if (isGif) {
        text = 'GIF';
      } else if (isVideoCircle) {
        text = 'Кружок';
      } else if (isAudio) {
        text = 'Голосовое сообщение';
      } else if (isVideo) {
        text = 'Видео';
      } else if (isImage) {
        text = 'Фотография';
      } else {
        text = 'Файл';
      }
    }

    mediaPreviewUrl = att.url;
    if (isSticker) {
      mediaType = 'sticker';
    } else if (isGif) {
      mediaType = 'image';
    } else if (isVideoCircle) {
      mediaType = 'video-circle';
    } else if (isAudio) {
      mediaType = 'audio';
    } else if (isVideo) {
      mediaType = 'video';
    } else if (isImage) {
      mediaType = 'image';
    } else {
      mediaType = 'file';
    }
  }

  if (hasLocation) {
    mediaType ??= 'location';
    if (text.isEmpty) {
      text = 'Локация';
    }
  }

  if (text.isEmpty && hasPoll) {
    text = 'Опрос';
  }
  if (hasPoll) {
    mediaType ??= 'poll';
  }

  final plain = text.trim().toLowerCase();
  final hasLink =
      raw.contains('<a ') ||
      RegExp(r'(https?:\/\/|www\.)', caseSensitive: false).hasMatch(raw) ||
      RegExp(r'(https?:\/\/|www\.)', caseSensitive: false).hasMatch(plain);
  if (hasLink && mediaType == null) {
    mediaType = 'link';
    if (text.isEmpty) {
      text = 'Ссылка';
    }
  }

  if (text.isEmpty) text = 'Сообщение';

  return ReplyContext(
    messageId: message.id,
    senderName: senderName,
    text: text,
    mediaPreviewUrl: mediaPreviewUrl,
    mediaType: mediaType,
  );
}

/// Firestore `pinnedMessages[]` entry (same fields as web `PinnedMessage`).
PinnedMessage buildPinnedMessageFromChatMessage({
  required ChatMessage message,
  required String currentUserId,
  required bool isGroup,
  String? otherUserId,
  String? otherUserName,
}) {
  final preview = buildReplyPreview(
    message: message,
    currentUserId: currentUserId,
    isGroup: isGroup,
    otherUserId: otherUserId,
    otherUserName: otherUserName,
  );
  return PinnedMessage(
    messageId: message.id,
    text: preview.text ?? 'Сообщение',
    senderName: preview.senderName,
    senderId: message.senderId,
    mediaPreviewUrl: preview.mediaPreviewUrl,
    mediaType: preview.mediaType,
    messageCreatedAt: message.createdAt.toUtc().toIso8601String(),
  );
}

String _resolveSenderName(
  String senderId, {
  required String currentUserId,
  required bool isGroup,
  String? otherUserId,
  String? otherUserName,
}) {
  if (senderId == currentUserId) return 'Вы';
  if (!isGroup &&
      otherUserId != null &&
      otherUserId.isNotEmpty &&
      senderId == otherUserId &&
      (otherUserName ?? '').trim().isNotEmpty) {
    return otherUserName!.trim();
  }
  return 'Участник';
}
