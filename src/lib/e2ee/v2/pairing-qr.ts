'use client';

/**
 * QR pairing (device → device) для E2EE v2.
 *
 * Сценарий: пользователь хочет перенести приватник со старого устройства (donor)
 * на новое (initiator). Новое устройство генерирует эфемерный ECDH-ключ и
 * создаёт `users/{uid}/e2eePairingSessions/{sessionId}`; старое сканирует QR,
 * выполняет ECDH со своим одноразовым ключом, шифрует приватник под общий AES
 * и записывает донорскую часть обратно в документ.
 *
 * Почему не peer-to-peer:
 *  - Firestore уже обеспечивает authenticated RPC (правила — только владелец);
 *  - ни web-камера, ни мобильная камера не могут стабильно сделать прямой p2p;
 *  - TTL-очистка документов делается Cloud Function (см.
 *    `functions/src/triggers/scheduled/cleanupE2eePairingSessions.ts`), чтобы
 *    мусор не копился.
 *
 * Защита от MITM:
 *  - 6-значный код — это HMAC-SHA-256 от общего AES-ключа, обрезанный до 6
 *    десятичных цифр. Пользователь сверяет его на обоих экранах. Если код
 *    совпал — ECDH-handshake пришёл от того устройства, которое сейчас в руках
 *    у пользователя, а не от проникшего посередине.
 *
 * Сам модуль не знает ничего про UI (QR-рендер, сканер камеры) — только
 * протокол и Firestore. UI-слой поверх сможет упаковать `buildQrPayload`
 * в QR и распарсить `parseQrPayload` обратно.
 */

import {
  collection,
  doc,
  deleteDoc,
  getDoc,
  onSnapshot,
  setDoc,
  type Firestore,
  type Unsubscribe,
} from 'firebase/firestore';
import type { E2eePairingSessionDocV2 } from '@/lib/types';
import { fromBase64, toBase64 } from '@/lib/e2ee/b64';
import { exportSpkiPublic, generateEcdhKeyPair, importEcdhPublicFromSpki } from '@/lib/e2ee/webcrypto';

/** Версия протокола pairing — дублируется внутрь QR-payload для forward-compat. */
export const E2EE_PAIRING_QR_VERSION = 'v2-pairing-1' as const;

/** Время жизни сессии на клиенте — сервер (Cloud Function) чистит по этому же сроку. */
export const E2EE_PAIRING_TTL_MS = 10 * 60 * 1000;

/** Публичный payload, который помещается в QR. Размер ≈ 170 байт base64-url. */
export type PairingQrPayload = {
  v: typeof E2EE_PAIRING_QR_VERSION;
  uid: string;
  sessionId: string;
  initiatorEphPub: string;
};

function randomSessionId(): string {
  // 12 байт — короче ULID, но достаточно, чтобы не столкнуться. Firestore doc id.
  const bytes = new Uint8Array(12);
  crypto.getRandomValues(bytes);
  return Array.from(bytes, (b) => b.toString(16).padStart(2, '0')).join('');
}

