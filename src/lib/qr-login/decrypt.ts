'use client';

// SECURITY: web-side decrypt for the customToken delivered through the QR
// login flow. Mirrors functions/src/lib/qr-login-token-crypto.ts (server) —
// any change here MUST be matched there. The construction is the same as our
// E2EE v2 chat-key wrap (ECDH-P256 + HKDF-SHA256 + AES-256-GCM), differing
// only in the HKDF info string ('lighchat/qr-login/v1') and the AAD
// (sessionId).
//
// Why this matters: qrLoginSessions/{sessionId} is intentionally world-
// readable (the listener on the new, not-yet-authenticated device must be
// able to read it). Putting the customToken in plaintext let anyone with the
// session id call signInWithCustomToken on the user's account. With this
// envelope, even a leaked session document is useless without the device's
// private key, which lives in the browser's IndexedDB and never leaves it.

import { fromBase64 } from '@/lib/e2ee/b64';

const HKDF_INFO = 'lighchat/qr-login/v1';
const ALG_LABEL = 'ecdh-p256-hkdf-aesgcm-v1';
const GCM_TAG_BITS = 128;

export type EncryptedCustomToken = {
  alg: string;
  ephPub: string; // SPKI base64
  iv: string;     // 12-byte base64
  ct: string;     // ciphertext || tag base64
};

export class QrTokenDecryptError extends Error {
  readonly code: string;
  constructor(code: string, message?: string) {
    super(message ?? code);
    this.code = code;
    this.name = 'QrTokenDecryptError';
  }
}

async function importEcdhPublic(spki: ArrayBuffer): Promise<CryptoKey> {
  return crypto.subtle.importKey(
    'spki',
    spki as BufferSource,
    { name: 'ECDH', namedCurve: 'P-256' },
    false,
    [],
  );
}

async function hkdfSha256(
  ikm: ArrayBuffer,
  salt: Uint8Array,
  info: string,
  lengthBytes: number,
): Promise<ArrayBuffer> {
  const base = await crypto.subtle.importKey('raw', ikm as BufferSource, 'HKDF', false, [
    'deriveBits',
  ]);
  return crypto.subtle.deriveBits(
    {
      name: 'HKDF',
      hash: 'SHA-256',
      salt: salt as BufferSource,
      info: new TextEncoder().encode(info) as BufferSource,
    },
    base,
    lengthBytes * 8,
  );
}

/**
 * Decrypt the customToken using the device's STATIC ECDH P-256 private key
 * (from getOrCreateDeviceIdentityV2). Throws QrTokenDecryptError on any
 * shape / algorithm / authentication failure — caller should treat it as
 * "session not usable, retry the QR flow".
 */
export async function decryptCustomToken(
  cipher: EncryptedCustomToken,
  recipientPrivateKey: CryptoKey,
  sessionId: string,
): Promise<string> {
  if (!cipher || cipher.alg !== ALG_LABEL) {
    throw new QrTokenDecryptError('BAD_ALG', String(cipher?.alg));
  }
  if (!cipher.ephPub || !cipher.iv || !cipher.ct) {
    throw new QrTokenDecryptError('BAD_FIELDS');
  }
  if (!sessionId || sessionId.length < 16) {
    throw new QrTokenDecryptError('BAD_SESSION');
  }

  const ephPub = await importEcdhPublic(fromBase64(cipher.ephPub).buffer as ArrayBuffer);
  const z = await crypto.subtle.deriveBits(
    { name: 'ECDH', public: ephPub },
    recipientPrivateKey,
    256,
  );
  const salt = new TextEncoder().encode(sessionId);
  const wrapKeyRaw = await hkdfSha256(z, salt, HKDF_INFO, 32);
  const wrapKey = await crypto.subtle.importKey(
    'raw',
    wrapKeyRaw as BufferSource,
    { name: 'AES-GCM' },
    false,
    ['decrypt'],
  );
  const aad = new TextEncoder().encode(sessionId);
  let plain: ArrayBuffer;
  try {
    plain = await crypto.subtle.decrypt(
      {
        name: 'AES-GCM',
        iv: fromBase64(cipher.iv) as BufferSource,
        additionalData: aad as BufferSource,
        tagLength: GCM_TAG_BITS,
      },
      wrapKey,
      fromBase64(cipher.ct) as BufferSource,
    );
  } catch {
    throw new QrTokenDecryptError('AUTH_FAILURE');
  }
  return new TextDecoder().decode(plain);
}
