import 'package:cloud_firestore/cloud_firestore.dart';

import 'meeting_chat_attachment.dart';

/// Reply-context inside a meeting chat message. Stored on Firestore as a
/// nested map so the web side can read it later (see `meetingChatMessages`
/// in `src/lib/types.ts`).
class MeetingChatReplyTo {
  const MeetingChatReplyTo({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    required this.preview,
  });

  final String messageId;
  final String senderId;
  final String senderName;
  final String preview;

  static MeetingChatReplyTo? fromMap(dynamic raw) {
    if (raw is! Map) return null;
    final mid = raw['messageId'];
    final sid = raw['senderId'];
    final sname = raw['senderName'];
    final preview = raw['preview'];
    if (mid is! String || mid.isEmpty) return null;
    if (sid is! String) return null;
    if (sname is! String) return null;
    return MeetingChatReplyTo(
      messageId: mid,
      senderId: sid,
      senderName: sname,
      preview: preview is String ? preview : '',
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'messageId': messageId,
        'senderId': senderId,
        'senderName': senderName,
        'preview': preview,
      };
}

/// Модель сообщения чата внутри митинга.
///
/// Wire-формат совпадает с web (`meetings/{id}/messages`):
/// ```
/// {
///   senderId: string,
///   senderName: string,
///   text?: string,
///   attachments: ChatAttachment[],
///   createdAt: Timestamp,
///   updatedAt?: string,
///   isDeleted?: boolean,
///   replyTo?: { messageId, senderId, senderName, preview },
///   reactions?: { [emoji: string]: string[] /* uids */ }
/// }
/// ```
///
/// Удаление на web — мягкое: `updateDoc({ isDeleted: true })`.
class MeetingChatMessage {
  const MeetingChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.text,
    this.attachments = const [],
    this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
    this.replyTo,
    this.reactions = const <String, List<String>>{},
    this.senderAvatar,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String? text;
  final List<MeetingChatAttachment> attachments;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isDeleted;
  final MeetingChatReplyTo? replyTo;

  /// `emoji → list of uids who reacted`. The user is part of a reaction
  /// iff their uid is in the list.
  final Map<String, List<String>> reactions;

  /// Optional sender avatar URL — written at send-time by the composer.
  final String? senderAvatar;

  int get attachmentsCount => attachments.length;

  /// Показывать строку в ленте (в т.ч. «удалено»).
  bool get isVisibleRow => isDeleted || hasPayload;

  bool get hasPayload =>
      (text?.isNotEmpty ?? false) || attachments.isNotEmpty;

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  static List<MeetingChatAttachment> _parseAttachments(dynamic raw) {
    if (raw is! List) return const [];
    final out = <MeetingChatAttachment>[];
    for (final e in raw) {
      final a = MeetingChatAttachment.tryParse(e);
      if (a != null) out.add(a);
    }
    return out;
  }

  static Map<String, List<String>> _parseReactions(dynamic raw) {
    if (raw is! Map) return const <String, List<String>>{};
    final out = <String, List<String>>{};
    raw.forEach((k, v) {
      if (k is! String) return;
      if (v is! List) return;
      final uids = <String>[];
      for (final e in v) {
        if (e is String && e.isNotEmpty) uids.add(e);
      }
      if (uids.isNotEmpty) out[k] = uids;
    });
    return out;
  }

  static MeetingChatMessage? fromFirestore(
    String id,
    Map<String, dynamic>? data,
  ) {
    if (data == null) return null;
    final senderId = data['senderId'];
    final senderName = data['senderName'];
    if (senderId is! String || senderId.isEmpty) return null;
    if (senderName is! String || senderName.isEmpty) return null;
    final text = data['text'];
    final attachments = _parseAttachments(data['attachments']);
    final isDeleted = data['isDeleted'] == true;
    final senderAvatar = data['senderAvatar'];
    return MeetingChatMessage(
      id: id,
      senderId: senderId,
      senderName: senderName,
      text: text is String && text.isNotEmpty ? text : null,
      attachments: attachments,
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
      isDeleted: isDeleted,
      replyTo: MeetingChatReplyTo.fromMap(data['replyTo']),
      reactions: _parseReactions(data['reactions']),
      senderAvatar: senderAvatar is String && senderAvatar.isNotEmpty
          ? senderAvatar
          : null,
    );
  }
}
