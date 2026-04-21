/**
 * Phase 8 — хелпер для публикации system-маркеров E2EE в timeline чата.
 *
 * События — system-message (`senderId = '__system__'`, `text = ''`,
 * `systemEvent = {...}`). Они не шифруются, чтобы любой клиент — даже без ключа
 * эпохи — мог отрендерить timeline divider. См. §9.4 RFC.
 *
 * Используется триггерами:
 *  - `enableE2eeOnConversation` / `enableE2eeOnConversationV2` → `e2ee.v2.enabled`
 *  - revoke device / add member / remove member / re-key → `e2ee.v2.epoch.rotated`
 *  - публикация нового устройства / отзыв → `device.added` / `device.revoked`
 *  - detected fingerprint change у собеседника → `fingerprint.changed`
 *
 * NB: вызывать **после** успешной записи основного Firestore-обновления, иначе
 * UI покажет divider к событию, которое в итоге не произошло.
 */

import {
  addDoc,
  collection,
  serverTimestamp,
  type Firestore,
} from 'firebase/firestore';

import type { ChatSystemEvent, ChatSystemEventType } from '@/lib/types';

export const CHAT_SYSTEM_SENDER_ID = '__system__';

export type PostSystemEventOptions = {
  firestore: Firestore;
  conversationId: string;
  event: ChatSystemEvent;
};

/**
 * Постит system-маркер в `conversations/{cid}/messages/`. Возвращает id нового
 * документа. Поле `text` оставлено пустым; UI считывает `systemEvent` и
 * рендерит divider вместо bubble.
 */
export async function postChatSystemEventV2(
  opts: PostSystemEventOptions
): Promise<string> {
  const ref = collection(opts.firestore, `conversations/${opts.conversationId}/messages`);
  const docRef = await addDoc(ref, {
    senderId: CHAT_SYSTEM_SENDER_ID,
    text: '',
    attachments: [],
    createdAt: serverTimestamp(),
    readAt: null,
    systemEvent: opts.event,
  });
  return docRef.id;
}

/** Удобные shortcut-фабрики для типовых событий. */
export const chatSystemEvents = {
  e2eeEnabled(epoch: number, actorUserId?: string): ChatSystemEvent {
    return { type: 'e2ee.v2.enabled', data: { epoch, actorUserId } };
  },
  epochRotated(epoch: number, actorUserId?: string): ChatSystemEvent {
    return { type: 'e2ee.v2.epoch.rotated', data: { epoch, actorUserId } };
  },
  deviceAdded(params: {
    actorUserId?: string;
    actorName?: string;
    deviceId: string;
    deviceLabel: string;
  }): ChatSystemEvent {
    return { type: 'e2ee.v2.device.added', data: params };
  },
  deviceRevoked(params: {
    actorUserId?: string;
    actorName?: string;
    deviceId: string;
    deviceLabel: string;
  }): ChatSystemEvent {
    return { type: 'e2ee.v2.device.revoked', data: params };
  },
  fingerprintChanged(params: {
    actorUserId?: string;
    actorName?: string;
    previousFingerprint?: string;
    nextFingerprint: string;
  }): ChatSystemEvent {
    return { type: 'e2ee.v2.fingerprint.changed', data: params };
  },
};

export type { ChatSystemEventType };
