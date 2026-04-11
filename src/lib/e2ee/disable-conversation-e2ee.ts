import { doc, updateDoc, type Firestore } from 'firebase/firestore';

/**
 * Выключает сквозное шифрование для чата: новые сообщения уходят без поля `e2ee`.
 * Старые зашифрованные сообщения остаются в ленте; клиент расшифровывает их по `e2ee.epoch`.
 */
export async function disableE2eeOnConversation(firestore: Firestore, conversationId: string): Promise<void> {
  await updateDoc(doc(firestore, 'conversations', conversationId), {
    e2eeEnabled: false,
    e2eeKeyEpoch: 0,
  });
}
