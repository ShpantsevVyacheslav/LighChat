/// Orchestrator-виджет для Phase 4 / Phase 9 E2EE read-path.
///
/// Зачем отдельный файл:
///  - изоляция E2EE-логики (user-rule #1): `ChatMessageList` остаётся чистым,
///    этот файл знает про `MobileE2eeRuntime`, Riverpod и Firebase;
///  - одна реализация переиспользуется в `chat_screen.dart` и `thread_screen.dart`;
///  - state (`decryptedById`, `failedIds`, `decryptedAttachments`) локализован
///    в `State`, не переживает logout и не течёт между чатами.
///
/// Public API: [E2eeMessagesResolver] — билдер, который принимает список
/// сообщений и отдаёт дочернему виджету:
///   * `hydratedMessages` — клон `messages`, где в `.attachments` добавлены
///     расшифрованные E2EE-вложения (blob-URL → `file://…` во временной папке);
///   * `decryptedTextByMessageId` — расшифрованный HTML-текст;
///   * `failedMessageIds` — id сообщений, где либо текст, либо медиа
///     не удалось расшифровать (UI показывает плейсхолдер).
///
/// Дочерний виджет (обычно `ChatMessageList`) не знает о крипто — он просто
/// получает готовые данные.
library;

import 'dart:async';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lighchat_firebase/lighchat_firebase.dart';
import 'package:lighchat_models/lighchat_models.dart';

import 'e2ee_plaintext_cache.dart';
import 'e2ee_runtime.dart';

typedef E2eeMessagesBuilder = Widget Function(
  BuildContext context,
  List<ChatMessage> hydratedMessages,
  Map<String, String> decryptedTextByMessageId,
  Set<String> failedMessageIds,
);

class E2eeMessagesResolver extends ConsumerStatefulWidget {
  const E2eeMessagesResolver({
    super.key,
    required this.conversationId,
    required this.messages,
    required this.builder,
  });

  final String conversationId;

  /// Полный список сообщений в чате. Дешифрует только те, у которых есть
  /// `e2eePayload`. При изменении списка новые E2EE-сообщения автоматически
  /// ставятся в очередь.
  final List<ChatMessage> messages;

  final E2eeMessagesBuilder builder;

  @override
  ConsumerState<E2eeMessagesResolver> createState() =>
      _E2eeMessagesResolverState();
}

/// Один расшифрованный envelope, готовый к рендеру.
class _DecryptedMediaEntry {
  const _DecryptedMediaEntry({required this.attachment});

  final ChatAttachment attachment;
}

class _E2eeMessagesResolverState extends ConsumerState<E2eeMessagesResolver> {
  final Map<String, String> _decrypted = <String, String>{};
  final Set<String> _failed = <String>{};
  final Set<String> _inFlight = <String>{};

  /// Ключ: `messageId`. Значение: параллельный массив envelope'ам из payload.
  /// Слот `null` означает «envelope ещё в работе / не сделан».
  final Map<String, List<_DecryptedMediaEntry?>> _decryptedMedia =
      <String, List<_DecryptedMediaEntry?>>{};

  /// Anti-duplicate set. Формат: `messageId:fileId`.
  final Set<String> _mediaInFlight = <String>{};
  final Set<String> _mediaFailed = <String>{};

  /// Lazy: директория для расшифрованных файлов. `null` пока не инициализирована.
  Directory? _mediaCacheDir;
  Future<Directory>? _mediaCacheDirFuture;

  bool _disposed = false;
  bool _textCacheWarmUpDone = false;

  @override
  void initState() {
    super.initState();
    _warmUpPersistentTextCache();
    _scheduleDecryptionPass();
  }

  /// Подгружает расшифрованный текст, кэшированный на предыдущей сессии,
  /// чтобы первая отрисовка ленты не показывала плейсхолдеры.
  Future<void> _warmUpPersistentTextCache() async {
    try {
      await E2eePlaintextCache.instance.warmUp(widget.conversationId);
    } catch (_) {
      // best-effort — при ошибке просто работаем без persistent cache.
    }
    if (_disposed) return;
    // Забираем plaintext для всех уже видимых сообщений и форсим rebuild.
    var updated = false;
    for (final m in widget.messages) {
      if (m.e2eePayload == null) continue;
      if (_decrypted.containsKey(m.id)) continue;
      final cached = E2eePlaintextCache.instance.getTextSync(
        conversationId: widget.conversationId,
        messageId: m.id,
      );
      if (cached != null) {
        _decrypted[m.id] = cached;
        updated = true;
      }
    }
    if (!mounted) return;
    if (updated || !_textCacheWarmUpDone) {
      setState(() {
        _textCacheWarmUpDone = true;
      });
    }
  }

