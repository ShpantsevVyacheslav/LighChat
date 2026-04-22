'use client';

/**
 * Phase 7 — React hook для работы с зашифрованными вложениями E2EE v2.
 *
 * Две ответственности:
 *  1. `encryptAndUploadForSend` — берёт `File[]` и шифрует каждый через
 *     `encryptAndUploadMediaFileV2`. Возвращает массив envelope'ов в том же
 *     порядке. Стикеры / GIF проходят `null` и остаются в plaintext-`attachments`.
 *  2. `resolveForView({ messageId, envelopes })` — для просмотра входящих:
 *     скачивает и расшифровывает каждый envelope, возвращает `Blob`/URL.
 *     Отпечатки blob-URL кэшируются по `messageId+fileId`.
 *
 * Используется на стороне `ChatWindow`/`ThreadWindow` в Phase 9 (rollout) или
 * локально для pilot-фич. Текстовая часть сообщения по-прежнему шифруется через
 * `useE2eeConversation.encryptOutgoingHtmlV2`.
 */

import { useCallback, useEffect, useMemo, useRef } from 'react';
import type { FirebaseStorage } from 'firebase/storage';

import {
  E2EE_MEDIA_V2_STORAGE_PREFIX,
  decryptMediaFileStreamV2,
  encryptAndUploadMediaFileV2,
  downloadAndDecryptMediaFileV2,
  isEncryptableMimeV2,
  getCachedMedia,
  putCachedMedia,
  type EncryptUploadResult,
} from '@/lib/e2ee';
import { ref as storageRef, getDownloadURL } from 'firebase/storage';
import type { ChatMessageE2eeAttachmentEnvelopeV2 } from '@/lib/types';

export type EncryptAndUploadAttachmentInput = {
  file: File;
  thumbnailBytes?: Uint8Array;
  thumbnailMime?: string;
  /** Сериализованный JSON метаданных (duration/width/height/waveform). */
  metadataJson?: string;
  kindHint?: ChatMessageE2eeAttachmentEnvelopeV2['kind'];
};

export type EncryptAttachmentsForSendResult = {
  /** В том же порядке, что и `inputs`. `null` — файл не нуждается в шифровании
   * (стикер/GIF) и должен быть загружен обычным путём. */
  envelopes: Array<ChatMessageE2eeAttachmentEnvelopeV2 | null>;
  /** Paths для rollback'а при ошибке writeMessage. */
  uploadedPaths: string[];
};

export type UseE2eeMediaAttachmentsParams = {
  storage: FirebaseStorage | null;
  conversationId: string | null;
  /** Из `useE2eeConversation`. */
  getChatKeyRawV2ForEpoch: (epoch: number) => Promise<ArrayBuffer | null>;
  /** Текущая эпоха чата. */
  epoch: number;
};

