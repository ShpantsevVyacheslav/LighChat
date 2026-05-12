/// E2EE v2 Phase 9 — helper для подготовки вложений к отправке в E2EE-active
/// чатах.
///
/// Контракт:
///  - На вход: `List<XFile>` (XFile из image_picker/file_picker) + runtime +
///    параметры сессии. На выход: `E2eeAttachmentPrepareResult` с двумя
///    параллельными списками:
///      * `plaintextFiles` — стикеры/GIFs, которые не подлежат шифрованию
///        и должны быть загружены обычным `uploadChatAttachmentFromXFile`.
///      * `encryptedEnvelopes` — уже зашифрованные и загруженные в
///        `chat-attachments-enc/...` вложения; вписываются в
///        `e2ee.attachments[]` исходящего сообщения.
///
/// Вызывающий ответственен за:
///  - предварительное резервирование `messageId` (он входит в AAD);
///  - последующий `sendTextMessage(e2eeEnvelope: ..., attachments: ...)`;
///  - отображение ошибок, бросаемых рантаймом (см. `MobileE2eeEncryptException`).
///
/// Для не-E2EE чатов helper не используется — вызывающий напрямую кладёт
/// файлы в plaintext-путь.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lighchat_firebase/lighchat_firebase.dart';

import 'package:lighchat_mobile/core/app_logger.dart';
import '../../../l10n/app_localizations.dart';
import 'e2ee_runtime.dart';
import 'video_send_compress_720p.dart';

/// Stability-first guardrails for E2EE multi-media send.
const int e2eeSendMaxFilesPerMessage = 5;
const int e2eeSendMaxTotalBytes = 96 * 1024 * 1024;

class E2eeAttachmentSendLimitException implements Exception {
  const E2eeAttachmentSendLimitException(this.message);
  final String message;

  @override
  String toString() => message;
}

class E2eePreparedSendFile {
  const E2eePreparedSendFile({
    required this.file,
    required this.effectiveMime,
    required this.temporaryCompressedFile,
  });

  final XFile file;
  final String effectiveMime;
  final bool temporaryCompressedFile;
}

Future<void> validateE2eeBatchLimitsOrThrow(List<XFile> files, {AppLocalizations? l10n}) async {
  if (files.length > e2eeSendMaxFilesPerMessage) {
    throw E2eeAttachmentSendLimitException(
      l10n?.e2ee_too_many_attachments ?? 'Too many attachments for encrypted sending: maximum 5 files per message.',
    );
  }
  var totalBytes = 0;
  for (final f in files) {
    totalBytes += await f.length();
    if (totalBytes > e2eeSendMaxTotalBytes) {
      throw E2eeAttachmentSendLimitException(
        l10n?.e2ee_total_size_exceeded ?? 'Total attachment size too large: maximum 96 MB per encrypted message.',
      );
    }
  }
}

Future<void> cleanupPreparedE2eeFile(E2eePreparedSendFile prepared) async {
  if (!prepared.temporaryCompressedFile) return;
  final p = prepared.file.path.trim();
  if (p.isEmpty) return;
  try {
    final f = File(p);
    if (await f.exists()) await f.delete();
  } catch (e) {
    appLogger.w('cleanupPreparedE2eeFile failed', error: e);
  }
}

Future<E2eePreparedSendFile> prepareE2eeFileForSend(XFile file) async {
  final originalMime = _effectiveMime(file);
  if (!isEncryptableMimeV2(originalMime) ||
      !originalMime.startsWith('video/')) {
    return E2eePreparedSendFile(
      file: file,
      effectiveMime: originalMime,
      temporaryCompressedFile: false,
    );
  }
  final compressed = await maybeCompressVideoForSend720p(file);
  final effective = compressed.file;
  final effectiveMime = _effectiveMime(effective);
  return E2eePreparedSendFile(
    file: effective,
    effectiveMime: effectiveMime,
    temporaryCompressedFile: compressed.didCompress,
  );
}

class E2eeAttachmentPrepareResult {
  const E2eeAttachmentPrepareResult({
    required this.plaintextFiles,
    required this.encryptedEnvelopes,
  });