  @override
  void didUpdateWidget(covariant E2eeMessagesResolver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversationId != widget.conversationId) {
      // При переходе между чатами state обнуляем, чтобы не смешать ключи.
      _decrypted.clear();
      _failed.clear();
      _inFlight.clear();
      _decryptedMedia.clear();
      _mediaInFlight.clear();
      _mediaFailed.clear();
    }
    _scheduleDecryptionPass();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Persistent дир для расшифрованных медиа-файлов. Ранее мы держали их в
  /// `temp/`, но OS может очищать этот каталог в любой момент, из-за чего
  /// кэш не выживал рестарты приложения. Теперь пишем в
  /// `applicationSupport/e2ee_cache/media/{conversationId}/`.
  Future<Directory> _ensureMediaCacheDir() async {
    if (_mediaCacheDir != null) return _mediaCacheDir!;
    _mediaCacheDirFuture ??= () async {
      final dir =
          await E2eePlaintextCache.instance.mediaDir(widget.conversationId);
      _mediaCacheDir = dir;
      return dir;
    }();
    return _mediaCacheDirFuture!;
  }

  void _scheduleDecryptionPass() {
    final runtime = ref.read(mobileE2eeRuntimeProvider);
    if (runtime == null) return;
    for (final m in widget.messages) {
      final payload = m.e2eePayload;
      if (payload == null) continue;

      // Текст: расшифровываем один раз, если iv/ct непустые.
      if (!_decrypted.containsKey(m.id) &&
          !_failed.contains(m.id) &&
          !_inFlight.contains(m.id)) {
        _inFlight.add(m.id);
        unawaited(_decryptOne(runtime, m.id, payload));
      }

      // Медиа: расшифровываем каждый envelope отдельно, ленивая очередь.
      final attachmentsJson = payload.attachmentsJson;
      if (attachmentsJson == null || attachmentsJson.isEmpty) continue;
      final slots = _decryptedMedia.putIfAbsent(
        m.id,
        () => List<_DecryptedMediaEntry?>.filled(
          attachmentsJson.length,
          null,
          growable: false,
        ),
      );
      for (var i = 0; i < attachmentsJson.length; i++) {
        if (slots[i] != null) continue;
        MediaEnvelopeV2 env;
        try {
          env = MediaEnvelopeV2.fromWireJson(attachmentsJson[i]);
        } catch (_) {
          // malformed envelope — единичный слот в failed, остальные продолжают.
          continue;
        }
        final key = '${m.id}:${env.fileId}';
        if (_mediaInFlight.contains(key)) continue;
        if (_mediaFailed.contains(key)) continue;
        _mediaInFlight.add(key);
        unawaited(
          _decryptMediaOne(
            runtime: runtime,
            messageId: m.id,
            envelope: env,
            epoch: payload.epoch,
            slotIndex: i,
          ),
        );
      }
    }
  }

  Future<void> _decryptOne(
    MobileE2eeRuntime runtime,
    String messageId,
    ChatMessageE2eePayload payload,
  ) async {
    try {
      final res = await runtime.decryptMessage(
        conversationId: widget.conversationId,
        messageId: messageId,
        payload: payload,
      );
      if (_disposed) return;
      setState(() {
        _inFlight.remove(messageId);
        if (res.ok) {
          _decrypted[messageId] = res.plaintext!;
        } else {
          _failed.add(messageId);
        }
      });
      if (res.ok && res.plaintext != null) {
        unawaited(
          E2eePlaintextCache.instance.putText(
            conversationId: widget.conversationId,
            messageId: messageId,
            plaintext: res.plaintext!,
          ),
        );
      }
    } catch (_) {
      if (_disposed) return;
      setState(() {
        _inFlight.remove(messageId);
        _failed.add(messageId);
      });
    }
  }

