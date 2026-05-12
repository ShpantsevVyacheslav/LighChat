import 'dart:async';
import 'dart:math' show min;

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:lighchat_mobile/core/app_logger.dart';
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

/// Подписка на `userCalls/{uid}` и документы `calls/{callId}`.
///
/// Важно: `whereIn(documentId, [...])` падает целиком с permission-denied, если хотя бы один
/// callId не читается правилами (например, устаревший id в `userCalls`). Поэтому читаем по doc.
class ChatCallsRepository {
  ChatCallsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const int _whereInChunk = 30;

  Stream<ChatCallsHistorySnapshot> watchHistory(String uid) {
    return Stream<ChatCallsHistorySnapshot>.multi((listener) {
      StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? userSub;
      final callSubs = <StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>[];

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

        // Keep chunk constant for future parity, but subscribe per-document to avoid
        // query-level permission failures.
        final batches = <List<String>>[];
        for (var i = 0; i < unique.length; i += _whereInChunk) {
          batches.add(unique.sublist(i, min(i + _whereInChunk, unique.length)));
        }

        final byId = <String, ChatCallRecord>{};
        final ready = <String, bool>{for (final id in unique) id: false};

        void publish() {
          final list =
              byId.values
                  .where((c) => isTerminalCallStatus(c.status))
                  .toList(growable: false)
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          listener.add(
            ChatCallsHistorySnapshot(
              calls: list,
              loading: ready.values.any((v) => v == false),
            ),
          );
        }

        listener.add(
          ChatCallsHistorySnapshot(
            calls: const <ChatCallRecord>[],
            loading: true,
          ),
        );

        for (final batch in batches) {
          for (final id in batch) {
            final sub = _firestore
                .collection('calls')
                .doc(id)
                .snapshots()
                .listen(
                  (snap) {
                    ready[id] = true;
                    if (!snap.exists) {
                      byId.remove(id);
                      publish();
                      return;
                    }
                    final data = snap.data();
                    if (data == null) {
                      byId.remove(id);
                      publish();
                      return;
                    }
                    final parsed = ChatCallRecord.fromFirestore(snap.id, data);
                    if (parsed == null) {
                      byId.remove(id);
                      publish();
                      return;
                    }
                    byId[id] = parsed;
                    publish();
                  },
                  onError: (Object e, StackTrace st) {
                    // If a single call doc is not readable (permission-denied),
                    // skip it instead of failing the whole history view.
                    appLogger.w('[ChatCallsRepository] call doc listen $id', error: e, stackTrace: st);
                    ready[id] = true;
                    byId.remove(id);
                    publish();
                  },
                );
            callSubs.add(sub);
          }
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
              appLogger.w('[ChatCallsRepository] userCalls listen', error: e, stackTrace: st);
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
