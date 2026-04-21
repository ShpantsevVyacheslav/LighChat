'use client';

/**
 * Revoke устройства E2EE v2.
 *
 * Что делает:
 *  1. Помечает `users/{uid}/e2eeDevices/{deviceId}.revoked = true` + `revokedAt`,
 *     `revokedByDeviceId`. После этого `listActiveE2eeDevicesV2` больше не
 *     возвращает это устройство.
 *  2. Для всех конверсейшенов, где пользователь участвует и включён E2EE,
 *     пересоздаёт session-doc под новой эпохой (без revoked deviceId в wraps) и
 *     бампит `conversations/{cid}.e2eeKeyEpoch`. После этого revoked device
 *     технически не сможет прочесть **новые** сообщения (старые остаются
 *     доступны — приватник никто не уничтожает удалённо).
 *
 * Идемпотентность: если процесс прерван — повторный вызов начинает с того чата,
 * где `e2eeKeyEpoch` меньше, чем фактически созданные эпохи. Мы просто пропускаем
 * чаты, чья текущая эпоха уже не содержит revoked-устройство в wraps: это
 * означает, что re-key уже произошёл.
 *
 * Почему не Cloud Function: всё честно шифруется **клиентом** из-под revoker'а,
 * потому что только клиент имеет в памяти приватник, способный поднять chat-key
 * каждой эпохи. Серверу мы не доверяем.
 */

import {
  collection,
  doc,
  getDocs,
  query,
  updateDoc,
  where,
  type Firestore,
} from 'firebase/firestore';
import type { Conversation } from '@/lib/types';
import { revokeE2eeDeviceV2 } from '@/lib/e2ee/v2/device-identity-v2';
import type { DeviceIdentityV2 } from '@/lib/e2ee/v2/device-identity-v2';
import {
  collectParticipantDevicesV2,
  createE2eeSessionDocV2,
  fetchE2eeSessionAny,
} from '@/lib/e2ee/v2/session-firestore-v2';
import {
  chatSystemEvents,
  postChatSystemEventV2,
} from '@/lib/e2ee/v2/system-events';
import { logE2eeEvent, normalizeErrorCode } from '@/lib/e2ee/v2/telemetry';

export type RevokeProgress = {
  conversationId: string;
  stage: 'skipped' | 'rekeyed' | 'failed';
  reason?: string;
  newEpoch?: number;
};

export type RevokeOptions = {
  /**
   * Сигнал отмены (например, пользователь закрыл диалог прогресса).
   * При срабатывании текущий чат дописывается, дальше цикл останавливается.
   */
  signal?: AbortSignal;
  /** Колбэк прогресса — UI рисует счётчик "N из M чатов обновлено". */
  onProgress?: (progress: RevokeProgress, done: number, total: number) => void;
};

/**
 * Главная функция. Блокирующий итератор по всем чатам: плюс-минус линейно
 * зависит от количества чатов пользователя × числа устройств у участников.
 *
 * Для heavy-users (500+ чатов) может идти несколько минут — UI должен
 * показывать прогресс. Возвращает общее число успешных re-key и список ошибок.
 */
