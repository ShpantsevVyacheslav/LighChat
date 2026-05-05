'use client';

/**
 * v2 device identity layer. Отличия от v1 (`src/lib/e2ee/device-identity.ts`):
 *  - У пользователя может быть несколько активных устройств, каждое со своим
 *    ECDH P-256 ключом. Приватник по-прежнему лежит в IndexedDB **только**
 *    на этом устройстве; публичник публикуется в
 *    `users/{uid}/e2eeDevices/{deviceId}`.
 *  - Идентификатор устройства стабилен в рамках IndexedDB (не привязан к
 *    Firestore), поэтому после logout/login мы переиспользуем тот же deviceId.
 *    Это важно, чтобы ключ чата, обёрнутый под этот deviceId, оставался
 *    расшифровываемым.
 *
 * Совместимость с v1: если в IndexedDB уже есть v1-identity (`store=identity`,
 * `key=p256`), мы его переиспользуем как «первое v2 устройство» с сохранением
 * ключа. Это обеспечивает бесшовную миграцию для одно-девайсных пользователей.
 */

import {
  doc,
  getDoc,
  getDocs,
  collection,
  setDoc,
  serverTimestamp,
  updateDoc,
  type Firestore,
} from 'firebase/firestore';
import { getApp } from 'firebase/app';
import { getFunctions, httpsCallable } from 'firebase/functions';
import type { E2eeDeviceDocV2 } from '@/lib/types';
import {
  exportPkcs8Private,
  exportSpkiPublic,
  generateEcdhKeyPair,
  importEcdhPrivateFromPkcs8,
} from '@/lib/e2ee/webcrypto';
import { fromBase64, toBase64 } from '@/lib/e2ee/b64';

const DB_NAME = 'lighchat-e2ee';
const STORE_V2 = 'identity-v2';
const STORE_V1 = 'identity';
const V1_KEY_ID = 'p256';

type StoredIdentityV2 = {
  deviceId: string;
  privateKeyPkcs8B64: string;
  publicKeySpkiB64: string;
  createdAt: string;
};

type StoredIdentityV1 = {
  privateKeyPkcs8B64: string;
  publicKeySpkiB64: string;
  createdAt: string;
};

function ulid(): string {
  // Лёгкий ULID на основе crypto.getRandomValues: достаточно для deviceId,
  // не пытается выдержать межпроцессную монотонность (нам она не нужна).
  const time = Date.now().toString(36).toUpperCase().padStart(10, '0');
  const bytes = new Uint8Array(10);
  crypto.getRandomValues(bytes);
  const rand = Array.from(bytes, (b) => (b % 32).toString(32).toUpperCase()).join('');
  return `${time}${rand}`;
}

function openDb(): Promise<IDBDatabase> {
  return new Promise((resolve, reject) => {
    // bump версии до 2, чтобы создать STORE_V2. V1 store остаётся нетронутым.
    const req = indexedDB.open(DB_NAME, 2);
    req.onerror = () => reject(req.error);
    req.onsuccess = () => resolve(req.result);
    req.onupgradeneeded = () => {
      const db = req.result;
      if (!db.objectStoreNames.contains(STORE_V1)) db.createObjectStore(STORE_V1);
      if (!db.objectStoreNames.contains(STORE_V2)) db.createObjectStore(STORE_V2);
    };
  });
}

async function idbGetV2(): Promise<StoredIdentityV2 | null> {
  const db = await openDb();
  return new Promise((resolve, reject) => {
    const tx = db.transaction(STORE_V2, 'readonly');
    const req = tx.objectStore(STORE_V2).get('default');
    req.onsuccess = () => resolve((req.result as StoredIdentityV2) ?? null);
    req.onerror = () => reject(req.error);
  });
}

async function idbPutV2(value: StoredIdentityV2): Promise<void> {
  const db = await openDb();
  return new Promise((resolve, reject) => {
    const tx = db.transaction(STORE_V2, 'readwrite');
    tx.objectStore(STORE_V2).put(value, 'default');
    tx.oncomplete = () => resolve();
    tx.onerror = () => reject(tx.error);
  });
}

async function idbGetV1(): Promise<StoredIdentityV1 | null> {
  const db = await openDb();
  return new Promise((resolve, reject) => {
    const tx = db.transaction(STORE_V1, 'readonly');
    const req = tx.objectStore(STORE_V1).get(V1_KEY_ID);
    req.onsuccess = () => resolve((req.result as StoredIdentityV1) ?? null);
    req.onerror = () => reject(req.error);
  });
}

function detectPlatform(): E2eeDeviceDocV2['platform'] {
  // web клиент использует WebCrypto; native wrapper поставит свой фикс.
  if (typeof navigator !== 'undefined' && /(iPhone|iPad|iOS)/i.test(navigator.userAgent)) {
    return 'ios';
  }
  if (typeof navigator !== 'undefined' && /Android/i.test(navigator.userAgent)) {
    return 'android';
  }
  return 'web';
}

