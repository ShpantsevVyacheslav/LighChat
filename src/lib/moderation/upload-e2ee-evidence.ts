'use client';

import {
  type FirebaseStorage,
  getDownloadURL,
  ref as storageRef,
  uploadBytes,
} from 'firebase/storage';
import { downloadAndDecryptMediaFileV2 } from '@/lib/e2ee';
import type {
  ChatAttachment,
  ChatMessageE2eeAttachmentEnvelopeV2,
} from '@/lib/types';

/**
 * Перекладывает расшифрованную копию E2EE-вложений в Storage-зону
 * `moderation-evidence/{reporterUid}/{nonce}/...` для рассмотрения
 * админом. Используется ровно в момент сабмита жалобы — после успешной
 * записи `messageReports` evidence остаётся жить до его очистки
 * scheduled CF (`evidenceCleanupDaily`).
 *
 * SECURITY:
 *  - Storage rules `moderation-evidence/{ownerUid}/**`:
 *      write — только сам владелец uid, read — только admin.
 *  - Server action `createMessageReportAction` дополнительно
 *    валидирует, что каждый URL из переданного `evidenceAttachments`
 *    указывает на путь `moderation-evidence/{reporterUid}/{nonce}/`.
 */

export type UploadE2eeEvidenceParams = {
  storage: FirebaseStorage;
  conversationId: string;
  messageId: string;
  reporterUid: string;
  /** Случайный nonce (8–64 символа `[A-Za-z0-9_-]`). Generates via `randomEvidenceNonce`. */
  evidenceNonce: string;
  envelopes: Array<ChatMessageE2eeAttachmentEnvelopeV2 | null | undefined>;
  /** Берём ключ чата для нужной эпохи (E2EE rekey-флоу). */
  getChatKeyRawV2ForEpoch: (epoch: number) => Promise<ArrayBuffer | null>;
  /** Эпоха сообщения; обычно совпадает с `message.e2ee.epoch`. */
  messageEpoch: number;
};

const EVIDENCE_NONCE_ALPHABET =
  'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

/** Криптостойкий nonce для evidence-префикса (24 символа). */
export function randomEvidenceNonce(): string {
  const out = new Array<string>(24);
  const rand = new Uint8Array(24);
  if (typeof globalThis.crypto !== 'undefined' && globalThis.crypto.getRandomValues) {
    globalThis.crypto.getRandomValues(rand);
  } else {
    for (let i = 0; i < rand.length; i++) rand[i] = Math.floor(Math.random() * 256);
  }
  for (let i = 0; i < out.length; i++) {
    out[i] = EVIDENCE_NONCE_ALPHABET[rand[i] % EVIDENCE_NONCE_ALPHABET.length];
  }
  return out.join('');
}

function sanitizeFileName(name: string): string {
  // оставляем буквы, цифры, точку, подчёркивание, дефис; всё остальное — `_`.
  return name.replace(/[^A-Za-z0-9._-]/g, '_').slice(0, 120) || 'evidence';
}

function extForMime(mime: string): string {
  if (mime.startsWith('image/jpeg')) return '.jpg';
  if (mime.startsWith('image/png')) return '.png';
  if (mime.startsWith('image/webp')) return '.webp';
  if (mime.startsWith('image/gif')) return '.gif';
  if (mime.startsWith('video/mp4') || mime === 'video/quicktime') return '.mp4';
  if (mime.startsWith('video/webm')) return '.webm';
  if (mime.startsWith('audio/mp4') || mime === 'audio/x-m4a' || mime === 'audio/m4a') return '.m4a';
  if (mime.startsWith('audio/mpeg')) return '.mp3';
  if (mime.startsWith('audio/ogg')) return '.ogg';
  if (mime.startsWith('audio/wav')) return '.wav';
  if (mime === 'application/pdf') return '.pdf';
  return '';
}

export async function uploadE2eeEvidence(
  params: UploadE2eeEvidenceParams,
): Promise<ChatAttachment[]> {
  const {
    storage,
    conversationId,
    messageId,
    reporterUid,
    evidenceNonce,
    envelopes,
    getChatKeyRawV2ForEpoch,
    messageEpoch,
  } = params;

  const out: ChatAttachment[] = [];
  if (envelopes.length === 0) return out;

  const chatKeyRaw = await getChatKeyRawV2ForEpoch(messageEpoch);
  if (!chatKeyRaw) {
    throw new Error('EVIDENCE_NO_CHAT_KEY');
  }

  for (let i = 0; i < envelopes.length; i++) {
    const env = envelopes[i];
    if (!env) continue; // null = plaintext sticker/gif, evidence не нужен
    // Расшифровываем chunked-файл целиком в память. Размер ограничен
    // нашими общими лимитами (220 МиБ через storage rules), на админ-
    // моделирование жалоб такого размера не рассчитываем — обычно
    // изображение/видео < 30 МиБ.
    const decrypted = await downloadAndDecryptMediaFileV2(
      {
        storage,
        conversationId,
        messageId,
        envelope: env,
      },
      chatKeyRaw,
    );

    const baseName = `att${i}${extForMime(env.mime)}`;
    const fileName = sanitizeFileName(baseName);
    const objectPath = `moderation-evidence/${reporterUid}/${evidenceNonce}/${fileName}`;
    const ref = storageRef(storage, objectPath);
    const bytes = decrypted.data;
    const blob = new Blob([bytes as BlobPart], { type: env.mime || 'application/octet-stream' });
    await uploadBytes(ref, blob, {
      contentType: env.mime || 'application/octet-stream',
      customMetadata: {
        evidenceNonce,
        sourceMessageId: messageId,
        sourceConversationId: conversationId,
        sourceFileId: env.fileId,
      },
    });
    const url = await getDownloadURL(ref);
    out.push({
      url,
      name: fileName,
      type: env.mime || 'application/octet-stream',
      size: bytes.byteLength,
    });
  }

  return out;
}
