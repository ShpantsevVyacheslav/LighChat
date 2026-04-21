/// Phase 7 — E2EE v2 media crypto (mobile, bit-for-bit compat с web
/// `src/lib/e2ee/v2/media-crypto-v2.ts`).
///
/// Реализует §6.4–§6.5 RFC: per-file AES-256-GCM ключи, chunked encryption
/// по 4 МиБ, симметричную обёртку file-key под ChatKey эпохи через
/// HKDF-SHA-256, inline-thumbnail/metadata.
///
/// Тестируется теми же test vectors, что и web (`e2ee-v2-test-vectors.json` —
/// `media.chunk.v2`).
library;

import 'dart:convert';
import 'dart:typed_data';

import 'webcrypto_compat.dart';

/// 4 МиБ — соответствует `E2EE_MEDIA_V2_CHUNK_SIZE` в web.
const int e2eeMediaChunkSizeV2 = 4 * 1024 * 1024;

/// Inline thumbnail limit (должен совпадать с web).
const int e2eeMediaThumbInlineMaxBytes = 64 * 1024;

/// Тип медиа envelope'а, см. `ChatMessageE2eeAttachmentEnvelopeV2`.
enum MediaKindV2 { image, video, voice, videoCircle, file }

extension MediaKindV2Name on MediaKindV2 {
  String get wire {
    switch (this) {
      case MediaKindV2.image:
        return 'image';
      case MediaKindV2.video:
        return 'video';
      case MediaKindV2.voice:
        return 'voice';
      case MediaKindV2.videoCircle:
        return 'videoCircle';
      case MediaKindV2.file:
        return 'file';
    }
  }

  static MediaKindV2 fromWire(String wire) {
    switch (wire) {
      case 'image':
        return MediaKindV2.image;
      case 'video':
        return MediaKindV2.video;
      case 'voice':
        return MediaKindV2.voice;
      case 'videoCircle':
        return MediaKindV2.videoCircle;
      case 'file':
      default:
        return MediaKindV2.file;
    }
  }
}

/// Обёртка key-wrap — сериализуется в `E2eeKeyWrapEntry` JSON.
class SymmetricWrapEntry {
  const SymmetricWrapEntry({required this.iv, required this.ct});

  /// IV 12 байт.
  final Uint8List iv;

  /// Ciphertext + 16-байт GCM tag.
  final Uint8List ct;

  /// Wire-формат: `{ephPub: '', iv: b64, ct: b64}`. `ephPub` пустой — признак
  /// symmetric wrap, в web decoder это используется для валидации.
  Map<String, String> toWireJson() => {
        'ephPub': '',
        'iv': base64.encode(iv),
        'ct': base64.encode(ct),
      };

  static SymmetricWrapEntry fromWireJson(Map<String, Object?> j) {
    final ephPub = (j['ephPub'] ?? '') as String;
    if (ephPub.isNotEmpty) {
      throw StateError('E2EE_MEDIA_WRAP_EXPECTED_SYMMETRIC');
    }
    final ivStr = j['iv'];
    final ctStr = j['ct'];
    if (ivStr is! String || ctStr is! String) {
      throw StateError('E2EE_MEDIA_WRAP_MALFORMED');
    }
    return SymmetricWrapEntry(
      iv: Uint8List.fromList(base64.decode(ivStr)),
      ct: Uint8List.fromList(base64.decode(ctStr)),
    );
  }
}

/// Зеркало `ChatMessageE2eeAttachmentEnvelopeV2` в TypeScript.
class MediaEnvelopeV2 {
  MediaEnvelopeV2({
    required this.fileId,
    required this.kind,
    required this.mime,
    required this.size,
    required this.wrap,
    required this.chunkCount,
    required this.ivPrefix,
    this.thumb,
    this.metadataEnc,
  });

  final String fileId;
  final MediaKindV2 kind;
  final String mime;
  final int size;
  final SymmetricWrapEntry wrap;
  final int chunkCount;
  final Uint8List ivPrefix; // 8 байт
  final MediaEnvelopeThumbV2? thumb;
  final MediaEnvelopeMetaV2? metadataEnc;

  Map<String, Object?> toWireJson() => <String, Object?>{
        'fileId': fileId,
        'kind': kind.wire,
        'mime': mime,
        'size': size,
        'wrap': wrap.toWireJson(),
        'chunking': {
          'chunkSizeBytes': e2eeMediaChunkSizeV2,
          'chunkCount': chunkCount,
        },
        'iv': {'prefixB64': base64.encode(ivPrefix)},
        if (thumb != null) 'thumb': thumb!.toWireJson(),
        if (metadataEnc != null) 'metadataEnc': metadataEnc!.toWireJson(),
      };

