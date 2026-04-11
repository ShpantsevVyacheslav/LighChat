import { fromBase64, toBase64 } from '@/lib/e2ee/b64';

/** Копия в «чистый» ArrayBuffer (избегаем SharedArrayBuffer в типах TS). */
function uint8ToArrayBuffer(u: Uint8Array): ArrayBuffer {
  const c = new Uint8Array(u.byteLength);
  c.set(u);
  return c.buffer;
}

const ECDH_CURVE = 'P-256' as const;
const AES_BITS = 256;
const GCM_TAG_BITS = 128;

export async function generateEcdhKeyPair(): Promise<CryptoKeyPair> {
  return crypto.subtle.generateKey({ name: 'ECDH', namedCurve: ECDH_CURVE }, true, ['deriveKey']);
}

export async function exportSpkiPublic(key: CryptoKey): Promise<Uint8Array> {
  const buf = await crypto.subtle.exportKey('spki', key);
  return new Uint8Array(buf);
}

export async function exportPkcs8Private(key: CryptoKey): Promise<Uint8Array> {
  const buf = await crypto.subtle.exportKey('pkcs8', key);
  return new Uint8Array(buf);
}

export async function importEcdhPublicFromSpki(spki: ArrayBuffer | Uint8Array): Promise<CryptoKey> {
  const u8 = spki instanceof Uint8Array ? spki : new Uint8Array(spki);
  const buf = uint8ToArrayBuffer(u8);
  return crypto.subtle.importKey('spki', buf, { name: 'ECDH', namedCurve: ECDH_CURVE }, false, []);
}

export async function importEcdhPrivateFromPkcs8(pkcs8: ArrayBuffer | Uint8Array): Promise<CryptoKey> {
  const u8 = pkcs8 instanceof Uint8Array ? pkcs8 : new Uint8Array(pkcs8);
  const buf = uint8ToArrayBuffer(u8);
  return crypto.subtle.importKey('pkcs8', buf, { name: 'ECDH', namedCurve: ECDH_CURVE }, false, ['deriveKey']);
}

/** Обёртка 32-байтного ключа чата для получателя (ephemeral отправителя). */
export async function wrapRawChatKeyForRecipient(
  chatKey32: ArrayBuffer,
  recipientPublicSpki: ArrayBuffer
): Promise<{ ephPub: string; iv: string; ct: string }> {
  const ephemeral = await crypto.subtle.generateKey({ name: 'ECDH', namedCurve: ECDH_CURVE }, true, ['deriveKey']);
  const recipientPub = await importEcdhPublicFromSpki(recipientPublicSpki);
  const wrapKey = await crypto.subtle.deriveKey(
    { name: 'ECDH', public: recipientPub },
    ephemeral.privateKey,
    { name: 'AES-GCM', length: AES_BITS },
    false,
    ['encrypt']
  );
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const ct = await crypto.subtle.encrypt(
    { name: 'AES-GCM', iv: iv as BufferSource, tagLength: GCM_TAG_BITS },
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

export async function unwrapRawChatKeyWithRecipientPrivateKey(
  wrap: { ephPub: string; iv: string; ct: string },
  recipientPrivateKey: CryptoKey
): Promise<ArrayBuffer> {
  const ephPub = await importEcdhPublicFromSpki(fromBase64(wrap.ephPub));
  const unwrapKey = await crypto.subtle.deriveKey(
    { name: 'ECDH', public: ephPub },
    recipientPrivateKey,
    { name: 'AES-GCM', length: AES_BITS },
    false,
    ['decrypt']
  );
  return crypto.subtle.decrypt(
    { name: 'AES-GCM', iv: fromBase64(wrap.iv) as BufferSource, tagLength: GCM_TAG_BITS },
    unwrapKey,
    fromBase64(wrap.ct) as BufferSource
  );
}

export async function unwrapRawChatKey(
  wrap: { ephPub: string; iv: string; ct: string },
  recipientPrivatePkcs8: ArrayBuffer | Uint8Array
): Promise<ArrayBuffer> {
  const ephPub = await importEcdhPublicFromSpki(fromBase64(wrap.ephPub));
  const pk8u8 =
    recipientPrivatePkcs8 instanceof Uint8Array
      ? recipientPrivatePkcs8
      : new Uint8Array(recipientPrivatePkcs8);
  const recipientPriv = await importEcdhPrivateFromPkcs8(pk8u8);
  const unwrapKey = await crypto.subtle.deriveKey(
    { name: 'ECDH', public: ephPub },
    recipientPriv,
    { name: 'AES-GCM', length: AES_BITS },
    false,
    ['decrypt']
  );
  return crypto.subtle.decrypt(
    { name: 'AES-GCM', iv: fromBase64(wrap.iv) as BufferSource, tagLength: GCM_TAG_BITS },
    unwrapKey,
    fromBase64(wrap.ct) as BufferSource
  );
}

export async function importAesGcmKeyFromRaw(raw32: ArrayBuffer): Promise<CryptoKey> {
  return crypto.subtle.importKey('raw', raw32 as BufferSource, { name: 'AES-GCM' }, false, ['encrypt', 'decrypt']);
}

export async function encryptUtf8WithAesGcm(key: CryptoKey, plaintext: string): Promise<{ iv: string; ciphertext: string }> {
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const data = new TextEncoder().encode(plaintext);
  const ct = await crypto.subtle.encrypt(
    { name: 'AES-GCM', iv: iv as BufferSource, tagLength: GCM_TAG_BITS },
    key,
    data as BufferSource
  );
  return { iv: toBase64(iv), ciphertext: toBase64(new Uint8Array(ct)) };
}

export async function decryptUtf8WithAesGcm(key: CryptoKey, ivB64: string, ciphertextB64: string): Promise<string> {
  const pt = await crypto.subtle.decrypt(
    { name: 'AES-GCM', iv: fromBase64(ivB64) as BufferSource, tagLength: GCM_TAG_BITS },
    key,
    fromBase64(ciphertextB64) as BufferSource
  );
  return new TextDecoder().decode(pt);
}

export function randomChatKeyRaw(): ArrayBuffer {
  const u = new Uint8Array(32);
  crypto.getRandomValues(u);
  return uint8ToArrayBuffer(u);
}