export function useE2eeMediaAttachments(params: UseE2eeMediaAttachmentsParams) {
  const { storage, conversationId, getChatKeyRawV2ForEpoch, epoch } = params;
  const resolvedUrlCache = useRef<Map<string, string>>(new Map());

  useEffect(() => {
    const cache = resolvedUrlCache.current;
    return () => {
      cache.forEach((url) => URL.revokeObjectURL(url));
      cache.clear();
    };
  }, [conversationId]);

  const encryptAndUploadForSend = useCallback(
    async (
      messageId: string,
      inputs: EncryptAndUploadAttachmentInput[]
    ): Promise<EncryptAttachmentsForSendResult> => {
      if (!storage || !conversationId) {
        throw new Error('E2EE_MEDIA_NO_STORAGE');
      }
      const chatKeyRaw = await getChatKeyRawV2ForEpoch(epoch);
      if (!chatKeyRaw) {
        throw new Error('E2EE_MEDIA_NO_KEY_FOR_EPOCH');
      }

      const envelopes: Array<ChatMessageE2eeAttachmentEnvelopeV2 | null> = [];
      const uploadedPaths: string[] = [];

      for (const input of inputs) {
        if (!isEncryptableMimeV2(input.file.type)) {
          envelopes.push(null);
          continue;
        }
        const res: EncryptUploadResult = await encryptAndUploadMediaFileV2(
          {
            storage,
            conversationId,
            messageId,
            file: input.file,
            thumbnailBytes: input.thumbnailBytes,
            thumbnailMime: input.thumbnailMime,
            metadataJson: input.metadataJson,
            kindHint: input.kindHint,
          },
          chatKeyRaw
        );
        envelopes.push(res.envelope);
        uploadedPaths.push(...res.chunkStoragePaths);
      }

      return { envelopes, uploadedPaths };
    },
    [storage, conversationId, epoch, getChatKeyRawV2ForEpoch]
  );

  const resolveForView = useCallback(
    async (opts: {
      messageId: string;
      envelope: ChatMessageE2eeAttachmentEnvelopeV2;
      messageEpoch: number;
    }): Promise<{ objectUrl: string; mime: string }> => {
      if (!storage || !conversationId) {
        throw new Error('E2EE_MEDIA_NO_STORAGE');
      }
      const cacheKey = `${opts.messageId}:${opts.envelope.fileId}`;
      // 1) in-memory blob-URL (одна сессия).
      const hit = resolvedUrlCache.current.get(cacheKey);
      if (hit) return { objectUrl: hit, mime: opts.envelope.mime };
      // 2) persistent IndexedDB cache расшифрованных байт. Если нашли —
      //    просто создаём свежий blob-URL (objectURL'ы не переживают reload).
      try {
        const cached = await getCachedMedia(
          conversationId,
          opts.messageId,
          opts.envelope.fileId
        );
        if (cached) {
          const bytesCopy = cached.bytes instanceof Uint8Array
            ? cached.bytes
            : new Uint8Array(cached.bytes as unknown as ArrayBuffer);
          const blob = new Blob([bytesCopy as BlobPart], { type: cached.mime });
          const url = URL.createObjectURL(blob);
          resolvedUrlCache.current.set(cacheKey, url);
          return { objectUrl: url, mime: cached.mime };
        }
      } catch {
        // best-effort — продолжаем к сетевому пути.
      }
      const chatKeyRaw = await getChatKeyRawV2ForEpoch(opts.messageEpoch);
      if (!chatKeyRaw) throw new Error('E2EE_MEDIA_NO_KEY_FOR_EPOCH');
      const decrypted = await downloadAndDecryptMediaFileV2(
        {
          storage,
          conversationId,
          messageId: opts.messageId,
          envelope: opts.envelope,
        },
        chatKeyRaw
      );
      const bytes = new Uint8Array(decrypted.data);
      const blob = new Blob([bytes as BlobPart], { type: opts.envelope.mime });
      const url = URL.createObjectURL(blob);
      resolvedUrlCache.current.set(cacheKey, url);
      // Сохраняем расшифрованные байты в persistent cache (fire-and-forget).
      void putCachedMedia(conversationId, opts.messageId, opts.envelope.fileId, {
        bytes,
        mime: opts.envelope.mime,
      });
      return { objectUrl: url, mime: opts.envelope.mime };
    },
    [storage, conversationId, getChatKeyRawV2ForEpoch]
  );

  /**
   * Gap #2 (минимальный вариант) — потоковая расшифровка поверх
   * `decryptMediaFileStreamV2`. Возвращает `Blob`-URL как и `resolveForView`,
   * но **собирает plaintext по 4 МиБ чанкам**: чанк скачивается → сразу
   * расшифровывается → кладётся в растущий `Uint8Array[]`. Разница с
   * `resolveForView` (который дёргает `downloadAndDecryptMediaFileV2`):
   *
   *  - пик памяти ≈ 1 чанк (4 МиБ) поверх итогового plaintext'а, а не
   *    2× (ciphertext + plaintext) как у обычного пути;
   *  - первый байт ciphertext'а начинает обрабатываться параллельно со
   *    скачиванием следующего — меньше сетевая пауза.
   *
   * Playback всё равно стартует только после полного скачивания и склейки
   * в `Blob`. Для instant-playback нужен MSE или Service Worker — это
   * отложенный вариант, см. RFC §8 и комментарий в `media-crypto-v2.ts`.
   *
   * Кэш blob-URL общий с `resolveForView` — один и тот же ключ
   * `messageId:fileId` покрывает оба пути, что позволяет UI спокойно
   * переключаться между ними без повторной расшифровки.
   */
  const resolveStreamForView = useCallback(
    async (opts: {
      messageId: string;
      envelope: ChatMessageE2eeAttachmentEnvelopeV2;
      messageEpoch: number;
    }): Promise<{ objectUrl: string; mime: string }> => {
      if (!storage || !conversationId) {
        throw new Error('E2EE_MEDIA_NO_STORAGE');
      }
      const cacheKey = `${opts.messageId}:${opts.envelope.fileId}`;
      const hit = resolvedUrlCache.current.get(cacheKey);
      if (hit) return { objectUrl: hit, mime: opts.envelope.mime };
      // persistent cache — точно так же, как в resolveForView
      try {
        const cached = await getCachedMedia(
          conversationId,
          opts.messageId,
          opts.envelope.fileId
        );
        if (cached) {
          const bytesCopy = cached.bytes instanceof Uint8Array
            ? cached.bytes
            : new Uint8Array(cached.bytes as unknown as ArrayBuffer);
          const blob = new Blob([bytesCopy as BlobPart], { type: cached.mime });
          const url = URL.createObjectURL(blob);
          resolvedUrlCache.current.set(cacheKey, url);
          return { objectUrl: url, mime: cached.mime };
        }
      } catch {
        // ignore
      }
      const chatKeyRaw = await getChatKeyRawV2ForEpoch(opts.messageEpoch);
      if (!chatKeyRaw) throw new Error('E2EE_MEDIA_NO_KEY_FOR_EPOCH');

      const fileId = opts.envelope.fileId;
      const cidLocal = conversationId;
      const midLocal = opts.messageId;
      const storageLocal = storage;
      const stream = await decryptMediaFileStreamV2(
        opts.envelope,
        chatKeyRaw,
        async (index: number) => {
          const path = `${E2EE_MEDIA_V2_STORAGE_PREFIX}/${cidLocal}/${midLocal}/${fileId}/chunk_${index}`;
          const url = await getDownloadURL(storageRef(storageLocal, path));
          const resp = await fetch(url);
          if (!resp.ok) {
            throw new Error(
              `E2EE_MEDIA_CHUNK_FETCH_FAILED:${index}:${resp.status}`
            );
          }
          return new Uint8Array(await resp.arrayBuffer());
        }
      );

      const chunks: Uint8Array[] = [];
      const reader = stream.getReader();
      while (true) {
        const { value, done } = await reader.read();
        if (done) break;
        if (value) chunks.push(value);
      }
      let totalLen = 0;
      for (const c of chunks) totalLen += c.byteLength;
      const flat = new Uint8Array(totalLen);
      let offset = 0;
      for (const c of chunks) {
        flat.set(c, offset);
        offset += c.byteLength;
      }
      const blob = new Blob([flat as BlobPart], { type: opts.envelope.mime });
      const url = URL.createObjectURL(blob);
      resolvedUrlCache.current.set(cacheKey, url);
      void putCachedMedia(conversationId, opts.messageId, opts.envelope.fileId, {
        bytes: flat,
        mime: opts.envelope.mime,
      });
      return { objectUrl: url, mime: opts.envelope.mime };
    },
    [storage, conversationId, getChatKeyRawV2ForEpoch]
  );

  return useMemo(
    () => ({ encryptAndUploadForSend, resolveForView, resolveStreamForView }),
    [encryptAndUploadForSend, resolveForView, resolveStreamForView]
  );
}
