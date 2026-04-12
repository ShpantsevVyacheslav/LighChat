import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:logger/logger.dart';

import 'package:lighchat_models/lighchat_models.dart';

/// Элемент ответа callable `checkGroupInvitesAllowed` (web `CheckGroupInvitesResult`).
class GroupInviteDenied {
  const GroupInviteDenied({required this.uid, required this.reason});

  final String uid;
  final String reason;
}

class GroupInvitesCheckResult {
  const GroupInvitesCheckResult({required this.ok, required this.denied});

  final bool ok;
  final List<GroupInviteDenied> denied;
}

class ChatRepository {
  ChatRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    Logger? logger,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _logger = logger ?? Logger();

  static const Duration _userChatIndexInitialTimeout = Duration(seconds: 15);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final Logger _logger;

  /// Web `placeholder-images.json` → `group-avatar-placeholder`.
  static const String _groupAvatarPlaceholderUrl =
      'https://images.unsplash.com/photo-1511632765486-a01980e01a18?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=MnwzNDE5ODJ8MHwxfHNlYXJjaHwxfHxncm91cCUyMHBvcHVsYXRpb258ZW58MHx8fHwxNjYwNjIzNzY5&ixlib=rb-4.1.0&q=80&w=1080';

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

  /// Сообщение из основной ленты (для экрана ветки без `extra` в роуте).
  Future<ChatMessage?> getChatMessage({
    required String conversationId,
    required String messageId,
  }) async {
    if (conversationId.isEmpty || messageId.isEmpty) return null;
    final doc = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .get();
    return ChatMessage.fromDoc(doc);
  }

