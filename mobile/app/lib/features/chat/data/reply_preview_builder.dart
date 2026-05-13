import 'package:lighchat_models/lighchat_models.dart';
import '../../../l10n/app_localizations.dart';

import '../ui/message_html_text.dart';

/// Mirrors web `getReplyPreview` ([src/lib/chat-utils.ts]) for mobile.
ReplyContext buildReplyPreview({
  required ChatMessage message,
  required String currentUserId,
  required bool isGroup,
  required AppLocalizations l10n,
  String? otherUserId,
  String? otherUserName,
  String? decryptedText,
}) {
  final senderName = _resolveSenderName(
    message.senderId,
    currentUserId: currentUserId,
    isGroup: isGroup,
    l10n: l10n,
    otherUserId: otherUserId,
    otherUserName: otherUserName,
  );

  var text = '';
  String? mediaPreviewUrl;
  String? mediaType;
  final hasPoll = (message.chatPollId ?? '').trim().isNotEmpty;
  final hasLocation = message.locationShare != null;

  // For E2EE messages, use decrypted text if available, otherwise fall back to message.text
  final raw = decryptedText ?? message.text ?? '';
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
        text = l10n.reply_sticker;
      } else if (isGif) {
        text = l10n.reply_gif;
      } else if (isVideoCircle) {
        text = l10n.reply_video_circle;
      } else if (isAudio) {
        text = l10n.reply_voice_message;
      } else if (isVideo) {
        text = l10n.reply_video;
      } else if (isImage) {
        text = l10n.reply_photo;
      } else {
        text = l10n.reply_file;
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
      text = l10n.reply_location;
    }
  }

  if (text.isEmpty && hasPoll) {
    text = l10n.reply_poll;
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
      text = l10n.reply_link;
    }
  }

  if (text.isEmpty) text = l10n.reply_message;

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
  required AppLocalizations l10n,
  String? otherUserId,
  String? otherUserName,
  String? decryptedText,
}) {
  final preview = buildReplyPreview(
    message: message,
    currentUserId: currentUserId,
    isGroup: isGroup,
    l10n: l10n,
    otherUserId: otherUserId,
    otherUserName: otherUserName,
    decryptedText: decryptedText,
  );
  return PinnedMessage(
    messageId: message.id,
    text: preview.text ?? l10n.reply_message,
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
  required AppLocalizations l10n,
  String? otherUserId,
  String? otherUserName,
}) {
  if (senderId == currentUserId) return l10n.reply_sender_you;
  if (!isGroup &&
      otherUserId != null &&
      otherUserId.isNotEmpty &&
      senderId == otherUserId &&
      (otherUserName ?? '').trim().isNotEmpty) {
    return otherUserName!.trim();
  }
  return l10n.reply_sender_member;
}
