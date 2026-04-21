/**
 * Логика выбора версии протокола при отправке сообщения / создании эпохи.
 *
 * Правила (см. RFC §8.2):
 *   - `flag = 'v1'`  → пишем v1 всегда (legacy).
 *   - `flag = 'v2'`  → пишем v2 всегда.
 *   - `flag = 'auto'` → читаем последний session-doc текущей эпохи; если он v2 —
 *     пишем v2, иначе v1. Это даёт плавную миграцию без хардкода.
 *
 * Читатель (decrypt) **всегда** поддерживает обе версии — это задаётся в
 * `use-e2ee-conversation` / mobile-декодере.
 */

import type { Firestore } from 'firebase/firestore';
import { fetchE2eeSessionAny } from '@/lib/e2ee/v2/session-firestore-v2';

export type E2eeWriteProtocol = 'v1' | 'v2';
export type E2eeProtocolFlag = 'v1' | 'v2' | 'auto';

export async function selectWriteProtocol(
  firestore: Firestore,
  conversationId: string,
  currentEpoch: number,
  flag: E2eeProtocolFlag = 'auto'
): Promise<E2eeWriteProtocol> {
  if (flag === 'v1') return 'v1';
  if (flag === 'v2') return 'v2';
  if (currentEpoch <= 0) return 'v1';
  const existing = await fetchE2eeSessionAny(firestore, conversationId, currentEpoch);
  if (!existing) return 'v1';
  return existing.version === 'v2' ? 'v2' : 'v1';
}

/**
 * Для создания *новой* эпохи мы уже знаем, что будем писать session-doc. Здесь
 * правило чуть другое: `auto` создаёт v2, если хотя бы у одного участника есть
 * хоть одно `e2eeDevices/*` документ (т.е. кто-то уже «живёт» в v2).
 * Подробная логика по участникам вычисляется в `enable-conversation-v2.ts`,
 * здесь — только базовое переключение на основе флага.
 */
export function resolveEpochProtocolFromFlag(flag: E2eeProtocolFlag): E2eeWriteProtocol {
  if (flag === 'v1') return 'v1';
  if (flag === 'v2') return 'v2';
  return 'v2';
}
