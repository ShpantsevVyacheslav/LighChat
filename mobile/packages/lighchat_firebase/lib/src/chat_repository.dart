import 'dart:async';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:logger/logger.dart';

import 'package:lighchat_models/lighchat_models.dart';

import 'chat_open_diagnostics.dart';
import 'firebase_callable_http.dart';

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

/// Phase 0 safety guard: mobile пока не умеет шифровать исходящие сообщения
/// и редактировать зашифрованные. Пока нет Phase 4 клиента — мы блокируем
/// такие операции на уровне репозитория, чтобы не утечь plaintext в Firestore
/// в чатах, где собеседник на вебе ждёт E2EE-ciphertext.
///
/// Распознаётся по code='e2ee_not_supported_on_mobile'. UI переводит в
/// человекочитаемое сообщение и предлагает отправить с веба.
class E2eeNotSupportedOnMobileException implements Exception {
  const E2eeNotSupportedOnMobileException([this.message]);

  final String? message;

  String get code => 'e2ee_not_supported_on_mobile';

  @override
  String toString() => 'E2eeNotSupportedOnMobileException(${message ?? code})';
}

class ChatRepository {
  ChatRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    Logger? logger,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _logger = logger ?? Logger();

  static const Duration _userChatIndexInitialTimeout = Duration(seconds: 15);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final Logger _logger;
  final Set<String> _inFlightReadKeys = <String>{};

  /// Возвращает true, если документ диалога активно зашифрован (E2EE
  /// включён И эпоха ключа > 0 — значит обёртки ключа уже созданы на вебе).
  /// Используется Phase 0 safety guard'ом, чтобы не писать plaintext в чаты,
  /// где веб-клиент ждёт ciphertext.
  static bool _isE2eeActive(Map<String, dynamic> convData) {
    final enabled = convData['e2eeEnabled'];
    if (enabled != true) return false;
    final epoch = convData['e2eeKeyEpoch'];
    if (epoch is int) return epoch > 0;
    if (epoch is num) return epoch.toInt() > 0;
    return false;
  }

  bool _shouldRetryWithFreshToken(FirebaseException e) {
    final code = e.code.toLowerCase();
    return code == 'permission-denied' || code == 'unauthenticated';
  }

  Future<T> _withAuthRefreshRetry<T>(Future<T> Function() op) async {
    try {
      return await op();
    } on FirebaseException catch (e, st) {
      if (!_shouldRetryWithFreshToken(e)) rethrow;
      _logger.w(
        'Retrying Firebase operation after token refresh code=${e.code}',
        error: e,
        stackTrace: st,
      );
      await fb_auth.FirebaseAuth.instance.currentUser?.getIdToken(true);
      return op();
    }
  }

  DocumentReference<Map<String, dynamic>> _messageDocRef({
    required String conversationId,
    required String messageId,
    String? threadParentMessageId,
  }) {
    final conv = _firestore.collection('conversations').doc(conversationId);
    final parent = threadParentMessageId?.trim();
    if (parent == null || parent.isEmpty) {
      return conv.collection('messages').doc(messageId);
    }
    return conv
        .collection('messages')
        .doc(parent)
        .collection('thread')
        .doc(messageId);
  }

  ChatMessage _withPendingWriteStatus(
    ChatMessage message, {
    required bool hasPendingWrites,
  }) {
    if (!hasPendingWrites || message.deliveryStatus == 'failed') return message;
    if (message.deliveryStatus == 'sending') return message;
    return ChatMessage(
      id: message.id,
      senderId: message.senderId,
      text: message.text,
      attachments: message.attachments,
      replyTo: message.replyTo,
      isDeleted: message.isDeleted,
      reactions: message.reactions,
      createdAt: message.createdAt,
      readAt: message.readAt,
      updatedAt: message.updatedAt,
      forwardedFrom: message.forwardedFrom,
      deliveryStatus: 'sending',
      chatPollId: message.chatPollId,
      locationShare: message.locationShare,
      threadCount: message.threadCount,
      unreadThreadCounts: message.unreadThreadCounts,
      lastThreadMessageText: message.lastThreadMessageText,
      lastThreadMessageSenderId: message.lastThreadMessageSenderId,
      lastThreadMessageTimestamp: message.lastThreadMessageTimestamp,
      hasE2eeCiphertext: message.hasE2eeCiphertext,
      e2eePayload: message.e2eePayload,
      mediaNorm: message.mediaNorm,
      emojiBurst: message.emojiBurst,
      systemEvent: message.systemEvent,
      voiceTranscript: message.voiceTranscript,
    );
  }

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

