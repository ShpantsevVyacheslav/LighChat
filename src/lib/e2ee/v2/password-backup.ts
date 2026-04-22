'use client';

/**
 * Password-based backup приватного E2EE-ключа (web).
 *
 * Зачем:
 *  - Если пользователь потерял все устройства или не успел их спарить по QR,
 *    нужно уметь восстановить приватник по паролю. Это второй recovery-путь
 *    параллельно с QR pairing (см. `pairing-qr.ts`).
 *
 * Протокол (совместим с RFC §5.2, §8.2):
 *  1. Пользователь задаёт пароль.
 *  2. Генерируем 16 байт salt + 12 байт IV (WebCrypto).
 *  3. `kdfKey = KDF(password, salt)` — 32 байта для AES-256.
 *  4. `wrappedPrivateKey = AES-GCM(kdfKey, privateKeyPkcs8, iv, aad)`, где
 *     AAD = `userId:backupId` — предотвращает copy-paste между аккаунтами.
 *  5. Записываем `users/{uid}/e2eeBackups/{backupId}` в формате `E2eeBackupDocV2`.
 *     `backupId` = `deviceId` текущего устройства.
 *
 * KDF:
 *  - Целевой Argon2id (memory-hard) требует WASM-пакет, который ещё не
 *    установлен. Поэтому по умолчанию используем **PBKDF2-SHA256 / 600 000
 *    итераций** — встроено в `crypto.subtle`, OWASP-2023 рекомендация.
 *    Когда Argon2id-зависимость будет добавлена, код выберет его автоматически
 *    (см. `createBackupV2` опция `kdf`).
 *  - В документе явно хранится `kdf.algorithm`, поэтому при переходе со временем
 *    старые PBKDF2-бэкапы продолжают работать без миграции.
 *
 * Модуль self-contained: ни один другой файл E2EE не зависит от него, поэтому
 * если функции recovery ещё не включены в UI, это не влияет на send/receive.
 */

import {
  collection,
  doc,
  getDoc,
  getDocs,
  setDoc,
  type Firestore,
} from 'firebase/firestore';
import type { E2eeBackupDocV2, E2eeBackupKdfParams } from '@/lib/types';
import { fromBase64, toBase64 } from '@/lib/e2ee/b64';

/** Минимальная длина пароля. Совпадает с web UI валидацией в ChatPrivacyScreen. */
export const E2EE_BACKUP_MIN_PASSWORD_LENGTH = 10;

/** Дефолтные KDF-параметры для PBKDF2 fallback'а. */
const PBKDF2_DEFAULT_ITERATIONS = 600_000;
const SALT_BYTES = 16;
const IV_BYTES = 12;

/**
 * Дефолтные параметры Argon2id (Phase 9 gap #6). Цифры из OWASP-2024:
 *  - 64 MiB памяти (разумно даже для mid-range устройств),
 *  - 3 итерации,
 *  - параллелизм 1 (браузерный WASM однопоточный).
 * Этого достаточно, чтобы GPU-атака была дорогой, а UI не фризился >~1 сек на
 * мобилке с Safari.
 */
const ARGON2_DEFAULT_MEM_KIB = 64 * 1024;
const ARGON2_DEFAULT_ITERATIONS = 3;
const ARGON2_DEFAULT_PARALLELISM = 1;

/**
 * Какой KDF использовать для *новых* backups. `'auto'` — пробуем argon2id
 * через `hash-wasm`, при недоступности падаем на PBKDF2. Существующие backups
 * читаются по полю `kdf.algorithm` в их собственном документе, поэтому смена
 * этого дефолта **не ломает** ранее созданные PBKDF2-бэкапы.
 */
export type BackupKdfPreference = 'auto' | 'argon2id' | 'pbkdf2-sha256';

export type CreateBackupOptions = {
  firestore: Firestore;
  userId: string;
  /** Идентификатор бэкапа; обычно равен deviceId текущего устройства. */
  backupId: string;
  password: string;
  /** PKCS#8 представление приватника — то же, что лежит в IndexedDB. */
  privateKeyPkcs8: Uint8Array;
  /**
   * Человекочитаемые метки устройств, с которых backup можно восстановить.
   * Это pure metadata для UI, не влияет на криптографию.
   */
  allowedDeviceLabels?: string[];
  /** Переопределение KDF-параметров (например, для теста). */
  kdf?: E2eeBackupKdfParams;
  /**
   * Предпочтение KDF-алгоритма, если `kdf` не задан явно. По умолчанию
   * `'auto'` — argon2id через `hash-wasm`, при недоступности — PBKDF2.
   */
  kdfPreference?: BackupKdfPreference;
};