function defaultLabel(platform: E2eeDeviceDocV2['platform']): string {
  const ua = typeof navigator !== 'undefined' ? navigator.userAgent : 'Unknown';
  const short = ua.split(' ').slice(-2).join(' ');
  return `${platform}-web/${short}`;
}

export type DeviceIdentityV2 = {
  deviceId: string;
  privateKey: CryptoKey;
  publicKeySpkiB64: string;
};

/**
 * Загружает v2 identity с IndexedDB, создавая его при первом запуске.
 * Если v1 ключ уже существует, переиспользуем его как «первое устройство v2»,
 * чтобы не сломать чтение старых сообщений.
 */
export async function getOrCreateDeviceIdentityV2(): Promise<DeviceIdentityV2> {
  const existingV2 = await idbGetV2();
  if (existingV2) {
    const privateKey = await importEcdhPrivateFromPkcs8(
      fromBase64(existingV2.privateKeyPkcs8B64)
    );
    return {
      deviceId: existingV2.deviceId,
      privateKey,
      publicKeySpkiB64: existingV2.publicKeySpkiB64,
    };
  }

  const v1 = await idbGetV1();
  if (v1) {
    const deviceId = ulid();
    await idbPutV2({
      deviceId,
      privateKeyPkcs8B64: v1.privateKeyPkcs8B64,
      publicKeySpkiB64: v1.publicKeySpkiB64,
      createdAt: v1.createdAt,
    });
    const privateKey = await importEcdhPrivateFromPkcs8(fromBase64(v1.privateKeyPkcs8B64));
    return { deviceId, privateKey, publicKeySpkiB64: v1.publicKeySpkiB64 };
  }

  // Свежий ключ.
  const pair = await generateEcdhKeyPair();
  const privB64 = toBase64(new Uint8Array(await exportPkcs8Private(pair.privateKey)));
  const pubB64 = toBase64(new Uint8Array(await exportSpkiPublic(pair.publicKey)));
  const deviceId = ulid();
  await idbPutV2({
    deviceId,
    privateKeyPkcs8B64: privB64,
    publicKeySpkiB64: pubB64,
    createdAt: new Date().toISOString(),
  });
  return { deviceId, privateKey: pair.privateKey, publicKeySpkiB64: pubB64 };
}

/**
 * Phase 6: возвращает сырой PKCS#8 приватника из IndexedDB. Нужно для
 * создания password-backup'a: хранимый в памяти `CryptoKey` импортирован как
 * non-extractable, поэтому `crypto.subtle.exportKey('pkcs8', key)` на нём
 * падает. Читаем напрямую из IDB, где лежит сохранённая изначально связка.
 *
 * Возвращает `null`, если identity ещё не создавалась (вызывающий должен
 * сначала вызвать `getOrCreateDeviceIdentityV2`).
 */
export async function readStoredIdentityPkcs8V2(): Promise<Uint8Array | null> {
  const stored = await idbGetV2();
  if (!stored) return null;
  return fromBase64(stored.privateKeyPkcs8B64);
}

/**
 * Phase 6: перезаписывает identity в IndexedDB из восстановленного backup/pair.
 * После вызова `getOrCreateDeviceIdentityV2` вернёт этот deviceId.
 *
 * Публичник вычисляется из приватника (импортом PKCS#8 через WebCrypto), чтобы
 * избежать рассогласованного состояния. Если приватник «кривой», функция
 * бросит исключение — storage останется прежним (idempotent fail).
 */
export async function replaceIdentityFromBackupV2(params: {
  deviceId: string;
  privateKeyPkcs8: Uint8Array;
  publicKeySpkiB64: string;
}): Promise<DeviceIdentityV2> {
  const priv = await importEcdhPrivateFromPkcs8(params.privateKeyPkcs8.buffer as ArrayBuffer);
  const pkcs8B64 = toBase64(params.privateKeyPkcs8);
  await idbPutV2({
    deviceId: params.deviceId,
    privateKeyPkcs8B64: pkcs8B64,
    publicKeySpkiB64: params.publicKeySpkiB64,
    createdAt: new Date().toISOString(),
  });
  return {
    deviceId: params.deviceId,
    privateKey: priv,
    publicKeySpkiB64: params.publicKeySpkiB64,
  };
}

/**
 * Публикует / обновляет `e2eeDevices/{deviceId}` документ. Повторные вызовы
 * безопасны: обновляется только `lastSeenAt`, остальные поля не перезаписываются
 * (merge: true).
 */
