/**
 * E2EE v2 — Media crypto (web).
 *
 * Реализует §6.4–§6.5 RFC `07-e2ee-v2-protocol.md`:
 *  - per-file AES-256-GCM ключ, генерируется клиентом;
 *  - chunked streaming encryption (4 МиБ, IV = `nonce_prefix‖chunkIndex_BE32`);
 *  - symmetric wrap file-key под ChatKey эпохи через HKDF-SHA-256;
 *  - AEAD AAD на chunk'ах: `fileId‖chunkIndex‖kind` — защищает от перестановки;
 *  - thumbnail inline AEAD, метаданные (length/dims/waveform) тоже AEAD.
 *
 * НЕ решает: upload/download транспорт (это на вызывающей стороне),
 * тип сообщения в Firestore (кладёт MediaEnvelopeV2, отдельно `message.attachments`
 * для E2EE-медиа остаётся пустым; стикеры/GIF проходят plain-путём).
 */

import { fromBase64, toBase64 } from '@/lib/e2ee/b64';
import type {
  ChatMessageE2eeAttachmentEnvelopeV2,
  E2eeKeyWrapEntry,
} from '@/lib/types';

const GCM_TAG_BITS = 128;
const E2EE_MEDIA_CHUNK_SIZE = 4 * 1024 * 1024; // 4 МиБ — см. §7.3.
const E2EE_MEDIA_THUMB_INLINE_MAX_BYTES = 64 * 1024; // inline thumb порог.

export const E2EE_MEDIA_V2_CHUNK_SIZE = E2EE_MEDIA_CHUNK_SIZE;
export const E2EE_MEDIA_V2_THUMB_INLINE_MAX = E2EE_MEDIA_THUMB_INLINE_MAX_BYTES;

export type EncryptedMediaChunk = {
  /** 0-based индекс chunk'а. */
  index: number;
  /** Зашифрованные байты (ciphertext + 16-байт GCM tag в конце). */
  data: Uint8Array;
};

export type EncryptMediaInput = {
  /** Сырое тело файла. Предпочтительно передавать `ArrayBuffer`/`Uint8Array`,
   * чтобы не делать промежуточное `.arrayBuffer()`. */
  data: Uint8Array;
  kind: ChatMessageE2eeAttachmentEnvelopeV2['kind'];
  mime: string;
  /** Стабильный ULID/UUID; служит доменным разделителем AAD. */
  fileId: string;
  /** Плоский сериализованный JSON метаданных (длительность, размеры, waveform). */
  metadataPlaintext?: Uint8Array;
  /** Исходные байты thumbnail (будет зашифрован inline). */
  thumbnail?: {
    data: Uint8Array;
    mime: string;
  };
};

export type EncryptMediaResult = {
  envelope: ChatMessageE2eeAttachmentEnvelopeV2;
  /** Зашифрованные chunk'и в порядке `index`. Вызывающая сторона загружает их
   * в `chat-attachments-enc/{cid}/{mid}/{fileId}/chunk_{i}`. */
  chunks: EncryptedMediaChunk[];
};

function u8ToArrayBuffer(u: Uint8Array): ArrayBuffer {
  const c = new Uint8Array(u.byteLength);
  c.set(u);
  return c.buffer;
}

function buildAad(parts: ReadonlyArray<string | number>): Uint8Array {
  const joined = parts.map((p) => String(p)).join('\u001F');
  return new TextEncoder().encode(joined);
}

async function hkdfSha256(
  ikm: ArrayBuffer,
  salt: Uint8Array,
  info: string,
  lengthBytes: number
): Promise<ArrayBuffer> {
  const base = await crypto.subtle.importKey('raw', ikm as BufferSource, 'HKDF', false, [
    'deriveBits',
  ]);
  return crypto.subtle.deriveBits(
    {
      name: 'HKDF',
      hash: 'SHA-256',
      salt: u8ToArrayBuffer(salt) as BufferSource,
      info: new TextEncoder().encode(info) as BufferSource,
    },
    base,
    lengthBytes * 8
  );
}

/**
 * Собирает IV для chunk'а: 8-байт `nonce_prefix` + 4-байт big-endian index.
 * Важно: prefix генерируется один раз на файл и кладётся в envelope.
 */
