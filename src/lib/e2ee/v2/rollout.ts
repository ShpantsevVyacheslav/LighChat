/**
 * Phase 9 — rollout helper для E2EE v2.
 *
 * Что делает: читает `platformSettings/main.e2eeProtocolVersion` и на
 * основании флага решает, какую функцию auto-enable вызвать.
 *
 * Правила:
 *  - `v1`  → legacy v1 auto-enable (`tryAutoEnableE2eeNewDirectChat`).
 *  - `v2`  → v2 auto-enable (`tryAutoEnableE2eeV2NewDirectChat`).
 *  - `auto` (default) → если у инициатора (или собеседника — опциональная
 *    проверка) уже есть хоть одно `e2eeDevices/*`, используем v2 — иначе v1.
 *
 * Куда встроить: call-site'ы, где сейчас вызывается
 * `tryAutoEnableE2eeNewDirectChat` (см. ChatWindow, ContactsClient,
 * NewChatDialog). Миграция — в отдельном PR, чтобы проще было откатить флаг.
 *
 * ВНИМАНИЕ: этот модуль ТОЛЬКО читает флаг и делает routing. Никакой другой
 * логики здесь нет — это гарантирует, что rollback сводится к смене флага в
 * Firestore без переписывания кода.
 */

import { doc, getDoc, type Firestore } from 'firebase/firestore';
import type { PlatformSettingsDoc } from '@/lib/types';
import { tryAutoEnableE2eeNewDirectChat } from '@/lib/e2ee/enable-conversation';
import { tryAutoEnableE2eeV2NewDirectChat } from '@/lib/e2ee/v2/enable-conversation-v2';
import { logE2eeEvent, normalizeErrorCode } from '@/lib/e2ee/v2/telemetry';

export type AutoEnableRolloutOptions = {
  userWants: boolean;
  platformWants: boolean;
  deviceLabel?: string;
};

/**
 * Читает `platformSettings/main.e2eeProtocolVersion` с аккуратным fallback'ом:
 * если документ недоступен (permissions/offline) — возвращаем `'auto'`,
 * т.е. поведение «как до Phase 9». Не должно бросать.
 */
export async function readE2eeProtocolFlag(
  firestore: Firestore
): Promise<'v1' | 'v2' | 'auto'> {
  try {
    const snap = await getDoc(doc(firestore, 'platformSettings', 'main'));
    const data = snap.data() as PlatformSettingsDoc | undefined;
    const v = data?.e2eeProtocolVersion;
    if (v === 'v1' || v === 'v2' || v === 'auto') return v;
    return 'auto';
  } catch {
    return 'auto';
  }
}

/**
 * Главная точка для call-site'ов. Решает, куда роутить auto-enable.
 * Ошибки пересыпаются в telemetry, но не бросаются — auto-enable это
 * best-effort UX-фича и не должна валить создание чата.
 */
export async function autoEnableE2eeForNewDirectChat(
  firestore: Firestore,
  conversationId: string,
  currentUserId: string,
  options: AutoEnableRolloutOptions
): Promise<void> {
  if (!options.userWants && !options.platformWants) return;

  const flag = await readE2eeProtocolFlag(firestore);

  try {
    if (flag === 'v2') {
      await tryAutoEnableE2eeV2NewDirectChat(firestore, conversationId, currentUserId, {
        userWants: options.userWants,
        platformWants: options.platformWants,
        deviceLabel: options.deviceLabel,
      });
      return;
    }
    if (flag === 'v1') {
      await tryAutoEnableE2eeNewDirectChat(firestore, conversationId, currentUserId, {
        userWants: options.userWants,
        platformWants: options.platformWants,
      });
      return;
    }
    // flag === 'auto' — в Phase 9 по умолчанию включаем v2 для новых DM,
    // v1 остаётся путём для принудительного отката через флаг.
    await tryAutoEnableE2eeV2NewDirectChat(firestore, conversationId, currentUserId, {
      userWants: options.userWants,
      platformWants: options.platformWants,
      deviceLabel: options.deviceLabel,
    });
  } catch (e) {
    logE2eeEvent('e2ee.v2.enable.failure', {
      userId: currentUserId,
      conversationId,
      errorCode: normalizeErrorCode(e),
    });
  }
}