/** Сериализация QR-payload в компактную base64-url строку. */
export function buildQrPayload(payload: PairingQrPayload): string {
  return toBase64(new TextEncoder().encode(JSON.stringify(payload)))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

/** Разбор строки, полученной со сканера. Throws при невалидном формате. */
export function parseQrPayload(raw: string): PairingQrPayload {
  const normalized = raw.replace(/-/g, '+').replace(/_/g, '/');
  const padded = normalized + '='.repeat((4 - (normalized.length % 4)) % 4);
  const decoded = new TextDecoder().decode(fromBase64(padded));
  const parsed = JSON.parse(decoded) as Partial<PairingQrPayload>;
  if (
    parsed.v !== E2EE_PAIRING_QR_VERSION ||
    typeof parsed.uid !== 'string' ||
    typeof parsed.sessionId !== 'string' ||
    typeof parsed.initiatorEphPub !== 'string'
  ) {
    throw new Error('E2EE_PAIRING_INVALID_QR');
  }
  return parsed as PairingQrPayload;
}

/**
 * ECDH P-256 → 32 байта общего ключа. Используется одинаково для derive на donor
 * и initiator стороне. Делаем импорт/деривацию внутри, чтобы вызывающий не
 * таскал CryptoKey.
 */
async function deriveSharedAesRaw(
  myPrivate: CryptoKey,
  peerPublicSpki: Uint8Array
): Promise<Uint8Array> {
  const peer = await importEcdhPublicFromSpki(peerPublicSpki);
  const bits = await crypto.subtle.deriveBits(
    { name: 'ECDH', public: peer } as EcdhKeyDeriveParams,
    myPrivate,
    256
  );
  return new Uint8Array(bits);
}

/** 6-значный код для проверки пары глазами (HMAC(key, "pairing-code") mod 10^6). */
async function shortPairingCode(sharedKey: Uint8Array): Promise<string> {
  const hmacKey = await crypto.subtle.importKey(
    'raw',
    sharedKey.buffer.slice(sharedKey.byteOffset, sharedKey.byteOffset + sharedKey.byteLength) as ArrayBuffer,
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );
  const tag = new Uint8Array(
    await crypto.subtle.sign(
      'HMAC',
      hmacKey,
      new TextEncoder().encode('lighchat/v2/pairing-code') as BufferSource
    )
  );
  // первые 4 байта → uint32 → mod 1_000_000 → 6 цифр
  const n = ((tag[0] << 24) | (tag[1] << 16) | (tag[2] << 8) | tag[3]) >>> 0;
  return (n % 1_000_000).toString().padStart(6, '0');
}

/* -------------------------------------------------------------------------- */
/*                               INITIATOR (new device)                       */
/* -------------------------------------------------------------------------- */

export type InitiatorSession = {
  sessionId: string;
  qrPayload: PairingQrPayload;
  qrEncoded: string;
  /** Эфемерный ECDH-keypair — держим в памяти до завершения или таймаута. */
  ephemeralPrivate: CryptoKey;
  ephemeralPublicSpkiB64: string;
};

/**
 * Вызывается на новом устройстве. Генерирует эфемерный ключ, создаёт документ
 * `pairingSessions/{sessionId}` в состоянии `awaiting_scan`, возвращает QR payload.
 */
export async function initiatePairingSessionV2(
  firestore: Firestore,
  userId: string
): Promise<InitiatorSession> {
  const keyPair = await generateEcdhKeyPair();
  const pubBytes = await exportSpkiPublic(keyPair.publicKey);
  const pubB64 = toBase64(pubBytes);
  const sessionId = randomSessionId();
  const nowIso = new Date().toISOString();
  const expiresIso = new Date(Date.now() + E2EE_PAIRING_TTL_MS).toISOString();
  const doc0: E2eePairingSessionDocV2 = {
    sessionId,
    createdAt: nowIso,
    expiresAt: expiresIso,
    state: 'awaiting_scan',
    initiatorEphPubSpkiB64: pubB64,
  };
  await setDoc(
    doc(firestore, 'users', userId, 'e2eePairingSessions', sessionId),
    doc0
  );
  const qrPayload: PairingQrPayload = {
    v: E2EE_PAIRING_QR_VERSION,
    uid: userId,
    sessionId,
    initiatorEphPub: pubB64,
  };
  return {
    sessionId,
    qrPayload,
    qrEncoded: buildQrPayload(qrPayload),
    ephemeralPrivate: keyPair.privateKey,
    ephemeralPublicSpkiB64: pubB64,
  };
}

/**
 * Подписка на обновления pairing-документа. Возвращает unsubscribe.
 * UI использует, чтобы показать "старое устройство отсканировало QR".
 */
export function watchPairingSessionV2(
  firestore: Firestore,
  userId: string,
  sessionId: string,
  onUpdate: (data: E2eePairingSessionDocV2 | null) => void
): Unsubscribe {
  return onSnapshot(
    doc(firestore, 'users', userId, 'e2eePairingSessions', sessionId),
    (snap) => {
      if (!snap.exists()) {
        onUpdate(null);
        return;
      }
      onUpdate(snap.data() as E2eePairingSessionDocV2);
    }
  );
}

/**
 * Вызывается на initiator после того, как donor прислал свою часть. Выполняет
 * финальный ECDH, расшифровывает payload от donor'а.
 * Возвращает приватник и 6-значный код для сверки пользователем.
 */
export async function consumeDonorPayloadV2(params: {
  firestore: Firestore;
  userId: string;
  sessionId: string;
  initiatorEphemeralPrivate: CryptoKey;
  donorDoc: E2eePairingSessionDocV2;
}): Promise<{ privateKeyPkcs8: Uint8Array; pairingCode: string }> {
  const donor = params.donorDoc.donorPayload;
  if (!donor) {
    throw new Error('E2EE_PAIRING_DONOR_PAYLOAD_MISSING');
  }
  const donorEphPubSpki = fromBase64(donor.donorEphPubSpkiB64);
  const sharedRaw = await deriveSharedAesRaw(params.initiatorEphemeralPrivate, donorEphPubSpki);
  const aesKey = await crypto.subtle.importKey(
    'raw',
    sharedRaw.buffer.slice(
      sharedRaw.byteOffset,
      sharedRaw.byteOffset + sharedRaw.byteLength
    ) as ArrayBuffer,
    { name: 'AES-GCM', length: 256 },
    false,
    ['decrypt']
  );
  const iv = fromBase64(donor.ivB64);
  const ct = fromBase64(donor.ciphertextB64);
  const aad = new TextEncoder().encode(
    `lighchat/v2/pairing|${params.userId}|${params.sessionId}`
  );
  let privateKeyPkcs8: Uint8Array;
  try {
    const pt = await crypto.subtle.decrypt(
      {
        name: 'AES-GCM',
        iv: iv.buffer.slice(iv.byteOffset, iv.byteOffset + iv.byteLength) as ArrayBuffer,
        additionalData: aad.buffer.slice(
          aad.byteOffset,
          aad.byteOffset + aad.byteLength
        ) as ArrayBuffer,
      },
      aesKey,
      ct.buffer.slice(ct.byteOffset, ct.byteOffset + ct.byteLength) as ArrayBuffer
    );
    privateKeyPkcs8 = new Uint8Array(pt);
  } catch {
    throw new Error('E2EE_PAIRING_DECRYPT_FAILED');
  }
  const pairingCode = await shortPairingCode(sharedRaw);

  // Завершаем сессию: меняем state, чтобы donor видел финал. Удалять доверяем
  // Cloud Function / TTL.
  await setDoc(
    doc(params.firestore, 'users', params.userId, 'e2eePairingSessions', params.sessionId),
    { ...params.donorDoc, state: 'completed' },
    { merge: true }
  );
  return { privateKeyPkcs8, pairingCode };
}

/* -------------------------------------------------------------------------- */
/*                                   DONOR                                    */
/* -------------------------------------------------------------------------- */

export type DonorRespondOptions = {
  firestore: Firestore;
  userId: string;
  sessionId: string;
  initiatorEphPubSpkiB64: string;
  privateKeyPkcs8: Uint8Array;
  deviceDraft: E2eePairingSessionDocV2['donorPayload'] extends infer T
    ? T extends { deviceDraft: infer D }
      ? D
      : never
    : never;
};

/**
 * Вызывается на donor-устройстве после сканирования QR. Генерирует эфемерный
 * ключ donor'a, шифрует приватник под общий AES, пишет обратно в документ.
 * Возвращает 6-значный код для показа пользователю на сверку.
 */
export async function donorRespondToPairingV2(
  opts: DonorRespondOptions
): Promise<{ pairingCode: string }> {
  const donorKeyPair = await generateEcdhKeyPair();
  const donorPubBytes = await exportSpkiPublic(donorKeyPair.publicKey);
  const initiatorPub = fromBase64(opts.initiatorEphPubSpkiB64);
  const sharedRaw = await deriveSharedAesRaw(donorKeyPair.privateKey, initiatorPub);
  const aesKey = await crypto.subtle.importKey(
    'raw',
    sharedRaw.buffer.slice(
      sharedRaw.byteOffset,
      sharedRaw.byteOffset + sharedRaw.byteLength
    ) as ArrayBuffer,
    { name: 'AES-GCM', length: 256 },
    false,
    ['encrypt']
  );
  const iv = new Uint8Array(12);
  crypto.getRandomValues(iv);
  const aad = new TextEncoder().encode(
    `lighchat/v2/pairing|${opts.userId}|${opts.sessionId}`
  );
  const ct = new Uint8Array(
    await crypto.subtle.encrypt(
      {
        name: 'AES-GCM',
        iv: iv.buffer.slice(iv.byteOffset, iv.byteOffset + iv.byteLength) as ArrayBuffer,
        additionalData: aad.buffer.slice(
          aad.byteOffset,
          aad.byteOffset + aad.byteLength
        ) as ArrayBuffer,
      },
      aesKey,
      opts.privateKeyPkcs8.buffer.slice(
        opts.privateKeyPkcs8.byteOffset,
        opts.privateKeyPkcs8.byteOffset + opts.privateKeyPkcs8.byteLength
      ) as ArrayBuffer
    )
  );

  const ref = doc(
    opts.firestore,
    'users',
    opts.userId,
    'e2eePairingSessions',
    opts.sessionId
  );
  const snap = await getDoc(ref);
  if (!snap.exists()) {
    throw new Error('E2EE_PAIRING_SESSION_NOT_FOUND');
  }
  const existing = snap.data() as E2eePairingSessionDocV2;
  const donorPayload: E2eePairingSessionDocV2['donorPayload'] = {
    donorEphPubSpkiB64: toBase64(donorPubBytes),
    ivB64: toBase64(iv),
    ciphertextB64: toBase64(ct),
    deviceDraft: opts.deviceDraft,
  };
  await setDoc(
    ref,
    <E2eePairingSessionDocV2>{
      ...existing,
      state: 'awaiting_accept',
      donorPayload,
    },
    { merge: true }
  );
  const pairingCode = await shortPairingCode(sharedRaw);
  return { pairingCode };
}

/**
 * Ручная отмена сессии (пользователь нажал "Отмена" или код не совпал).
 * Помечаем `rejected` и удаляем сразу — TTL не нужен.
 */
export async function rejectPairingSessionV2(
  firestore: Firestore,
  userId: string,
  sessionId: string
): Promise<void> {
  const ref = doc(firestore, 'users', userId, 'e2eePairingSessions', sessionId);
  try {
    const snap = await getDoc(ref);
    if (!snap.exists()) return;
    await setDoc(ref, { ...(snap.data() as E2eePairingSessionDocV2), state: 'rejected' }, { merge: true });
  } finally {
    await deleteDoc(ref).catch(() => {
      /* idempotent */
    });
  }
}

/** Служебный accessor, удобен для unit-тестов. */
export async function listActivePairingSessionsV2(
  firestore: Firestore,
  userId: string
): Promise<E2eePairingSessionDocV2[]> {
  const snap = await import('firebase/firestore').then(({ getDocs }) =>
    getDocs(collection(firestore, 'users', userId, 'e2eePairingSessions'))
  );
  return snap.docs.map((d) => d.data() as E2eePairingSessionDocV2);
}
