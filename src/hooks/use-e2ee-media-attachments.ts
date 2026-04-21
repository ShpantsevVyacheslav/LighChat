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
  encryptAndUploadMediaFileV2,
  downloadAndDecryptMediaFileV2,
  isEncryptableMimeV2,
  type EncryptUploadResult,
} from '@/lib/e2ee';
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
      const hit = resolvedUrlCache.current.get(cacheKey);
      if (hit) return { objectUrl: hit, mime: opts.envelope.mime };
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
      const blob = new Blob([decrypted.data as BlobPart], { type: opts.envelope.mime });
      const url = URL.createObjectURL(blob);
      resolvedUrlCache.current.set(cacheKey, url);
      return { objectUrl: url, mime: opts.envelope.mime };
    },
    [storage, conversationId, getChatKeyRawV2ForEpoch]
  );

  return useMemo(
    () => ({ encryptAndUploadForSend, resolveForView }),
    [encryptAndUploadForSend, resolveForView]
  );
}
