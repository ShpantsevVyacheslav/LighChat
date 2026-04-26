import 'package:cloud_firestore/cloud_firestore.dart';

/// Документ `calls/{callId}` — зеркало веб-типа `Call`.
class ChatCallRecord {
  const ChatCallRecord({
    required this.id,
    required this.callerId,
    required this.receiverId,
    required this.callerName,
    this.receiverName,
    required this.status,
    required this.isVideo,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
    this.endedBy,
  });

  final String id;
  final String callerId;
  final String receiverId;
  final String callerName;
  final String? receiverName;
  final String status;
  final bool isVideo;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String? endedBy;

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is String) {
      return DateTime.tryParse(v);
    }
    return null;
  }

  static ChatCallRecord? fromFirestore(String id, Map<String, dynamic> data) {
    final callerId = data['callerId'];
    final receiverId = data['receiverId'];
    final callerName = data['callerName'];
    if (callerId is! String || receiverId is! String || callerName is! String) {
      return null;
    }
    final status = data['status'];
    if (status is! String) return null;
    final created = _parseDate(data['createdAt']);
    if (created == null) return null;
    final receiverName = data['receiverName'];
    final isVideo = data['isVideo'] == true;
    return ChatCallRecord(
      id: id,
      callerId: callerId,
      receiverId: receiverId,
      callerName: callerName,
      receiverName: receiverName is String ? receiverName : null,
      status: status,
      isVideo: isVideo,
      createdAt: created,
      startedAt: _parseDate(data['startedAt']),
      endedAt: _parseDate(data['endedAt']),
      endedBy: data['endedBy'] is String ? data['endedBy'] as String : null,
    );
  }
}
