'use client';

import {
  exportPkcs8Private,
  exportSpkiPublic,
  generateEcdhKeyPair,
  importEcdhPrivateFromPkcs8,
} from '@/lib/e2ee/webcrypto';
import { toBase64, fromBase64 } from '@/lib/e2ee/b64';

const DB_NAME = 'lighchat-e2ee';
const STORE = 'identity';
const KEY_ID = 'p256';

type StoredIdentity = {
  privateKeyPkcs8B64: string;
  publicKeySpkiB64: string;
  createdAt: string;
};

function openDb(): Promise<IDBDatabase> {
  return new Promise((resolve, reject) => {
    const req = indexedDB.open(DB_NAME, 1);
    req.onerror = () => reject(req.error);
    req.onsuccess = () => resolve(req.result);
    req.onupgradeneeded = () => {
      req.result.createObjectStore(STORE);
    };
  });
}

async function idbGet(): Promise<StoredIdentity | null> {
  const db = await openDb();
  return new Promise((resolve, reject) => {
    const tx = db.transaction(STORE, 'readonly');
    const req = tx.objectStore(STORE).get(KEY_ID);
    req.onsuccess = () => resolve((req.result as StoredIdentity) ?? null);
    req.onerror = () => reject(req.error);
  });
}

async function idbSet(identity: StoredIdentity): Promise<void> {
  const db = await openDb();
  return new Promise((resolve, reject) => {
    const tx = db.transaction(STORE, 'readwrite');
    tx.objectStore(STORE).put(identity, KEY_ID);
    tx.oncomplete = () => resolve();
    tx.onerror = () => reject(tx.error);
  });
}

/**
 * Загружает или создаёт пару ECDH P-256; приватный ключ только в IndexedDB.
 */
export async function getOrCreateDeviceIdentity(): Promise<{
  privateKey: CryptoKey;
  publicKeySpkiB64: string;
}> {
  const existing = await idbGet();
  if (existing?.privateKeyPkcs8B64 && existing.publicKeySpkiB64) {
    const privateKey = await importEcdhPrivateFromPkcs8(fromBase64(existing.privateKeyPkcs8B64));
    return { privateKey, publicKeySpkiB64: existing.publicKeySpkiB64 };
  }

  const pair = await generateEcdhKeyPair();
  const privB64 = toBase64(new Uint8Array(await exportPkcs8Private(pair.privateKey)));
  const pubB64 = toBase64(new Uint8Array(await exportSpkiPublic(pair.publicKey)));
  await idbSet({
    privateKeyPkcs8B64: privB64,
    publicKeySpkiB64: pubB64,
    createdAt: new Date().toISOString(),
  });
  return { privateKey: pair.privateKey, publicKeySpkiB64: pubB64 };
}
