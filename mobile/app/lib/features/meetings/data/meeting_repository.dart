import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'meeting_models.dart';

/// CRUD и подписки на митинг + его подколлекции (participants/requests).
/// Сигналинг (signals) вынесен в `meeting_signaling.dart` как отдельная отв.
///
/// Wire-контракт — см. `docs/arcitecture/meetings-wire-protocol.md`.
/// Все ISO-timestamps — UTC, чтобы совпадало с web-клиентом (там тоже `new Date().toISOString()`).
class MeetingRepository {
  MeetingRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _meetingDoc(String id) =>
      _firestore.collection('meetings').doc(id);

  CollectionReference<Map<String, dynamic>> _participantsCol(String id) =>
      _meetingDoc(id).collection('participants');

  CollectionReference<Map<String, dynamic>> _requestsCol(String id) =>
      _meetingDoc(id).collection('requests');

  /// Создаёт митинг. Правила требуют `hostId == auth.uid` и `id == meetingId`.
  Future<String> createMeeting({
    required String hostId,
    required String name,
    required bool isPrivate,
    Duration? duration,
  }) async {
    final id = _generateMeetingId();
    final now = DateTime.now().toUtc();
    final expiresAt = duration == null ? null : now.add(duration);
    await _meetingDoc(id).set(<String, Object?>{
      'id': id,
      'name': name,
      'hostId': hostId,
      'isPrivate': isPrivate,
      'status': 'active',
      'createdAt': now.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    });
    return id;
  }

  Stream<MeetingDoc?> watchMeeting(String meetingId) {
    return _meetingDoc(meetingId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return MeetingDoc.fromFirestore(snap.id, snap.data());
    });
  }

  Stream<List<MeetingParticipant>> watchParticipants(String meetingId) {
    return _participantsCol(meetingId).snapshots().map((snap) {
      final list = <MeetingParticipant>[];
      for (final d in snap.docs) {
        final p = MeetingParticipant.fromFirestore(d.id, d.data());
        if (p != null) list.add(p);
      }
      return list;
    });
  }

  Stream<List<MeetingRequestDoc>> watchRequests(String meetingId) {
    return _requestsCol(meetingId).snapshots().map((snap) {
      final list = <MeetingRequestDoc>[];
      for (final d in snap.docs) {
        final r = MeetingRequestDoc.fromFirestore(d.id, d.data());
        if (r != null) list.add(r);
      }
      return list;
    });
  }

  Stream<MeetingRequestDoc?> watchOwnRequest(String meetingId, String userId) {
    return _requestsCol(meetingId).doc(userId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return MeetingRequestDoc.fromFirestore(snap.id, snap.data());
    });
  }

  /// Создаёт/мержит собственный документ участника. Вход в комнату.
  Future<void> joinMeeting({
    required String meetingId,
    required String userId,
    required String name,
    String? avatar,
    String? avatarThumb,
    String? role,
  }) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    await _participantsCol(meetingId).doc(userId).set(<String, Object?>{
      'id': userId,
      'name': name,
      if (avatar != null) 'avatar': avatar,
      if (avatarThumb != null) 'avatarThumb': avatarThumb,
      if (role != null) 'role': role,
      'joinedAt': FieldValue.serverTimestamp(),
      'lastSeen': nowIso,
      'isAudioMuted': false,
      'isVideoMuted': false,
      'isHandRaised': false,
      'isScreenSharing': false,
    }, SetOptions(merge: true));
  }

  /// Обновить локальные поля своего участника (mute/hand/reaction).
  Future<void> updateOwnParticipant(
    String meetingId,
    String userId,
    Map<String, Object?> patch,
  ) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    await _participantsCol(meetingId).doc(userId).update(<String, Object?>{
      ...patch,
      'lastSeen': nowIso,
    });
  }

  /// Переключить «поднятую руку» у своего участника.
  /// Web-аналог: `toggleHand` в `src/hooks/use-meeting-webrtc.ts`.
  Future<void> setHandRaised(
    String meetingId,
    String userId,
    bool raised,
  ) {
    return updateOwnParticipant(
      meetingId,
      userId,
      <String, Object?>{'isHandRaised': raised},
    );
  }

  /// Отправить реакцию-эмодзи. Web ставит `reaction: emoji` и через 3s
  /// сбрасывает в `null` — здесь тот же контракт (auto-reset контролирует
  /// вызывающая сторона; репозиторий — чистый писатель).
  Future<void> setReaction(
    String meetingId,
    String userId,
    String? reaction,
  ) {
    return updateOwnParticipant(
      meetingId,
      userId,
      <String, Object?>{'reaction': reaction},
    );
  }

  /// История встреч: митинги, где пользователь — host. Web тоже показывает
  /// только свои встречи (см. waiting-room-аудит / роль host'а).
  /// Ограничение 50 — расширить по требованию.
  Stream<List<MeetingDoc>> watchMyHostedMeetings(String hostId,
      {int limit = 50}) {
    return _firestore
        .collection('meetings')
        .where('hostId', isEqualTo: hostId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
      final list = <MeetingDoc>[];
      for (final d in snap.docs) {
        final m = MeetingDoc.fromFirestore(d.id, d.data());
        if (m != null) list.add(m);
      }
      return list;
    });
  }

  /// Heartbeat присутствия. Клиент вызывает раз в 20 сек; scheduler чистит
  /// застарелые документы с порогом 90 сек (см. wire-protocol §5).
  Future<void> heartbeat(String meetingId, String userId) {
    return _participantsCol(meetingId).doc(userId).update(<String, Object?>{
      'lastSeen': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Покинуть комнату. Допустимо вызвать несколько раз (идемпотентно — delete).
  Future<void> leaveMeeting(String meetingId, String userId) async {
    try {
      await _participantsCol(meetingId).doc(userId).delete();
    } catch (_) {
      // Документ уже удалён планировщиком / хостом — это нормально.
    }
  }

  String _generateMeetingId() {
    const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rnd = Random.secure();
    final buf = StringBuffer();
    for (var i = 0; i < 12; i++) {
      buf.write(alphabet[rnd.nextInt(alphabet.length)]);
    }
    return buf.toString();
  }
}