  static MediaEnvelopeV2 fromWireJson(Map<String, Object?> j) {
    final wrapJson = (j['wrap'] as Map).cast<String, Object?>();
    final chunking = (j['chunking'] as Map).cast<String, Object?>();
    final ivMap = (j['iv'] as Map).cast<String, Object?>();
    return MediaEnvelopeV2(
      fileId: j['fileId'] as String,
      kind: MediaKindV2Name.fromWire(j['kind'] as String),
      mime: j['mime'] as String,
      size: (j['size'] as num).toInt(),
      wrap: SymmetricWrapEntry.fromWireJson(wrapJson),
      chunkCount: (chunking['chunkCount'] as num).toInt(),
      ivPrefix: Uint8List.fromList(base64.decode(ivMap['prefixB64'] as String)),
      thumb: j['thumb'] is Map
          ? MediaEnvelopeThumbV2.fromWireJson(
              (j['thumb'] as Map).cast<String, Object?>())
          : null,
      metadataEnc: j['metadataEnc'] is Map
          ? MediaEnvelopeMetaV2.fromWireJson(
              (j['metadataEnc'] as Map).cast<String, Object?>())
          : null,
    );
  }
}

class MediaEnvelopeThumbV2 {
  const MediaEnvelopeThumbV2({
    required this.iv,
    required this.ct,
    required this.mime,
    this.path,
  });

  final Uint8List iv;
  final Uint8List ct;
  final String mime;
  final String? path;

  Map<String, Object?> toWireJson() => <String, Object?>{
        'ivB64': base64.encode(iv),
        'ciphertextB64': base64.encode(ct),
        'mime': mime,
        if (path != null) 'path': path,
      };

  static MediaEnvelopeThumbV2 fromWireJson(Map<String, Object?> j) {
    return MediaEnvelopeThumbV2(
      iv: Uint8List.fromList(base64.decode(j['ivB64'] as String)),
      ct: Uint8List.fromList(base64.decode(j['ciphertextB64'] as String)),
      mime: j['mime'] as String,
      path: j['path'] as String?,
    );
  }
}

class MediaEnvelopeMetaV2 {
  const MediaEnvelopeMetaV2({required this.iv, required this.ct});

  final Uint8List iv;
  final Uint8List ct;

  Map<String, Object?> toWireJson() => <String, Object?>{
        'ivB64': base64.encode(iv),
        'ciphertextB64': base64.encode(ct),
      };

  static MediaEnvelopeMetaV2 fromWireJson(Map<String, Object?> j) {
    return MediaEnvelopeMetaV2(
      iv: Uint8List.fromList(base64.decode(j['ivB64'] as String)),
      ct: Uint8List.fromList(base64.decode(j['ciphertextB64'] as String)),
    );
  }
}

/// Собирает IV для chunk'а: 8-байт prefix + 4-байт BE index. 12 байт суммарно.
Uint8List _buildChunkIv(Uint8List prefix, int index) {
  if (prefix.length != 8) {
    throw StateError('E2EE_MEDIA_IV_PREFIX_BAD_LEN');
  }
  final iv = Uint8List(12);
  iv.setRange(0, 8, prefix);
  iv[8] = (index >> 24) & 0xff;
  iv[9] = (index >> 16) & 0xff;
  iv[10] = (index >> 8) & 0xff;
  iv[11] = index & 0xff;
  return iv;
}

/// Wrap per-file ключа под ChatKey эпохи (симметричный AES-GCM).
Future<SymmetricWrapEntry> wrapFileKeySymmetricV2({
  required Uint8List fileKeyRaw,
  required Uint8List chatKeyRaw,
  required String fileId,
}) async {
  final wrapKey = await hkdfSha256(
    ikm: chatKeyRaw,
    salt: utf8.encode(fileId),
    info: v2MediaWrapInfo,
    lengthBytes: 32,
  );
  final iv = randomBytes(12);
  final aad = buildAadV2(<Object>[v2MediaWrapInfo, fileId]);
  final ct = await aesGcmEncryptV2(
    key: wrapKey,
    iv: iv,
    plaintext: fileKeyRaw,
    aad: aad,
  );
  return SymmetricWrapEntry(iv: iv, ct: ct);
}

