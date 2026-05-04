'use client';

/**
 * Гибридная передача E2EE-доступа новому устройству при QR-логине.
 *
 * Сценарий: пользователь сканирует QR-логин нового устройства со старого. После
 * того, как `confirmQrLogin` выдал новому Firebase custom token, **на старом
 * устройстве** мы:
 *   1. Публикуем `users/{uid}/e2eeDevices/{newDeviceId}` (новое устройство
 *      сделает то же самое после signIn — но мы хотим иметь его раньше, чтобы
 *      следующая ротация эпохи в любом чате уже включала его в wraps).
 *   2. Перебираем все E2EE-чаты пользователя. Для каждого:
 *        a) В *текущей* эпохе session-doc находим свой wrap (`wraps[me][myDev]`),
 *           распаковываем chatKey, переоборачиваем под новый publicKey и пишем
 *           `wraps[me][newDeviceId]`. Это даёт новому устройству доступ к
 *           истории, зашифрованной под текущей эпохой.
 *        b) Создаём новую эпоху (`epoch+1`) с wraps под все известные устройства
 *           всех участников, **включая новое**. Это и forward secrecy для
 *           будущих сообщений, и явная регистрация нового устройства в чате.
 *           (Используем существующую `createE2eeSessionDocV2`.)
 *
 * Что НЕ делает:
 *   - Не передаёт приватник старого устройства (тот остаётся уникальным per-device).
 *   - Не переписывает старые эпохи целиком. Это даёт быстрое подключение для
 *     активных чатов; если пользователь хочет читать **очень* старую историю —
 *     можно потом расширить функцию на full-rewrap всех эпох.
 *
 * Идемпотентность: повторный запуск пропускает чаты, где `wraps[me][newDeviceId]`
 * уже есть в текущей эпохе. Если что-то упало посередине — пользователь
 * запускает «повторить синхронизацию» и догоняет.
 */

import {
  collection,
  doc,
  getDocs,
  query,
  setDoc,
  updateDoc,
  where,
  type Firestore,
} from 'firebase/firestore';
import type { Conversation, E2eeSessionDocV2 } from '@/lib/types';
import {
  publishE2eeDeviceV2,
  type DeviceIdentityV2,
} from '@/lib/e2ee/v2/device-identity-v2';
import {
  collectParticipantDevicesV2,
  createE2eeSessionDocV2,
  fetchE2eeSessionAny,
} from '@/lib/e2ee/v2/session-firestore-v2';
import {
  unwrapChatKeyForDeviceV2,
  wrapChatKeyForDeviceV2,
} from '@/lib/e2ee/v2/webcrypto-v2';
import { fromBase64 } from '@/lib/e2ee/b64';
import {
  chatSystemEvents,
  postChatSystemEventV2,
} from '@/lib/e2ee/v2/system-events';

export type DeviceHandoverProgress = {
  conversationId: string;
  stage: 'rewrapped' | 'rotated' | 'skipped' | 'failed';
  newEpoch?: number;
  reason?: string;
};

export type DeviceHandoverOptions = {
  signal?: AbortSignal;
  onProgress?: (
    progress: DeviceHandoverProgress,
    done: number,
    total: number
  ) => void;
  /**
   * Если true — после re-wrap текущей эпохи также создаём новую эпоху (epoch+1)
   * с wraps под все известные устройства (включая новое). По умолчанию true:
   * это закрывает forward-secrecy окно, в котором новое устройство добавлено,
   * но эпоха ещё не ротирована.
   */
  rotateEpoch?: boolean;
};

/** Описание нового устройства, которое подключают. */
export type IncomingDeviceInfo = {
  deviceId: string;
  publicKeySpki: string;
  platform: 'web' | 'ios' | 'android';
  label: string;
};