export type RestoreBackupOptions = {
  firestore: Firestore;
  userId: string;
  password: string;
};

export type RestoredBackup = {
  backupId: string;
  privateKeyPkcs8: Uint8Array;
  createdAt: string;
};

function randomBytes(n: number): Uint8Array {
  const out = new Uint8Array(n);
  crypto.getRandomValues(out);
  return out;
}

/** AAD для AEAD: привязывает шифртекст к владельцу и конкретному backupId. */
function buildAad(userId: string, backupId: string): Uint8Array {
  return new TextEncoder().encode(`lighchat/v2/backup|${userId}|${backupId}`);
}

/**
 * Выводит 32-байтный ключ AES-256 из пароля по выбранному KDF. Возвращает
 * сырые байты, ещё не импортированные в CryptoKey — так проще писать unit-тесты
 * (хотя раунд-трип в этом модуле всё делает через `crypto.subtle`).
 */
async function deriveKdfKey(password: string, params: E2eeBackupKdfParams): Promise<Uint8Array> {
  if (params.algorithm === 'pbkdf2-sha256') {
    const salt = fromBase64(params.saltB64);
    const baseKey = await crypto.subtle.importKey(
      'raw',
      new TextEncoder().encode(password) as BufferSource,
      'PBKDF2',
      false,
      ['deriveBits']
    );
    const bits = await crypto.subtle.deriveBits(
      {
        name: 'PBKDF2',
        salt: (salt.buffer.slice(salt.byteOffset, salt.byteOffset + salt.byteLength)) as ArrayBuffer,
        iterations: params.iterations,
        hash: 'SHA-256',
      },
      baseKey,
      256
    );
    return new Uint8Array(bits);
  }
  // Argon2id через `hash-wasm`. Импортируем лениво — только когда KDF реально
  // задан как argon2id в документе (т.е. существующие PBKDF2-бэкапы не тащат
  // WASM-модуль в бандл).
  const { argon2id } = await import('hash-wasm');
  const salt = fromBase64(params.saltB64);
  const hex = await argon2id({
    password,
    salt,
    parallelism: params.parallelism,
    iterations: params.iterations,
    memorySize: params.memKiB,
    hashLength: 32,
    outputType: 'hex',
  });
  // Конвертируем hex → bytes.
  const out = new Uint8Array(32);
  for (let i = 0; i < 32; i++) {
    out[i] = parseInt(hex.substr(i * 2, 2), 16);
  }
  return out;
}

/**
 * Проверяет, доступен ли Argon2id (WASM). Динамический import, чтобы не падать
 * в окружениях без WASM (старые браузеры, SSR).
 */
async function isArgon2idAvailable(): Promise<boolean> {
  try {
    const { argon2id } = await import('hash-wasm');
    return typeof argon2id === 'function';
  } catch {
    return false;
  }
}

/** Генерирует дефолтные параметры KDF для нового бэкапа. */
async function defaultKdfParams(
  preference: BackupKdfPreference
): Promise<E2eeBackupKdfParams> {
  const wantsArgon =
    preference === 'argon2id' ||
    (preference === 'auto' && (await isArgon2idAvailable()));
  if (wantsArgon) {
    return {
      algorithm: 'argon2id',
      memKiB: ARGON2_DEFAULT_MEM_KIB,
      iterations: ARGON2_DEFAULT_ITERATIONS,
      parallelism: ARGON2_DEFAULT_PARALLELISM,
      saltB64: toBase64(randomBytes(SALT_BYTES)),
    };
  }
  return {
    algorithm: 'pbkdf2-sha256',
    iterations: PBKDF2_DEFAULT_ITERATIONS,
    saltB64: toBase64(randomBytes(SALT_BYTES)),
  };
}