Future<Uint8List> unwrapFileKeySymmetricV2({
  required SymmetricWrapEntry wrap,
  required Uint8List chatKeyRaw,
  required String fileId,
}) async {
  final wrapKey = await hkdfSha256(
    ikm: chatKeyRaw,
    salt: utf8.encode(fileId),
    info: v2MediaWrapInfo,
    lengthBytes: 32,
  );
  final aad = buildAadV2(<Object>[v2MediaWrapInfo, fileId]);
  return aesGcmDecryptV2(
    key: wrapKey,
    iv: wrap.iv,
    ciphertextPlusTag: wrap.ct,
    aad: aad,
  );
}

/// Результат шифрования одного файла.
class EncryptMediaResultV2 {
  const EncryptMediaResultV2({required this.envelope, required this.chunks});

  final MediaEnvelopeV2 envelope;

  /// Зашифрованные chunks в порядке `index`. Вызывающая сторона выкладывает их
  /// в Storage `chat-attachments-enc/{cid}/{mid}/{fileId}/chunk_{i}`.
  final List<EncryptedChunkV2> chunks;
}

class EncryptedChunkV2 {
  const EncryptedChunkV2({required this.index, required this.data});

  final int index;
  final Uint8List data;
}

/// Шифрование файла.
///
/// [thumbnail] должен быть ≤ 64 КБ (иначе бросаем). Большие thumbnails — follow-up.
Future<EncryptMediaResultV2> encryptMediaFileV2({
  required Uint8List data,
  required MediaKindV2 kind,
  required String mime,
  required String fileId,
  required Uint8List chatKeyRaw,
  Uint8List? metadataPlaintext,
  Uint8List? thumbnailBytes,
  String? thumbnailMime,
}) async {
  if (fileId.isEmpty) {
    throw StateError('E2EE_MEDIA_FILE_ID_REQUIRED');
  }
  if (data.isEmpty) {
    throw StateError('E2EE_MEDIA_EMPTY');
  }
  if (thumbnailBytes != null &&
      thumbnailBytes.lengthInBytes > e2eeMediaThumbInlineMaxBytes) {
    throw StateError('E2EE_MEDIA_THUMB_TOO_LARGE');
  }

  final fileKeyRaw = randomBytes(32);
  final ivPrefix = randomBytes(8);

  final total = data.lengthInBytes;
  final chunkCount =
      total == 0 ? 1 : ((total + e2eeMediaChunkSizeV2 - 1) ~/ e2eeMediaChunkSizeV2);
  final chunks = <EncryptedChunkV2>[];
  for (var i = 0; i < chunkCount; i++) {
    final start = i * e2eeMediaChunkSizeV2;
    final end = (start + e2eeMediaChunkSizeV2) > total
        ? total
        : start + e2eeMediaChunkSizeV2;
    final slice = Uint8List.sublistView(data, start, end);
    final iv = _buildChunkIv(ivPrefix, i);
    final aad = buildAadV2(<Object>[fileId, i, kind.wire]);
    final ct = await aesGcmEncryptV2(
      key: fileKeyRaw,
      iv: iv,
      plaintext: slice,
      aad: aad,
    );
    chunks.add(EncryptedChunkV2(index: i, data: ct));
  }

  final wrap = await wrapFileKeySymmetricV2(
    fileKeyRaw: fileKeyRaw,
    chatKeyRaw: chatKeyRaw,
    fileId: fileId,
  );

  MediaEnvelopeThumbV2? thumb;
  if (thumbnailBytes != null && thumbnailBytes.isNotEmpty) {
    final tIv = randomBytes(12);
    final tAad = buildAadV2(<Object>[fileId, 'thumb', kind.wire]);
    final tCt = await aesGcmEncryptV2(
      key: fileKeyRaw,
      iv: tIv,
      plaintext: thumbnailBytes,
      aad: tAad,
    );
    thumb = MediaEnvelopeThumbV2(
      iv: tIv,
      ct: tCt,
      mime: thumbnailMime ?? 'image/jpeg',
    );
  }

  MediaEnvelopeMetaV2? metadataEnc;
  if (metadataPlaintext != null && metadataPlaintext.isNotEmpty) {
    final mIv = randomBytes(12);
    final mAad = buildAadV2(<Object>[fileId, 'meta', kind.wire]);
    final mCt = await aesGcmEncryptV2(
      key: fileKeyRaw,
      iv: mIv,
      plaintext: metadataPlaintext,
      aad: mAad,
    );
    metadataEnc = MediaEnvelopeMetaV2(iv: mIv, ct: mCt);
  }

  final envelope = MediaEnvelopeV2(
    fileId: fileId,
    kind: kind,
    mime: mime,
    size: total,
    wrap: wrap,
    chunkCount: chunkCount,
    ivPrefix: ivPrefix,
    thumb: thumb,
    metadataEnc: metadataEnc,
  );

  return EncryptMediaResultV2(envelope: envelope, chunks: chunks);
}

