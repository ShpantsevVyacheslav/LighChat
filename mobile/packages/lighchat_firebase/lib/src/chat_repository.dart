import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

import 'package:lighchat_models/lighchat_models.dart';

class ChatRepository {
  ChatRepository({FirebaseFirestore? firestore, Logger? logger})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _logger = logger ?? Logger();

  static const Duration _userChatIndexInitialTimeout = Duration(seconds: 15);

  final FirebaseFirestore _firestore;
  final Logger _logger;

  /// Сначала [DocumentReference.get] с таймаутом — иначе при проблемах сети первый [snapshots] может не прийти
  /// и [StreamProvider] в приложении остаётся в loading.
  Stream<UserChatIndex?> watchUserChatIndex({required String userId}) {
    final ref = _firestore
        .collection('userChats')
        .doc(userId)
        .withConverter<UserChatIndex?>(
          fromFirestore: (snap, options) {
            try {
              final data = snap.data();
              if (!snap.exists || data == null) return null;
              return UserChatIndex.fromJson(data);
            } catch (e, st) {
              _logger.w('UserChatIndex parse failed', error: e, stackTrace: st);
              return null;
            }
          },
          toFirestore: (value, options) => <String, Object?>{},
        );

    return () async* {
      try {
        final initial = await ref.get().timeout(_userChatIndexInitialTimeout);
        yield initial.data();
      } catch (e, st) {
        _logger.w(
          'userChats/$userId initial get failed',
          error: e,
          stackTrace: st,
        );
        yield null;
      }
      await for (final snap in ref.snapshots()) {
        yield snap.data();
      }
    }();
  }

  /// Mirrors the web strategy: subscribe to each `conversations/{id}` doc
  /// individually (avoid list-query limitations under rules).
  Stream<List<ConversationWithId>> watchConversationsByIds(
    List<String> conversationIds,
  ) {
    final ids = conversationIds.where((s) => s.isNotEmpty).toSet().toList()
      ..sort();
    if (ids.isEmpty) return Stream.value(const <ConversationWithId>[]);

    final controller = StreamController<List<ConversationWithId>>();
    final byId = <String, ConversationWithId>{};
    final subs = <StreamSubscription<DocumentSnapshot<ConversationWithId?>?>>[];

    void publish() {
      final ordered = ids
          .map((id) => byId[id])
          .whereType<ConversationWithId>()
          .toList(growable: false);
      controller.add(ordered);
    }

    for (final id in ids) {
      final ref = _firestore
          .collection('conversations')
          .doc(id)
          .withConverter<ConversationWithId?>(
            fromFirestore: (snap, options) {
              try {
                final data = snap.data();
                if (!snap.exists || data == null) return null;
                return ConversationWithId(
                  id: snap.id,
                  data: Conversation.fromJson(data),
                );
              } catch (e, st) {
                _logger.w(
                  'Conversation parse failed: $id',
                  error: e,
                  stackTrace: st,
                );
                return null;
              }
            },
            toFirestore: (value, options) => <String, Object?>{},
          );
      subs.add(
        ref.snapshots().listen(
          (snap) {
            final v = snap.data();
            if (v == null) {
              byId.remove(id);
            } else {
              byId[id] = v;
            }
            publish();
          },
          onError: (Object e, StackTrace st) {
            // permission-denied is expected when access revoked; drop silently.
            _logger.w(
              'Conversation snapshot error: $id',
              error: e,
              stackTrace: st,
            );
            byId.remove(id);
            publish();
          },
        ),
      );
    }

    controller.onCancel = () async {
      for (final s in subs) {
        try {
          await s.cancel();
        } catch (_) {}
      }
    };

    // Сразу отдаём пустой список, чтобы [StreamProvider] не зависал в loading до первых snapshot'ов.
    publish();
    return controller.stream;
  }

  Stream<List<ChatMessage>> watchMessages({
    required String conversationId,
    required int limit,
  }) {
    final q = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .withConverter<ChatMessage?>(
          fromFirestore: (snap, options) => ChatMessage.fromDoc(snap),
          toFirestore: (value, options) => <String, Object?>{},
        );

    return q.snapshots().map((snap) {
      return snap.docs
          .map((d) => d.data())
          .whereType<ChatMessage>()
          .toList(growable: false);
    });
  }

