'use client';

/**
 * v2 session-firestore layer. Читает и пишет `conversations/{cid}/e2eeSessions/{epoch}`
 * в формате `E2eeSessionDocV2` (multi-device wraps).
 *
 * Почему отдельный модуль, а не правка `session-firestore.ts`:
 *  - v1 модуль активно используется legacy-кодом (hooks/use-e2ee-conversation,
 *    enable-conversation); вкладывать в него логику v2 увеличило бы риск
 *    регрессии на v1-клиентах.
 *  - Читатель v2 может обратиться к обоим модулям (см. `protocol-select.ts`).
 */

import { doc, getDoc, setDoc, type Firestore } from 'firebase/firestore';
import type {
  E2eeDeviceDocV2,
  E2eeKeyWrapEntry,
  E2eeSessionDocV2,
} from '@/lib/types';
import { fromBase64 } from '@/lib/e2ee/b64';
import {
  listActiveE2eeDevicesV2,
  publishE2eeDeviceV2,
  type DeviceIdentityV2,
} from '@/lib/e2ee/v2/device-identity-v2';
import {
  importAesGcmChatKeyV2,
  randomChatKeyRawV2,
  unwrapChatKeyForDeviceV2,
  wrapChatKeyForDeviceV2,
} from '@/lib/e2ee/v2/webcrypto-v2';

export const E2EE_V2_WRAP_CONTEXT = 'lighchat/v2/session';
export const E2EE_V2_PROTOCOL = 'v2-p256-aesgcm-multi' as const;

export type ParticipantDeviceBundle = {
  userId: string;
  devices: E2eeDeviceDocV2[];
};

/**
 * Собирает список активных устройств для каждого участника.
 *
 * После Phase 10 cleanup legacy-v1 fallback удалён — если у участника нет
 * ни одного `e2eeDevices/*`, функция бросает `E2EE_NO_DEVICE:{uid}`. UI
 * должен попросить собеседника залогиниться хотя бы раз, чтобы опубликовать
 * v2-ключ.
 */
export async function collectParticipantDevicesV2(
  firestore: Firestore,
  participantIds: string[]
): Promise<ParticipantDeviceBundle[]> {
  const out: ParticipantDeviceBundle[] = [];
  for (const uid of participantIds) {
    const devices = await listActiveE2eeDevicesV2(firestore, uid);
    if (devices.length > 0) {
      out.push({ userId: uid, devices });
      continue;
    }
    throw new Error(`E2EE_NO_DEVICE:${uid}`);
  }
  return out;
}

/**
 * Создаёт новый v2 session-doc с обёртками на каждое устройство каждого участника.
 * Вызывать на событиях: enable E2EE, add member, remove member, revoke device, re-key.
 */
export async function createE2eeSessionDocV2(
  firestore: Firestore,
  conversationId: string,
  epoch: number,
  currentIdentity: DeviceIdentityV2,
  currentUserId: string,
  participantBundles: ParticipantDeviceBundle[]
): Promise<void> {
  const chatKeyRaw = randomChatKeyRawV2();
  const wraps: E2eeSessionDocV2['wraps'] = {};
  const epochId = `${conversationId}:${epoch}`;
  for (const bundle of participantBundles) {
    wraps[bundle.userId] = {};
    for (const dev of bundle.devices) {
      const pubBytes = fromBase64(dev.publicKeySpki);
      const pubCopy = new Uint8Array(pubBytes.length);
      pubCopy.set(pubBytes);
      const wrap = await wrapChatKeyForDeviceV2(
        chatKeyRaw,
        pubCopy.buffer,
        epochId,
        dev.deviceId
      );
      wraps[bundle.userId][dev.deviceId] = wrap;
    }
  }
  const payload: E2eeSessionDocV2 = {
    protocolVersion: E2EE_V2_PROTOCOL,
    epoch,
    createdAt: new Date().toISOString(),
    createdByUserId: currentUserId,
    createdByDeviceId: currentIdentity.deviceId,
    participantIds: participantBundles.map((b) => b.userId),
    wraps,
    wrapContext: E2EE_V2_WRAP_CONTEXT,
  };
  await setDoc(
    doc(firestore, 'conversations', conversationId, 'e2eeSessions', String(epoch)),
    payload
  );
}

/**
 * Загружает session-doc. Возвращает `null`, если документа нет или если
 * `protocolVersion` не поддерживается (legacy v1 или неизвестная версия).
 *
 * Для нераспознанных версий возвращаем `{ version: 'unsupported', raw }`,
 * чтобы вызывающий мог запустить self-heal (перекатить эпоху в v2).
 */
export async function fetchE2eeSessionAny(
  firestore: Firestore,
  conversationId: string,
  epoch: number
): Promise<
  | { version: 'v2'; data: E2eeSessionDocV2 }
  | { version: 'unsupported'; raw: Record<string, unknown> }
  | null
> {
  const snap = await getDoc(
    doc(firestore, 'conversations', conversationId, 'e2eeSessions', String(epoch))
  );
  if (!snap.exists()) return null;
  const raw = snap.data() as Record<string, unknown>;
  if (raw.protocolVersion === E2EE_V2_PROTOCOL) {
    return { version: 'v2', data: raw as E2eeSessionDocV2 };
  }
  return { version: 'unsupported', raw };
}

/**
 * Возвращает расшифрованный ChatKey для текущего `identity`. Если в session-doc
 * нет обёртки под мой `deviceId`, бросаем `E2EE_NO_WRAP_FOR_DEVICE` — UI
 * показывает «восстановите доступ через pairing/backup».
 */
export async function unwrapChatKeyForMeV2(
  session: E2eeSessionDocV2,
  userId: string,
  identity: DeviceIdentityV2,
  conversationId: string
): Promise<CryptoKey> {
  const perUser = session.wraps[userId];
  if (!perUser) {
    throw new Error('E2EE_NO_WRAP_FOR_USER');
  }
  const entry = perUser[identity.deviceId];
  if (!entry) {
    throw new Error('E2EE_NO_WRAP_FOR_DEVICE');
  }
  const raw = await unwrapChatKeyForDeviceV2(
    entry,
    identity.privateKey,
    `${conversationId}:${session.epoch}`,
    identity.deviceId
  );
  return importAesGcmChatKeyV2(raw);
}

/**
 * Phase 7: media-шифрование использует `chatKey` через HKDF как IKM, поэтому
 * нам нужен доступ к **сырым байтам** ключа. `unwrapChatKeyForMeV2` возвращает
 * `CryptoKey` с `extractable=false`; добавляем отдельный путь, который
 * останавливается на шаге после unwrap и не импортирует результат в WebCrypto.
 */
export async function unwrapChatKeyRawForMeV2(
  session: E2eeSessionDocV2,
  userId: string,
  identity: DeviceIdentityV2,
  conversationId: string
): Promise<ArrayBuffer> {
  const perUser = session.wraps[userId];
  if (!perUser) {
    throw new Error('E2EE_NO_WRAP_FOR_USER');
  }
  const entry = perUser[identity.deviceId];
  if (!entry) {
    throw new Error('E2EE_NO_WRAP_FOR_DEVICE');
  }
  return unwrapChatKeyForDeviceV2(
    entry,
    identity.privateKey,
    `${conversationId}:${session.epoch}`,
    identity.deviceId
  );
}

/** Гарантирует публикацию текущего устройства перед созданием новой эпохи. */
export async function ensureDevicePublishedV2(
  firestore: Firestore,
  userId: string,
  identity: DeviceIdentityV2
): Promise<void> {
  await publishE2eeDeviceV2(firestore, userId, identity);
}
