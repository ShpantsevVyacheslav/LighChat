import 'dart:async';
import 'dart:math' show min;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'chat_call_record.dart';
import 'chat_call_status.dart';

/// Снимок истории звонков для UI.
class ChatCallsHistorySnapshot {
  const ChatCallsHistorySnapshot({
    required this.calls,
    required this.loading,
    this.error,
  });

  final List<ChatCallRecord> calls;
  final bool loading;
  final String? error;
}

/// Подписка на `userCalls/{uid}` и батчи `calls` через `whereIn` (до 30 id, как на вебе).
class ChatCallsRepository {
  ChatCallsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const int _whereInChunk = 30;

  Stream<ChatCallsHistorySnapshot> watchHistory(String uid) {
    return Stream<ChatCallsHistorySnapshot>.multi((listener) {
      StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? userSub;
      final callSubs =
          <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];

      Future<void> cancelCallSubs() async {
        for (final s in callSubs) {
          await s.cancel();
        }
        callSubs.clear();
      }

      Future<void> attachCallIds(List<String> rawIds) async {
        await cancelCallSubs();
        final unique = rawIds
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList(growable: false);
        if (unique.isEmpty) {
          listener.add(
            const ChatCallsHistorySnapshot(
              calls: <ChatCallRecord>[],
              loading: false,
            ),
          );
          return;
        }

        final batches = <List<String>>[];
        for (var i = 0; i < unique.length; i += _whereInChunk) {
          batches.add(unique.sublist(i, min(i + _whereInChunk, unique.length)));
        }

        final perBatch = <int, Map<String, ChatCallRecord>>{};
        final batchReady = List<bool>.filled(batches.length, false);

        void publish() {
          final allReady = batchReady.every((e) => e);
          final merged = <String, ChatCallRecord>{};
          for (final m in perBatch.values) {
            merged.addAll(m);
          }
          final list =
              merged.values
                  .where((c) => isTerminalCallStatus(c.status))
                  .toList(growable: false)
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          listener.add(
            ChatCallsHistorySnapshot(calls: list, loading: !allReady),
          );
        }

        listener.add(
          ChatCallsHistorySnapshot(
            calls: const <ChatCallRecord>[],
            loading: true,
          ),
        );

        for (var bi = 0; bi < batches.length; bi++) {
          final batch = batches[bi];
          final sub = _firestore
              .collection('calls')
              .where(FieldPath.documentId, whereIn: batch)
              .snapshots()
              .listen(
                (snap) {
                  final m = <String, ChatCallRecord>{};
                  for (final d in snap.docs) {
                    final parsed = ChatCallRecord.fromFirestore(d.id, d.data());
                    if (parsed != null) m[d.id] = parsed;
                  }
                  perBatch[bi] = m;
                  batchReady[bi] = true;
                  publish();
                },
                onError: (Object e, StackTrace st) {
                  debugPrint(
                    '[ChatCallsRepository] calls batch listen: $e $st',
                  );
                  listener.add(
                    ChatCallsHistorySnapshot(
                      calls: const <ChatCallRecord>[],
                      loading: false,
                      error: e.toString(),
                    ),
                  );
                },
              );
          callSubs.add(sub);
        }
      }

      listener.add(
        const ChatCallsHistorySnapshot(
          calls: <ChatCallRecord>[],
          loading: true,
        ),
      );

      userSub = _firestore
          .doc('userCalls/$uid')
          .snapshots()
          .listen(
            (snap) {
              final raw = snap.data()?['callIds'];
              final ids = raw is List
                  ? raw
                        .map((e) => e is String ? e : e?.toString())
                        .whereType<String>()
                        .where((e) => e.trim().isNotEmpty)
                        .toList(growable: false)
                  : const <String>[];
              unawaited(attachCallIds(ids));
            },
            onError: (Object e, StackTrace st) {
              debugPrint('[ChatCallsRepository] userCalls listen: $e $st');
              listener.add(
                ChatCallsHistorySnapshot(
                  calls: const <ChatCallRecord>[],
                  loading: false,
                  error: e.toString(),
                ),
              );
            },
          );

      listener.onCancel = () async {
        await userSub?.cancel();
        await cancelCallSubs();
      };
    });
  }
}
