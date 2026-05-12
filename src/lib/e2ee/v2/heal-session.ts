'use client';

/**
 * Lazy session re-keying для multi-device self-healing.
 *
 * Зачем: исходный дизайн предусматривал ротацию эпохи только на явных событиях
 * (enable, add/remove member, revoke, manual). В реальном мире пользователь
 * входит на новое устройство или чистит кэш, и новая `e2eeDevices/{id}` запись
 * появляется **без** триггера ротации. В результате:
 *  1. Сообщения от других участников приходят только на те устройства, что
 *     были зарегистрированы на момент предыдущей ротации — новый девайс не в
 *     `wraps[me]`.
 *  2. После очистки кэша браузер получает новый `deviceId`/publicKey и теряет
 *     возможность unwrap'ить chat-key старой эпохи.
 *  3. На send получение chat-key падает → `E2EE_NO_CHAT_KEY`, UI показывает
 *     «Не удалось зашифровать сообщение».
 *
 * Fix: клиент **сам** определяет рассогласование и триггерит новую эпоху.
 *
 * Рассогласование обнаруживается так:
 *  - session-doc для текущего `e2eeKeyEpoch` не существует / v1 (legacy), а
 *    текущий клиент не v1 → нужно создать v2 эпоху.
 *  - В v2 session `wraps[me][identity.deviceId]` отсутствует → мой девайс не
 *    покрыт → rotate.
 *  - У любого участника активных devices больше, чем ключей в `wraps[uid]` →
 *    чужой девайс не покрыт → rotate (чтобы остальные участники могли читать
 *    с новых устройств).
 *
 * После ротации:
 *  - `conversations/{id}.e2eeKeyEpoch` инкрементируется,
 *  - новый session-doc содержит wraps для всех текущих активных устройств.
 *
 * Все операции идемпотентные: если другой клиент уже ротирнул, мы просто
 * перечитываем документ и работаем с новой эпохой.
 *
 * Изоляция: модуль не зависит от send/receive pipeline напрямую — его можно
 * вызывать из любого места (на mount чата, перед send, после ошибки unwrap).
 */

import {
  doc,
  getDoc,
  runTransaction,
  type Firestore,
} from 'firebase/firestore';
import type { Conversation, E2eeSessionDocV2 } from '@/lib/types';
import {
  collectParticipantDevicesV2,
  createE2eeSessionDocV2,
  fetchE2eeSessionAny,
} from '@/lib/e2ee/v2/session-firestore-v2';
import {
  getOrCreateDeviceIdentityV2,
  publishE2eeDeviceV2,
  type DeviceIdentityV2,
} from '@/lib/e2ee/v2/device-identity-v2';
import {
  chatSystemEvents,
  postChatSystemEventV2,
} from '@/lib/e2ee/v2/system-events';
import { logE2eeEvent, normalizeErrorCode } from '@/lib/e2ee/v2/telemetry';
import { logger } from '@/lib/logger';

export type HealReason =
  | 'no-session-doc'
  | 'session-unsupported'
  | 'my-device-missing'
  | 'other-device-missing';

export type HealResult =
  | { healed: true; reason: HealReason; newEpoch: number }
  | { healed: false };

/**
 * Определяет, нужна ли ротация. Чтение-онли, без побочных эффектов.
 */