typedef FetchEncryptedChunkFnV2 = Future<Uint8List> Function(int index);

class DecryptMediaResultV2 {
  const DecryptMediaResultV2({required this.data, this.thumbnail, this.metadata});

  final Uint8List data;
  final DecryptedMediaThumb? thumbnail;
  final Uint8List? metadata;
}

class DecryptedMediaThumb {
  const DecryptedMediaThumb({required this.data, required this.mime});

  final Uint8List data;
  final String mime;
}

/// Расшифровка: загружает все chunk'и и собирает plain-buffer.
///
/// Для больших файлов используйте `decryptMediaFileStreamV2` (отдаёт поток).
Future<DecryptMediaResultV2> decryptMediaFileV2({
  required MediaEnvelopeV2 envelope,
  required Uint8List chatKeyRaw,
  required FetchEncryptedChunkFnV2 fetchChunk,
}) async {
  final fileKeyRaw = await unwrapFileKeySymmetricV2(
    wrap: envelope.wrap,
    chatKeyRaw: chatKeyRaw,
    fileId: envelope.fileId,
  );
  final pieces = <Uint8List>[];
  var total = 0;
  for (var i = 0; i < envelope.chunkCount; i++) {
    final ct = await fetchChunk(i);
    final iv = _buildChunkIv(envelope.ivPrefix, i);
    final aad = buildAadV2(<Object>[envelope.fileId, i, envelope.kind.wire]);
    final pt = await aesGcmDecryptV2(
      key: fileKeyRaw,
      iv: iv,
      ciphertextPlusTag: ct,
      aad: aad,
    );
    pieces.add(pt);
    total += pt.lengthInBytes;
  }
  final out = Uint8List(total);
  var off = 0;
  for (final p in pieces) {
    out.setRange(off, off + p.lengthInBytes, p);
    off += p.lengthInBytes;
  }

  DecryptedMediaThumb? thumbnail;
  if (envelope.thumb != null) {
    final t = envelope.thumb!;
    final pt = await aesGcmDecryptV2(
      key: fileKeyRaw,
      iv: t.iv,
      ciphertextPlusTag: t.ct,
      aad: buildAadV2(<Object>[envelope.fileId, 'thumb', envelope.kind.wire]),
    );
    thumbnail = DecryptedMediaThumb(data: pt, mime: t.mime);
  }

  Uint8List? metadata;
  if (envelope.metadataEnc != null) {
    final m = envelope.metadataEnc!;
    metadata = await aesGcmDecryptV2(
      key: fileKeyRaw,
      iv: m.iv,
      ciphertextPlusTag: m.ct,
      aad: buildAadV2(<Object>[envelope.fileId, 'meta', envelope.kind.wire]),
    );
  }

  return DecryptMediaResultV2(data: out, thumbnail: thumbnail, metadata: metadata);
}

/// Ленивая потоковая расшифровка. Отдаёт по одному chunk'у, не удерживает
/// весь файл в памяти.
Stream<Uint8List> decryptMediaFileStreamV2({
  required MediaEnvelopeV2 envelope,
  required Uint8List chatKeyRaw,
  required FetchEncryptedChunkFnV2 fetchChunk,
}) async* {
  final fileKeyRaw = await unwrapFileKeySymmetricV2(
    wrap: envelope.wrap,
    chatKeyRaw: chatKeyRaw,
    fileId: envelope.fileId,
  );
  for (var i = 0; i < envelope.chunkCount; i++) {
    final ct = await fetchChunk(i);
    final iv = _buildChunkIv(envelope.ivPrefix, i);
    final aad = buildAadV2(<Object>[envelope.fileId, i, envelope.kind.wire]);
    final pt = await aesGcmDecryptV2(
      key: fileKeyRaw,
      iv: iv,
      ciphertextPlusTag: ct,
      aad: aad,
    );
    yield pt;
  }
}

/// Storage prefix. Должен совпадать с web.
const String e2eeMediaV2StoragePrefix = 'chat-attachments-enc';

/// Полный путь к chunk'у в Storage.
String chunkStoragePathV2({
  required String conversationId,
  required String messageId,
  required String fileId,
  required int index,
}) {
  return '$e2eeMediaV2StoragePrefix/$conversationId/$messageId/$fileId/chunk_$index';
}
