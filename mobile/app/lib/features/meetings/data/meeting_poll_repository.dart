import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lighchat_models/lighchat_models.dart';

/// Опросы митинга: `meetings/{meetingId}/polls/{pollId}` — тот же контракт, что
/// [MeetingPolls] на web (`src/components/meetings/MeetingPolls.tsx`).
class MeetingPollRepository {
  MeetingPollRepository(this._fs);

  final FirebaseFirestore _fs;

  CollectionReference<Map<String, dynamic>> _col(String meetingId) =>
      _fs.collection('meetings').doc(meetingId).collection('polls');

  /// Сериализация голосов в Firestore: один вариант — `int`, несколько — список.
  static Map<String, dynamic> votesToFirestore(Map<String, List<int>> votes) {
    final m = <String, dynamic>{};
    for (final e in votes.entries) {
      if (e.value.isEmpty) continue;
      if (e.value.length == 1) {
        m[e.key] = e.value.single;
      } else {
        m[e.key] = e.value;
      }
    }
    return m;
  }

  Stream<List<MeetingPoll>> watchPolls(String meetingId, {int limit = 60}) {
    return _col(meetingId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
      final list = <MeetingPoll>[];
      for (final d in snap.docs) {
        final p = MeetingPoll.fromDoc(d);
        if (p != null) list.add(p);
      }
      return list;
    });
  }

  Future<void> createPoll({
    required String meetingId,
    required String creatorId,
    required String question,
    required List<String> options,
    required bool isAnonymous,
    required bool asDraft,
  }) async {
    final pollId = 'poll-${DateTime.now().millisecondsSinceEpoch}';
    await _col(meetingId).doc(pollId).set(<String, dynamic>{
      'id': pollId,
      'question': question,
      'options': options,
      'creatorId': creatorId,
      'status': asDraft ? 'draft' : 'active',
      'isAnonymous': isAnonymous,
      'createdAt': FieldValue.serverTimestamp(),
      'votes': <String, dynamic>{},
    });
  }

  /// Один голос (как web `handleVote`): uid → индекс варианта.
  Future<void> vote({
    required String meetingId,
    required MeetingPoll poll,
    required String userId,
    required int optionIdx,
    required int participantsCount,
  }) async {
    if (poll.status != 'active') return;
    if (optionIdx < 0 || optionIdx >= poll.options.length) return;
    final newVotes = Map<String, List<int>>.from(poll.votes);
    newVotes[userId] = [optionIdx];
    final update = <String, dynamic>{'votes': votesToFirestore(newVotes)};
    if (participantsCount > 0 && newVotes.length >= participantsCount) {
      update['status'] = 'ended';
    }
    await _col(meetingId).doc(poll.id).update(update);
  }

  Future<void> startPoll(String meetingId, String pollId) async {
    await _col(meetingId).doc(pollId).update(<String, dynamic>{
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> endPoll(String meetingId, String pollId) async {
    await _col(meetingId).doc(pollId).update(<String, dynamic>{
      'status': 'ended',
    });
  }

  Future<void> deletePoll(String meetingId, String pollId) async {
    await _col(meetingId).doc(pollId).delete();
  }

  Future<void> restartPoll(String meetingId, String pollId) async {
    await _col(meetingId).doc(pollId).update(<String, dynamic>{
      'status': 'active',
      'votes': <String, dynamic>{},
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> revokeMyVote({
    required String meetingId,
    required MeetingPoll poll,
    required String userId,
  }) async {
    final newVotes = Map<String, List<int>>.from(poll.votes);
    newVotes.remove(userId);
    await _col(meetingId).doc(poll.id).update(<String, dynamic>{
      'votes': votesToFirestore(newVotes),
    });
  }
}
