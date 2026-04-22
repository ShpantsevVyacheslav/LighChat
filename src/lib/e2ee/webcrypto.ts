/**
 * Низкоуровневые WebCrypto-примитивы E2EE (только v2, см. Gap #5 в
 * `docs/arcitecture/04-runtime-flows.md` — legacy v1 удалён).
 *
 * Модуль держит ECDH key-pair management + SPKI/PKCS8 импорт/экспорт;
 * всё остальное (wrap/unwrap, AEAD) лежит в `src/lib/e2ee/v2/webcrypto-v2.ts`.
 */

/** Копия в «чистый» ArrayBuffer (избегаем SharedArrayBuffer в типах TS). */
function uint8ToArrayBuffer(u: Uint8Array): ArrayBuffer {
  const c = new Uint8Array(u.byteLength);
  c.set(u);
  return c.buffer;
}

const ECDH_CURVE = 'P-256' as const;

// v2 протокол использует `crypto.subtle.deriveBits(...)` для ECDH (см.
// `src/lib/e2ee/v2/webcrypto-v2.ts::unwrapChatKeyForDeviceV2`). WebCrypto
// проверяет usages на деривации отдельно от самого `deriveKey`, поэтому
// без `'deriveBits'` получаем `InvalidAccessError: key.usages does not
// permit this operation`. `'deriveKey'` оставлен для симметричного пути
// (HKDF wrap в pairing-qr).
const ECDH_PRIVATE_USAGES: KeyUsage[] = ['deriveKey', 'deriveBits'];

export async function generateEcdhKeyPair(): Promise<CryptoKeyPair> {
  return crypto.subtle.generateKey(
    { name: 'ECDH', namedCurve: ECDH_CURVE },
    true,
    ECDH_PRIVATE_USAGES
  );
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
  return crypto.subtle.importKey(
    'pkcs8',
    buf,
    { name: 'ECDH', namedCurve: ECDH_CURVE },
    false,
    ECDH_PRIVATE_USAGES
  );
}