  final List<XFile> plaintextFiles;
  final List<Map<String, Object?>> encryptedEnvelopes;

  bool get hasEncrypted => encryptedEnvelopes.isNotEmpty;
}

/// Разбивает `files` на encryptable / non-encryptable; для encryptable
/// читает байты и шифрует через `MobileE2eeRuntime.encryptMediaForSend`.
/// Возвращает пустые списки, если `files` пустой.
///
/// Бросает ошибку рантайма (`MobileE2eeEncryptException` и т.п.) если ключ
/// эпохи недоступен или шифрование не удалось — вызывающий должен отменить
/// отправку, чтобы не уехал plaintext.
Future<E2eeAttachmentPrepareResult> prepareE2eeAttachmentsForSend({
  required MobileE2eeRuntime runtime,
  required FirebaseStorage storage,
  required String conversationId,
  required String messageId,
  required int epoch,
  required List<XFile> files,
  AppLocalizations? l10n,
}) async {
  if (files.isEmpty) {
    return const E2eeAttachmentPrepareResult(
      plaintextFiles: [],
      encryptedEnvelopes: [],
    );
  }
  await validateE2eeBatchLimitsOrThrow(files, l10n: l10n);

  final plaintextFiles = <XFile>[];
  final envelopes = <Map<String, Object?>>[];

  for (final f in files) {
    final prepared = await prepareE2eeFileForSend(f);
    try {
      if (!isEncryptableMimeV2(prepared.effectiveMime)) {
        plaintextFiles.add(prepared.file);
        continue;
      }
      final bytes = await prepared.file.readAsBytes();
      final envelope = await runtime.encryptMediaForSend(
        storage: storage,
        conversationId: conversationId,
        messageId: messageId,
        epoch: epoch,
        data: Uint8List.fromList(bytes),
        mime: prepared.effectiveMime,
      );
      envelopes.add(envelope.toWireJson());
    } finally {
      await cleanupPreparedE2eeFile(prepared);
    }
  }

  return E2eeAttachmentPrepareResult(
    plaintextFiles: plaintextFiles,
    encryptedEnvelopes: envelopes,
  );
}

String _effectiveMime(XFile f) {
  final m = (f.mimeType ?? '').trim();
  if (m.isNotEmpty) return m.toLowerCase();
  final p = f.path.toLowerCase();
  if (p.endsWith('.jpg') || p.endsWith('.jpeg')) return 'image/jpeg';
  if (p.endsWith('.png')) return 'image/png';
  if (p.endsWith('.webp')) return 'image/webp';
  if (p.endsWith('.heic') || p.endsWith('.heif')) return 'image/heic';
  if (p.endsWith('.gif')) return 'image/gif';
  if (p.endsWith('.mp4')) return 'video/mp4';
  if (p.endsWith('.mov') || p.endsWith('.qt')) return 'video/quicktime';
  if (p.endsWith('.m4a')) return 'audio/m4a';
  if (p.endsWith('.mp3')) return 'audio/mpeg';
  if (p.endsWith('.pdf')) return 'application/pdf';
  return 'application/octet-stream';
}

/// Оборачивает media-envelopes + опциональный текст-envelope в валидный
/// `e2ee.*`-блок для `sendTextMessage`. Если `textEnvelope` пустой — создаёт
/// media-only envelope c пустым ciphertext (push-нотификация покажет
/// «Зашифрованное сообщение (вложение)»).
Map<String, Object?> mergeE2eeEnvelopeWithMedia({
  Map<String, Object?>? textEnvelope,
  required List<Map<String, Object?>> mediaEnvelopes,
  required int epoch,
}) {
  if (mediaEnvelopes.isEmpty) {
    return textEnvelope ?? const <String, Object?>{};
  }
  if (textEnvelope != null && textEnvelope.isNotEmpty) {
    return <String, Object?>{...textEnvelope, 'attachments': mediaEnvelopes};
  }
  return <String, Object?>{
    'protocolVersion': v2Protocol,
    'epoch': epoch,
    'iv': '',
    'ciphertext': '',
    'attachments': mediaEnvelopes,
  };
}
