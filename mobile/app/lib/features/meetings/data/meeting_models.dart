import 'package:cloud_firestore/cloud_firestore.dart';

/// Зеркало типа `Meeting` из `src/lib/types.ts` для flutter-клиента.
///
/// Совместимость wire-формата описана в
/// `docs/arcitecture/meetings-wire-protocol.md` (§1).
/// Любое изменение полей здесь — breaking для web ↔ mobile.
class MeetingDoc {
  const MeetingDoc({
    required this.id,
    required this.name,
    required this.hostId,
    required this.isPrivate,
    required this.status,
    required this.createdAt,
    this.adminIds = const <String>[],
    this.expiresAt,
    this.isRecording = false,
  });

  final String id;
  final String name;
  final String hostId;
  final List<String> adminIds;
  final bool isPrivate;
  final String status;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isRecording;

  bool isHost(String uid) => hostId == uid;
  bool isAdmin(String uid) => hostId == uid || adminIds.contains(uid);

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  static MeetingDoc? fromFirestore(String id, Map<String, dynamic>? data) {
    if (data == null) return null;
    final name = data['name'];
    final hostId = data['hostId'];
    if (name is! String || hostId is! String) return null;
    final created = _parseDate(data['createdAt']);
    if (created == null) return null;
    final status = data['status'] is String ? data['status'] as String : 'active';
    final rawAdmins = data['adminIds'];
    final admins = rawAdmins is List
        ? rawAdmins.whereType<String>().toList(growable: false)
        : const <String>[];
    return MeetingDoc(
      id: id,
      name: name,
      hostId: hostId,
      adminIds: admins,
      isPrivate: data['isPrivate'] == true,
      status: status,
      createdAt: created,
      expiresAt: _parseDate(data['expiresAt']),
      isRecording: data['isRecording'] == true,
    );
  }
}

/// Живое присутствие участника в комнате. Зеркало `MeetingParticipant` в UI-слое web.
class MeetingParticipant {
  const MeetingParticipant({
    required this.id,
    required this.name,
    this.avatar,
    this.avatarThumb,
    this.role,
    this.lastSeen,
    this.isAudioMuted = false,
    this.isVideoMuted = false,
    this.isHandRaised = false,
    this.isScreenSharing = false,
    this.reaction,
    this.forceMuteAudio = false,
    this.forceMuteVideo = false,
    this.facingMode,
  });

  final String id;
  final String name;
  final String? avatar;
  final String? avatarThumb;
  final String? role;
  final DateTime? lastSeen;
  final bool isAudioMuted;
  final bool isVideoMuted;
  final bool isHandRaised;
  final bool isScreenSharing;
  final String? reaction;
  final bool forceMuteAudio;
  final bool forceMuteVideo;
  final String? facingMode;

  static MeetingParticipant? fromFirestore(String id, Map<String, dynamic>? data) {
    if (data == null) return null;
    final name = data['name'];
    if (name is! String || name.isEmpty) return null;
    DateTime? lastSeen;
    final raw = data['lastSeen'];
    if (raw is Timestamp) {
      lastSeen = raw.toDate();
    } else if (raw is String) {
      lastSeen = DateTime.tryParse(raw);
    }
    return MeetingParticipant(
      id: id,
      name: name,
      avatar: data['avatar'] is String ? data['avatar'] as String : null,
      avatarThumb: data['avatarThumb'] is String
          ? data['avatarThumb'] as String
          : null,
      role: data['role'] is String ? data['role'] as String : null,
      lastSeen: lastSeen,
      isAudioMuted: data['isAudioMuted'] == true,
      isVideoMuted: data['isVideoMuted'] == true,
      isHandRaised: data['isHandRaised'] == true,
      isScreenSharing: data['isScreenSharing'] == true,
      reaction: data['reaction'] is String ? data['reaction'] as String : null,
      forceMuteAudio: data['forceMuteAudio'] == true,
      forceMuteVideo: data['forceMuteVideo'] == true,
      facingMode: data['facingMode'] is String
          ? data['facingMode'] as String
          : null,
    );
  }
}

/// Документ сигналинга (`meetings/{id}/signals/{autoId}`).
class MeetingSignalDoc {
  const MeetingSignalDoc({
    required this.id,
    required this.from,
    required this.to,
    required this.type,
    required this.data,
  });

  final String id;
  final String from;
  final String to;

  /// 'offer' | 'answer' | 'candidate'.
  final String type;

  /// Payload как-есть, формат описан в wire-protocol §3.
  final Map<String, dynamic> data;

  static MeetingSignalDoc? fromFirestore(String id, Map<String, dynamic>? data) {
    if (data == null) return null;
    final from = data['from'];
    final to = data['to'];
    final type = data['type'];
    if (from is! String || to is! String || type is! String) return null;
    final payload = data['data'];
    if (payload is! Map) return null;
    return MeetingSignalDoc(
      id: id,
      from: from,
      to: to,
      type: type,
      data: payload.map((k, v) => MapEntry(k.toString(), v)),
    );
  }
}

/// Заявка в waiting-room (`meetings/{id}/requests/{uid}`).
class MeetingRequestDoc {
  const MeetingRequestDoc({
    required this.userId,
    required this.name,
    required this.status,
    this.avatar,
    this.createdAt,
  });

  final String userId;
  final String name;
  final String? avatar;

  /// 'pending' | 'approved' | 'denied'.
  final String status;
  final DateTime? createdAt;

  static MeetingRequestDoc? fromFirestore(String id, Map<String, dynamic>? data) {
    if (data == null) return null;
    final name = data['name'];
    final status = data['status'];
    if (name is! String || status is! String) return null;
    DateTime? created;
    final raw = data['createdAt'];
    if (raw is Timestamp) {
      created = raw.toDate();
    } else if (raw is String) {
      created = DateTime.tryParse(raw);
    }
    return MeetingRequestDoc(
      userId: id,
      name: name,
      avatar: data['avatar'] is String ? data['avatar'] as String : null,
      status: status,
      createdAt: created,
    );
  }
}