export async function diagnoseSessionCoverageV2(
  firestore: Firestore,
  conversation: Conversation,
  currentUserId: string,
  currentIdentity: DeviceIdentityV2
): Promise<{ needsHeal: boolean; reason: HealReason | null; currentEpoch: number }> {
  const currentEpoch = conversation.e2eeKeyEpoch ?? 0;
  if (currentEpoch < 1) {
    // Эпохи ещё нет — это отдельный сценарий (enable), здесь не heal'им.
    return { needsHeal: false, reason: null, currentEpoch };
  }

  const session = await fetchE2eeSessionAny(firestore, conversation.id, currentEpoch);
  if (!session) {
    return { needsHeal: true, reason: 'no-session-doc', currentEpoch };
  }
  if (session.version !== 'v2') {
    // Неопознанный / legacy session-doc. Перекатываем эпоху в v2.
    return { needsHeal: true, reason: 'session-unsupported', currentEpoch };
  }
  const data: E2eeSessionDocV2 = session.data;
  const myWraps = data.wraps?.[currentUserId];
  if (!myWraps || !myWraps[currentIdentity.deviceId]) {
    return { needsHeal: true, reason: 'my-device-missing', currentEpoch };
  }

  // Участники: сравним set активных devices с тем, что покрыто в wraps.
  // Если у кого-то появились новые devices — перекодируем, чтобы они смогли
  // читать сообщения.
  try {
    const participants = conversation.participantIds ?? [];
    const bundles = await collectParticipantDevicesV2(firestore, participants);
    for (const b of bundles) {
      const wrappedIds = new Set(Object.keys(data.wraps?.[b.userId] ?? {}));
      for (const dev of b.devices) {
        if (!wrappedIds.has(dev.deviceId)) {
          return { needsHeal: true, reason: 'other-device-missing', currentEpoch };
        }
      }
    }
  } catch {
    // collectParticipantDevicesV2 может бросить E2EE_NO_DEVICE(uid). Это не
    // heal-кейс — это ошибка данных, эскалируем выше в send-pipeline.
    return { needsHeal: false, reason: null, currentEpoch };
  }

  return { needsHeal: false, reason: null, currentEpoch };
}

/**
 * In-memory гвард, чтобы два параллельных вызова healSession в пределах одной
 * вкладки не сгенерировали две конкурирующие ротации. Транзакция на backend
 * защитит от дубликата на уровне Firestore, но UX улучшится, если мы просто
 * подождём первую попытку.
 */
const inflightHeal = new Map<string, Promise<HealResult>>();

/**
 * Пытается привести session в консистентное состояние. Идемпотентно:
 * повторные вызовы для той же эпохи либо возвращают `{ healed: false }`
 * (если уже покрыто), либо результат предыдущего in-flight вызова.
 */
export async function healSessionForCurrentDevicesV2(
  firestore: Firestore,
  conversation: Conversation,
  currentUserId: string
): Promise<HealResult> {
  const cacheKey = `${conversation.id}:${conversation.e2eeKeyEpoch ?? 0}`;
  const existing = inflightHeal.get(cacheKey);
  if (existing) return existing;

  const promise = (async (): Promise<HealResult> => {
    try {
      const identity = await getOrCreateDeviceIdentityV2();
      // На всякий случай сначала опубликуем наш публичник — если это новое
      // устройство / cache-clear, он ещё не в `e2eeDevices`, и без этого
      // новая эпоха не покроет нас.
      await publishE2eeDeviceV2(firestore, currentUserId, identity);

      const diag = await diagnoseSessionCoverageV2(
        firestore,
        conversation,
        currentUserId,
        identity
      );
      if (!diag.needsHeal) return { healed: false };

      // Всё: ротируем. Используем transaction для чтения e2eeKeyEpoch и для
      // атомарного обновления — если другой клиент успел раньше, мы
      // прочитаем его значение и откажемся от своей ротации.
      const convRef = doc(firestore, 'conversations', conversation.id);
      let nextEpoch = diag.currentEpoch + 1;
      let conflict = false;

      await runTransaction(firestore, async (tx) => {
        const snap = await tx.get(convRef);
        if (!snap.exists()) throw new Error('E2EE_CONV_NOT_FOUND');
        const latestEpoch = (snap.data()?.e2eeKeyEpoch as number | undefined) ?? 0;
        if (latestEpoch > diag.currentEpoch) {
          // Кто-то уже ротирнул между нашим diagnose и txn start.
          conflict = true;
          return;
        }
        nextEpoch = latestEpoch + 1;
        tx.update(convRef, {
          e2eeKeyEpoch: nextEpoch,
          e2eeEnabled: true,
          e2eeEnabledAt: new Date().toISOString(),
        });
      });

      if (conflict) {
        // Не делаем ничего — другой клиент создал session. Следующий read
        // возьмёт её. Возвращаем healed=false, чтобы вызывающий не думал,
        // что это мы ротировали.
        return { healed: false };
      }

      // Теперь создаём session-doc для нашей новой эпохи. Transaction выше
      // зафиксировала, что nextEpoch уникален для нас — safe to setDoc.
      const participants = conversation.participantIds ?? [];
      const bundles = await collectParticipantDevicesV2(firestore, participants);
      await createE2eeSessionDocV2(
        firestore,
        conversation.id,
        nextEpoch,
        identity,
        currentUserId,
        bundles
      );

      logE2eeEvent('e2ee.v2.rotate.success', {
        userId: currentUserId,
        conversationId: conversation.id,
        deviceId: identity.deviceId,
        metrics: { epoch: nextEpoch },
      });

      try {
        await postChatSystemEventV2({
          firestore,
          conversationId: conversation.id,
          event: chatSystemEvents.epochRotated(nextEpoch, currentUserId),
        });
      } catch (e) {
        logger.warn('e2ee-heal', 'system-event post failed', e);
      }

      return { healed: true, reason: diag.reason ?? 'my-device-missing', newEpoch: nextEpoch };
    } catch (e) {
      logE2eeEvent('e2ee.v2.rotate.failure', {
        userId: currentUserId,
        conversationId: conversation.id,
        errorCode: normalizeErrorCode(e),
      });
      // Не пробрасываем наверх — heal best-effort. Вызывающий получит
      // `{ healed: false }` и покажет стандартный error-placeholder.
      logger.warn('e2ee-heal', 'heal failed', e);
      return { healed: false };
    } finally {
      inflightHeal.delete(cacheKey);
    }
  })();
  inflightHeal.set(cacheKey, promise);
  return promise;
}

