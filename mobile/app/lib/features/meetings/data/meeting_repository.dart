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
  static const int _whereInChunk = 30;

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
      // ignore: use_null_aware_elements
      if (avatar != null) 'avatar': avatar,
      // ignore: use_null_aware_elements
      if (avatarThumb != null) 'avatarThumb': avatarThumb,
      // ignore: use_null_aware_elements
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
    await _participantsCol(
      meetingId,
    ).doc(userId).update(<String, Object?>{...patch, 'lastSeen': nowIso});
  }

  /// Переключить «поднятую руку» у своего участника.
  /// Web-аналог: `toggleHand` в `src/hooks/use-meeting-webrtc.ts`.
  Future<void> setHandRaised(String meetingId, String userId, bool raised) {
    return updateOwnParticipant(meetingId, userId, <String, Object?>{
      'isHandRaised': raised,
    });
  }

  /// Отправить реакцию-эмодзи. Web ставит `reaction: emoji` и через 3s
  /// сбрасывает в `null` — здесь тот же контракт (auto-reset контролирует
  /// вызывающая сторона; репозиторий — чистый писатель).
  Future<void> setReaction(String meetingId, String userId, String? reaction) {
    return updateOwnParticipant(meetingId, userId, <String, Object?>{
      'reaction': reaction,
    });
  }

  /// История встреч пользователя:
  /// - основа: индекс `userMeetings/{uid}.meetingIds` (как на web),
  /// - fallback: встречи, где пользователь host (если индекс пуст/запаздывает).
  ///
  /// Стрим всегда быстро отдаёт первый кадр (`[]`), чтобы UI не застревал
  /// в бесконечном loading при долгом рукопожатии realtime.
  Stream<List<MeetingDoc>> watchMeetingHistory(
    String userId, {
    int limit = 50,
  }) {
    final uid = userId.trim();
    if (uid.isEmpty) return Stream.value(const <MeetingDoc>[]);

    final safeLimit = limit <= 0 ? 50 : limit;

    return Stream<List<MeetingDoc>>.multi((listener) {
      StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? indexSub;
      StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? hostedSub;
      final indexedMeetingSubs =
          <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];

      var hostedById = <String, MeetingDoc>{};
      var indexedById = <String, MeetingDoc>{};
      var indexEpoch = 0;

      List<MeetingDoc> mergeAndSort() {
        final merged = <String, MeetingDoc>{...hostedById, ...indexedById};
        final list = merged.values.toList(growable: false)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list.take(safeLimit).toList(growable: false);
      }

      void publish() {
        listener.add(mergeAndSort());
      }

      Future<void> cancelIndexedMeetingSubs() async {
        for (final sub in indexedMeetingSubs) {
          await sub.cancel();
        }
        indexedMeetingSubs.clear();
      }

      Future<void> attachIndexedMeetings(List<String> rawIds) async {
        final epoch = ++indexEpoch;
        await cancelIndexedMeetingSubs();
        if (epoch != indexEpoch) return;

        final unique = rawIds
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList(growable: false);

        if (unique.isEmpty) {
          indexedById = <String, MeetingDoc>{};
          publish();
          return;
        }

        final maxIndexedIds = max(safeLimit * 4, 60);
        final capped = unique.length > maxIndexedIds
            ? unique.sublist(unique.length - maxIndexedIds)
            : unique;

        final batches = <List<String>>[];
        for (var i = 0; i < capped.length; i += _whereInChunk) {
          batches.add(capped.sublist(i, min(i + _whereInChunk, capped.length)));
        }

        final perBatch = <int, Map<String, MeetingDoc>>{};
        final batchReady = List<bool>.filled(batches.length, false);

        void publishIfReady() {
          if (epoch != indexEpoch) return;
          if (batchReady.any((ready) => !ready)) return;
          final next = <String, MeetingDoc>{};
          for (final m in perBatch.values) {
            next.addAll(m);
          }
          indexedById = next;
          publish();
        }

        for (var bi = 0; bi < batches.length; bi++) {
          final batch = batches[bi];
          final sub = _firestore
              .collection('meetings')
              .where(FieldPath.documentId, whereIn: batch)
              .snapshots()
              .listen(
                (snap) {
                  if (epoch != indexEpoch) return;
                  final next = <String, MeetingDoc>{};
                  for (final d in snap.docs) {
                    final meeting = MeetingDoc.fromFirestore(d.id, d.data());
                    if (meeting != null) next[d.id] = meeting;
                  }
                  perBatch[bi] = next;
                  batchReady[bi] = true;
                  publishIfReady();
                },
                onError: (Object error, StackTrace stackTrace) {
                  if (epoch != indexEpoch) return;
                  perBatch[bi] = <String, MeetingDoc>{};
                  batchReady[bi] = true;
                  publishIfReady();
                },
              );
          indexedMeetingSubs.add(sub);
        }
      }

      listener.add(const <MeetingDoc>[]);

      hostedSub = _firestore
          .collection('meetings')
          .where('hostId', isEqualTo: uid)
          .limit(max(safeLimit * 2, 60))
          .snapshots()
          .listen(
            (snap) {
              final next = <String, MeetingDoc>{};
              for (final d in snap.docs) {
                final meeting = MeetingDoc.fromFirestore(d.id, d.data());
                if (meeting != null) next[d.id] = meeting;
              }
              hostedById = next;
              publish();
            },
            onError: (Object error, StackTrace stackTrace) {
              hostedById = <String, MeetingDoc>{};
              publish();
            },
          );

      indexSub = _firestore
          .doc('userMeetings/$uid')
          .snapshots()
          .listen(
            (snap) {
              final raw = snap.data()?['meetingIds'];
              final ids = raw is List
                  ? raw
                        .map((e) => e is String ? e : e?.toString())
                        .whereType<String>()
                        .toList(growable: false)
                  : const <String>[];
              unawaited(attachIndexedMeetings(ids));
            },
            onError: (Object error, StackTrace stackTrace) {
              indexedById = <String, MeetingDoc>{};
              publish();
            },
          );

      listener.onCancel = () async {
        indexEpoch++;
        await indexSub?.cancel();
        await hostedSub?.cancel();
        await cancelIndexedMeetingSubs();
      };
    });
  }

  /// Legacy alias: сохранён для обратной совместимости вызовов.
  Stream<List<MeetingDoc>> watchMyHostedMeetings(
    String hostId, {
    int limit = 50,
  }) {
    return watchMeetingHistory(hostId, limit: limit);
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
