/**
 * v2 WebCrypto helpers. Новое по сравнению с `src/lib/e2ee/webcrypto.ts`:
 *  - wrap/unwrap chat-key использует явный HKDF-SHA-256 вместо прямого
 *    WebCrypto `deriveKey`. Это делает derivation воспроизводимым в Dart
 *    (через `cryptography.Hkdf(Hmac.sha256(), ...)`) и задаёт чёткий
 *    `info`-доменник.
 *  - AEAD (`encryptUtf8WithAesGcmV2`, `decryptUtf8WithAesGcmV2`) принимают
 *    структурированный AAD — protocolVersion/conversationId/messageId/epoch —
 *    и собирают его детерминистично. Это предотвращает substitution-атаки,
 *    при которых ciphertext из сообщения A «подставляют» в сообщение B.
 *
 * Все функции сохраняют совместимость с v1 типами (`E2eeKeyWrapEntry`).
 */

import { fromBase64, toBase64 } from '@/lib/e2ee/b64';
import {
  importEcdhPrivateFromPkcs8,
  importEcdhPublicFromSpki,
} from '@/lib/e2ee/webcrypto';
import type { E2eeKeyWrapEntry } from '@/lib/types';

const AES_BITS = 256;
const GCM_TAG_BITS = 128;
const HKDF_SALT_EMPTY = new Uint8Array(0);

/** Копирует Uint8Array в независимый ArrayBuffer (TypeScript ругается на SAB). */
function u8ToArrayBuffer(u: Uint8Array): ArrayBuffer {
  const c = new Uint8Array(u.byteLength);
  c.set(u);
  return c.buffer;
}

/** Конкатенирует UTF-8 строки с разделителем 0x1F — тот же формат, что в Dart AAD. */
function buildAad(parts: ReadonlyArray<string | number>): Uint8Array {
  const joined = parts.map((p) => String(p)).join('\u001F');
  return new TextEncoder().encode(joined);
}

/** Внутренний HKDF-SHA-256 → N байт. */
async function hkdfSha256(
  ikm: ArrayBuffer,
  salt: ArrayBuffer | Uint8Array,
  info: string,
  lengthBytes: number
): Promise<ArrayBuffer> {
  const base = await crypto.subtle.importKey('raw', ikm as BufferSource, 'HKDF', false, [
    'deriveBits',
  ]);
  const saltU8 = salt instanceof Uint8Array ? salt : new Uint8Array(salt);
  const bits = await crypto.subtle.deriveBits(
    {
      name: 'HKDF',
      hash: 'SHA-256',
      salt: u8ToArrayBuffer(saltU8) as BufferSource,
      info: new TextEncoder().encode(info) as BufferSource,
    },
    base,
    lengthBytes * 8
  );
  return bits;
}

/**
 * v2 wrap chat-key для устройства получателя.
 *
 * Шаги (см. RFC §6.1):
 *  1. ephemeral ECDH ключ отправителя.
 *  2. Z = ECDH.deriveBits(ephPriv, recipientPub).
 *  3. wrapKey = HKDF-SHA-256(Z, salt = epochId || deviceId, info = 'lighchat/v2/wrap', len = 32).
 *  4. AES-GCM-Enc(wrapKey, iv, chatKey, aad = 'lighchat/v2/wrap' | epochId | deviceId).
 */
export async function wrapChatKeyForDeviceV2(
  chatKey32: ArrayBuffer,
  recipientPublicSpki: ArrayBuffer,
  epochId: string,
  deviceId: string
): Promise<E2eeKeyWrapEntry> {
  const ephemeral = await crypto.subtle.generateKey(
    { name: 'ECDH', namedCurve: 'P-256' },
    true,
    ['deriveBits']
  );
  const recipientPub = await importEcdhPublicFromSpki(recipientPublicSpki);
  const zBits = await crypto.subtle.deriveBits(
    { name: 'ECDH', public: recipientPub },
    ephemeral.privateKey,
    256
  );
  const saltBytes = new TextEncoder().encode(`${epochId}|${deviceId}`);
  const wrapKeyRaw = await hkdfSha256(zBits, saltBytes, 'lighchat/v2/wrap', 32);
  const wrapKey = await crypto.subtle.importKey(
    'raw',
    wrapKeyRaw as BufferSource,
    { name: 'AES-GCM' },
    false,
    ['encrypt']
  );
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const aad = buildAad(['lighchat/v2/wrap', epochId, deviceId]);
  const ct = await crypto.subtle.encrypt(
    {
      name: 'AES-GCM',
      iv: iv as BufferSource,
      additionalData: aad as BufferSource,
      tagLength: GCM_TAG_BITS,
    },
    wrapKey,
    chatKey32 as BufferSource
  );
  const ephSpki = await crypto.subtle.exportKey('spki', ephemeral.publicKey);
  return {
    ephPub: toBase64(new Uint8Array(ephSpki)),
    iv: toBase64(iv),
    ct: toBase64(new Uint8Array(ct)),
  };
}

