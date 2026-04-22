import 'package:cloud_firestore/cloud_firestore.dart';

import 'meeting_chat_attachment.dart';

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
///   isDeleted?: boolean
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
  });

  final String id;
  final String senderId;
  final String senderName;
  final String? text;
  final List<MeetingChatAttachment> attachments;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isDeleted;

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
    return MeetingChatMessage(
      id: id,
      senderId: senderId,
      senderName: senderName,
      text: text is String && text.isNotEmpty ? text : null,
      attachments: attachments,
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
      isDeleted: isDeleted,
    );
  }
}
