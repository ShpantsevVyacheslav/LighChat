import { doc, getDoc, updateDoc, type Firestore } from 'firebase/firestore';

import {
  chatSystemEvents,
  postChatSystemEventV2,
} from '@/lib/e2ee/v2/system-events';

/**
 * Выключает сквозное шифрование для чата: новые сообщения уходят без поля `e2ee`.
 * Старые зашифрованные сообщения остаются в ленте; клиент расшифровывает их
 * по `e2ee.epoch`.
 *
 * После успешного обновления публикует system-event `e2ee.v2.disabled` в
 * timeline, чтобы UI нарисовал divider (парно с `e2eeEnabled`).
 *
 * Параметры:
 *  - firestore — Firestore instance;
 *  - conversationId — id беседы;
 *  - actorUserId — кто инициировал отключение (для отображения «N отключил»).
 *
 * Безопасно при повторном вызове: updateDoc идемпотентен, а duplicate-divider
 * в UI — визуальный шум, но не ошибка. System-event постим внутри try/catch,
 * чтобы отказ логгирования не ломал сам disable.
 */
export async function disableE2eeOnConversation(
  firestore: Firestore,
  conversationId: string,
  actorUserId?: string
): Promise<void> {
  const convRef = doc(firestore, 'conversations', conversationId);
  // Читаем предыдущую epoch до обновления, чтобы положить её в data события.
  // Если чтение не удалось — не блокируем отключение.
  let previousEpoch = 0;
  try {
    const snap = await getDoc(convRef);
    const raw = snap.data() as { e2eeKeyEpoch?: number } | undefined;
    if (typeof raw?.e2eeKeyEpoch === 'number') {
      previousEpoch = raw.e2eeKeyEpoch;
    }
  } catch {
    // ignore: previousEpoch останется 0
  }

  await updateDoc(convRef, {
    e2eeEnabled: false,
    e2eeKeyEpoch: 0,
  });

  try {
    await postChatSystemEventV2({
      firestore,
      conversationId,
      event: chatSystemEvents.e2eeDisabled(previousEpoch, actorUserId),
    });
  } catch {
    // Divider — cosmetic. Не даём сбою логирования откатить отключение.
  }
}