function buildChunkIv(prefix: Uint8Array, index: number): Uint8Array {
  if (prefix.length !== 8) {
    throw new Error('E2EE_MEDIA_IV_PREFIX_BAD_LEN');
  }
  const iv = new Uint8Array(12);
  iv.set(prefix, 0);
  iv[8] = (index >>> 24) & 0xff;
  iv[9] = (index >>> 16) & 0xff;
  iv[10] = (index >>> 8) & 0xff;
  iv[11] = index & 0xff;
  return iv;
}

async function importAesGcmKey(raw32: ArrayBuffer, usages: KeyUsage[]): Promise<CryptoKey> {
  return crypto.subtle.importKey('raw', raw32 as BufferSource, { name: 'AES-GCM' }, false, usages);
}

function randomBytes(length: number): Uint8Array {
  const u = new Uint8Array(length);
  crypto.getRandomValues(u);
  return u;
}

/**
 * Wrap per-file ключа под ChatKey эпохи (симметричная обёртка поверх AES-GCM).
 * Возвращает структуру совместимую с `E2eeKeyWrapEntry` (ephPub = '' —
 * признак симметричной обёртки; расшифровщик видит пустую строку и не пытается
 * делать ECDH).
 */
async function wrapFileKeySymmetric(
  fileKeyRaw: ArrayBuffer,
  chatKeyRaw: ArrayBuffer,
  fileId: string
): Promise<E2eeKeyWrapEntry> {
  const wrapKeyRaw = await hkdfSha256(
    chatKeyRaw,
    new TextEncoder().encode(fileId),
    'lighchat/v2/media-wrap',
    32
  );
  const wrapKey = await importAesGcmKey(wrapKeyRaw, ['encrypt']);
  const iv = randomBytes(12);
  const aad = buildAad(['lighchat/v2/media-wrap', fileId]);
  const ct = await crypto.subtle.encrypt(
    {
      name: 'AES-GCM',
      iv: iv as BufferSource,
      additionalData: aad as BufferSource,
      tagLength: GCM_TAG_BITS,
    },
    wrapKey,
    fileKeyRaw as BufferSource
  );
  return { ephPub: '', iv: toBase64(iv), ct: toBase64(new Uint8Array(ct)) };
}

async function unwrapFileKeySymmetric(
  wrap: E2eeKeyWrapEntry,
  chatKeyRaw: ArrayBuffer,
  fileId: string
): Promise<ArrayBuffer> {
  if (wrap.ephPub && wrap.ephPub.length > 0) {
    throw new Error('E2EE_MEDIA_WRAP_EXPECTED_SYMMETRIC');
  }
  const wrapKeyRaw = await hkdfSha256(
    chatKeyRaw,
    new TextEncoder().encode(fileId),
    'lighchat/v2/media-wrap',
    32
  );
  const wrapKey = await importAesGcmKey(wrapKeyRaw, ['decrypt']);
  const aad = buildAad(['lighchat/v2/media-wrap', fileId]);
  return crypto.subtle.decrypt(
    {
      name: 'AES-GCM',
      iv: fromBase64(wrap.iv) as BufferSource,
      additionalData: aad as BufferSource,
      tagLength: GCM_TAG_BITS,
    },
    wrapKey,
    fromBase64(wrap.ct) as BufferSource
  );
}

async function encryptChunk(
  fileKey: CryptoKey,
  plain: Uint8Array,
  iv: Uint8Array,
  fileId: string,
  index: number,
  kind: string
): Promise<Uint8Array> {
  const aad = buildAad([fileId, index, kind]);
  const ct = await crypto.subtle.encrypt(
    {
      name: 'AES-GCM',
      iv: iv as BufferSource,
      additionalData: aad as BufferSource,
      tagLength: GCM_TAG_BITS,
    },
    fileKey,
    plain as BufferSource
  );
  return new Uint8Array(ct);
}

async function decryptChunk(
  fileKey: CryptoKey,
  ct: Uint8Array,
  iv: Uint8Array,
  fileId: string,
  index: number,
  kind: string
): Promise<Uint8Array> {
  const aad = buildAad([fileId, index, kind]);
  const pt = await crypto.subtle.decrypt(
    {
      name: 'AES-GCM',
      iv: iv as BufferSource,
      additionalData: aad as BufferSource,
      tagLength: GCM_TAG_BITS,
    },
    fileKey,
    ct as BufferSource
  );
  return new Uint8Array(pt);
}

/**
 * Шифрует один файл под ChatKey эпохи.
 */