  Future<void> sendTextMessage({
    required String conversationId,
    required String senderId,
    required String text,
    ReplyContext? replyTo,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final payload = <String, Object?>{
      'senderId': senderId,
      'text': trimmed,
      // Use client device time (requested parity for mobile timestamps).
      // NOTE: this may differ from server time if device clock is skewed.
      'createdAt': Timestamp.now(),
    };

    if (replyTo != null) {
      payload['replyTo'] = <String, Object?>{
        'messageId': replyTo.messageId,
        'senderName': replyTo.senderName,
        if (replyTo.text != null && replyTo.text!.trim().isNotEmpty)
          'text': replyTo.text!.trim(),
        if (replyTo.mediaPreviewUrl != null &&
            replyTo.mediaPreviewUrl!.trim().isNotEmpty)
          'mediaPreviewUrl': replyTo.mediaPreviewUrl!.trim(),
        if (replyTo.mediaType != null && replyTo.mediaType!.trim().isNotEmpty)
          'mediaType': replyTo.mediaType!.trim(),
      };
    }

    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add(payload);
  }

  /// Web-parity: find existing 1:1 chat between users or create it.
  /// NOTE: this mirrors `src/lib/direct-chat.ts` (index scan + getDoc).
  Future<String> createOrOpenDirectChat({
    required String currentUserId,
    required String otherUserId,
    required ({String name, String? avatar, String? avatarThumb})
    currentUserInfo,
    required ({String name, String? avatar, String? avatarThumb}) otherUserInfo,
  }) async {
    final indexSnap = await _firestore
        .collection('userChats')
        .doc(currentUserId)
        .get();
    final ids = indexSnap.exists
        ? ((indexSnap.data()?['conversationIds'] as List?)
                  ?.whereType<String>()
                  .where((s) => s.isNotEmpty)
                  .toList() ??
              const <String>[])
        : const <String>[];

    for (final convId in ids) {
      final d = await _firestore.collection('conversations').doc(convId).get();
      if (!d.exists) continue;
      final data = d.data();
      if (data == null) continue;
      final isGroup = data['isGroup'] == true;
      final pRaw = data['participantIds'];
      final p = (pRaw is List ? pRaw : const <Object?>[])
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toList();
      if (!isGroup &&
          p.length == 2 &&
          p.contains(currentUserId) &&
          p.contains(otherUserId)) {
        return d.id;
      }
    }

    final newRef = _firestore.collection('conversations').doc();
    await newRef.set(<String, Object?>{
      'isGroup': false,
      'participantIds': [currentUserId, otherUserId],
      'adminIds': const <String>[],
      'participantInfo': <String, Object?>{
        currentUserId: <String, Object?>{
          'name': currentUserInfo.name,
          if (currentUserInfo.avatar != null) 'avatar': currentUserInfo.avatar,
          if (currentUserInfo.avatarThumb != null)
            'avatarThumb': currentUserInfo.avatarThumb,
        },
        otherUserId: <String, Object?>{
          'name': otherUserInfo.name,
          if (otherUserInfo.avatar != null) 'avatar': otherUserInfo.avatar,
          if (otherUserInfo.avatarThumb != null)
            'avatarThumb': otherUserInfo.avatarThumb,
        },
      },
      'lastMessageTimestamp': DateTime.now().toUtc().toIso8601String(),
      'lastMessageText': 'Чат создан',
      'unreadCounts': <String, Object?>{currentUserId: 0, otherUserId: 0},
      'unreadThreadCounts': <String, Object?>{currentUserId: 0, otherUserId: 0},
      'typing': <String, Object?>{},
    });
    _logger.i('Created direct chat: ${newRef.id}');
    return newRef.id;
  }

  /// Ensure personal saved-messages chat exists for current user and return its id.
  Future<String> ensureSavedMessagesChat({
    required String currentUserId,
    required ({String name, String? avatar, String? avatarThumb})
    currentUserInfo,
  }) async {
    final indexSnap = await _firestore
        .collection('userChats')
        .doc(currentUserId)
        .get();
    final ids = indexSnap.exists
        ? ((indexSnap.data()?['conversationIds'] as List?)
                  ?.whereType<String>()
                  .where((s) => s.isNotEmpty)
                  .toList() ??
              const <String>[])
        : const <String>[];

    for (final convId in ids) {
      final d = await _firestore.collection('conversations').doc(convId).get();
      if (!d.exists) continue;
      final data = d.data();
      if (data == null) continue;
      final isGroup = data['isGroup'] == true;
      final pRaw = data['participantIds'];
      final p = (pRaw is List ? pRaw : const <Object?>[])
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toList();
      if (!isGroup && p.length == 1 && p.first == currentUserId) {
        return d.id;
      }
    }

    final newRef = _firestore.collection('conversations').doc();
    await newRef.set(<String, Object?>{
      'isGroup': false,
      'name': 'Избранное',
      'participantIds': <String>[currentUserId],
      'adminIds': const <String>[],
      'participantInfo': <String, Object?>{
        currentUserId: <String, Object?>{
          'name': currentUserInfo.name,
          if (currentUserInfo.avatar != null) 'avatar': currentUserInfo.avatar,
          if (currentUserInfo.avatarThumb != null)
            'avatarThumb': currentUserInfo.avatarThumb,
        },
      },
      'lastMessageTimestamp': DateTime.now().toUtc().toIso8601String(),
      'lastMessageText': '',
      'unreadCounts': <String, Object?>{currentUserId: 0},
      'unreadThreadCounts': <String, Object?>{currentUserId: 0},
      'typing': <String, Object?>{},
    });
    _logger.i('Created saved messages chat: ${newRef.id}');
    return newRef.id;
  }

  String _createdAtComparable(Object? raw) {
    if (raw is Timestamp) return raw.toDate().toUtc().toIso8601String();
    if (raw is String && raw.isNotEmpty) return raw;
    return '';
  }

  List<ChatAttachment> _attachmentsFromRaw(Object? raw) {
    return (raw is List ? raw : const <Object?>[])
        .whereType<Map>()
        .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
        .map(ChatAttachment.fromJson)
        .whereType<ChatAttachment>()
        .toList();
  }

  /// Plain-text edit (web parity for non-E2E messages).
  Future<void> updateMessageText({
    required String conversationId,
    required String messageId,
    required String text,
    List<ChatAttachment>? attachments,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final msgRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId);
    final msgSnap = await msgRef.get();
    if (!msgSnap.exists) return;
    final msgData = msgSnap.data();
    if (msgData == null) return;

    final now = DateTime.now().toUtc().toIso8601String();
    final update = <String, Object?>{'text': trimmed, 'updatedAt': now};
    final att = attachments ?? _attachmentsFromRaw(msgData['attachments']);
    update['attachments'] = att.map((a) => a.toFirestoreMap()).toList();

    await msgRef.update(update);

    final convRef = _firestore.collection('conversations').doc(conversationId);
    final convSnap = await convRef.get();
    final convData = convSnap.data();
    if (convData == null) return;
    final lastTs = convData['lastMessageTimestamp'];
    final createdKey = _createdAtComparable(msgData['createdAt']);
    final lastKey = lastTs is String ? lastTs : '';
    if (lastKey.isNotEmpty && createdKey.isNotEmpty && lastKey == createdKey) {
      var plain = trimmed
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll('&nbsp;', ' ')
          .trim();
      if (plain.length > 100) plain = plain.substring(0, 100);
      await convRef.update(<String, Object?>{'lastMessageText': plain});
    }
  }

  /// Soft delete (web: `isDeleted: true` + optional unread fix).
  Future<void> softDeleteMessage({
    required String conversationId,
    required String messageId,
  }) async {
    final msgRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId);
    final msgSnap = await msgRef.get();
    if (!msgSnap.exists) return;
    final msgData = msgSnap.data();
    if (msgData == null) return;

    final now = DateTime.now().toUtc().toIso8601String();
    await msgRef.update(<String, Object?>{'isDeleted': true, 'updatedAt': now});

    final readAt = msgData['readAt'];
    final hasReadAt = readAt != null && !((readAt is String && readAt.isEmpty));

    if (!hasReadAt) {
      final senderId = msgData['senderId'];
      if (senderId is! String) return;
      final convRef = _firestore
          .collection('conversations')
          .doc(conversationId);
      final convSnap = await convRef.get();
      final convData = convSnap.data();
      if (convData == null) return;
      final pRaw = convData['participantIds'];
      final participantIds = (pRaw is List ? pRaw : const <Object?>[])
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toList();
      final others = participantIds.where((id) => id != senderId).toList();
      if (others.isEmpty) return;
      final updates = <String, Object?>{};
      for (final uid in others) {
        updates['unreadCounts.$uid'] = FieldValue.increment(-1);
      }
      try {
        await convRef.update(updates);
      } catch (e, st) {
        _logger.w(
          'Unread decrement after delete failed',
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  /// Replace `pinnedMessages` and clear legacy `pinnedMessage` (web parity).
  Future<void> setPinnedMessages({
    required String conversationId,
    required List<PinnedMessage> pins,
  }) async {
    final convRef = _firestore.collection('conversations').doc(conversationId);
    if (pins.isEmpty) {
      await convRef.update(<String, Object?>{
        'pinnedMessages': FieldValue.delete(),
        'pinnedMessage': FieldValue.delete(),
      });
    } else {
      await convRef.update(<String, Object?>{
        'pinnedMessages': pins.map((p) => p.toFirestoreMap()).toList(),
        'pinnedMessage': FieldValue.delete(),
      });
    }
  }

  /// Forward one or more messages into target chats (web `ChatForwardSheet` batch shape).
  Future<void> forwardMessagesToChats({
    required String currentUserId,
    required List<String> targetConversationIds,
    required List<ChatMessage> sourceMessages,
    required Map<String, String> senderIdToDisplayName,
  }) async {
    if (targetConversationIds.isEmpty || sourceMessages.isEmpty) return;
    final nowIso = DateTime.now().toUtc().toIso8601String();

    for (final convId in targetConversationIds) {
      final convRef = _firestore.collection('conversations').doc(convId);
      final convSnap = await convRef.get();
      if (!convSnap.exists) continue;
      final convData = convSnap.data();
      if (convData == null) continue;
      final pRaw = convData['participantIds'];
      final participantIds = (pRaw is List ? pRaw : const <Object?>[])
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toList();
      if (!participantIds.contains(currentUserId)) continue;

      final batch = _firestore.batch();
      for (final m in sourceMessages) {
        if (m.isDeleted) continue;
        final newRef = convRef.collection('messages').doc();
        final fromName = senderIdToDisplayName[m.senderId] ?? 'Неизвестный';
        final payload = <String, Object?>{
          'senderId': currentUserId,
          'createdAt': Timestamp.now(),
          'isDeleted': false,
          'readAt': null,
          'forwardedFrom': <String, Object?>{'name': fromName},
          if (m.text != null && m.text!.trim().isNotEmpty)
            'text': m.text!.trim(),
          if (m.attachments.isNotEmpty)
            'attachments': m.attachments
                .map((a) => a.toFirestoreMap())
                .toList(),
        };
        batch.set(newRef, payload);
      }

      var lastMessageText = 'Пересланное сообщение';
      final active = sourceMessages.where((x) => !x.isDeleted).toList();
      if (active.length > 1) {
        lastMessageText = 'Переслано ${active.length} сообщений';
      } else if (active.isNotEmpty) {
        final one = active.first;
        if (one.text != null && one.text!.trim().isNotEmpty) {
          var plain = one.text!
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .replaceAll('&nbsp;', ' ')
              .trim();
          if (plain.length > 50) plain = '${plain.substring(0, 50)}...';
          lastMessageText = 'Переслано: $plain';
        } else if (one.attachments.isNotEmpty) {
          lastMessageText = 'Пересланное вложение';
        }
      }

      final unread = <String, Object?>{};
      final n = active.length;
      for (final id in participantIds) {
        if (id != currentUserId) {
          unread['unreadCounts.$id'] = FieldValue.increment(n);
        }
      }

      batch.update(convRef, <String, Object?>{
        'lastMessageText': lastMessageText,
        'lastMessageTimestamp': nowIso,
        'lastMessageSenderId': currentUserId,
        'lastMessageIsThread': false,
        ...unread,
      });

      await batch.commit();
    }
  }
}