export async function unwrapChatKeyForDeviceV2(
  wrap: E2eeKeyWrapEntry,
  recipientPrivateKey: CryptoKey,
  epochId: string,
  deviceId: string
): Promise<ArrayBuffer> {
  const ephPub = await importEcdhPublicFromSpki(fromBase64(wrap.ephPub));
  const zBits = await crypto.subtle.deriveBits(
    { name: 'ECDH', public: ephPub },
    recipientPrivateKey,
    256
  );
  const saltBytes = new TextEncoder().encode(`${epochId}|${deviceId}`);
  const wrapKeyRaw = await hkdfSha256(zBits, saltBytes, 'lighchat/v2/wrap', 32);
  const wrapKey = await crypto.subtle.importKey(
    'raw',
    wrapKeyRaw as BufferSource,
    { name: 'AES-GCM' },
    false,
    ['decrypt']
  );
  const aad = buildAad(['lighchat/v2/wrap', epochId, deviceId]);
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

/**
 * Версия для unwrap через PKCS#8 приватник (например, при восстановлении из
 * password-backup, где у нас нет `CryptoKey`). Эквивалентна импорту + unwrap.
 */
export async function unwrapChatKeyForDeviceV2FromPkcs8(
  wrap: E2eeKeyWrapEntry,
  recipientPrivatePkcs8: Uint8Array,
  epochId: string,
  deviceId: string
): Promise<ArrayBuffer> {
  const priv = await importEcdhPrivateFromPkcs8(recipientPrivatePkcs8);
  return unwrapChatKeyForDeviceV2(wrap, priv, epochId, deviceId);
}

export type V2MessageAadContext = {
  conversationId: string;
  messageId: string;
  epoch: number;
};

export async function importAesGcmChatKeyV2(raw32: ArrayBuffer): Promise<CryptoKey> {
  return crypto.subtle.importKey(
    'raw',
    raw32 as BufferSource,
    { name: 'AES-GCM' },
    false,
    ['encrypt', 'decrypt']
  );
}

export async function encryptUtf8WithAesGcmV2(
  chatKey: CryptoKey,
  plaintext: string,
  aadCtx: V2MessageAadContext
): Promise<{ ivB64: string; ciphertextB64: string }> {
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const data = new TextEncoder().encode(plaintext);
  const aad = buildAad([
    'msg/v2',
    aadCtx.conversationId,
    aadCtx.messageId,
    aadCtx.epoch,
  ]);
  const ct = await crypto.subtle.encrypt(
    {
      name: 'AES-GCM',
      iv: iv as BufferSource,
      additionalData: aad as BufferSource,
      tagLength: GCM_TAG_BITS,
    },
    chatKey,
    data as BufferSource
  );
  return { ivB64: toBase64(iv), ciphertextB64: toBase64(new Uint8Array(ct)) };
}

export async function decryptUtf8WithAesGcmV2(
  chatKey: CryptoKey,
  ivB64: string,
  ciphertextB64: string,
  aadCtx: V2MessageAadContext
): Promise<string> {
  const aad = buildAad([
    'msg/v2',
    aadCtx.conversationId,
    aadCtx.messageId,
    aadCtx.epoch,
  ]);
  const pt = await crypto.subtle.decrypt(
    {
      name: 'AES-GCM',
      iv: fromBase64(ivB64) as BufferSource,
      additionalData: aad as BufferSource,
      tagLength: GCM_TAG_BITS,
    },
    chatKey,
    fromBase64(ciphertextB64) as BufferSource
  );
  return new TextDecoder().decode(pt);
}

/**
 * Генерация свежего 32-байтного chat-key, используется при создании эпохи.
 * Не путать с v1 — формат совпадает, отдельно экспортируем для ясности вызовов.
 */
export function randomChatKeyRawV2(): ArrayBuffer {
  const u = new Uint8Array(32);
  crypto.getRandomValues(u);
  return u8ToArrayBuffer(u);
}

export { buildAad as _buildAadForTesting };
export { hkdfSha256 as _hkdfSha256ForTesting };
// AES_BITS/GCM_TAG_BITS экспортируем ниже — полезно для тестов, которые
// сверяют константы с Dart-реализацией.
export const AES_KEY_BITS_V2 = AES_BITS;
export const GCM_TAG_BITS_V2 = GCM_TAG_BITS;
export const HKDF_SALT_EMPTY_V2 = HKDF_SALT_EMPTY;