export async function encryptMediaFileV2(
  input: EncryptMediaInput,
  chatKeyRaw: ArrayBuffer
): Promise<EncryptMediaResult> {
  if (!input.fileId) {
    throw new Error('E2EE_MEDIA_FILE_ID_REQUIRED');
  }
  if (input.data.byteLength === 0) {
    throw new Error('E2EE_MEDIA_EMPTY');
  }
  if (input.thumbnail && input.thumbnail.data.byteLength > E2EE_MEDIA_THUMB_INLINE_MAX_BYTES) {
    // Phase 7 inline thumbnail порог; более крупные thumbs — это open question
    // (см. §Open questions в RFC). Пока просим вызывающего дать thumbnail ≤ 64 КБ.
    throw new Error('E2EE_MEDIA_THUMB_TOO_LARGE');
  }

  const fileKeyRaw = u8ToArrayBuffer(randomBytes(32));
  const fileKey = await importAesGcmKey(fileKeyRaw, ['encrypt']);
  const ivPrefix = randomBytes(8);

  const chunks: EncryptedMediaChunk[] = [];
  const total = input.data.byteLength;
  const chunkCount = Math.max(1, Math.ceil(total / E2EE_MEDIA_CHUNK_SIZE));

  for (let i = 0; i < chunkCount; i++) {
    const start = i * E2EE_MEDIA_CHUNK_SIZE;
    const end = Math.min(start + E2EE_MEDIA_CHUNK_SIZE, total);
    const slice = input.data.subarray(start, end);
    const iv = buildChunkIv(ivPrefix, i);
    const ct = await encryptChunk(fileKey, slice, iv, input.fileId, i, input.kind);
    chunks.push({ index: i, data: ct });
  }

  const wrap = await wrapFileKeySymmetric(fileKeyRaw, chatKeyRaw, input.fileId);

  let thumb: ChatMessageE2eeAttachmentEnvelopeV2['thumb'];
  if (input.thumbnail) {
    const thumbEncKey = await importAesGcmKey(fileKeyRaw, ['encrypt']);
    const thumbIv = randomBytes(12);
    const thumbAad = buildAad([input.fileId, 'thumb', input.kind]);
    const thumbCt = await crypto.subtle.encrypt(
      {
        name: 'AES-GCM',
        iv: thumbIv as BufferSource,
        additionalData: thumbAad as BufferSource,
        tagLength: GCM_TAG_BITS,
      },
      thumbEncKey,
      input.thumbnail.data as BufferSource
    );
    thumb = {
      ivB64: toBase64(thumbIv),
      ciphertextB64: toBase64(new Uint8Array(thumbCt)),
      mime: input.thumbnail.mime,
    };
  }

  let metadataEnc: ChatMessageE2eeAttachmentEnvelopeV2['metadataEnc'];
  if (input.metadataPlaintext && input.metadataPlaintext.byteLength > 0) {
    const mKey = await importAesGcmKey(fileKeyRaw, ['encrypt']);
    const mIv = randomBytes(12);
    const mAad = buildAad([input.fileId, 'meta', input.kind]);
    const mCt = await crypto.subtle.encrypt(
      {
        name: 'AES-GCM',
        iv: mIv as BufferSource,
        additionalData: mAad as BufferSource,
        tagLength: GCM_TAG_BITS,
      },
      mKey,
      input.metadataPlaintext as BufferSource
    );
    metadataEnc = {
      ivB64: toBase64(mIv),
      ciphertextB64: toBase64(new Uint8Array(mCt)),
    };
  }

  const envelope: ChatMessageE2eeAttachmentEnvelopeV2 = {
    fileId: input.fileId,
    kind: input.kind,
    mime: input.mime,
    size: total,
    wrap,
    chunking: { chunkSizeBytes: 4194304, chunkCount },
    iv: { prefixB64: toBase64(ivPrefix) },
    ...(thumb ? { thumb } : {}),
    ...(metadataEnc ? { metadataEnc } : {}),
  };

  return { envelope, chunks };
}

/** Каллбек загрузки chunk'а по индексу. Реализация может быть http/fetch/... */
export type FetchEncryptedChunk = (index: number) => Promise<Uint8Array>;

/** Результат расшифровки — собранный plain-buffer + inline thumb/meta при наличии. */
export type DecryptMediaResult = {
  data: Uint8Array;
  thumbnail?: { data: Uint8Array; mime: string };
  metadata?: Uint8Array;
};

