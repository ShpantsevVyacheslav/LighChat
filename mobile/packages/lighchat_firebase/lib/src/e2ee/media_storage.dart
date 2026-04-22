/// Phase 7 — E2EE v2 media storage (mobile).
///
/// Обёртка вокруг [`media_crypto.dart`](./media_crypto.dart) + Firebase
/// Storage. Симметрично с web `src/lib/e2ee/v2/media-upload-v2.ts`:
/// выкладывает зашифрованные chunks в `chat-attachments-enc/{cid}/{mid}/{fileId}/chunk_{i}`,
/// забирает через `getData`.
library;

import 'dart:math' show Random;
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import 'media_crypto.dart';

/// Случайный fileId (hex, 32 символа) — совместим с web `randomFileIdV2`.
String randomFileIdV2() {
  final rnd = Random.secure();
  final u = List<int>.generate(16, (_) => rnd.nextInt(256));
  return u.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

/// Нужно ли шифровать этот MIME? stickers/gif — нет (см. RFC §7.5).
bool isEncryptableMimeV2(String mime) {
  final m = mime.toLowerCase();
  if (m == 'image/gif') return false;
  if (m.contains('sticker')) return false;
  return true;
}

MediaKindV2 mapMimeToKindV2(String mime, {MediaKindV2? hint}) {
  if (hint != null) return hint;
  final m = mime.toLowerCase();
  if (m.startsWith('image/')) return MediaKindV2.image;
  if (m.startsWith('video/')) return MediaKindV2.video;
  if (m.startsWith('audio/')) return MediaKindV2.voice;
  return MediaKindV2.file;
}

class EncryptUploadInputV2 {
  const EncryptUploadInputV2({
    required this.storage,
    required this.conversationId,
    required this.messageId,
    required this.data,
    required this.mime,
    this.kindHint,
    this.fileId,
    this.thumbnailBytes,
    this.thumbnailMime,
    this.metadataJson,
  });

  final FirebaseStorage storage;
  final String conversationId;
  final String messageId;
  final Uint8List data;
  final String mime;
  final MediaKindV2? kindHint;
  final String? fileId;
  final Uint8List? thumbnailBytes;
  final String? thumbnailMime;

  /// UTF-8 сериализованный JSON длительности/размеров/waveform.
  final String? metadataJson;
}

class EncryptUploadResultV2 {
  const EncryptUploadResultV2({
    required this.envelope,
    required this.chunkStoragePaths,
  });

  final MediaEnvelopeV2 envelope;
  final List<String> chunkStoragePaths;
}

/// Шифрует файл и загружает chunk'и в Storage по пути
/// `chat-attachments-enc/{cid}/{mid}/{fileId}/chunk_{i}`. Возвращает
/// `MediaEnvelopeV2`, готовый к сериализации в `message.e2ee.attachments[i]`.
Future<EncryptUploadResultV2> encryptAndUploadMediaFileV2({
  required EncryptUploadInputV2 input,
  required Uint8List chatKeyRaw,
}) async {
  final fileId = input.fileId ?? randomFileIdV2();
  final kind = mapMimeToKindV2(input.mime, hint: input.kindHint);

  final encrypted = await encryptMediaFileV2(
    data: input.data,
    kind: kind,
    mime: input.mime.isEmpty ? 'application/octet-stream' : input.mime,
    fileId: fileId,
    chatKeyRaw: chatKeyRaw,
    metadataPlaintext: input.metadataJson == null
        ? null
        : Uint8List.fromList(input.metadataJson!.codeUnits),
    thumbnailBytes: input.thumbnailBytes,
    thumbnailMime: input.thumbnailMime,
  );

  // Параллельный upload чанков с ограниченным окном. Последовательный `for`
  // давал линейный rtt*chunkCount — отправка больших медиа была «вечной».
  // Симметрично с web (`src/lib/e2ee/v2/media-upload-v2.ts`).
  final paths = List<String>.filled(encrypted.chunks.length, '');
  final concurrency = encrypted.chunks.length < e2eeMediaV2UploadConcurrency
      ? encrypted.chunks.length
      : e2eeMediaV2UploadConcurrency;
  var cursor = 0;
  Future<void> worker() async {
    while (true) {
      final i = cursor++;
      if (i >= encrypted.chunks.length) return;
      final chunk = encrypted.chunks[i];
      final path = chunkStoragePathV2(
        conversationId: input.conversationId,
        messageId: input.messageId,
        fileId: fileId,
        index: chunk.index,
      );
      final ref = input.storage.ref(path);
      await ref.putData(
        chunk.data,
        SettableMetadata(
          contentType: 'application/octet-stream',
          customMetadata: {
            'e2eeV2ChunkIndex': chunk.index.toString(),
            'e2eeV2FileId': fileId,
            'e2eeV2ChunkCount': encrypted.envelope.chunkCount.toString(),
          },
        ),
      );
      paths[i] = path;
    }
  }

  await Future.wait(List<Future<void>>.generate(concurrency, (_) => worker()));

  return EncryptUploadResultV2(
    envelope: encrypted.envelope,
    chunkStoragePaths: paths,
  );
}

/// Компромисс между скоростью upload'а и нагрузкой на мобильную сеть/Storage.
const int e2eeMediaV2UploadConcurrency = 4;

class DownloadDecryptInputV2 {
  const DownloadDecryptInputV2({
    required this.storage,
    required this.conversationId,
    required this.messageId,
    required this.envelope,
  });

  final FirebaseStorage storage;
  final String conversationId;
  final String messageId;
  final MediaEnvelopeV2 envelope;
}

/// Лимит одного getData (10 МиБ достаточно для 4 МиБ chunk + tag).
const int _chunkFetchMaxBytes = 10 * 1024 * 1024;

/// Загружает и полностью расшифровывает файл в память.
Future<DecryptMediaResultV2> downloadAndDecryptMediaFileV2({
  required DownloadDecryptInputV2 input,
  required Uint8List chatKeyRaw,
}) async {
  return decryptMediaFileV2(
    envelope: input.envelope,
    chatKeyRaw: chatKeyRaw,
    fetchChunk: (index) async {
      final path = chunkStoragePathV2(
        conversationId: input.conversationId,
        messageId: input.messageId,
        fileId: input.envelope.fileId,
        index: index,
      );
      final bytes = await input.storage.ref(path).getData(_chunkFetchMaxBytes);
      if (bytes == null) {
        throw StateError('E2EE_MEDIA_CHUNK_MISSING:$index');
      }
      return bytes;
    },
  );
}