  /// Индекс секретных чатов (`userSecretChats/{uid}`), зеркалит структуру [UserChatIndex].
  Stream<UserChatIndex?> watchUserSecretChatIndex({required String userId}) {
    final ref = _firestore
        .collection('userSecretChats')
        .doc(userId)
        .withConverter<UserChatIndex?>(
          fromFirestore: (snap, options) {
            try {
              final data = snap.data();
              if (!snap.exists || data == null) return null;
              return UserChatIndex.fromJson(data);
            } catch (e, st) {
              _logger.w(
                'UserSecretChatIndex parse failed',
                error: e,
                stackTrace: st,
              );
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
          'userSecretChats/$userId initial get failed',
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
          fromFirestore: (snap, options) {
            try {
              return ChatMessage.fromDoc(snap);
            } catch (e, st) {
              _logger.w(
                'ChatMessage parse failed ${snap.id}',
                error: e,
                stackTrace: st,
              );
              return null;
            }
          },
          toFirestore: (value, options) => <String, Object?>{},
        );

    final controller = StreamController<List<ChatMessage>>();
    StreamSubscription<QuerySnapshot<ChatMessage?>>? sub;
    var retried = false;

    void emitFrom(QuerySnapshot<ChatMessage?> snap) {
      final out = <ChatMessage>[];
      for (final d in snap.docs) {
        final parsed = d.data();
        if (parsed == null) continue;
        out.add(
          _withPendingWriteStatus(
            parsed,
            hasPendingWrites: d.metadata.hasPendingWrites,
          ),
        );
      }
      controller.add(out);
    }

    Future<void> start() async {
      await sub?.cancel().catchError((_) {});
      sub = q
          .snapshots(includeMetadataChanges: true)
          .listen(
            emitFrom,
            onError: (Object err, StackTrace st) async {
              final code = err is FirebaseException
                  ? err.code.toLowerCase().trim()
                  : '';
              final shouldRetry =
                  !retried &&
                  (code == 'permission-denied' || code == 'unauthenticated');
              if (!shouldRetry) {
                if (code == 'permission-denied' || code == 'unauthenticated') {
                  try {
                    await logChatOpenDiagnostics(
                      stage: 'watchMessages.onError.final',
                      conversationId: conversationId,
                      error: err,
                      stackTrace: st,
                      logger: _logger,
                    );
                  } catch (_) {}
                }
                controller.addError(err, st);
                return;
              }
              retried = true;
              try {
                await logChatOpenDiagnostics(
                  stage: 'watchMessages.onError.before_refresh',
                  conversationId: conversationId,
                  error: err,
                  stackTrace: st,
                  logger: _logger,
                );
              } catch (_) {}
              try {
                await fb_auth.FirebaseAuth.instance.currentUser?.getIdToken(
                  true,
                );
              } catch (e, st2) {
                // Important: on older iOS builds/VPN/mitm cases token refresh fails
                // with TLS errors (-1200 / -9816) and Firestore will keep denying reads.
                _logger.w(
                  'watchMessages token refresh failed',
                  error: e,
                  stackTrace: st2,
                );
              }
              await start();
            },
          );
    }

    unawaited(start());
    controller.onCancel = () async {
      await sub?.cancel().catchError((_) {});
    };
    return controller.stream;
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
          fromFirestore: (snap, options) {
            try {
              return ChatMessage.fromDoc(snap);
            } catch (e, st) {
              _logger.w(
                'Thread ChatMessage parse failed ${snap.id}',
                error: e,
                stackTrace: st,
              );
              return null;
            }
          },
          toFirestore: (value, options) => <String, Object?>{},
        );

    final controller = StreamController<List<ChatMessage>>();
    StreamSubscription<QuerySnapshot<ChatMessage?>>? sub;
    var retried = false;

    void emitFrom(QuerySnapshot<ChatMessage?> snap) {
      final out = <ChatMessage>[];
      for (final d in snap.docs) {
        final parsed = d.data();
        if (parsed == null) continue;
        out.add(
          _withPendingWriteStatus(
            parsed,
            hasPendingWrites: d.metadata.hasPendingWrites,
          ),
        );
      }
      controller.add(out);
    }

    Future<void> start() async {
      await sub?.cancel().catchError((_) {});
      sub = q
          .snapshots(includeMetadataChanges: true)
          .listen(
            emitFrom,
            onError: (Object err, StackTrace st) async {
              final code = err is FirebaseException
                  ? err.code.toLowerCase().trim()
                  : '';
              final shouldRetry =
                  !retried &&
                  (code == 'permission-denied' || code == 'unauthenticated');
              if (!shouldRetry) {
                if (code == 'permission-denied' || code == 'unauthenticated') {
                  try {
                    await logChatOpenDiagnostics(
                      stage: 'watchThreadMessages.onError.final',
                      conversationId: conversationId,
                      error: err,
                      stackTrace: st,
                      logger: _logger,
                    );
                  } catch (_) {}
                }
                controller.addError(err, st);
                return;
              }
              retried = true;
              try {
                await logChatOpenDiagnostics(
                  stage: 'watchThreadMessages.onError.before_refresh',
                  conversationId: conversationId,
                  error: err,
                  stackTrace: st,
                  logger: _logger,
                );
              } catch (_) {}
              try {
                await fb_auth.FirebaseAuth.instance.currentUser?.getIdToken(
                  true,
                );
              } catch (e, st2) {
                _logger.w(
                  'watchThreadMessages token refresh failed',
                  error: e,
                  stackTrace: st2,
                );
              }
              await start();
            },
          );
    }

    unawaited(start());
    controller.onCancel = () async {
      await sub?.cancel().catchError((_) {});
    };
    return controller.stream;
  }

  /// Marker constants stored in Firestore `lastMessageText`.
  /// Translated to the user's locale on the UI side.
  static const kPreviewMessage = '{{message}}';
  static const kPreviewSticker = '{{sticker}}';
  static const kPreviewAttachment = '{{attachment}}';
  static const kPreviewEncrypted = '{{encrypted}}';

  static String _threadLastPreviewText({
    required String trimmedPlainText,
    required List<ChatAttachment> attachments,
  }) {
    if (trimmedPlainText.isNotEmpty) return trimmedPlainText;
    if (attachments.isEmpty) return kPreviewMessage;
    final n = attachments.first.name.toLowerCase();
    if (n.startsWith('sticker_')) return kPreviewSticker;
    if (n.startsWith('gif_')) return 'GIF';
    return kPreviewAttachment;
  }

  /// Превью для `conversations.lastMessageText` из HTML основного чата.
  static String _mainChatLastPreviewText({
    required String trimmedHtml,
    required List<ChatAttachment> attachments,
  }) {
    var plain = trimmedHtml
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&#x27;', "'")
        .trim();
    if (plain.length > 100) plain = plain.substring(0, 100);
    return _threadLastPreviewText(
      trimmedPlainText: plain,
      attachments: attachments,
    );
  }

  /// Отправка текста в ветку (паритет `ThreadWindow.handleSendMessage` без E2EE/загрузки файлов).
  Future<void> sendThreadTextMessage({
    required String conversationId,
    required String parentMessageId,
    required String senderId,
    String text = '',
    List<ChatAttachment> attachments = const [],
    ReplyContext? replyTo,
    Map<String, Object?>? e2eeEnvelope,
    String? messageIdOverride,

    /// См. одноимённый параметр в [sendTextMessage] — то же самое, но для
    /// thread-сообщений.
    String? voiceTranscript,
  }) async {
    final trimmed = text.trim();
    final hasE2ee = e2eeEnvelope != null;
    if (trimmed.isEmpty && attachments.isEmpty && !hasE2ee) return;

    final convSnap = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .get();
    final convData = convSnap.data();
    if (convData == null) return;
    // Phase 4: пропускаем E2EE-active чат только если есть envelope.
    if (_isE2eeActive(convData) && !hasE2ee) {
      throw const E2eeNotSupportedOnMobileException(
        'E2EE thread reply requires encrypted envelope '
        '(attachments not yet supported on mobile)',
      );
    }

    final pRaw = convData['participantIds'];
    final participantIds = (pRaw is List ? pRaw : const <Object?>[])
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList();
    final others = participantIds.where((id) => id != senderId).toList();

    final nowIso = DateTime.now().toUtc().toIso8601String();
    final threadLastText = hasE2ee
        ? kPreviewEncrypted
        : _threadLastPreviewText(
            trimmedPlainText: trimmed,
            attachments: attachments,
          );

    final threadCol = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(parentMessageId)
        .collection('thread');

    final newDoc =
        messageIdOverride != null && messageIdOverride.trim().isNotEmpty
        ? threadCol.doc(messageIdOverride)
        : threadCol.doc();
    final transcriptTrimmed = voiceTranscript?.trim() ?? '';
    final payload = <String, Object?>{
      'senderId': senderId,
      'createdAt': nowIso,
      'attachments': attachments.map((a) => a.toFirestoreMap()).toList(),
      if (!hasE2ee && trimmed.isNotEmpty) 'text': trimmed,
      if (hasE2ee) 'e2ee': e2eeEnvelope,
      if (!hasE2ee && transcriptTrimmed.isNotEmpty)
        'voiceTranscript': transcriptTrimmed,
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

  /// Геолокация в подколлекцию `messages/{parentId}/thread` (паритет основного чата).
  Future<void> sendThreadLocationShareMessage({
    required String conversationId,
    required String parentMessageId,
    required String senderId,
    required List<String> participantIds,
    required ChatLocationShare locationShare,
    required bool activateUserLiveShare,
    String? userLiveExpiresAt,
  }) async {
    if (conversationId.isEmpty || parentMessageId.isEmpty) return;
    final others = participantIds.where((id) => id != senderId).toList();
    final nowIso = DateTime.now().toUtc().toIso8601String();

    final threadCol = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(parentMessageId)
        .collection('thread');

    final newDoc = threadCol.doc();
    await newDoc.set(<String, Object?>{
      'senderId': senderId,
      'createdAt': nowIso,
      'locationShare': _locationShareToFirestore(locationShare),
    });

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
      'lastThreadMessageText': '📍 Геолокация',
      'lastThreadMessageSenderId': senderId,
      'lastThreadMessageTimestamp': nowIso,
      ...unreadUpdates,
    });

    await convRef.update(<String, Object?>{
      'lastMessageText': '📍 Геолокация',
      'lastMessageTimestamp': nowIso,
      'lastMessageSenderId': senderId,
      'lastMessageIsThread': true,
      ...unreadUpdates,
    });

    if (activateUserLiveShare) {
      await _firestore.collection('users').doc(senderId).update(
        <String, Object?>{
          'liveLocationShare': <String, Object?>{
            'active': true,
            'expiresAt': userLiveExpiresAt,
            'lat': locationShare.lat,
            'lng': locationShare.lng,
            if (locationShare.accuracyM != null)
              'accuracyM': locationShare.accuracyM,
            'updatedAt': nowIso,
            'startedAt': nowIso,
            // Bug #15: записываем id чата, в котором началась
            // трансляция — chat list использует это поле, чтобы
            // подсветить именно этот ряд индикатором «идёт live».
            'conversationId': conversationId,
          },
        },
      );
    }
    _logger.i('Thread location share sent in $conversationId/$parentMessageId');
  }

  /// Опрос в ветку: документ опроса в `polls/` + сообщение в `…/thread/`.
  Future<void> sendThreadChatPollMessage({
    required String conversationId,
    required String parentMessageId,
    required String senderId,
    required List<String> participantIds,
    required ChatPollCreatePayload pollPayload,
  }) async {
    if (conversationId.isEmpty || parentMessageId.isEmpty) return;
    final opts = pollPayload.options
        .map((e) => e.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (pollPayload.question.trim().isEmpty || opts.length < 2) return;

    final others = participantIds.where((id) => id != senderId).toList();
    final pollId = 'chat-poll-${DateTime.now().millisecondsSinceEpoch}';
    final pollRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('polls')
        .doc(pollId);

    final threadMsgRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(parentMessageId)
        .collection('thread')
        .doc();

    final parentRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(parentMessageId);
    final convRef = _firestore.collection('conversations').doc(conversationId);

    Future<void> runStep(String step, Future<void> Function() fn) async {
      try {
        await fn();
      } on TimeoutException catch (_) {
        _logger.e('sendThreadChatPollMessage timeout at step=$step');
        throw StateError('poll_send_timeout:$step');
      } on FirebaseException catch (e, st) {
        _logger.e(
          'sendThreadChatPollMessage firebase error at step=$step code=${e.code} message=${e.message}',
          error: e,
          stackTrace: st,
        );
        throw StateError(
          'poll_send_firebase:$step:${e.code}:${e.message ?? ''}',
        );
      } catch (e, st) {
        _logger.e(
          'sendThreadChatPollMessage error at step=$step',
          error: e,
          stackTrace: st,
        );
        throw StateError('poll_send_error:$step:$e');
      }
    }

    final nowIso = DateTime.now().toUtc().toIso8601String();
    final msg = <String, Object?>{
      'senderId': senderId,
      'createdAt': nowIso,
      'text': '<p>📊 Опрос</p>',
      'chatPollId': pollId,
    };

    final unreadUpdates = <String, Object?>{};
    for (final id in others) {
      unreadUpdates['unreadThreadCounts.$id'] = FieldValue.increment(1);
    }

    await runStep('batch_commit', () async {
      final batch = _firestore.batch();
      batch.set(pollRef, <String, Object?>{
        ...pollPayload.pollDocumentFields(pollId, senderId),
        'createdAt': nowIso,
      });
      batch.set(threadMsgRef, msg);
      batch.update(parentRef, <String, Object?>{
        'threadCount': FieldValue.increment(1),
        'lastThreadMessageText': '📊 Опрос',
        'lastThreadMessageSenderId': senderId,
        'lastThreadMessageTimestamp': nowIso,
        ...unreadUpdates,
      });
      batch.update(convRef, <String, Object?>{
        'lastMessageText': '📊 Опрос',
        'lastMessageTimestamp': nowIso,
        'lastMessageSenderId': senderId,
        'lastMessageIsThread': true,
        ...unreadUpdates,
      });
      await batch.commit().timeout(const Duration(seconds: 15));
    });
  }

  Future<void> sendTextMessage({
    required String conversationId,
    required String senderId,
    String text = '',
    ReplyContext? replyTo,
    List<ChatAttachment> attachments = const [],
    Map<String, Object?>? e2eeEnvelope,
    String? messageIdOverride,

    /// Опциональный ISO-таймштамп для `createdAt` / `lastMessageTimestamp`.
    /// Нужен звонящему стороннему коду (см. `chat_outbox_attachment_notifier`),
    /// чтобы записать тот же `ts` в локальный preview-кэш и сразу показать
    /// настоящий plaintext в списке чатов вместо плейсхолдера E2EE — кеш
    /// сравнивает свой `ts` с серверным `lastMessageTimestamp`, и без
    /// синхронизации значения превью не подхватится. Если не передан —
    /// используем текущее время как раньше.
    String? nowIsoOverride,

    /// On-device транскрипт голосового сообщения, посчитанный отправителем
    /// в [VoiceMessagePreviewBar] перед отправкой. Если задан и чат не
    /// E2EE — пишется в Firestore-поле `voiceTranscript`. Получатель
    /// читает его напрямую вместо повторного запуска ASR на своём
    /// устройстве, экономя ~1-3s и заряд батареи.
    ///
    /// В E2EE-чатах transcript НЕ публикуется в plaintext в Firestore;
    /// он остаётся только в локальном кэше отправителя. Cross-device
    /// синк зашифрованного transcript-а — отдельная фича (см.
    /// `voiceTranscriptCipher`).
    String? voiceTranscript,
  }) async {
    final trimmed = text.trim();
    final hasE2ee = e2eeEnvelope != null;
    if (trimmed.isEmpty && attachments.isEmpty && !hasE2ee) return;
    final nowIso = nowIsoOverride ?? DateTime.now().toUtc().toIso8601String();

    // Phase 4: при E2EE записываем `e2ee.*` и placeholder-preview вместо
    // plaintext. `text` НЕ пишем (собеседник всё равно декодирует из envelope).
    final transcriptTrimmed = voiceTranscript?.trim() ?? '';
    final payload = <String, Object?>{
      'senderId': senderId,
      'createdAt': nowIso,
      if (!hasE2ee && trimmed.isNotEmpty) 'text': trimmed,
      if (attachments.isNotEmpty)
        'attachments': attachments.map((a) => a.toFirestoreMap()).toList(),
      if (hasE2ee) 'e2ee': e2eeEnvelope,
      // voiceTranscript leak'аем только если чат не E2EE — иначе содержание
      // голосового всё равно ушло бы plaintext-ом, что ломает контракт.
      if (!hasE2ee && transcriptTrimmed.isNotEmpty)
        'voiceTranscript': transcriptTrimmed,
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

    try {
      await _withAuthRefreshRetry(() async {
        final convSnap = await _firestore
            .collection('conversations')
            .doc(conversationId)
            .get();
        final convData = convSnap.data();
        if (convData == null) {
          throw StateError('conversation_not_found:$conversationId');
        }
        // Phase 4: если чат E2EE-активен и envelope НЕ подан — это всё ещё
        // leak plaintext. Допускаем только два состояния:
        //   (a) E2EE active + envelope — шифрованный send (ожидаемый путь);
        //   (b) E2EE active + attachments (без envelope) — пока блокируем до
        //       Phase 7 (media encryption);
        //   (c) E2EE inactive — обычный plaintext.
        if (_isE2eeActive(convData) && !hasE2ee) {
          throw const E2eeNotSupportedOnMobileException(
            'E2EE conversation requires encrypted envelope '
            '(attachments not yet supported on mobile)',
          );
        }
        final pRaw = convData['participantIds'];
        final participantIds = (pRaw is List ? pRaw : const <Object?>[])
            .whereType<String>()
            .where((s) => s.isNotEmpty)
            .toList();

        final msgRef =
            messageIdOverride != null && messageIdOverride.trim().isNotEmpty
            ? _firestore
                  .collection('conversations')
                  .doc(conversationId)
                  .collection('messages')
                  .doc(messageIdOverride)
            : _firestore
                  .collection('conversations')
                  .doc(conversationId)
                  .collection('messages')
                  .doc();
        final convRef = _firestore
            .collection('conversations')
            .doc(conversationId);

        final unread = <String, Object?>{};
        for (final id in participantIds) {
          if (id.isNotEmpty && id != senderId) {
            unread['unreadCounts.$id'] = FieldValue.increment(1);
          }
        }

        final preview = hasE2ee
            ? kPreviewEncrypted
            : _mainChatLastPreviewText(
                trimmedHtml: trimmed,
                attachments: attachments,
              );

        final batch = _firestore.batch();
        batch.set(msgRef, payload);
        batch.update(convRef, <String, Object?>{
          'lastMessageText': preview,
          'lastMessageTimestamp': nowIso,
          'lastMessageSenderId': senderId,
          'lastMessageIsThread': false,
          ...unread,
        });
        await batch.commit();
      });
    } on FirebaseException catch (e, st) {
      _logger.e(
        'sendTextMessage failed conversationId=$conversationId senderId=$senderId code=${e.code} message=${e.message}',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Паритет веб `ChatWindow.handleSendPoll`.
  Future<void> sendChatPollMessage({
    required String conversationId,
    required String senderId,
    required List<String> participantIds,
    required ChatPollCreatePayload pollPayload,
    ReplyContext? replyTo,
  }) async {
    final opts = pollPayload.options
        .map((e) => e.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (pollPayload.question.trim().isEmpty || opts.length < 2) return;

    final pollId = 'chat-poll-${DateTime.now().millisecondsSinceEpoch}';
    final pollRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('polls')
        .doc(pollId);
    final messageRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc();

    Future<void> runStep(String step, Future<void> Function() fn) async {
      try {
        await fn();
      } on TimeoutException catch (_) {
        _logger.e('sendChatPollMessage timeout at step=$step');
        throw StateError('poll_send_timeout:$step');
      } on FirebaseException catch (e, st) {
        _logger.e(
          'sendChatPollMessage firebase error at step=$step code=${e.code} message=${e.message}',
          error: e,
          stackTrace: st,
        );
        throw StateError(
          'poll_send_firebase:$step:${e.code}:${e.message ?? ''}',
        );
      } catch (e, st) {
        _logger.e(
          'sendChatPollMessage error at step=$step',
          error: e,
          stackTrace: st,
        );
        throw StateError('poll_send_error:$step:$e');
      }
    }

    final nowIso = DateTime.now().toUtc().toIso8601String();
    final msg = <String, Object?>{
      'senderId': senderId,
      'createdAt': nowIso,
      'text': '<p>📊 Опрос</p>',
      'chatPollId': pollId,
    };
    if (replyTo != null) {
      msg['replyTo'] = <String, Object?>{
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

    final convRef = _firestore.collection('conversations').doc(conversationId);
    final unread = <String, Object?>{};
    for (final id in participantIds) {
      if (id.isNotEmpty && id != senderId) {
        unread['unreadCounts.$id'] = FieldValue.increment(1);
      }
    }

    await runStep('batch_commit', () async {
      final batch = _firestore.batch();
      batch.set(pollRef, <String, Object?>{
        ...pollPayload.pollDocumentFields(pollId, senderId),
        'createdAt': nowIso,
      });
      batch.set(messageRef, msg);
      batch.update(convRef, <String, Object?>{
        'lastMessageText': '📊 Опрос',
        'lastMessageTimestamp': nowIso,
        'lastMessageSenderId': senderId,
        'lastMessageIsThread': false,
        ...unread,
      });
      await batch.commit().timeout(const Duration(seconds: 15));
    });
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
        'liveSession': <String, Object?>{'expiresAt': s.liveSession!.expiresAt},
    };
  }

  /// Паритет `ChatWindow.handleSendLocationShare`.
  ///
  /// Bug 13 (Phase 13): для длительных трансляций (durationId != 'once')
  /// LiveLocationTracker автоматически стартует Geolocator stream и
  /// пишет track-points в sub-collection через
  /// [writeLiveLocationTrackPoint] (см. ниже). Cleanup — клиентский
  /// через [clearLiveLocationTrackPoints] (вызывается при Stop в
  /// LiveLocationStopBanner и при старте нового share).
  Future<void> sendLocationShareMessage({
    required String conversationId,
    required String senderId,
    required List<String> participantIds,
    required ChatLocationShare locationShare,
    ReplyContext? replyTo,
    required bool activateUserLiveShare,
    String? userLiveExpiresAt,
    /// Phase 12.2 (iMessage-paritет): опциональный text который рендерится
    /// в том же bubble сверху от location preview. Если задан и непустой
    /// — попадает в payload `text`, и `lastMessageText` для conversation
    /// меняется на этот текст вместо «📍 Геолокация».
    String? text,
  }) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final trimmedText = text?.trim();
    final hasText = trimmedText != null && trimmedText.isNotEmpty;
    final payload = <String, Object?>{
      'senderId': senderId,
      'createdAt': nowIso,
      'locationShare': _locationShareToFirestore(locationShare),
      if (hasText) 'text': trimmedText,
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

    final convRef = _firestore.collection('conversations').doc(conversationId);
    final unread = <String, Object?>{};
    for (final id in participantIds) {
      if (id.isNotEmpty && id != senderId) {
        unread['unreadCounts.$id'] = FieldValue.increment(1);
      }
    }
    await convRef.update(<String, Object?>{
      // Phase 12.2: если есть text — он становится lastMessage preview
      // (как iMessage). Иначе — старый «📍 Геолокация» fallback.
      // Префиксуем text эмодзи 📍, чтобы chat list делать одинаково:
      // юзер сразу видит что это location-сообщение.
      'lastMessageText': hasText ? '📍 $trimmedText' : '📍 Геолокация',
      'lastMessageTimestamp': nowIso,
      'lastMessageSenderId': senderId,
      'lastMessageIsThread': false,
      ...unread,
    });

    if (activateUserLiveShare) {
      await _firestore.collection('users').doc(senderId).update(
        <String, Object?>{
          'liveLocationShare': <String, Object?>{
            'active': true,
            'expiresAt': userLiveExpiresAt,
            'lat': locationShare.lat,
            'lng': locationShare.lng,
            if (locationShare.accuracyM != null)
              'accuracyM': locationShare.accuracyM,
            'updatedAt': nowIso,
            'startedAt': nowIso,
            // Bug #15: записываем id чата, в котором началась
            // трансляция — chat list использует это поле, чтобы
            // подсветить именно этот ряд индикатором «идёт live».
            'conversationId': conversationId,
          },
        },
      );
    }
    _logger.i('Location share sent in $conversationId');
  }

  /// Phase 12.3: send location request. Receiver видит специальный
  /// bubble с Accept/Decline, у sender — pending state с анимацией
  /// ожидания (UI handled in chat_message_list).
  Future<String> sendLocationRequestMessage({
    required String conversationId,
    required String senderId,
    required List<String> participantIds,
  }) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final payload = <String, Object?>{
      'senderId': senderId,
      'createdAt': nowIso,
      'locationRequest': <String, Object?>{
        'requesterId': senderId,
        'status': 'pending',
        'requestedAt': nowIso,
      },
    };
    final ref = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add(payload);

    final convRef = _firestore.collection('conversations').doc(conversationId);
    final unread = <String, Object?>{};
    for (final id in participantIds) {
      if (id.isNotEmpty && id != senderId) {
        unread['unreadCounts.$id'] = FieldValue.increment(1);
      }
    }
    await convRef.update(<String, Object?>{
      'lastMessageText': '📍 Запрос геолокации',
      'lastMessageTimestamp': nowIso,
      'lastMessageSenderId': senderId,
      'lastMessageIsThread': false,
      ...unread,
    });
    _logger.i('Location request sent in $conversationId (${ref.id})');
    return ref.id;
  }

  /// Phase 12.3: ответ на location request. `accepted=true` ставит
  /// status `accepted` и оставляет `acceptedShareMessageId` (caller
  /// уже создал отдельный location-share через `sendLocationShareMessage`).
  /// `accepted=false` → status `declined`.
  Future<void> respondToLocationRequest({
    required String conversationId,
    required String requestMessageId,
    required bool accepted,
    String? acceptedShareMessageId,
  }) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final updates = <String, Object?>{
      'locationRequest.status': accepted ? 'accepted' : 'declined',
      'locationRequest.respondedAt': nowIso,
    };
    if (accepted && acceptedShareMessageId != null) {
      updates['locationRequest.acceptedShareMessageId'] = acceptedShareMessageId;
    }
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(requestMessageId)
        .update(updates);
    _logger.i(
      'Location request $requestMessageId responded: '
      '${accepted ? "accepted" : "declined"}',
    );
  }

  /// Bug 13 (Phase 13): записать одну точку пройденного трека live-
  /// location-share. Документы лежат в `users/{uid}/
  /// liveLocationTrackPoints/{tsMillis}` — id = millisecondsSinceEpoch
  /// в виде строки. Stable id даёт идемпотентность (повторный fix с
  /// тем же ts перепишет существующий, не создаст дубль) и orderBy
  /// без дополнительного индекса. Также обновляем lat/lng/updatedAt
  /// в `users/{uid}.liveLocationShare` — для прежнего web-paritета
  /// «последняя точка видна как пин» (без задержки на чтение
  /// trackPoints).
  Future<void> writeLiveLocationTrackPoint({
    required String uid,
    required double lat,
    required double lng,
    double? accuracyM,
  }) async {
    final now = DateTime.now().toUtc();
    final tsIso = now.toIso8601String();
    final tsMillis = now.millisecondsSinceEpoch.toString();
    final userRef = _firestore.collection('users').doc(uid);
    final pointPayload = <String, Object?>{
      'lat': lat,
      'lng': lng,
      'ts': tsIso,
    };
    if (accuracyM != null) {
      pointPayload['accuracyM'] = accuracyM;
    }
    await userRef
        .collection('liveLocationTrackPoints')
        .doc(tsMillis)
        .set(pointPayload);
    final shareUpdates = <String, Object?>{
      'liveLocationShare.lat': lat,
      'liveLocationShare.lng': lng,
      'liveLocationShare.updatedAt': tsIso,
    };
    if (accuracyM != null) {
      shareUpdates['liveLocationShare.accuracyM'] = accuracyM;
    }
    await userRef.update(shareUpdates);
  }

  /// Bug 13: поток точек трека отсортированный по ts. Получатель
  /// подписывается и рисует MKPolyline. `limit` ограничивает
  /// клиента — старые точки можно держать в Firestore до cleanup,
  /// но в UI рисуем последние ~720 (24h × 30 точек/час) чтобы не
  /// раздувать память.
  Stream<List<ChatLocationTrackPoint>> liveLocationTrackPointsStream({
    required String uid,
    int limit = 720,
  }) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('liveLocationTrackPoints')
        .orderBy('ts')
        .limitToLast(limit)
        .snapshots()
        .map((snap) {
      final out = <ChatLocationTrackPoint>[];
      for (final doc in snap.docs) {
        final pt = ChatLocationTrackPoint.fromJson(doc.data());
        if (pt != null) out.add(pt);
      }
      return out;
    });
  }

  /// Bug 13: cleanup при Stop / истечении live-share. Удаляет ВСЕ
  /// trackPoints отправителя. Без Cloud Function — клиент сам
  /// выполняет batched delete (Firestore-rules должны разрешать
  /// удаление документов в этой sub-collection владельцу).
  Future<void> clearLiveLocationTrackPoints({required String uid}) async {
    final col = _firestore
        .collection('users')
        .doc(uid)
        .collection('liveLocationTrackPoints');
    while (true) {
      final batchSnap = await col.limit(400).get();
      if (batchSnap.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final doc in batchSnap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      if (batchSnap.docs.length < 400) return;
    }
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
    String buildDirectChatId(String left, String right) {
      final ids = <String>[left.trim(), right.trim()]..sort();
      String part(String v) => '${v.length}:$v';
      return 'dm_${part(ids[0])}_${part(ids[1])}';
    }

    bool isDirectForPair(Map<String, dynamic>? data) {
      if (data == null) return false;
      if (data['isGroup'] == true) return false;
      final pRaw = data['participantIds'];
      final p = (pRaw is List ? pRaw : const <Object?>[])
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toList(growable: false);
      return p.length == 2 &&
          p.contains(currentUserId) &&
          p.contains(otherUserId);
    }

    if (currentUserId.trim().isEmpty || otherUserId.trim().isEmpty) {
      throw ArgumentError('createOrOpenDirectChat requires non-empty user ids');
    }
    if (currentUserId == otherUserId) {
      throw ArgumentError('createOrOpenDirectChat requires distinct users');
    }

    final canonicalId = buildDirectChatId(currentUserId, otherUserId);
    final canonicalRef = _firestore
        .collection('conversations')
        .doc(canonicalId);
    final canonicalSnap = await canonicalRef.get();
    if (canonicalSnap.exists && isDirectForPair(canonicalSnap.data())) {
      return canonicalSnap.id;
    }

    int tsScore(Object? raw) {
      if (raw is Timestamp) return raw.toDate().millisecondsSinceEpoch;
      if (raw is String) {
        return DateTime.tryParse(raw)?.millisecondsSinceEpoch ?? 0;
      }
      return 0;
    }

    try {
      final q = await _firestore
          .collection('conversations')
          .where('participantIds', arrayContains: currentUserId)
          .get();
      DocumentSnapshot<Map<String, dynamic>>? best;
      var bestTs = -1;
      for (final d in q.docs) {
        final data = d.data();
        if (!isDirectForPair(data)) continue;
        final ts = tsScore(data['lastMessageTimestamp']);
        if (best == null || ts > bestTs) {
          best = d;
          bestTs = ts;
        }
      }
      if (best != null) return best.id;
    } on FirebaseException catch (e, st) {
      // На некоторых правилах list-query по conversations может дать permission-denied.
      // Не блокируем открытие чата: ниже идем через детерминированный id + transaction.
      _logger.w(
        'createOrOpenDirectChat: fallback list-query denied, continue with canonical id',
        error: e,
        stackTrace: st,
      );
    }

    final nowIso = DateTime.now().toUtc().toIso8601String();
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(canonicalRef);
      if (snap.exists && isDirectForPair(snap.data())) return;

      tx.set(canonicalRef, <String, Object?>{
        'isGroup': false,
        'participantIds': [currentUserId, otherUserId],
        'adminIds': const <String>[],
        'participantInfo': <String, Object?>{
          currentUserId: <String, Object?>{
            'name': currentUserInfo.name,
            if (currentUserInfo.avatar != null)
              'avatar': currentUserInfo.avatar,
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
        'lastMessageTimestamp': nowIso,
        'lastMessageText': 'Чат создан',
        'unreadCounts': <String, Object?>{currentUserId: 0, otherUserId: 0},
        'unreadThreadCounts': <String, Object?>{
          currentUserId: 0,
          otherUserId: 0,
        },
        // При повторном создании чата после удаления скрываем исторические
        // "сиротские" сообщения (подколлекции, оставшиеся без parent-документа).
        'clearedAt': <String, Object?>{
          currentUserId: nowIso,
          otherUserId: nowIso,
        },
        'typing': <String, Object?>{},
      });
    });

    // Ускоряем отображение в собственном списке чатов, не ожидая Cloud Function.
    try {
      await _firestore.collection('userChats').doc(currentUserId).set(
        <String, Object?>{
          'conversationIds': FieldValue.arrayUnion(<String>[canonicalId]),
        },
        SetOptions(merge: true),
      );
    } catch (_) {}

    _logger.i('Ensured direct chat: $canonicalId');
    return canonicalId;
  }

  /// Ensure personal saved-messages chat exists for current user and return its id.
  Future<String> ensureSavedMessagesChat({
    required String currentUserId,
    required ({String name, String? avatar, String? avatarThumb})
    currentUserInfo,
  }) async {
    final canonicalId = 'saved_${currentUserId.length}:${currentUserId.trim()}';
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

    final savedCandidates = <({String id, int ts})>[];
    var canonicalExists = false;
    final seenCandidateIds = <String>{};
    void addCandidate(String id, int ts) {
      if (!seenCandidateIds.add(id)) return;
      savedCandidates.add((id: id, ts: ts));
    }

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
        final rawTs = data['lastMessageTimestamp'];
        final ts = rawTs is String
            ? DateTime.tryParse(rawTs)?.millisecondsSinceEpoch ?? 0
            : 0;
        addCandidate(d.id, ts);
        if (d.id == canonicalId) canonicalExists = true;
      }
    }

    // Fallback: если userChats неполный/устаревший, ищем saved-чат напрямую
    // по conversations (аналог web-паритета createOrOpenDirectChat).
    try {
      final q = await _firestore
          .collection('conversations')
          .where('participantIds', arrayContains: currentUserId)
          .get();
      for (final d in q.docs) {
        final data = d.data();
        final isGroup = data['isGroup'] == true;
        final pRaw = data['participantIds'];
        final p = (pRaw is List ? pRaw : const <Object?>[])
            .whereType<String>()
            .where((s) => s.isNotEmpty)
            .toList();
        if (!isGroup && p.length == 1 && p.first == currentUserId) {
          final rawTs = data['lastMessageTimestamp'];
          final ts = rawTs is String
              ? DateTime.tryParse(rawTs)?.millisecondsSinceEpoch ?? 0
              : 0;
          addCandidate(d.id, ts);
          if (d.id == canonicalId) canonicalExists = true;
        }
      }
    } on FirebaseException catch (e, st) {
      _logger.w(
        'ensureSavedMessagesChat: fallback list-query denied, continue with known candidates',
        error: e,
        stackTrace: st,
      );
    }

    savedCandidates.sort((a, b) => b.ts.compareTo(a.ts));
    var ensuredId = canonicalExists
        ? canonicalId
        : (savedCandidates.isNotEmpty ? savedCandidates.first.id : null);

    if (ensuredId == null) {
      final canonicalRef = _firestore
          .collection('conversations')
          .doc(canonicalId);
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(canonicalRef);
        if (snap.exists) return;
        tx.set(canonicalRef, <String, Object?>{
          'isGroup': false,
          'name': 'Избранное',
          'participantIds': <String>[currentUserId],
          'adminIds': const <String>[],
          'participantInfo': <String, Object?>{
            currentUserId: <String, Object?>{
              'name': currentUserInfo.name,
              if (currentUserInfo.avatar != null)
                'avatar': currentUserInfo.avatar,
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
      });
      ensuredId = canonicalId;
    }

    final duplicateIds = savedCandidates
        .map((e) => e.id)
        .where((id) => id != ensuredId)
        .toList(growable: false);

    if (duplicateIds.isNotEmpty) {
      try {
        await _firestore.collection('userChats').doc(currentUserId).set(
          <String, Object?>{
            'conversationIds': FieldValue.arrayRemove(duplicateIds),
          },
          SetOptions(merge: true),
        );
      } catch (_) {}
    }

    try {
      await _firestore.collection('userChats').doc(currentUserId).set(
        <String, Object?>{
          'conversationIds': FieldValue.arrayUnion(<String>[ensuredId]),
        },
        SetOptions(merge: true),
      );
    } catch (_) {}

    _logger.i('Ensured saved messages chat: $ensuredId');
    return ensuredId;
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

  /// Редактирование текста сообщения. В E2EE-чате принимает готовый envelope
  /// (см. [sendTextMessage]): вместо `text` записывается `e2ee.*`, старый
  /// plaintext удаляется (через FieldValue.delete).
  Future<void> updateMessageText({
    required String conversationId,
    required String messageId,
    required String text,
    List<ChatAttachment>? attachments,
    Map<String, Object?>? e2eeEnvelope,
  }) async {
    final trimmed = text.trim();
    final hasE2ee = e2eeEnvelope != null;
    if (trimmed.isEmpty && !hasE2ee) return;
    final msgRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId);
    final msgSnap = await msgRef.get();
    if (!msgSnap.exists) return;
    final msgData = msgSnap.data();
    if (msgData == null) return;

    // Phase 4: если сообщение E2EE — должен прийти новый envelope. Plaintext
    // edit поверх зашифрованного сообщения по-прежнему запрещён.
    final e2eeRaw = msgData['e2ee'];
    final msgHasCiphertext =
        e2eeRaw is Map &&
        e2eeRaw['ciphertext'] is String &&
        (e2eeRaw['ciphertext'] as String).isNotEmpty;
    if (msgHasCiphertext && !hasE2ee) {
      throw const E2eeNotSupportedOnMobileException(
        'Encrypted message can only be edited with a new encrypted envelope',
      );
    }
    // Для plaintext-edit сохраняем старый guard: в E2EE-чате plaintext
    // запрещён. Если envelope есть — это валидный send-path.
    if (!hasE2ee) {
      final convSnapGuard = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .get();
      final convGuardData = convSnapGuard.data();
      if (convGuardData != null && _isE2eeActive(convGuardData)) {
        throw const E2eeNotSupportedOnMobileException(
          'Cannot edit plaintext message in an E2EE conversation',
        );
      }
    }

    final now = DateTime.now().toUtc().toIso8601String();
    final update = <String, Object?>{'updatedAt': now};
    if (hasE2ee) {
      update['e2ee'] = e2eeEnvelope;
      // Удаляем старый plaintext, если был: иначе клиент мог бы дешифровать
      // и одновременно видеть старое содержимое.
      update['text'] = FieldValue.delete();
    } else {
      update['text'] = trimmed;
    }
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
      final String preview;
      if (hasE2ee) {
        preview = 'Зашифрованное сообщение';
      } else {
        var plain = trimmed
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .replaceAll('&nbsp;', ' ')
            .trim();
        if (plain.length > 100) plain = plain.substring(0, 100);
        preview = plain;
      }
      await convRef.update(<String, Object?>{'lastMessageText': preview});
    }
  }

  Future<void> clearConversationForMe({
    required String conversationId,
    required String userId,
  }) async {
    if (conversationId.trim().isEmpty || userId.trim().isEmpty) return;
    final ref = _firestore.collection('conversations').doc(conversationId);
    final now = DateTime.now().toUtc().toIso8601String();
    await ref.update(<String, Object?>{
      'clearedAt.$userId': now,
      'unreadCounts.$userId': 0,
      'unreadThreadCounts.$userId': 0,
    });

    // Чистим избранные сообщения текущего пользователя по этому чату — иначе
    // ранее starred сообщения остаются на странице "Starred" с кэшированным
    // previewText даже после очистки истории.
    try {
      final starredCol = _firestore
          .collection('users')
          .doc(userId)
          .collection('starredChatMessages')
          .where('conversationId', isEqualTo: conversationId);
      final snap = await starredCol.get();
      const chunkSize = 400;
      for (var i = 0; i < snap.docs.length; i += chunkSize) {
        final end = (i + chunkSize < snap.docs.length)
            ? i + chunkSize
            : snap.docs.length;
        final batch = _firestore.batch();
        for (final doc in snap.docs.sublist(i, end)) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    } catch (_) {
      // Не блокируем основное действие — сами entries отфильтруются на UI
      // по clearedAt cutoff'у при рендере.
    }
  }

  String _readFlightKey({
    required String conversationId,
    required String messageId,
    bool isThread = false,
    String? threadParentMessageId,
  }) {
    final parentPart = isThread ? (threadParentMessageId ?? '') : '';
    return '$conversationId|$parentPart|$messageId';
  }

  /// Web parity: отметить сообщения прочитанными и декрементнуть unread-счётчик.
  ///
  /// [skipReadReceipt] — режим скрытых read-receipts: НЕ обновляет публичный
  /// `readAt` (собеседник не видит галочки прочтения), вместо этого пишет
  /// персональную метку `readByUid.{userId}` и декрементирует `unreadCounts`
  /// как обычно — чтобы у самого пользователя сбрасывался счётчик и якорь.
  Future<void> markMessagesAsRead({
    required String conversationId,
    required String userId,
    required List<String> messageIds,
    bool isThread = false,
    String? threadParentMessageId,
    bool skipReadReceipt = false,
  }) async {
    final convId = conversationId.trim();
    final uid = userId.trim();
    if (convId.isEmpty || uid.isEmpty || messageIds.isEmpty) return;

    final parentId = threadParentMessageId?.trim();
    if (isThread && (parentId == null || parentId.isEmpty)) return;

    final normalized = messageIds
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (normalized.isEmpty) return;

    final filtered = <String>[];
    final inflightKeys = <String>[];
    for (final id in normalized) {
      final key = _readFlightKey(
        conversationId: convId,
        messageId: id,
        isThread: isThread,
        threadParentMessageId: parentId,
      );
      if (_inFlightReadKeys.contains(key)) continue;
      _inFlightReadKeys.add(key);
      inflightKeys.add(key);
      filtered.add(id);
    }
    if (filtered.isEmpty) return;

    final now = DateTime.now().toUtc().toIso8601String();
    try {
      await _withAuthRefreshRetry(() async {
        final batch = _firestore.batch();
        for (final id in filtered) {
          final ref = _messageDocRef(
            conversationId: convId,
            messageId: id,
            threadParentMessageId: isThread ? parentId : null,
          );
          final update = <String, Object?>{
            'readByUid.$uid': now,
            if (!skipReadReceipt) 'readAt': now,
          };
          batch.update(ref, update);
        }
        final convRef = _firestore.collection('conversations').doc(convId);
        final counterField = isThread
            ? 'unreadThreadCounts.$uid'
            : 'unreadCounts.$uid';
        batch.update(convRef, <String, Object?>{
          counterField: FieldValue.increment(-filtered.length),
        });
        if (isThread && parentId != null && parentId.isNotEmpty) {
          final parentRef = _firestore
              .collection('conversations')
              .doc(convId)
              .collection('messages')
              .doc(parentId);
          batch.update(parentRef, <String, Object?>{
            'unreadThreadCounts.$uid': FieldValue.increment(-filtered.length),
          });
        }
        await batch.commit();
      });
      if (_inFlightReadKeys.length > 12000) {
        _inFlightReadKeys.clear();
      }
    } catch (_) {
      for (final key in inflightKeys) {
        _inFlightReadKeys.remove(key);
      }
      rethrow;
    }
  }

  /// Web parity: пакетная отметка read, чтобы не переполнить batch.
  Future<void> markManyMessagesAsRead({
    required String conversationId,
    required String userId,
    required List<String> messageIds,
    bool isThread = false,
    String? threadParentMessageId,
    bool skipReadReceipt = false,
  }) async {
    const chunkSize = 200;
    if (messageIds.isEmpty) return;
    for (var i = 0; i < messageIds.length; i += chunkSize) {
      final chunk = messageIds.skip(i).take(chunkSize).toList(growable: false);
      await markMessagesAsRead(
        conversationId: conversationId,
        userId: userId,
        messageIds: chunk,
        isThread: isThread,
        threadParentMessageId: threadParentMessageId,
        skipReadReceipt: skipReadReceipt,
      );
    }
  }

  /// Web parity: сброс unread-счётчиков разговора для пользователя.
  Future<void> markConversationAsRead({
    required String conversationId,
    required String userId,
  }) async {
    final convId = conversationId.trim();
    final uid = userId.trim();
    if (convId.isEmpty || uid.isEmpty) return;
    final convRef = _firestore.collection('conversations').doc(convId);
    await _withAuthRefreshRetry(() async {
      await convRef.update(<String, Object?>{
        'unreadCounts.$uid': 0,
        'unreadThreadCounts.$uid': 0,
      });
    });
  }

  int _asNonNegativeInt(Object? raw) {
    if (raw is int) return raw < 0 ? 0 : raw;
    if (raw is num) {
      final v = raw.toInt();
      return v < 0 ? 0 : v;
    }
    return 0;
  }

  /// Сброс unreadThreadCounts без проставления `readAt` (глобально скрытые read receipts).
  Future<void> markThreadMessagesSeenWithoutReceipt({
    required String conversationId,
    required String userId,
    required String threadParentMessageId,
    required int unreadCount,
  }) async {
    final convId = conversationId.trim();
    final uid = userId.trim();
    final parentId = threadParentMessageId.trim();
    final count = unreadCount < 0 ? 0 : unreadCount;
    if (convId.isEmpty || uid.isEmpty || parentId.isEmpty || count <= 0) return;

    final convRef = _firestore.collection('conversations').doc(convId);
    final parentRef = convRef.collection('messages').doc(parentId);

    await _withAuthRefreshRetry(() async {
      await _firestore.runTransaction((tx) async {
        final convSnap = await tx.get(convRef);
        if (convSnap.exists) {
          final convData = convSnap.data();
          final unreadMap = convData?['unreadThreadCounts'];
          final current = unreadMap is Map
              ? _asNonNegativeInt(unreadMap[uid])
              : 0;
          final dec = current < count ? current : count;
          if (dec > 0) {
            tx.update(convRef, <String, Object?>{
              'unreadThreadCounts.$uid': FieldValue.increment(-dec),
            });
          }
        }

        final parentSnap = await tx.get(parentRef);
        if (parentSnap.exists) {
          final parentData = parentSnap.data();
          final unreadMap = parentData?['unreadThreadCounts'];
          final current = unreadMap is Map
              ? _asNonNegativeInt(unreadMap[uid])
              : 0;
          final dec = current < count ? current : count;
          if (dec > 0) {
            tx.update(parentRef, <String, Object?>{
              'unreadThreadCounts.$uid': FieldValue.increment(-dec),
            });
          }
        }
      });
    });
  }

  Future<void> markReactionSeen({
    required String conversationId,
    required String userId,
    String? seenAtIso,
  }) async {
    final convId = conversationId.trim();
    final uid = userId.trim();
    if (convId.isEmpty || uid.isEmpty) return;
    final now = (seenAtIso ?? '').trim().isEmpty
        ? DateTime.now().toUtc().toIso8601String()
        : seenAtIso!.trim();
    final convRef = _firestore.collection('conversations').doc(convId);
    await _withAuthRefreshRetry(() async {
      await convRef.update(<String, Object?>{'lastReactionSeenAt.$uid': now});
    });
  }

  Future<void> deleteDirectConversationForAll({
    required String conversationId,
    required String currentUserId,
  }) async {
    if (conversationId.trim().isEmpty) return;
    final ref = _firestore.collection('conversations').doc(conversationId);
    final snap = await ref.get();
    final data = snap.data();
    if (data == null) return;
    final conversation = Conversation.fromJson(data);
    if (conversation.isGroup) {
      throw StateError(
        'Group conversations cannot be deleted from this action.',
      );
    }

    final participantIds = conversation.participantIds
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .toList(growable: false);
    await ref.delete();

    for (final uid in participantIds) {
      try {
        await _firestore.collection('userChats').doc(uid).set(<String, Object?>{
          'conversationIds': FieldValue.arrayRemove(<String>[conversationId]),
        }, SetOptions(merge: true));
      } catch (e, st) {
        _logger.w(
          'deleteDirectConversationForAll: userChats arrayRemove failed for $uid',
          error: e,
          stackTrace: st,
        );
      }
    }

    if (!participantIds.contains(currentUserId)) {
      try {
        await _firestore.collection('userChats').doc(currentUserId).set(
          <String, Object?>{
            'conversationIds': FieldValue.arrayRemove(<String>[conversationId]),
          },
          SetOptions(merge: true),
        );
      } catch (_) {}
    }
  }

  /// Удалить одно вложение из сообщения. Если вложений не осталось и текста нет — soft delete.
  Future<void> removeMessageAttachment({
    required String conversationId,
    required String messageId,
    required String attachmentUrl,
    String? threadParentMessageId,
  }) async {
    final target = attachmentUrl.trim();
    if (target.isEmpty) return;
    final msgRef = _messageDocRef(
      conversationId: conversationId,
      messageId: messageId,
      threadParentMessageId: threadParentMessageId,
    );
    final msgSnap = await msgRef.get();
    if (!msgSnap.exists) return;
    final msgData = msgSnap.data();
    if (msgData == null) return;

    final atts = _attachmentsFromRaw(msgData['attachments']);
    final next = atts
        .where((a) => a.url.trim() != target)
        .toList(growable: false);
    if (next.length == atts.length) return;

    final textRaw = msgData['text'];
    final plain = textRaw is String
        ? textRaw
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .replaceAll('&nbsp;', ' ')
              .trim()
        : '';

    if (next.isEmpty && plain.isEmpty) {
      await softDeleteMessage(
        conversationId: conversationId,
        messageId: messageId,
        threadParentMessageId: threadParentMessageId,
      );
      return;
    }

    final now = DateTime.now().toUtc().toIso8601String();
    await msgRef.update(<String, Object?>{
      'attachments': next.map((a) => a.toFirestoreMap()).toList(),
      'updatedAt': now,
    });
  }

  /// Soft delete (web: `isDeleted: true` + optional unread fix).
  Future<void> softDeleteMessage({
    required String conversationId,
    required String messageId,
    String? threadParentMessageId,
  }) async {
    final msgRef = _messageDocRef(
      conversationId: conversationId,
      messageId: messageId,
      threadParentMessageId: threadParentMessageId,
    );
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

    final parsed =
        parseReactions(data['reactions']) ?? <String, List<ReactionEntry>>{};
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
      reactions[emoji] = [
        ...list,
        ReactionEntry(userId: userId, timestamp: now),
      ];
      added = true;
    }

    final firestoreMap = <String, dynamic>{};
    for (final e in reactions.entries) {
      firestoreMap[e.key] = e.value
          .map(
            (r) => <String, dynamic>{
              'userId': r.userId,
              if (r.timestamp != null && r.timestamp!.isNotEmpty)
                'timestamp': r.timestamp,
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

  /// Реакция на сообщение в треде (`messages/{parent}/thread/{message}`).
  Future<void> toggleThreadMessageReaction({
    required String conversationId,
    required String parentMessageId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    if (emoji.isEmpty) return;
    final msgRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(parentMessageId)
        .collection('thread')
        .doc(messageId);
    final convRef = _firestore.collection('conversations').doc(conversationId);

    final snap = await msgRef.get();
    if (!snap.exists) return;
    final data = snap.data();
    if (data == null) return;

    final parsed =
        parseReactions(data['reactions']) ?? <String, List<ReactionEntry>>{};
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
      reactions[emoji] = [
        ...list,
        ReactionEntry(userId: userId, timestamp: now),
      ];
      added = true;
    }

    final firestoreMap = <String, dynamic>{};
    for (final e in reactions.entries) {
      firestoreMap[e.key] = e.value
          .map(
            (r) => <String, dynamic>{
              'userId': r.userId,
              if (r.timestamp != null && r.timestamp!.isNotEmpty)
                'timestamp': r.timestamp,
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
          'lastReactionParentId': parentMessageId,
        });
      } catch (_) {}
    }
  }

  /// Публикует одноразовое событие emoji-burst для синхронизации эффекта между клиентами.
  Future<void> emitEmojiBurstEvent({
    required String conversationId,
    required String messageId,
    required String senderId,
    required String emoji,
    required String eventId,
    String? threadParentMessageId,
  }) async {
    final convId = conversationId.trim();
    final msgId = messageId.trim();
    final by = senderId.trim();
    final token = emoji.trim();
    final id = eventId.trim();
    if (convId.isEmpty ||
        msgId.isEmpty ||
        by.isEmpty ||
        token.isEmpty ||
        id.isEmpty) {
      return;
    }
    final now = DateTime.now().toUtc().toIso8601String();
    final burst = ChatEmojiBurstEvent(
      eventId: id,
      emoji: token,
      by: by,
      at: now,
    ).toFirestoreMap();
    final msgRef = _messageDocRef(
      conversationId: convId,
      messageId: msgId,
      threadParentMessageId: threadParentMessageId,
    );
    await _withAuthRefreshRetry(() async {
      await msgRef.update(<String, Object?>{'emojiBurst': burst});
    });
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
    var sentToAny = false;

    for (final convId in targetConversationIds) {
      try {
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
            'createdAt': nowIso,
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
        sentToAny = true;
      } on FirebaseException catch (e, st) {
        _logger.w(
          'forwardMessagesToChats skip conv=$convId due FirebaseException',
          error: e,
          stackTrace: st,
        );
      }
    }

    if (!sentToAny) {
      throw StateError('forward_failed_permission_or_membership');
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
      _logger.w(
        'checkGroupInvitesAllowed: no Firebase app',
        error: e,
        stackTrace: st,
      );
      throw StateError(
        'Firebase не инициализирован. Перезапустите приложение или проверьте '
        'настройки FlutterFire (нужен нативный appId, не :web:).',
      );
    }

    // iOS: обходим `cloud_functions` плагин — SDK FirebaseFunctions 12.9.0
    // в `FunctionsContext.context(options:)` использует три параллельных
    // `async let`, на которых Swift-рантайм воспроизводимо крашит Release-
    // сборку в `_swift_task_dealloc_specific (.cold.2)` при сборе токенов
    // для первого callable (SIGABRT, «freed pointer was not the last
    // allocation»). Прямой HTTPS-POST использует нативный ObjC-колбэк для
    // ID-token и не трогает Swift Concurrency. Android/Web — штатно через SDK.
    if (Platform.isIOS) {
      try {
        final raw = await callFirebaseCallableHttp(
          name: 'checkGroupInvitesAllowed',
          region: 'us-central1',
          data: <String, dynamic>{'targetUserIds': ids},
          timeout: const Duration(seconds: 40),
          logger: _logger,
        );
        return _parseGroupInvitesResult(raw);
      } on FirebaseCallableHttpException catch (e, st) {
        if (e.code == 'network' || e.code == 'timeout') {
          _logger.w(
            'checkGroupInvitesAllowed (iOS http): connectivity/timeout',
            error: e,
            stackTrace: st,
          );
          throw StateError(_groupInviteConnectivityMessage);
        }
        rethrow;
      }
    }

    final functions = FirebaseFunctions.instanceFor(
      app: app,
      region: 'us-central1',
    );
    final callable = functions.httpsCallable(
      'checkGroupInvitesAllowed',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 40)),
    );
    try {
      final res = await callable.call(<String, dynamic>{'targetUserIds': ids});
      return _parseGroupInvitesResult(res.data);
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

  /// Разбор ответа `checkGroupInvitesAllowed` (одинаков для SDK и HTTP-пути).
  GroupInvitesCheckResult _parseGroupInvitesResult(Object? raw) {
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
  }

  Future<void> retryChatMediaTranscode({
    required String conversationId,
    required String messageId,
    bool isThread = false,
    String? parentMessageId,
  }) async {
    final convId = conversationId.trim();
    final msgId = messageId.trim();
    final parentId = (parentMessageId ?? '').trim();
    if (convId.isEmpty || msgId.isEmpty) return;
    if (isThread && parentId.isEmpty) {
      throw StateError('Для thread retry требуется parentMessageId.');
    }
    final app = Firebase.app();
    final functions = FirebaseFunctions.instanceFor(
      app: app,
      region: 'us-central1',
    );
    final callable = functions.httpsCallable(
      'retryChatMediaTranscode',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
    );
    await callable.call(<String, dynamic>{
      'conversationId': convId,
      'messageId': msgId,
      if (isThread) 'isThread': true,
      if (isThread) 'parentMessageId': parentId,
    });
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
      throw ArgumentError(
        'additionalParticipants must not contain current user',
      );
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
        id: <String, Object?>{'name': nameById[id] ?? 'Неизвестный'},
    };

    final unreadCounts = <String, Object?>{
      for (final id in participantIds) id: 0,
    };
    final unreadThreadCounts = <String, Object?>{
      for (final id in participantIds) id: 0,
    };

    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .set(<String, Object?>{
          'isGroup': true,
          'name': trimmedName,
          if (description != null && description.trim().isNotEmpty)
            'description': description.trim(),
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
        await ref.putData(photo, SettableMetadata(contentType: 'image/jpeg'));
        final url = await ref.getDownloadURL();
        await _firestore.collection('conversations').doc(conversationId).update(
          <String, Object?>{'photoUrl': url},
        );
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

    return denied
        .map((d) {
          final n = nameFor(d.uid);
          return d.reason == 'none'
              ? '$n не принимает приглашения в группы'
              : '$n разрешает групповые приглашения только от людей из своих контактов';
        })
        .join(' ');
  }

  // ===== Scheduled messages =====

  /// Подписка на список запланированных сообщений (status='pending') данного
  /// пользователя в данном чате, отсортированных по `sendAt asc`.
  Stream<List<ScheduledChatMessage>> watchScheduledMessages({
    required String conversationId,
    required String userId,
  }) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('scheduledMessages')
        .where('senderId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('sendAt')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(ScheduledChatMessage.fromDoc)
              .whereType<ScheduledChatMessage>()
              .toList(growable: false),
        );
  }

  /// Создаёт запланированное сообщение. Файлы должны быть уже загружены
  /// в Storage (передавайте готовые [ChatAttachment] с url/name/type/size).
  /// При наступлении [sendAt] scheduler-CF опубликует обычное message-документ.
  ///
  /// E2EE: даже в E2EE-чате сохраняется plaintext (compromise — UI должен
  /// явно предупредить пользователя в диалоге планирования).
  Future<String> scheduleMessage({
    required String conversationId,
    required String senderId,
    required DateTime sendAt,
    String text = '',
    List<ChatAttachment> attachments = const <ChatAttachment>[],
    ReplyContext? replyTo,
    ScheduledChatPendingPoll? pendingPoll,
    ChatLocationShare? locationShare,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty &&
        attachments.isEmpty &&
        pendingPoll == null &&
        locationShare == null) {
      throw ArgumentError('scheduleMessage: empty payload');
    }
    final now = DateTime.now().toUtc();
    if (sendAt.isBefore(now.add(const Duration(seconds: 30)))) {
      throw ArgumentError('scheduleMessage: sendAt must be in the future');
    }

    final nowIso = now.toIso8601String();
    final sendAtIso = sendAt.toUtc().toIso8601String();

    final payload = <String, Object?>{
      'senderId': senderId,
      'status': 'pending',
      'scheduledAt': nowIso,
      'sendAt': sendAtIso,
      'createdAt': nowIso,
      if (trimmed.isNotEmpty) 'text': trimmed,
      if (attachments.isNotEmpty)
        'attachments': attachments.map((a) => a.toFirestoreMap()).toList(),
      if (replyTo != null)
        'replyTo': <String, Object?>{
          'messageId': replyTo.messageId,
          'senderName': replyTo.senderName,
          if (replyTo.text != null && replyTo.text!.trim().isNotEmpty)
            'text': replyTo.text!.trim(),
          if (replyTo.mediaPreviewUrl != null &&
              replyTo.mediaPreviewUrl!.trim().isNotEmpty)
            'mediaPreviewUrl': replyTo.mediaPreviewUrl!.trim(),
          if (replyTo.mediaType != null && replyTo.mediaType!.trim().isNotEmpty)
            'mediaType': replyTo.mediaType!.trim(),
        },
      if (pendingPoll != null) 'pendingPoll': pendingPoll.toFirestoreMap(),
      if (locationShare != null)
        'locationShare': _locationShareToFirestore(locationShare),
    };

    final ref = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('scheduledMessages')
        .add(payload);
    return ref.id;
  }

  /// Обновить время отправки запланированного сообщения. Доступно только
  /// для сообщений в status='pending' (rules).
  Future<void> rescheduleMessage({
    required String conversationId,
    required String scheduledMessageId,
    required DateTime sendAt,
  }) async {
    final now = DateTime.now().toUtc();
    if (sendAt.isBefore(now.add(const Duration(seconds: 30)))) {
      throw ArgumentError('rescheduleMessage: sendAt must be in the future');
    }
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('scheduledMessages')
        .doc(scheduledMessageId)
        .update(<String, Object?>{
          'sendAt': sendAt.toUtc().toIso8601String(),
          'updatedAt': now.toIso8601String(),
        });
  }

  /// Отменить (удалить) запланированное сообщение.
  Future<void> cancelScheduledMessage({
    required String conversationId,
    required String scheduledMessageId,
  }) async {
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('scheduledMessages')
        .doc(scheduledMessageId)
        .delete();
  }
}
