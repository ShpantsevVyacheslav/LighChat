'use client';

/**
 * Включение E2EE v2 для существующего чата / создание новой эпохи. Аналог
 * `src/lib/e2ee/enable-conversation.ts`, но с per-device wraps.
 *
 * Идемпотентность: повторный вызов создаёт новую эпоху (это предусмотрено
 * дизайном — например, на ротации ключа). Для «включить если выключено»
 * использовать `tryAutoEnableE2eeV2NewDirectChat` и проверять `e2eeEnabled`.
 */

import { doc, getDoc, updateDoc, type Firestore } from 'firebase/firestore';
import type { Conversation } from '@/lib/types';
import {
  getOrCreateDeviceIdentityV2,
  publishE2eeDeviceV2,
} from '@/lib/e2ee/v2/device-identity-v2';
import {
  collectParticipantDevicesV2,
  createE2eeSessionDocV2,
} from '@/lib/e2ee/v2/session-firestore-v2';
import {
  chatSystemEvents,
  postChatSystemEventV2,
} from '@/lib/e2ee/v2/system-events';
import { logE2eeEvent, normalizeErrorCode } from '@/lib/e2ee/v2/telemetry';

export async function enableE2eeOnConversationV2(
  firestore: Firestore,
  conversation: Conversation,
  currentUserId: string,
  opts?: { deviceLabel?: string }
): Promise<void> {
  const previousEpoch = conversation.e2eeKeyEpoch ?? 0;
  let identity: Awaited<ReturnType<typeof getOrCreateDeviceIdentityV2>>;
  try {
    identity = await getOrCreateDeviceIdentityV2();
    await publishE2eeDeviceV2(firestore, currentUserId, identity, opts?.deviceLabel);

    const participants = conversation.participantIds ?? [];
    if (!participants.includes(currentUserId)) {
      throw new Error('E2EE_CURRENT_USER_NOT_PARTICIPANT');
    }
    const bundles = await collectParticipantDevicesV2(firestore, participants);

    const nextEpoch = previousEpoch + 1;
    await createE2eeSessionDocV2(
      firestore,
      conversation.id,
      nextEpoch,
      identity,
      currentUserId,
      bundles
    );

    await updateDoc(doc(firestore, 'conversations', conversation.id), {
      e2eeEnabled: true,
      e2eeKeyEpoch: nextEpoch,
      e2eeEnabledAt: new Date().toISOString(),
    });

    // Phase 9: telemetry — enable / rotate разграничены по предыдущей эпохе.
    logE2eeEvent(
      previousEpoch === 0 ? 'e2ee.v2.enable.success' : 'e2ee.v2.rotate.success',
      {
        userId: currentUserId,
        conversationId: conversation.id,
        deviceId: identity.deviceId,
        metrics: { epoch: nextEpoch },
      }
    );
  } catch (e) {
    logE2eeEvent(
      previousEpoch === 0 ? 'e2ee.v2.enable.failure' : 'e2ee.v2.rotate.failure',
      {
        userId: currentUserId,
        conversationId: conversation.id,
        errorCode: normalizeErrorCode(e),
      }
    );
    throw e;
  }

  const nextEpoch = previousEpoch + 1;

  // Phase 8: timeline-маркер. Для первой эпохи — «enabled», для последующих —
  // «epoch rotated». Пишем после успешного updateDoc, чтобы UI не увидел
  // divider к событию, которое не произошло.
  try {
    const event =
      previousEpoch === 0
        ? chatSystemEvents.e2eeEnabled(nextEpoch, currentUserId)
        : chatSystemEvents.epochRotated(nextEpoch, currentUserId);
    await postChatSystemEventV2({
      firestore,
      conversationId: conversation.id,
      event,
    });
  } catch (e) {
    // Маркер — это UX-нюанс, не блокируем основной путь.
    console.warn('[e2ee/v2] system-event post failed:', e);
  }
}

/**
 * Дополняет эпоху: когда появляется новое устройство у участника,
 * можно попросить другого участника «дописать» wrap для нашего deviceId.
 * Возвращает true, если wrap создан; false — если уже был.
 *
 * ВАЖНО: приёмник должен уметь читать session-doc, значит его текущий
 * device — ровно тот, что будет unwrap'нуть chat-key. По сути мы здесь
 * берём уже расшифрованный chat-key в памяти и добавляем новую обёртку.
 *
 * (Полная реализация — Phase 5. Здесь — signature-only stub, чтобы
 * UI-код мог на него ссылаться и тесты могли мокать.)
 */
export async function appendDeviceWrapForEpochV2(
  _firestore: Firestore,
  _conversationId: string,
  _epoch: number,
  _recipientUserId: string,
  _recipientDeviceId: string,
  _recipientPublicSpkiB64: string
): Promise<boolean> {
  throw new Error('appendDeviceWrapForEpochV2 is implemented in Phase 5');
}

/**
 * Аналог v1 auto-enable для новых DM. Вызывать после создания `conversations/{cid}`.
 * Параметр `flag` соответствует `platformSettings.main.e2eeProtocolVersion`.
 */
export async function tryAutoEnableE2eeV2NewDirectChat(
  firestore: Firestore,
  conversationId: string,
  currentUserId: string,
  options: { userWants: boolean; platformWants: boolean; deviceLabel?: string }
): Promise<void> {
  if (!options.userWants && !options.platformWants) return;
  const snap = await getDoc(doc(firestore, 'conversations', conversationId));
  if (!snap.exists()) return;
  const data = snap.data() as Omit<Conversation, 'id'>;
  if (data.isGroup) return;
  const conv: Conversation = { ...data, id: conversationId };
  try {
    await enableE2eeOnConversationV2(firestore, conv, currentUserId, {
      deviceLabel: options.deviceLabel,
    });
  } catch (e) {
    console.warn('[e2ee/v2] auto-enable skipped:', e);
  }
}