/** Шифрует приватник паролем и пишет backup-документ в Firestore. */
export async function createPasswordBackupV2(opts: CreateBackupOptions): Promise<E2eeBackupDocV2> {
  if (opts.password.length < E2EE_BACKUP_MIN_PASSWORD_LENGTH) {
    throw new Error('E2EE_BACKUP_PASSWORD_TOO_SHORT');
  }
  const kdf = opts.kdf ?? (await defaultKdfParams(opts.kdfPreference ?? 'auto'));
  const keyBytes = await deriveKdfKey(opts.password, kdf);
  const aesKey = await crypto.subtle.importKey(
    'raw',
    (keyBytes.buffer.slice(keyBytes.byteOffset, keyBytes.byteOffset + keyBytes.byteLength)) as ArrayBuffer,
    { name: 'AES-GCM', length: 256 },
    false,
    ['encrypt', 'decrypt']
  );
  const iv = randomBytes(IV_BYTES);
  const aad = buildAad(opts.userId, opts.backupId);
  const ct = await crypto.subtle.encrypt(
    {
      name: 'AES-GCM',
      iv: (iv.buffer.slice(iv.byteOffset, iv.byteOffset + iv.byteLength)) as ArrayBuffer,
      additionalData: (aad.buffer.slice(aad.byteOffset, aad.byteOffset + aad.byteLength)) as ArrayBuffer,
    },
    aesKey,
    (opts.privateKeyPkcs8.buffer.slice(
      opts.privateKeyPkcs8.byteOffset,
      opts.privateKeyPkcs8.byteOffset + opts.privateKeyPkcs8.byteLength
    )) as ArrayBuffer
  );

  const payload: E2eeBackupDocV2 = {
    backupId: opts.backupId,
    backupVersion: 1,
    createdAt: new Date().toISOString(),
    kdf,
    aead: {
      algorithm: 'AES-GCM',
      ivB64: toBase64(iv),
      ciphertextB64: toBase64(new Uint8Array(ct)),
    },
    allowedDeviceLabels: opts.allowedDeviceLabels,
  };
  await setDoc(
    doc(opts.firestore, 'users', opts.userId, 'e2eeBackups', opts.backupId),
    payload
  );
  return payload;
}

/**
 * Пытается расшифровать любой из backups пользователя данным паролем.
 * Возвращает первый успешный; если ни один не подошёл — бросает
 * `E2EE_BACKUP_WRONG_PASSWORD`.
 *
 * Проверяет **все** доступные backups, чтобы поддержать кейс: у пользователя
 * два устройства, оба создавали backups под разными паролями; последний
 * созданный backup перезаписывает `{deviceId}` только для того же deviceId.
 */
export async function restorePasswordBackupV2(
  opts: RestoreBackupOptions
): Promise<RestoredBackup> {
  const snap = await getDocs(
    collection(opts.firestore, 'users', opts.userId, 'e2eeBackups')
  );
  if (snap.empty) throw new Error('E2EE_BACKUP_NOT_FOUND');
  let lastError: unknown = null;
  for (const d of snap.docs) {
    const data = d.data() as E2eeBackupDocV2;
    try {
      const keyBytes = await deriveKdfKey(opts.password, data.kdf);
      const aesKey = await crypto.subtle.importKey(
        'raw',
        (keyBytes.buffer.slice(keyBytes.byteOffset, keyBytes.byteOffset + keyBytes.byteLength)) as ArrayBuffer,
        { name: 'AES-GCM', length: 256 },
        false,
        ['encrypt', 'decrypt']
      );
      const iv = fromBase64(data.aead.ivB64);
      const ct = fromBase64(data.aead.ciphertextB64);
      const aad = buildAad(opts.userId, data.backupId);
      const pt = await crypto.subtle.decrypt(
        {
          name: 'AES-GCM',
          iv: (iv.buffer.slice(iv.byteOffset, iv.byteOffset + iv.byteLength)) as ArrayBuffer,
          additionalData: (aad.buffer.slice(aad.byteOffset, aad.byteOffset + aad.byteLength)) as ArrayBuffer,
        },
        aesKey,
        (ct.buffer.slice(ct.byteOffset, ct.byteOffset + ct.byteLength)) as ArrayBuffer
      );
      return {
        backupId: data.backupId,
        privateKeyPkcs8: new Uint8Array(pt),
        createdAt: data.createdAt,
      };
    } catch (e) {
      lastError = e;
      continue;
    }
  }
  // Ни один backup не расшифровался — пароль неверный или документы битые.
  void lastError;
  throw new Error('E2EE_BACKUP_WRONG_PASSWORD');
}

/**
 * Проверяет наличие backup-документа. UI использует перед показом
 * "Восстановить по паролю" — если документов нет, предлагаем QR-pairing.
 */
export async function hasAnyPasswordBackupV2(
  firestore: Firestore,
  userId: string
): Promise<boolean> {
  const snap = await getDocs(collection(firestore, 'users', userId, 'e2eeBackups'));
  return !snap.empty;
}

/** Удобный accessor единичного backup (по его id). */
export async function getPasswordBackupV2(
  firestore: Firestore,
  userId: string,
  backupId: string
): Promise<E2eeBackupDocV2 | null> {
  const snap = await getDoc(doc(firestore, 'users', userId, 'e2eeBackups', backupId));
  if (!snap.exists()) return null;
  return snap.data() as E2eeBackupDocV2;
}