export async function revokeDeviceAndRekeyV2(params: {
  firestore: Firestore;
  userId: string;
  revokerIdentity: DeviceIdentityV2;
  deviceIdToRevoke: string;
  options?: RevokeOptions;
}): Promise<{ rekeyed: number; failed: number; results: RevokeProgress[] }> {
  const { firestore, userId, revokerIdentity, deviceIdToRevoke, options } = params;

  if (deviceIdToRevoke === revokerIdentity.deviceId) {
    // Самоубийство текущего устройства — потеря доступа к будущим сообщениям.
    // UI должен предупредить, но если дошли сюда — доверяем.
  }

  await revokeE2eeDeviceV2(firestore, userId, deviceIdToRevoke, revokerIdentity.deviceId);
  logE2eeEvent('e2ee.v2.device.revoked', {
    userId,
    deviceId: deviceIdToRevoke,
  });

  const convsSnap = await getDocs(
    query(collection(firestore, 'conversations'), where('participantIds', 'array-contains', userId))
  );

  const targets: Conversation[] = [];
  for (const snap of convsSnap.docs) {
    const data = snap.data() as Omit<Conversation, 'id'>;
    if (!data.e2eeEnabled) continue;
    targets.push({ ...data, id: snap.id });
  }

  const results: RevokeProgress[] = [];
  let rekeyed = 0;
  let failed = 0;

  for (let i = 0; i < targets.length; i += 1) {
    if (options?.signal?.aborted) break;
    const conv = targets[i];
    try {
      const nextEpoch = (conv.e2eeKeyEpoch ?? 0) + 1;
      const currentEpoch = conv.e2eeKeyEpoch ?? 0;

      // Идемпотентность: если текущая эпоха уже НЕ содержит revoked deviceId —
      // пропускаем. Это случай повторного запуска revoke после сбоя сети.
      if (currentEpoch > 0) {
        const current = await fetchE2eeSessionAny(firestore, conv.id, currentEpoch);
        if (current && current.version === 'v2') {
          const perUser = current.data.wraps[userId] ?? {};
          if (!(deviceIdToRevoke in perUser)) {
            const progress: RevokeProgress = {
              conversationId: conv.id,
              stage: 'skipped',
              reason: 'already rekeyed',
            };
            results.push(progress);
            options?.onProgress?.(progress, i + 1, targets.length);
            continue;
          }
        }
      }

      const bundles = await collectParticipantDevicesV2(firestore, conv.participantIds ?? []);
      // Дополнительная защита: если у нашего пользователя вдруг всё ещё есть
      // revoked deviceId в `e2eeDevices` (race с чтением выше), принудительно
      // фильтруем его перед wrap.
      const bundlesFiltered = bundles.map((b) =>
        b.userId === userId
          ? {
              ...b,
              devices: b.devices.filter((d) => d.deviceId !== deviceIdToRevoke),
            }
          : b
      );

      await createE2eeSessionDocV2(
        firestore,
        conv.id,
        nextEpoch,
        revokerIdentity,
        userId,
        bundlesFiltered
      );
      await updateDoc(doc(firestore, 'conversations', conv.id), {
        e2eeKeyEpoch: nextEpoch,
      });

      // Phase 8: timeline-маркер о ротации ключа. Best-effort — если Firestore
      // отклонит запись (permissions/offline), это не должно проваливать revoke.
      try {
        await postChatSystemEventV2({
          firestore,
          conversationId: conv.id,
          event: chatSystemEvents.epochRotated(nextEpoch, userId),
        });
      } catch (_e) {
        // Не логируем в результат — divider это UX-украшение.
      }

      const progress: RevokeProgress = {
        conversationId: conv.id,
        stage: 'rekeyed',
        newEpoch: nextEpoch,
      };
      results.push(progress);
      options?.onProgress?.(progress, i + 1, targets.length);
      rekeyed += 1;
      logE2eeEvent('e2ee.v2.rotate.success', {
        userId,
        conversationId: conv.id,
        metrics: { epoch: nextEpoch },
      });
    } catch (e) {
      const progress: RevokeProgress = {
        conversationId: conv.id,
        stage: 'failed',
        reason: e instanceof Error ? e.message : String(e),
      };
      results.push(progress);
      options?.onProgress?.(progress, i + 1, targets.length);
      failed += 1;
      logE2eeEvent('e2ee.v2.rotate.failure', {
        userId,
        conversationId: conv.id,
        errorCode: normalizeErrorCode(e),
      });
    }
  }

  return { rekeyed, failed, results };
}

/** Переименование устройства (простой metadata update). */
export async function renameE2eeDeviceV2(
  firestore: Firestore,
  userId: string,
  deviceId: string,
  newLabel: string
): Promise<void> {
  const trimmed = newLabel.trim();
  if (!trimmed) throw new Error('E2EE_DEVICE_LABEL_EMPTY');
  if (trimmed.length > 120) throw new Error('E2EE_DEVICE_LABEL_TOO_LONG');
  await updateDoc(doc(firestore, 'users', userId, 'e2eeDevices', deviceId), {
    label: trimmed,
  });
}