/**
 * Расшифровывает медиа-файл полностью в память.
 *
 * Для больших video/voice такой подход подходит до ~100 МиБ; для потокового
 * воспроизведения используйте `decryptMediaFileStreamV2` (см. ниже), который
 * возвращает `ReadableStream<Uint8Array>`.
 */
export async function decryptMediaFileV2(
  envelope: ChatMessageE2eeAttachmentEnvelopeV2,
  chatKeyRaw: ArrayBuffer,
  fetchChunk: FetchEncryptedChunk
): Promise<DecryptMediaResult> {
  const fileKeyRaw = await unwrapFileKeySymmetric(envelope.wrap, chatKeyRaw, envelope.fileId);
  const fileKey = await importAesGcmKey(fileKeyRaw, ['decrypt']);
  const prefix = fromBase64(envelope.iv.prefixB64);
  if (prefix.byteLength !== 8) {
    throw new Error('E2EE_MEDIA_IV_PREFIX_BAD_LEN');
  }

  const pieces: Uint8Array[] = [];
  let total = 0;
  for (let i = 0; i < envelope.chunking.chunkCount; i++) {
    const ct = await fetchChunk(i);
    const iv = buildChunkIv(prefix, i);
    const pt = await decryptChunk(fileKey, ct, iv, envelope.fileId, i, envelope.kind);
    pieces.push(pt);
    total += pt.byteLength;
  }
  const data = new Uint8Array(total);
  let off = 0;
  for (const p of pieces) {
    data.set(p, off);
    off += p.byteLength;
  }

  let thumbnail: DecryptMediaResult['thumbnail'];
  if (envelope.thumb) {
    const thumbKey = await importAesGcmKey(fileKeyRaw, ['decrypt']);
    const tAad = buildAad([envelope.fileId, 'thumb', envelope.kind]);
    const tPt = await crypto.subtle.decrypt(
      {
        name: 'AES-GCM',
        iv: fromBase64(envelope.thumb.ivB64) as BufferSource,
        additionalData: tAad as BufferSource,
        tagLength: GCM_TAG_BITS,
      },
      thumbKey,
      fromBase64(envelope.thumb.ciphertextB64) as BufferSource
    );
    thumbnail = { data: new Uint8Array(tPt), mime: envelope.thumb.mime };
  }

  let metadata: DecryptMediaResult['metadata'];
  if (envelope.metadataEnc) {
    const mKey = await importAesGcmKey(fileKeyRaw, ['decrypt']);
    const mAad = buildAad([envelope.fileId, 'meta', envelope.kind]);
    const mPt = await crypto.subtle.decrypt(
      {
        name: 'AES-GCM',
        iv: fromBase64(envelope.metadataEnc.ivB64) as BufferSource,
        additionalData: mAad as BufferSource,
        tagLength: GCM_TAG_BITS,
      },
      mKey,
      fromBase64(envelope.metadataEnc.ciphertextB64) as BufferSource
    );
    metadata = new Uint8Array(mPt);
  }

  return { data, thumbnail, metadata };
}

/**
 * Возвращает потоковую расшифровку: по одному chunk'у за раз, чтобы можно было
 * скармливать напрямую в `<video>` через `MediaSource` или складывать в IDB
 * без удержания всего файла в памяти.
 */
export async function decryptMediaFileStreamV2(
  envelope: ChatMessageE2eeAttachmentEnvelopeV2,
  chatKeyRaw: ArrayBuffer,
  fetchChunk: FetchEncryptedChunk
): Promise<ReadableStream<Uint8Array>> {
  const fileKeyRaw = await unwrapFileKeySymmetric(envelope.wrap, chatKeyRaw, envelope.fileId);
  const fileKey = await importAesGcmKey(fileKeyRaw, ['decrypt']);
  const prefix = fromBase64(envelope.iv.prefixB64);
  let i = 0;
  return new ReadableStream<Uint8Array>({
    async pull(controller) {
      if (i >= envelope.chunking.chunkCount) {
        controller.close();
        return;
      }
      try {
        const ct = await fetchChunk(i);
        const iv = buildChunkIv(prefix, i);
        const pt = await decryptChunk(fileKey, ct, iv, envelope.fileId, i, envelope.kind);
        controller.enqueue(pt);
        i += 1;
      } catch (e) {
        controller.error(e);
      }
    },
  });
}

/** Вспомогательные внутренние экспорты для unit-тестов. */
export const _internalForTests = {
  buildChunkIv,
  wrapFileKeySymmetric,
  unwrapFileKeySymmetric,
  hkdfSha256,
};