  /// Подколлекция веба: `conversations/.../messages/{parentId}/thread`.
  Stream<List<ChatMessage>> watchThreadMessages({
    required String conversationId,
    required String parentMessageId,
    int limit = 200,
  }) {
    if (conversationId.isEmpty || parentMessageId.isEmpty) {
      return Stream.value(const <ChatMessage>[]);
    }
    final q = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(parentMessageId)
        .collection('thread')
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

  static String _threadLastPreviewText({
    required String trimmedPlainText,
    required List<ChatAttachment> attachments,
  }) {
    if (trimmedPlainText.isNotEmpty) return trimmedPlainText;
    if (attachments.isEmpty) return 'Сообщение';
    final n = attachments.first.name.toLowerCase();
    if (n.startsWith('sticker_')) return 'Стикер';
    if (n.startsWith('gif_')) return 'GIF';
    return 'Вложение';
  }

  /// Отправка текста в ветку (паритет `ThreadWindow.handleSendMessage` без E2EE/загрузки файлов).
  Future<void> sendThreadTextMessage({
    required String conversationId,
    required String parentMessageId,
    required String senderId,
    String text = '',
    List<ChatAttachment> attachments = const [],
    ReplyContext? replyTo,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && attachments.isEmpty) return;

    final convSnap =
        await _firestore.collection('conversations').doc(conversationId).get();
    final convData = convSnap.data();
    if (convData == null) return;

    final pRaw = convData['participantIds'];
    final participantIds = (pRaw is List ? pRaw : const <Object?>[])
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList();
    final others = participantIds.where((id) => id != senderId).toList();

    final nowIso = DateTime.now().toUtc().toIso8601String();
    final threadLastText = _threadLastPreviewText(
      trimmedPlainText: trimmed,
      attachments: attachments,
    );

    final threadCol = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(parentMessageId)
        .collection('thread');

    final newDoc = threadCol.doc();
    final payload = <String, Object?>{
      'senderId': senderId,
      'createdAt': nowIso,
      'attachments': attachments.map((a) => a.toFirestoreMap()).toList(),
      if (trimmed.isNotEmpty) 'text': trimmed,
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

    await newDoc.set(payload);

    final parentRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(parentMessageId);
    final convRef = _firestore.collection('conversations').doc(conversationId);

    final unreadUpdates = <String, Object?>{};
    for (final id in others) {
      unreadUpdates['unreadThreadCounts.$id'] = FieldValue.increment(1);
    }

    await parentRef.update(<String, Object?>{
      'threadCount': FieldValue.increment(1),
      'lastThreadMessageText': threadLastText,
      'lastThreadMessageSenderId': senderId,
      'lastThreadMessageTimestamp': nowIso,
      ...unreadUpdates,
    });

    await convRef.update(<String, Object?>{
      'lastMessageText': threadLastText,
      'lastMessageTimestamp': nowIso,
      'lastMessageSenderId': senderId,
      'lastMessageIsThread': true,
      ...unreadUpdates,
    });
  }

  Future<void> sendTextMessage({
    required String conversationId,
    required String senderId,
    String text = '',
    ReplyContext? replyTo,
    List<ChatAttachment> attachments = const [],
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && attachments.isEmpty) return;

    final payload = <String, Object?>{
      'senderId': senderId,
      // Use client device time (requested parity for mobile timestamps).
      // NOTE: this may differ from server time if device clock is skewed.
      'createdAt': Timestamp.now(),
      if (trimmed.isNotEmpty) 'text': trimmed,
      if (attachments.isNotEmpty)
        'attachments': attachments.map((a) => a.toFirestoreMap()).toList(),
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

  Map<String, Object?> _locationShareToFirestore(ChatLocationShare s) {
    return <String, Object?>{
      'lat': s.lat,
      'lng': s.lng,
      'mapsUrl': s.mapsUrl,
      'capturedAt': s.capturedAt,
      if (s.accuracyM != null) 'accuracyM': s.accuracyM,
      if (s.staticMapUrl != null && s.staticMapUrl!.trim().isNotEmpty)
        'staticMapUrl': s.staticMapUrl!.trim(),
      if (s.liveSession != null)
        'liveSession': <String, Object?>{
          'expiresAt': s.liveSession!.expiresAt,
        },
    };
  }

  /// Паритет `ChatWindow.handleSendLocationShare`.
  Future<void> sendLocationShareMessage({
    required String conversationId,
    required String senderId,
    required List<String> participantIds,
    required ChatLocationShare locationShare,
    ReplyContext? replyTo,
    required bool activateUserLiveShare,
    String? userLiveExpiresAt,
  }) async {
    final payload = <String, Object?>{
      'senderId': senderId,
      'createdAt': Timestamp.now(),
      'locationShare': _locationShareToFirestore(locationShare),
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

    final nowIso = DateTime.now().toUtc().toIso8601String();
    final convRef = _firestore.collection('conversations').doc(conversationId);
    final unread = <String, Object?>{};
    for (final id in participantIds) {
      if (id.isNotEmpty && id != senderId) {
        unread['unreadCounts.$id'] = FieldValue.increment(1);
      }
    }
    await convRef.update(<String, Object?>{
      'lastMessageText': '📍 Геолокация',
      'lastMessageTimestamp': nowIso,
      'lastMessageSenderId': senderId,
      'lastMessageIsThread': false,
      ...unread,
    });

    if (activateUserLiveShare) {
      await _firestore.collection('users').doc(senderId).update(<String, Object?>{
        'liveLocationShare': <String, Object?>{
          'active': true,
          'expiresAt': userLiveExpiresAt,
          'lat': locationShare.lat,
          'lng': locationShare.lng,
          if (locationShare.accuracyM != null) 'accuracyM': locationShare.accuracyM,
          'updatedAt': nowIso,
          'startedAt': nowIso,
        },
      });
    }
    _logger.i('Location share sent in $conversationId');
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

  /// Реакция на сообщение (паритет `ChatWindow.handleReactTo` на вебе).
  Future<void> toggleMessageReaction({
    required String conversationId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    if (emoji.isEmpty) return;
    final msgRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId);
    final convRef = _firestore.collection('conversations').doc(conversationId);

    final snap = await msgRef.get();
    if (!snap.exists) return;
    final data = snap.data();
    if (data == null) return;

    final parsed = parseReactions(data['reactions']) ?? <String, List<ReactionEntry>>{};
    final reactions = <String, List<ReactionEntry>>{
      for (final e in parsed.entries) e.key: List<ReactionEntry>.from(e.value),
    };
    final list = List<ReactionEntry>.from(reactions[emoji] ?? []);
    final existingIdx = list.indexWhere((r) => r.userId == userId);
    final now = DateTime.now().toUtc().toIso8601String();
    var added = false;
    if (existingIdx >= 0) {
      list.removeAt(existingIdx);
      if (list.isEmpty) {
        reactions.remove(emoji);
      } else {
        reactions[emoji] = list;
      }
    } else {
      reactions[emoji] = [...list, ReactionEntry(userId: userId, timestamp: now)];
      added = true;
    }

    final firestoreMap = <String, dynamic>{};
    for (final e in reactions.entries) {
      firestoreMap[e.key] = e.value
          .map(
            (r) => <String, dynamic>{
              'userId': r.userId,
              if (r.timestamp != null && r.timestamp!.isNotEmpty) 'timestamp': r.timestamp,
            },
          )
          .toList();
    }

    await msgRef.update(<String, Object?>{
      'reactions': firestoreMap,
      'lastReactionTimestamp': now,
    });

    if (added) {
      try {
        await convRef.update(<String, Object?>{
          'lastReactionEmoji': emoji,
          'lastReactionTimestamp': now,
          'lastReactionSenderId': userId,
          'lastReactionMessageId': messageId,
          'lastReactionParentId': null,
        });
      } catch (e, st) {
        _logger.w('conv lastReaction update failed', error: e, stackTrace: st);
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

  static const String _groupInviteConnectivityMessage =
      'Не удалось связаться с сервером для проверки приглашений в группу. '
      'Проверьте интернет и DNS (например, отключите VPN или смените сеть), '
      'затем повторите попытку.';

  static bool _isCloudFunctionConnectivityFailure(Object error) {
    if (error is FirebaseException) {
      final code = error.code.toLowerCase();
      final msg = (error.message ?? '').toLowerCase();
      if (code == 'unavailable' ||
          code == 'unknown' ||
          code == 'deadline-exceeded' ||
          code == 'network-error' ||
          msg.contains('hostname') ||
          msg.contains('could not be found') ||
          msg.contains('host lookup failed')) {
        return true;
      }
    }
    if (error is PlatformException) {
      final m = '${error.message}'.toLowerCase();
      final d = '${error.details}'.toLowerCase();
      if (m.contains('hostname') ||
          m.contains('could not be found') ||
          d.contains('hostname')) {
        return true;
      }
    }
    final s = error.toString().toLowerCase();
    return s.contains('hostname could not be found') ||
        (s.contains('could not be found') && s.contains('server'));
  }

  /// Web `checkGroupInvitesAllowed` (us-central1).
  Future<GroupInvitesCheckResult> checkGroupInvitesAllowed(
    List<String> targetUserIds,
  ) async {
    final ids = targetUserIds.where((s) => s.isNotEmpty).toList();
    if (ids.isEmpty) {
      return const GroupInvitesCheckResult(ok: true, denied: []);
    }
    final FirebaseApp app;
    try {
      app = Firebase.app();
    } catch (e, st) {
      _logger.w('checkGroupInvitesAllowed: no Firebase app', error: e, stackTrace: st);
      throw StateError(
        'Firebase не инициализирован. Перезапустите приложение или проверьте '
        'настройки FlutterFire (нужен нативный appId, не :web:).',
      );
    }

    final functions = FirebaseFunctions.instanceFor(app: app, region: 'us-central1');
    final callable = functions.httpsCallable(
      'checkGroupInvitesAllowed',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 40)),
    );
    try {
      final res = await callable.call(<String, dynamic>{'targetUserIds': ids});
      final raw = res.data;
      if (raw is! Map) {
        _logger.w('checkGroupInvitesAllowed: unexpected response $raw');
        return const GroupInvitesCheckResult(ok: true, denied: []);
      }
      final m = raw.map((k, v) => MapEntry(k.toString(), v));
      final ok = m['ok'] == true;
      final deniedRaw = m['denied'];
      final denied = <GroupInviteDenied>[];
      if (deniedRaw is List) {
        for (final e in deniedRaw) {
          if (e is! Map) continue;
          final dm = e.map((k, v) => MapEntry(k.toString(), v));
          final uid = dm['uid'];
          final reason = dm['reason'];
          if (uid is String && uid.isNotEmpty && reason is String) {
            denied.add(GroupInviteDenied(uid: uid, reason: reason));
          }
        }
      }
      return GroupInvitesCheckResult(ok: ok, denied: denied);
    } catch (e, st) {
      if (_isCloudFunctionConnectivityFailure(e)) {
        _logger.w(
          'checkGroupInvitesAllowed: connectivity/DNS failure',
          error: e,
          stackTrace: st,
        );
        throw StateError(_groupInviteConnectivityMessage);
      }
      rethrow;
    }
  }

  /// Новая групповая беседа (web `GroupChatFormPanel`, только создание).
  ///
  /// [groupPhotoJpeg]: после [set] документа беседы загружается в `group-avatars/{id}/`
  /// (иначе Storage rules не дадут записать до появления участника в Firestore).
  Future<String> createGroupChat({
    required String currentUserId,
    required String currentUserName,
    required String name,
    String? description,
    required List<({String id, String name})> additionalParticipants,
    Uint8List? groupPhotoJpeg,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'empty');
    }

    final extra = additionalParticipants.where((e) => e.id.isNotEmpty).toList();
    if (extra.any((e) => e.id == currentUserId)) {
      throw ArgumentError('additionalParticipants must not contain current user');
    }

    final extraIds = extra.map((e) => e.id).toList();
    if (extraIds.isNotEmpty) {
      final check = await checkGroupInvitesAllowed(extraIds);
      if (!check.ok) {
        final msg = _formatGroupInviteDenied(check.denied, extra);
        throw StateError(msg);
      }
    }

    final conversationId = 'group_${DateTime.now().millisecondsSinceEpoch}';
    final participantIds = <String>[currentUserId, ...extraIds];
    final nameById = <String, String>{
      currentUserId: currentUserName,
      for (final e in extra) e.id: e.name,
    };

    final participantInfo = <String, Object?>{
      for (final id in participantIds)
        id: <String, Object?>{
          'name': nameById[id] ?? 'Неизвестный',
        },
    };

    final unreadCounts = <String, Object?>{
      for (final id in participantIds) id: 0,
    };
    final unreadThreadCounts = <String, Object?>{
      for (final id in participantIds) id: 0,
    };

    await _firestore.collection('conversations').doc(conversationId).set(<String, Object?>{
      'isGroup': true,
      'name': trimmedName,
      if (description != null && description.trim().isNotEmpty) 'description': description.trim(),
      'photoUrl': _groupAvatarPlaceholderUrl,
      'participantIds': participantIds,
      'adminIds': const <String>[],
      'participantInfo': participantInfo,
      'createdByUserId': currentUserId,
      'lastMessageTimestamp': DateTime.now().toUtc().toIso8601String(),
      'lastMessageText': '$currentUserName создал(а) группу',
      'unreadCounts': unreadCounts,
      'unreadThreadCounts': unreadThreadCounts,
      'typing': <String, Object?>{},
    });

    final photo = groupPhotoJpeg;
    if (photo != null && photo.isNotEmpty) {
      try {
        final objectPath =
            'group-avatars/$conversationId/${DateTime.now().millisecondsSinceEpoch}_group.jpg';
        final ref = _storage.ref(objectPath);
        await ref.putData(
          photo,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        final url = await ref.getDownloadURL();
        await _firestore.collection('conversations').doc(conversationId).update(<String, Object?>{
          'photoUrl': url,
        });
      } catch (e, st) {
        _logger.w(
          'Group avatar upload failed, placeholder kept',
          error: e,
          stackTrace: st,
        );
      }
    }

    _logger.i('Created group chat: $conversationId');
    return conversationId;
  }

  String _formatGroupInviteDenied(
    List<GroupInviteDenied> denied,
    List<({String id, String name})> participants,
  ) {
    String nameFor(String uid) {
      for (final e in participants) {
        if (e.id == uid) return e.name;
      }
      return 'Участник';
    }

    return denied.map((d) {
      final n = nameFor(d.uid);
      return d.reason == 'none'
          ? '$n не принимает приглашения в группы'
          : '$n разрешает групповые приглашения только от людей из своих контактов';
    }).join(' ');
  }
}