/**
 * Отдельная кнопка / CTA в UI: «починить шифрование». Делает то же, что
 * `healSessionForCurrentDevicesV2`, но всегда пытается ротировать (даже если
 * diagnose говорит, что всё ок). Полезно, когда пользователь видит ошибку
 * расшифровки, но автоматическая эвристика не сработала.
 */
export async function forceRotateEpochV2(
  firestore: Firestore,
  conversation: Conversation,
  currentUserId: string
): Promise<{ newEpoch: number }> {
  const identity = await getOrCreateDeviceIdentityV2();
  await publishE2eeDeviceV2(firestore, currentUserId, identity);

  const convRef = doc(firestore, 'conversations', conversation.id);
  const snap = await getDoc(convRef);
  if (!snap.exists()) throw new Error('E2EE_CONV_NOT_FOUND');
  const latestEpoch = (snap.data()?.e2eeKeyEpoch as number | undefined) ?? 0;
  const nextEpoch = latestEpoch + 1;

  const participants = conversation.participantIds ?? [];
  const bundles = await collectParticipantDevicesV2(firestore, participants);
  await createE2eeSessionDocV2(
    firestore,
    conversation.id,
    nextEpoch,
    identity,
    currentUserId,
    bundles
  );
  await runTransaction(firestore, async (tx) => {
    const s = await tx.get(convRef);
    if (!s.exists()) throw new Error('E2EE_CONV_NOT_FOUND');
    const cur = (s.data()?.e2eeKeyEpoch as number | undefined) ?? 0;
    if (cur >= nextEpoch) return; // кто-то раньше — OK, наш doc валиден
    tx.update(convRef, {
      e2eeKeyEpoch: nextEpoch,
      e2eeEnabled: true,
      e2eeEnabledAt: new Date().toISOString(),
    });
  });

  logE2eeEvent('e2ee.v2.rotate.success', {
    userId: currentUserId,
    conversationId: conversation.id,
    deviceId: identity.deviceId,
    metrics: { epoch: nextEpoch },
  });
  try {
    await postChatSystemEventV2({
      firestore,
      conversationId: conversation.id,
      event: chatSystemEvents.epochRotated(nextEpoch, currentUserId),
    });
  } catch (e) {
    logger.warn('e2ee-heal', 'force-rotate: system-event post failed', e);
  }
  return { newEpoch: nextEpoch };
}
