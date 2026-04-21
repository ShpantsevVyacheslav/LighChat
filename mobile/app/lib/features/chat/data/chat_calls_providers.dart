import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lighchat_mobile/app_providers.dart';

import 'chat_call_record.dart';
import 'chat_calls_repository.dart';

final chatCallsRepositoryProvider = Provider<ChatCallsRepository>((ref) {
  return ChatCallsRepository(FirebaseFirestore.instance);
});

/// История звонков текущего пользователя (`userCalls` + `calls`).
final chatCallsHistoryProvider =
    StreamProvider.autoDispose<ChatCallsHistorySnapshot>((ref) {
      final user = ref.watch(authUserProvider).asData?.value;
      if (user == null) {
        return Stream.value(
          const ChatCallsHistorySnapshot(
            calls: <ChatCallRecord>[],
            loading: false,
          ),
        );
      }
      final repo = ref.watch(chatCallsRepositoryProvider);
      return repo.watchHistory(user.uid);
    });

/// Один документ `calls/{callId}` (экран деталей).
final chatCallDocProvider =
    StreamProvider.autoDispose.family<ChatCallRecord?, String>((ref, callId) {
      final trimmed = callId.trim();
      if (trimmed.isEmpty) {
        return Stream.value(null);
      }
      return FirebaseFirestore.instance
          .collection('calls')
          .doc(trimmed)
          .snapshots()
          .map((snap) {
            if (!snap.exists) return null;
            final data = snap.data();
            if (data == null) return null;
            return ChatCallRecord.fromFirestore(snap.id, data);
          });
    });