  /// Phase 9: один envelope → файл в темпе → [ChatAttachment] с `file://` URL.
  /// Ошибки не пропагируются в общий `_failed` (текст может быть успешным даже
  /// при сбое media). Вместо этого вкладка с медиа остаётся пустой.
  Future<void> _decryptMediaOne({
    required MobileE2eeRuntime runtime,
    required String messageId,
    required MediaEnvelopeV2 envelope,
    required int epoch,
    required int slotIndex,
  }) async {
    final key = '$messageId:${envelope.fileId}';
    try {
      final dir = await _ensureMediaCacheDir();
      final file = File('${dir.path}/$messageId-${envelope.fileId}');
      // Если файл уже лежит в кэше (напр. при rebuild экрана) — просто переиспользуем.
      if (!await file.exists()) {
        final result = await runtime.decryptMediaForView(
          storage: FirebaseStorage.instance,
          conversationId: widget.conversationId,
          messageId: messageId,
          epoch: epoch,
          envelope: envelope,
        );
        await file.writeAsBytes(result.data, flush: true);
      }
      if (_disposed) return;
      final ext = _extensionForMime(envelope.mime);
      final att = ChatAttachment(
        url: Uri.file(file.path).toString(),
        name: '${_prefixForKind(envelope.kind)}${envelope.fileId}$ext',
        type: envelope.mime,
        size: envelope.size,
      );
      setState(() {
        _mediaInFlight.remove(key);
        final slots = _decryptedMedia[messageId];
        if (slots != null && slotIndex < slots.length) {
          slots[slotIndex] = _DecryptedMediaEntry(attachment: att);
        }
      });
    } catch (_) {
      if (_disposed) return;
      setState(() {
        _mediaInFlight.remove(key);
        _mediaFailed.add(key);
      });
    }
  }

  /// Мерджит расшифрованные attachments в `message.attachments[]` и возвращает
  /// новый список сообщений. Если изменений нет — возвращает исходный список
  /// референсом (чтобы `ChatMessageList` не делал лишних rebuilds).
  List<ChatMessage> _hydrateMessages() {
    if (_decryptedMedia.isEmpty) return widget.messages;
    var didChange = false;
    final out = <ChatMessage>[];
    for (final m in widget.messages) {
      final slots = _decryptedMedia[m.id];
      if (slots == null) {
        out.add(m);
        continue;
      }
      final extras = <ChatAttachment>[];
      for (final s in slots) {
        if (s != null) extras.add(s.attachment);
      }
      if (extras.isEmpty) {
        out.add(m);
        continue;
      }
      didChange = true;
      final merged = <ChatAttachment>[
        ...m.attachments,
        ...extras,
      ];
      out.add(
        ChatMessage(
          id: m.id,
          senderId: m.senderId,
          text: m.text,
          attachments: merged,
          replyTo: m.replyTo,
          isDeleted: m.isDeleted,
          reactions: m.reactions,
          createdAt: m.createdAt,
          readAt: m.readAt,
          updatedAt: m.updatedAt,
          forwardedFrom: m.forwardedFrom,
          deliveryStatus: m.deliveryStatus,
          chatPollId: m.chatPollId,
          locationShare: m.locationShare,
          threadCount: m.threadCount,
          unreadThreadCounts: m.unreadThreadCounts,
          lastThreadMessageText: m.lastThreadMessageText,
          lastThreadMessageSenderId: m.lastThreadMessageSenderId,
          lastThreadMessageTimestamp: m.lastThreadMessageTimestamp,
          hasE2eeCiphertext: m.hasE2eeCiphertext,
          e2eePayload: m.e2eePayload,
          mediaNorm: m.mediaNorm,
          emojiBurst: m.emojiBurst,
          systemEvent: m.systemEvent,
        ),
      );
    }
    return didChange ? out : widget.messages;
  }

  @override
  Widget build(BuildContext context) {
    final hydrated = _hydrateMessages();
    return widget.builder(context, hydrated, _decrypted, _failed);
  }
}

String _extensionForMime(String mime) {
  final m = mime.toLowerCase();
  if (m == 'image/jpeg') return '.jpg';
  if (m == 'image/png') return '.png';
  if (m == 'image/webp') return '.webp';
  if (m == 'image/heic' || m == 'image/heif') return '.heic';
  if (m == 'video/mp4') return '.mp4';
  if (m == 'video/quicktime') return '.mov';
  // .webm / .ogg нужны чтобы нативные плееры (video_player/ExoPlayer и
  // подобные) распознавали контейнер — без расширения они отказываются
  // открывать file:// путь и UI показывает пустой кружок/квадрат.
  if (m == 'video/webm') return '.webm';
  if (m == 'video/ogg' || m == 'video/ogv') return '.ogv';
  if (m == 'audio/m4a' || m == 'audio/mp4' || m == 'audio/x-m4a') return '.m4a';
  if (m == 'audio/mpeg') return '.mp3';
  if (m == 'audio/ogg') return '.ogg';
  if (m == 'audio/webm') return '.webm';
  if (m == 'audio/wav' || m == 'audio/x-wav') return '.wav';
  if (m == 'application/pdf') return '.pdf';
  return '';
}

String _prefixForKind(MediaKindV2 kind) {
  switch (kind) {
    case MediaKindV2.image:
      return 'image_';
    case MediaKindV2.video:
      return 'video_';
    case MediaKindV2.voice:
      return 'voice_';
    case MediaKindV2.videoCircle:
      return 'video-circle_';
    case MediaKindV2.file:
      return 'file_';
  }
}
