import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lighchat_models/lighchat_models.dart';
import 'package:path_provider/path_provider.dart';

import '../../../app_providers.dart';
import '../../../l10n/app_localizations.dart';
import 'chat_attachment_upload.dart';
import 'composer_html_editing.dart';
import 'e2ee_attachment_send_helper.dart';
import 'e2ee_plaintext_cache.dart';
import 'e2ee_runtime.dart';
import '../ui/message_html_text.dart';

/// Префикс id синтетических сообщений в ленте (см. [buildDescWithOutboxMessages]).
const String kLocalOutboxMessageIdPrefix = 'local-outbox-';

enum OutboxAttachmentPhase { uploading, sending, failed }

@immutable
class OutboxAttachmentJob {
  const OutboxAttachmentJob({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.stagedAbsolutePaths,
    required this.captionHtml,
    this.replyTo,
    required this.convIsE2ee,
    required this.e2eeEncryptText,
    required this.e2eeEncryptMedia,
    this.e2eeEpoch,
    required this.effectiveMessageId,
    required this.createdAt,
    this.threadParentMessageId,
    this.phase = OutboxAttachmentPhase.uploading,
    this.lastError,
    this.cancelRequested = false,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final List<String> stagedAbsolutePaths;
  final String captionHtml;
  final ReplyContext? replyTo;
  final bool convIsE2ee;
  final bool e2eeEncryptText;
  final bool e2eeEncryptMedia;
  final int? e2eeEpoch;
  final String effectiveMessageId;
  final DateTime createdAt;

  /// Если задан — отправка в `messages/{id}/thread`, иначе в основной ленте.
  final String? threadParentMessageId;
  final OutboxAttachmentPhase phase;
  final String? lastError;
  final bool cancelRequested;

  OutboxAttachmentJob copyWith({
    OutboxAttachmentPhase? phase,
    String? lastError,
    bool? cancelRequested,
  }) {
    return OutboxAttachmentJob(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      stagedAbsolutePaths: stagedAbsolutePaths,
      captionHtml: captionHtml,
      replyTo: replyTo,
      convIsE2ee: convIsE2ee,
      e2eeEncryptText: e2eeEncryptText,
      e2eeEncryptMedia: e2eeEncryptMedia,
      e2eeEpoch: e2eeEpoch,
      effectiveMessageId: effectiveMessageId,
      createdAt: createdAt,
      threadParentMessageId: threadParentMessageId,
      phase: phase ?? this.phase,
      lastError: lastError ?? this.lastError,
      cancelRequested: cancelRequested ?? this.cancelRequested,
    );
  }

  String get previewPlain {
    final prepared = ComposerHtmlEditing.prepareChatMessageHtmlForSend(
      captionHtml,
    );
    final t = messageHtmlToPlainText(prepared).trim();
    if (t.isNotEmpty) {
      return t.length > 72 ? '${t.substring(0, 72)}…' : t;
    }
    final l10n = lookupAppLocalizations(PlatformDispatcher.instance.locale);
    if (stagedAbsolutePaths.length <= 1) {
      return l10n.outbox_attachment_single;
    }
    return l10n.outbox_attachment_count(stagedAbsolutePaths.length);
  }

  Future<void> deleteStagedFiles() async {
    for (final p in stagedAbsolutePaths) {
      try {
        final f = File(p);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    try {
      final dir = Directory(
        stagedAbsolutePaths.isNotEmpty
            ? File(stagedAbsolutePaths.first).parent.path
            : '',
      );
      if (dir.path.isNotEmpty && await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
  }
}

class ChatOutboxAttachmentNotifier extends Notifier<List<OutboxAttachmentJob>> {
  final Set<String> _inFlight = <String>{};

  @override
  List<OutboxAttachmentJob> build() => const <OutboxAttachmentJob>[];

  static Future<List<String>> _stageFilesForJob({
    required String jobId,
    required List<XFile> sources,
  }) async {
    if (sources.isEmpty) return const <String>[];
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/chat_outbox/$jobId');
    await dir.create(recursive: true);
    final out = <String>[];
    for (var i = 0; i < sources.length; i++) {
      final bytes = await sources[i].readAsBytes();
      final rawName = sources[i].name.trim();
      var safe = rawName.replaceAll(RegExp(r'[^\w.\-]+'), '_');
      if (safe.isEmpty) safe = 'file_$i';
      final target = File('${dir.path}/${i}_$safe');
      await target.writeAsBytes(bytes, flush: true);
      out.add(target.path);
    }
    return out;
  }

  Future<void> enqueueFromComposer({
    required String conversationId,
    required String senderId,
    required List<XFile> files,
    required String rawCaptionHtml,
    ReplyContext? replyTo,
    required bool convIsE2ee,
    required bool e2eeEncryptText,
    required bool e2eeEncryptMedia,
    int? e2eeEpoch,
    String? threadParentMessageId,
  }) async {
    final prepared = ComposerHtmlEditing.prepareChatMessageHtmlForSend(
      rawCaptionHtml,
    );
    final plainPreview = messageHtmlToPlainText(prepared).trim();
    if (plainPreview.isEmpty && files.isEmpty) {
      debugPrint('ChatOutboxAttachmentNotifier: skip empty enqueue');
      return;
    }
    final threadOpt = threadParentMessageId?.trim();
    if (threadOpt != null && threadOpt.isEmpty) {
      return;
    }

    final jobId =
        'ob_${DateTime.now().microsecondsSinceEpoch}_${conversationId.hashCode & 0xfffffff}';
    final staged = await _stageFilesForJob(jobId: jobId, sources: files);

    final fs = FirebaseFirestore.instance;
    final String effectiveMessageId;
    if (threadOpt != null && threadOpt.isNotEmpty) {
      effectiveMessageId = fs
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(threadOpt)
          .collection('thread')
          .doc()
          .id;
    } else {
      effectiveMessageId = fs
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc()
          .id;
    }

    final job = OutboxAttachmentJob(
      id: jobId,
      conversationId: conversationId,
      senderId: senderId,
      stagedAbsolutePaths: staged,
      captionHtml: rawCaptionHtml,
      replyTo: replyTo,
      convIsE2ee: convIsE2ee,
      e2eeEncryptText: e2eeEncryptText,
      e2eeEncryptMedia: e2eeEncryptMedia,
      e2eeEpoch: e2eeEpoch,
      effectiveMessageId: effectiveMessageId,
      createdAt: DateTime.now(),
      threadParentMessageId: threadOpt != null && threadOpt.isNotEmpty
          ? threadOpt
          : null,
    );
    state = [...state, job];
    unawaited(_runJob(jobId));
  }

  Future<void> retry(String jobId) async {
    final j = _byId(jobId);
    if (j == null) return;
    _replace(
      j.copyWith(
        phase: OutboxAttachmentPhase.uploading,
        lastError: null,
        cancelRequested: false,
      ),
    );
    unawaited(_runJob(jobId));
  }

  /// Отмена активной отправки (пока грузится или пишется в Firestore).
  void requestCancelInFlight(String jobId) {
    state = [
      for (final j in state)
        if (j.id == jobId) j.copyWith(cancelRequested: true) else j,
    ];
  }

  /// Убрать из ленты неуспешную или отменённую задачу.
  Future<void> removeJobDisplay(String jobId) async {
    final j = _byId(jobId);
    if (j != null) await _removeJobAndCleanup(j);
  }

  OutboxAttachmentJob? _byId(String id) {
    for (final j in state) {
      if (j.id == id) return j;
    }
    return null;
  }

  void _replace(OutboxAttachmentJob updated) {
    state = [
      for (final j in state)
        if (j.id == updated.id) updated else j,
    ];
  }

  Future<void> _removeJobAndCleanup(OutboxAttachmentJob j) async {
    await j.deleteStagedFiles();
    state = [
      for (final x in state)
        if (x.id != j.id) x,
    ];
  }

  Future<void> _runJob(String jobId) async {
    if (_inFlight.contains(jobId)) return;
    _inFlight.add(jobId);
    var job = _byId(jobId);
    if (job == null) {
      _inFlight.remove(jobId);
      return;
    }

    final repo = ref.read(chatRepositoryProvider);
    if (repo == null) {
      _replace(
        job.copyWith(
          phase: OutboxAttachmentPhase.failed,
          lastError: lookupAppLocalizations(PlatformDispatcher.instance.locale).outbox_chat_unavailable,
        ),
      );
      _inFlight.remove(jobId);
      return;
    }

    try {
      _replace(job.copyWith(phase: OutboxAttachmentPhase.uploading));
      job = _byId(jobId)!;

      if (job.cancelRequested) {
        await _removeJobAndCleanup(job);
        _inFlight.remove(jobId);
        return;
      }

      final storage = FirebaseStorage.instance;
      final files = job.stagedAbsolutePaths.map((p) => XFile(p)).toList();
      final textSave = ComposerHtmlEditing.prepareChatMessageHtmlForSend(
        job.captionHtml,
      );

      final MobileE2eeRuntime? e2eeRuntime = job.convIsE2ee
          ? ref.read(mobileE2eeRuntimeProvider)
          : null;
      final epoch = job.e2eeEpoch;

      E2eeAttachmentPrepareResult prep;
      if (job.convIsE2ee &&
          job.e2eeEncryptMedia &&
          e2eeRuntime != null &&
          epoch != null) {
        prep = await prepareE2eeAttachmentsForSend(
          runtime: e2eeRuntime,
          storage: storage,
          conversationId: job.conversationId,
          messageId: job.effectiveMessageId,
          epoch: epoch,
          files: files,
        );
      } else {
        prep = E2eeAttachmentPrepareResult(
          plaintextFiles: files,
          encryptedEnvelopes: const <Map<String, Object?>>[],
        );
      }

      job = _byId(jobId)!;
      if (job.cancelRequested) {
        await _removeJobAndCleanup(job);
        _inFlight.remove(jobId);
        return;
      }

      _replace(job.copyWith(phase: OutboxAttachmentPhase.sending));
      job = _byId(jobId)!;

      final uploaded = <ChatAttachment>[];
      for (final f in prep.plaintextFiles) {
        if (_byId(jobId)?.cancelRequested == true) {
          final cur = _byId(jobId);
          if (cur != null) await _removeJobAndCleanup(cur);
          _inFlight.remove(jobId);
          return;
        }
        uploaded.add(
          await uploadChatAttachmentFromXFile(
            storage: storage,
            conversationId: job.conversationId,
            file: f,
          ),
        );
      }

      job = _byId(jobId)!;
      if (job.cancelRequested) {
        await _removeJobAndCleanup(job);
        _inFlight.remove(jobId);
        return;
      }

      Map<String, Object?>? outgoingEnvelope;
      final hasEncryptedMedia = prep.encryptedEnvelopes.isNotEmpty;
      // В E2EE-активном чате envelope обязателен для любого исходящего
      // сообщения (иначе репозиторий заблокирует plaintext-send).
      final shouldUseE2eeEnvelope =
          job.convIsE2ee && e2eeRuntime != null && epoch != null;
      if (shouldUseE2eeEnvelope) {
        final textEnvelope = await e2eeRuntime.encryptOutgoing(
          conversationId: job.conversationId,
          messageId: job.effectiveMessageId,
          epoch: epoch,
          // Для чисто media-сообщений шифруем пустую строку (валидный envelope
          // + AAD), для остальных — текст.
          plaintext: hasEncryptedMedia && textSave.isEmpty ? '' : textSave,
        );
        outgoingEnvelope = mergeE2eeEnvelopeWithMedia(
          textEnvelope: textEnvelope,
          mediaEnvelopes: prep.encryptedEnvelopes,
          epoch: epoch,
        );
      }

      // Заранее фиксируем `nowIso` и передаём в repo: тот же таймштамп
      // должен попасть в Firestore (`createdAt` + `lastMessageTimestamp`)
      // и в локальный preview-кэш, чтобы ChatListScreen матчил их по `ts`.
      final nowIso = DateTime.now().toUtc().toIso8601String();
      final threadParent = job.threadParentMessageId;
      if (threadParent != null && threadParent.isNotEmpty) {
        await repo.sendThreadTextMessage(
          conversationId: job.conversationId,
          parentMessageId: threadParent,
          senderId: job.senderId,
          text: outgoingEnvelope != null ? '' : textSave,
          replyTo: job.replyTo,
          attachments: uploaded,
          e2eeEnvelope: outgoingEnvelope,
          messageIdOverride: job.effectiveMessageId,
        );
      } else {
        await repo.sendTextMessage(
          conversationId: job.conversationId,
          senderId: job.senderId,
          text: outgoingEnvelope != null ? '' : textSave,
          replyTo: job.replyTo,
          attachments: uploaded,
          e2eeEnvelope: outgoingEnvelope,
          messageIdOverride: job.effectiveMessageId,
          nowIsoOverride: nowIso,
        );
      }

      // Sender-side preview-cache: только для главного чата (в треде свой
      // `lastThreadMessageText` и собственный сценарий) и только когда
      // мы реально отправляли E2EE-текст. Для media-only без подписи кеш
      // не пишем — в сайдбаре останется плейсхолдер «Зашифрованное
      // сообщение», что корректно (текста как такового не было).
      if (outgoingEnvelope != null &&
          (threadParent == null || threadParent.isEmpty) &&
          textSave.isNotEmpty) {
        var preview = messageHtmlToPlainText(textSave).trim();
        if (preview.length > 240) preview = preview.substring(0, 240);
        if (preview.isNotEmpty) {
          unawaited(
            E2eePlaintextCache.instance.putPreview(
              conversationId: job.conversationId,
              text: preview,
              ts: nowIso,
              messageId: job.effectiveMessageId,
            ),
          );
        }
      }

      final done = _byId(jobId);
      if (done != null) await _removeJobAndCleanup(done);
    } on MobileE2eeEncryptException catch (e) {
      final cur = _byId(jobId);
      if (cur != null) {
        final message = (e.message != null && e.message!.trim().isNotEmpty)
            ? e.message!.trim()
            : lookupAppLocalizations(PlatformDispatcher.instance.locale).outbox_encryption_error(e.code);
        _replace(
          cur.copyWith(phase: OutboxAttachmentPhase.failed, lastError: message),
        );
      }
    } on E2eeAttachmentSendLimitException catch (e) {
      final cur = _byId(jobId);
      if (cur != null) {
        _replace(
          cur.copyWith(
            phase: OutboxAttachmentPhase.failed,
            lastError: e.message,
          ),
        );
      }
    } catch (e, st) {
      debugPrint('ChatOutboxAttachmentNotifier job=$jobId error=$e $st');
      final cur = _byId(jobId);
      if (cur != null) {
        final elapsed = DateTime.now().difference(cur.createdAt);
        if (elapsed < const Duration(seconds: 30) && !cur.cancelRequested) {
          _inFlight.remove(jobId);
          await Future<void>.delayed(const Duration(seconds: 3));
          final still = _byId(jobId);
          if (still != null && !still.cancelRequested) {
            unawaited(_runJob(jobId));
          }
          return;
        }
        final fe = e is FirebaseException
            ? '${e.code}: ${e.message ?? ''}'
            : '$e';
        _replace(
          cur.copyWith(phase: OutboxAttachmentPhase.failed, lastError: fe),
        );
      }
    } finally {
      _inFlight.remove(jobId);
    }
  }
}

final chatOutboxAttachmentNotifierProvider =
    NotifierProvider<ChatOutboxAttachmentNotifier, List<OutboxAttachmentJob>>(
      ChatOutboxAttachmentNotifier.new,
    );

List<ChatMessage> buildDescWithOutboxMessages({
  required List<ChatMessage> hydratedDesc,
  required List<OutboxAttachmentJob> jobs,
  required String conversationId,
  required String senderId,
  String? threadParentMessageId,
}) {
  final deliveredIds = hydratedDesc.map((m) => m.id).toSet();
  final out = <ChatMessage>[];
  for (final j in jobs) {
    if (j.conversationId != conversationId) continue;
    final jp = j.threadParentMessageId;
    if (threadParentMessageId != null) {
      if (jp != threadParentMessageId) continue;
    } else if (jp != null) {
      continue;
    }
    if (j.phase == OutboxAttachmentPhase.failed ||
        j.phase == OutboxAttachmentPhase.uploading ||
        j.phase == OutboxAttachmentPhase.sending) {
      // Не дублируем пузырь, если «реальный» документ сообщения уже появился в
      // ленте (тот же deterministic messageId из effectiveMessageId).
      if (deliveredIds.contains(j.effectiveMessageId)) continue;
      final ds = j.phase == OutboxAttachmentPhase.failed ? 'failed' : 'sending';
      out.add(
        ChatMessage(
          id: '$kLocalOutboxMessageIdPrefix${j.id}',
          senderId: senderId,
          text: '<p>${_safeXmlAttr(j.previewPlain)}</p>',
          attachments: const <ChatAttachment>[],
          replyTo: null,
          createdAt: j.createdAt,
          deliveryStatus: ds,
        ),
      );
    }
  }
  out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return [...out, ...hydratedDesc];
}

String _safeXmlAttr(String s) {
  return s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}

String? outboxJobIdFromSyntheticMessageId(String messageId) {
  if (!messageId.startsWith(kLocalOutboxMessageIdPrefix)) return null;
  return messageId.substring(kLocalOutboxMessageIdPrefix.length);
}
