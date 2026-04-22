import 'package:cloud_firestore/cloud_firestore.dart';

import 'meeting_chat_message.dart';

/// Репозиторий чата внутри митинга — отдельный от [MeetingRepository],
/// чтобы не смешивать ответственности (присутствие/подписки на участников
/// vs. чат). Wire-контракт описан в [MeetingChatMessage].
///
/// Правила Firestore (`firestore.rules` → `meetings/{id}/messages`):
///   - read: isMeetingMember (host + adminIds + approved guest + обычный
///     залогиненный участник с docом в `participants/{uid}`);
///   - create: isMeetingMember && senderId == auth.uid;
///   - update/delete: автор сообщения или admin.
///
/// Отправка текста и вложений, правка текста и мягкое удаление (`isDeleted`).
class MeetingChatRepository {
  MeetingChatRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _messagesCol(String meetingId) =>
      _firestore.collection('meetings').doc(meetingId).collection('messages');

  /// Подписка на последние [limit] сообщений в порядке возрастания
  /// `createdAt`. Web тоже использует `limitToLast` c asc-порядком —
  /// так список выглядит корректно даже на первом snapshot'е.
  Stream<List<MeetingChatMessage>> watchMessages(
    String meetingId, {
    int limit = 120,
  }) {
    final q = _messagesCol(meetingId)
        .orderBy('createdAt')
        .limitToLast(limit);
    return q.snapshots().map((snap) {
      final list = <MeetingChatMessage>[];
      for (final d in snap.docs) {
        final m = MeetingChatMessage.fromFirestore(d.id, d.data());
        if (m != null && m.isVisibleRow) list.add(m);
      }
      return list;
    });
  }

  /// Отправить текстовое сообщение. Пустая строка / только-пробелы —
  /// игнорируем (совпадает с поведением web-input'а).
  Future<void> sendText({
    required String meetingId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    await sendMessage(
      meetingId: meetingId,
      senderId: senderId,
      senderName: senderName,
      text: text,
      attachmentMaps: const [],
    );
  }

  /// Сообщение с текстом и/или вложениями (wire как на web).
  Future<void> sendMessage({
    required String meetingId,
    required String senderId,
    required String senderName,
    required String text,
    required List<Map<String, dynamic>> attachmentMaps,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && attachmentMaps.isEmpty) return;
    final data = <String, Object?>{
      'senderId': senderId,
      'senderName': senderName,
      'attachments': attachmentMaps,
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (trimmed.isNotEmpty) {
      data['text'] = trimmed;
    }
    await _messagesCol(meetingId).add(data);
  }

  /// Обновить текст (web: `updatedAt` — ISO-строка).
  Future<void> updateMessageText({
    required String meetingId,
    required String messageId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(text, 'text', 'empty');
    }
    await _messagesCol(meetingId).doc(messageId).update(<String, Object?>{
      'text': trimmed,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Мягкое удаление, как на web (`MeetingSidebar.tsx`).
  Future<void> softDeleteMessage({
    required String meetingId,
    required String messageId,
  }) async {
    await _messagesCol(meetingId).doc(messageId).update(<String, Object?>{
      'isDeleted': true,
    });
  }
}