export async function handoverDeviceAccessV2(params: {
  firestore: Firestore;
  userId: string;
  donorIdentity: DeviceIdentityV2;
  newDevice: IncomingDeviceInfo;
  options?: DeviceHandoverOptions;
}): Promise<{
  rewrapped: number;
  rotated: number;
  failed: number;
  results: DeviceHandoverProgress[];
}> {
  const { firestore, userId, donorIdentity, newDevice, options } = params;
  const rotateEpoch = options?.rotateEpoch !== false;

  // 1) Публикуем новое устройство в `e2eeDevices/{newDeviceId}` от имени старого
  //    (правила это позволяют — записывать может только владелец uid). Это
  //    гарантирует, что collectParticipantDevicesV2 ниже увидит новое устройство.
  await setDoc(
    doc(firestore, 'users', userId, 'e2eeDevices', newDevice.deviceId),
    {
      deviceId: newDevice.deviceId,
      publicKeySpki: newDevice.publicKeySpki,
      platform: newDevice.platform,
      label: newDevice.label,
      createdAt: new Date().toISOString(),
      lastSeenAt: new Date().toISOString(),
      keyBundleVersion: 1,
    },
    { merge: true }
  );
  // Также убедимся, что наш собственный device-doc актуален (lastSeenAt бампится).
  await publishE2eeDeviceV2(firestore, userId, donorIdentity);

  const convsSnap = await getDocs(
    query(
      collection(firestore, 'conversations'),
      where('participantIds', 'array-contains', userId)
    )
  );
  const targets: Conversation[] = [];
  for (const snap of convsSnap.docs) {
    const data = snap.data() as Omit<Conversation, 'id'>;
    if (!data.e2eeEnabled) continue;
    targets.push({ ...data, id: snap.id });
  }

  const results: DeviceHandoverProgress[] = [];
  let rewrapped = 0;
  let rotated = 0;
  let failed = 0;

  for (let i = 0; i < targets.length; i += 1) {
    if (options?.signal?.aborted) break;
    const conv = targets[i];
    try {
      const currentEpoch = conv.e2eeKeyEpoch ?? 0;
      // 2.a) Re-wrap chatKey текущей эпохи под новое устройство.
      let didRewrap = false;
      if (currentEpoch > 0) {
        const sess = await fetchE2eeSessionAny(firestore, conv.id, currentEpoch);
        if (sess && sess.version === 'v2') {
          const data = sess.data as E2eeSessionDocV2;
          const myWraps = data.wraps[userId] ?? {};
          if (newDevice.deviceId in myWraps) {
            // Идемпотентно: уже re-wrapped.
          } else if (donorIdentity.deviceId in myWraps) {
            const epochId = `${conv.id}:${data.epoch}`;
            const myEntry = myWraps[donorIdentity.deviceId];
            const chatKeyRaw = await unwrapChatKeyForDeviceV2(
              myEntry,
              donorIdentity.privateKey,
              epochId,
              donorIdentity.deviceId
            );
            const newPubBytes = fromBase64(newDevice.publicKeySpki);
            const newPubCopy = new Uint8Array(newPubBytes.length);
            newPubCopy.set(newPubBytes);
            const newWrap = await wrapChatKeyForDeviceV2(
              chatKeyRaw,
              newPubCopy.buffer,
              epochId,
              newDevice.deviceId
            );
            const updatedWraps: E2eeSessionDocV2['wraps'] = {
              ...data.wraps,
              [userId]: {
                ...(data.wraps[userId] ?? {}),
                [newDevice.deviceId]: newWrap,
              },
            };
            await setDoc(
              doc(firestore, 'conversations', conv.id, 'e2eeSessions', String(data.epoch)),
              { ...data, wraps: updatedWraps },
              { merge: true }
            );
            didRewrap = true;
            rewrapped += 1;
            const progress: DeviceHandoverProgress = {
              conversationId: conv.id,
              stage: 'rewrapped',
            };
            results.push(progress);
            options?.onProgress?.(progress, i + 1, targets.length);
          }
        }
      }

      // 2.b) Опционально создаём новую эпоху, чтобы будущие сообщения сразу
      //      шли с новым chatKey, обёрнутым под все устройства.
      if (rotateEpoch) {
        const bundles = await collectParticipantDevicesV2(
          firestore,
          conv.participantIds ?? []
        );
        const nextEpoch = currentEpoch + 1;
        await createE2eeSessionDocV2(
          firestore,
          conv.id,
          nextEpoch,
          donorIdentity,
          userId,
          bundles
        );
        await updateDoc(doc(firestore, 'conversations', conv.id), {
          e2eeKeyEpoch: nextEpoch,
        });
        try {
          await postChatSystemEventV2({
            firestore,
            conversationId: conv.id,
            event: chatSystemEvents.epochRotated(nextEpoch, userId),
          });
        } catch {
          // best-effort
        }
        rotated += 1;
        const progress: DeviceHandoverProgress = {
          conversationId: conv.id,
          stage: 'rotated',
          newEpoch: nextEpoch,
        };
        results.push(progress);
        options?.onProgress?.(progress, i + 1, targets.length);
      } else if (!didRewrap) {
        const progress: DeviceHandoverProgress = {
          conversationId: conv.id,
          stage: 'skipped',
          reason: 'no current wrap and rotateEpoch=false',
        };
        results.push(progress);
        options?.onProgress?.(progress, i + 1, targets.length);
      }
    } catch (e) {
      failed += 1;
      const progress: DeviceHandoverProgress = {
        conversationId: conv.id,
        stage: 'failed',
        reason: e instanceof Error ? e.message : String(e),
      };
      results.push(progress);
      options?.onProgress?.(progress, i + 1, targets.length);
    }
  }

  return { rewrapped, rotated, failed, results };
}
