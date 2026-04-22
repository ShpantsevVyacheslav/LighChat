/**
 * Phase 9 (+ Phase 10 cleanup) — rollout helper для E2EE.
 *
 * Что делает: читает `platformSettings/main.e2eeProtocolVersion` и на
 * основании флага решает, нужно ли включать E2EE для нового чата.
 *
 * После удаления legacy v1 (см. Gap #5 в `04-runtime-flows.md`) флаг
 * умеет только два смысловых значения:
 *  - `v2` / `auto` → v2 auto-enable (единственный поддерживаемый).
 *  - любое другое → no-op (можно отключить auto-enable централизованно,
 *    поставив в документ строку `off`).
 *
 * Куда встроить: call-site'ы, где сейчас вызывается auto-enable — ChatWindow,
 * ContactsClient, NewChatDialog. Миграция — в отдельном PR, чтобы проще было
 * откатить флаг.
 *
 * ВНИМАНИЕ: этот модуль ТОЛЬКО читает флаг и делает routing. Никакой другой
 * логики здесь нет — это гарантирует, что rollback сводится к смене флага в
 * Firestore без переписывания кода.
 */

import { doc, getDoc, type Firestore } from 'firebase/firestore';
import type { PlatformSettingsDoc } from '@/lib/types';
import { tryAutoEnableE2eeV2NewDirectChat } from '@/lib/e2ee/v2/enable-conversation-v2';
import { logE2eeEvent, normalizeErrorCode } from '@/lib/e2ee/v2/telemetry';

export type AutoEnableRolloutOptions = {
  userWants: boolean;
  platformWants: boolean;
  deviceLabel?: string;
};

/**
 * Читает `platformSettings/main.e2eeProtocolVersion` с аккуратным fallback'ом:
 * если документ недоступен (permissions/offline) — возвращаем `'auto'`.
 * Не должно бросать.
 */
export async function readE2eeProtocolFlag(
  firestore: Firestore
): Promise<'v2' | 'auto' | 'off'> {
  try {
    const snap = await getDoc(doc(firestore, 'platformSettings', 'main'));
    const data = snap.data() as PlatformSettingsDoc | undefined;
    const v = data?.e2eeProtocolVersion;
    if (v === 'v2' || v === 'auto' || v === 'off') return v;
    return 'auto';
  } catch {
    return 'auto';
  }
}

/**
 * Главная точка для call-site'ов. Решает, нужно ли включать E2EE.
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
  if (flag === 'off') return;

  try {
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
