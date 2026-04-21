/**
 * Phase 7 — E2EE v2 media upload/download (web).
 *
 * Обёртка вокруг [`media-crypto-v2.ts`](./media-crypto-v2.ts), которая берёт
 * `File` + `chatKey` эпохи, производит шифрование чанков, выкладывает их в
 * `chat-attachments-enc/{cid}/{mid}/{fileId}/chunk_{i}` и формирует готовый
 * `ChatMessageE2eeAttachmentEnvelopeV2` для поля `message.e2ee.attachments[i]`.
 *
 * НЕ шифрует sticker/gif (они идут обычным путём в `attachments[]`), см. RFC §7.5.
 *
 * Использование в ChatWindow/ThreadWindow — Phase 7d (UI-интеграция).
 */

import { ref as storageRef, uploadBytes, getDownloadURL } from 'firebase/storage';
import type { FirebaseStorage } from 'firebase/storage';

import type { ChatMessageE2eeAttachmentEnvelopeV2 } from '@/lib/types';
import {
  encryptMediaFileV2,
  decryptMediaFileV2,
  E2EE_MEDIA_V2_CHUNK_SIZE,
  type DecryptMediaResult,
} from '@/lib/e2ee/v2/media-crypto-v2';

export const E2EE_MEDIA_V2_STORAGE_PREFIX = 'chat-attachments-enc';

/** Мгновенный ULID-like id: случайные 16 байт → hex без тире. Хватает для fileId. */
export function randomFileIdV2(): string {
  const u = new Uint8Array(16);
  crypto.getRandomValues(u);
  return Array.from(u, (b) => b.toString(16).padStart(2, '0')).join('');
}

function mapMimeToKind(
  mime: string,
  hintedKind?: ChatMessageE2eeAttachmentEnvelopeV2['kind']
): ChatMessageE2eeAttachmentEnvelopeV2['kind'] {
  if (hintedKind) return hintedKind;
  const m = (mime || '').toLowerCase();
  if (m.startsWith('image/')) return 'image';
  if (m.startsWith('video/')) return 'video';
  if (m.startsWith('audio/')) return 'voice';
  return 'file';
}

/**
 * Не каждое сообщение с вложением нужно шифровать: stickers и gif, даже
 * приехав через `File`, шифрованию не подлежат (§7.5).
 */
export function isEncryptableMimeV2(mime: string): boolean {
  const m = (mime || '').toLowerCase();
  if (m === 'image/gif') return false;
  if (m.includes('sticker')) return false;
  return true;
}

export type EncryptUploadInput = {
  storage: FirebaseStorage;
  conversationId: string;
  messageId: string;
  /** Файл на загрузку. */
  file: File;
  /** Готовые байты thumbnail ≤ 64 КБ (напр. первый кадр видео, компресс image). */
  thumbnailBytes?: Uint8Array;
  thumbnailMime?: string;
  /** Сериализованные метаданные (длительность/размеры/waveform) — UTF-8. */
  metadataJson?: string;
  /** Подсказка kind, если детектор по MIME не уверен (voice vs audio file). */
  kindHint?: ChatMessageE2eeAttachmentEnvelopeV2['kind'];
  /** Уникальный id файла. Если не задан — генерируем. */
  fileId?: string;
};

export type EncryptUploadResult = {
  envelope: ChatMessageE2eeAttachmentEnvelopeV2;
  /** Полные пути загруженных chunk'ов в Storage. */
  chunkStoragePaths: string[];
};

function chunkStoragePath(
  conversationId: string,
  messageId: string,
  fileId: string,
  index: number
): string {
  return `${E2EE_MEDIA_V2_STORAGE_PREFIX}/${conversationId}/${messageId}/${fileId}/chunk_${index}`;
}

/**
 * Шифрует файл, загружает chunk'и в Storage и возвращает `MediaEnvelopeV2`.
 *
 * При ошибке часть chunk'ов может остаться в Storage; чистка — забота writer'а
 * (повтор отправки перезапишет chunk по тому же пути, поскольку fileId совпадает).
 */
export async function encryptAndUploadMediaFileV2(
  input: EncryptUploadInput,
  chatKeyRaw: ArrayBuffer
): Promise<EncryptUploadResult> {
  const fileId = input.fileId ?? randomFileIdV2();
  const kind = mapMimeToKind(input.file.type, input.kindHint);

  const arr = new Uint8Array(await input.file.arrayBuffer());
  const metadataPlaintext = input.metadataJson
    ? new TextEncoder().encode(input.metadataJson)
    : undefined;
  const thumbnail =
    input.thumbnailBytes && input.thumbnailBytes.byteLength > 0
      ? { data: input.thumbnailBytes, mime: input.thumbnailMime ?? 'image/jpeg' }
      : undefined;

  const { envelope, chunks } = await encryptMediaFileV2(
    {
      data: arr,
      kind,
      mime: input.file.type || 'application/octet-stream',
      fileId,
      metadataPlaintext,
      thumbnail,
    },
    chatKeyRaw
  );

  const chunkStoragePaths: string[] = [];
  for (const chunk of chunks) {
    const path = chunkStoragePath(input.conversationId, input.messageId, fileId, chunk.index);
    const ref = storageRef(input.storage, path);
    // Важно: contentType задаём чистый application/octet-stream, чтобы ни
    // transcoder, ни браузерная раскладка MIME не пыталась угадать что внутри.
    await uploadBytes(ref, chunk.data, {
      contentType: 'application/octet-stream',
      customMetadata: {
        e2eeV2ChunkIndex: String(chunk.index),
        e2eeV2FileId: fileId,
        e2eeV2ChunkCount: String(envelope.chunking.chunkCount),
      },
    });
    chunkStoragePaths.push(path);
  }

  return { envelope, chunkStoragePaths };
}

export type DownloadDecryptInput = {
  storage: FirebaseStorage;
  conversationId: string;
  messageId: string;
  envelope: ChatMessageE2eeAttachmentEnvelopeV2;
};

/**
 * Загружает все chunk'и и расшифровывает в память. Для больших файлов
 * используйте `decryptMediaFileStreamV2` + ручной fetcher (Phase 7d: в UI
 * воспроизведении видео/аудио подключим streaming-режим).
 */
export async function downloadAndDecryptMediaFileV2(
  input: DownloadDecryptInput,
  chatKeyRaw: ArrayBuffer
): Promise<DecryptMediaResult> {
  return decryptMediaFileV2(input.envelope, chatKeyRaw, async (index) => {
    const path = chunkStoragePath(
      input.conversationId,
      input.messageId,
      input.envelope.fileId,
      index
    );
    const url = await getDownloadURL(storageRef(input.storage, path));
    const resp = await fetch(url);
    if (!resp.ok) {
      throw new Error(`E2EE_MEDIA_CHUNK_FETCH_FAILED:${index}:${resp.status}`);
    }
    const buf = await resp.arrayBuffer();
    return new Uint8Array(buf);
  });
}

export const E2EE_MEDIA_V2_CHUNK_SIZE_RE_EXPORT = E2EE_MEDIA_V2_CHUNK_SIZE;