export async function publishE2eeDeviceV2(
  firestore: Firestore,
  userId: string,
  identity: DeviceIdentityV2,
  label?: string
): Promise<void> {
  const platform = detectPlatform();
  const docRef = doc(firestore, 'users', userId, 'e2eeDevices', identity.deviceId);
  const existing = await getDoc(docRef);
  const now = new Date().toISOString();
  if (!existing.exists()) {
    const payload: E2eeDeviceDocV2 = {
      deviceId: identity.deviceId,
      publicKeySpki: identity.publicKeySpkiB64,
      platform,
      label: label ?? defaultLabel(platform),
      createdAt: now,
      lastSeenAt: now,
      keyBundleVersion: 1,
    };
    await setDoc(docRef, payload);
    void refreshDeviceLastLocation(identity.deviceId);
    return;
  }
  await updateDoc(docRef, { lastSeenAt: now });
  void refreshDeviceLastLocation(identity.deviceId);
}

/**
 * Best-effort обновление `lastLoginAt`/`lastLoginCity`/`lastLoginCountry`/`lastLoginIp`
 * через Cloud Function. Сервер сам берёт IP/гео из своих заголовков, клиент
 * только дёргает callable. Локальный throttle 30 минут — чтобы не дёргать
 * функцию на каждый рендер страницы; серверный throttle тоже 30 минут.
 *
 * Ошибки и таймауты молча игнорируются: локация — украшение, не блокер.
 */
const LAST_LOC_LS_KEY = 'e2ee:lastLocationCallAt';
const LAST_LOC_THROTTLE_MS = 30 * 60 * 1000;

async function refreshDeviceLastLocation(deviceId: string): Promise<void> {
  if (typeof window === 'undefined') return;
  try {
    const prev = window.localStorage.getItem(LAST_LOC_LS_KEY);
    const prevMs = prev ? Number.parseInt(prev, 10) : 0;
    if (Number.isFinite(prevMs) && Date.now() - prevMs < LAST_LOC_THROTTLE_MS) {
      return;
    }
    const fn = httpsCallable(getFunctions(getApp(), 'us-central1'), 'updateDeviceLastLocation');
    await fn({ deviceId });
    window.localStorage.setItem(LAST_LOC_LS_KEY, String(Date.now()));
  } catch {
    // best-effort, не падаем
  }
}

/**
 * Возвращает все активные (не revoked) устройства пользователя. Нужно отправителю
 * при генерации новой эпохи: под каждое активное устройство получателя создаётся
 * отдельная обёртка chat-key.
 */
export async function listActiveE2eeDevicesV2(
  firestore: Firestore,
  userId: string
): Promise<E2eeDeviceDocV2[]> {
  const snap = await getDocs(collection(firestore, 'users', userId, 'e2eeDevices'));
  const out: E2eeDeviceDocV2[] = [];
  for (const d of snap.docs) {
    const data = d.data() as E2eeDeviceDocV2;
    if (data.revoked === true) continue;
    if (!data.publicKeySpki) continue;
    out.push(data);
  }
  return out;
}

/**
 * Возвращает все устройства (включая revoked). Нужно Management-UI,
 * чтобы показать историю и позволить повторно активировать / удалить.
 */
export async function listAllE2eeDevicesV2(
  firestore: Firestore,
  userId: string
): Promise<E2eeDeviceDocV2[]> {
  const snap = await getDocs(collection(firestore, 'users', userId, 'e2eeDevices'));
  return snap.docs.map((d) => d.data() as E2eeDeviceDocV2);
}

/**
 * Помечает устройство как revoked. Вызывается с того же или другого устройства
 * владельца. После revoke `listActiveE2eeDevicesV2` больше его не вернёт, и
 * следующая ротация эпохи исключит его из wraps. До ротации устройство может
 * расшифровывать старые сообщения (это свойство, а не баг: revoke ≠ уничтожение
 * приватника).
 */
export async function revokeE2eeDeviceV2(
  firestore: Firestore,
  userId: string,
  deviceId: string,
  revokedByDeviceId: string
): Promise<void> {
  await updateDoc(doc(firestore, 'users', userId, 'e2eeDevices', deviceId), {
    revoked: true,
    revokedAt: new Date().toISOString(),
    revokedByDeviceId,
    // serverTimestamp не нужен — clients сравнивают ISO строки.
  });
  // Мелкий side-effect: обновим lastSeenAt у revoker-device, чтобы было видно активность в списке.
  void serverTimestamp;
}

/**
 * SHA-256 отпечатка всех активных публичников пользователя. Отображается в UI
 * безопасности чата; собеседники могут сверить отпечатки.
 */
export async function computeUserFingerprintV2(devices: E2eeDeviceDocV2[]): Promise<string> {
  const sorted = [...devices]
    .filter((d) => !d.revoked)
    .sort((a, b) => a.deviceId.localeCompare(b.deviceId))
    .map((d) => `${d.deviceId}:${d.publicKeySpki}`)
    .join('|');
  const bytes = new TextEncoder().encode(sorted);
  const hash = await crypto.subtle.digest('SHA-256', bytes as BufferSource);
  const u8 = new Uint8Array(hash);
  return Array.from(u8, (b) => b.toString(16).padStart(2, '0')).join('');
}
