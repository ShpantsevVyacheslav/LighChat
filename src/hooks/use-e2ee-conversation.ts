'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import type { Firestore } from 'firebase/firestore';
import type { ChatMessageE2eePayload, Conversation } from '@/lib/types';
import {
  E2EE_PROTOCOL_VERSION,
  decryptUtf8WithAesGcm,
  encryptUtf8WithAesGcm,
  fetchE2eeSession,
  getOrCreateDeviceIdentity,
  publishE2eePublicKey,
  unwrapConversationChatKey,
} from '@/lib/e2ee';
import {
  E2EE_V2_PROTOCOL,
  decryptUtf8WithAesGcmV2,
  encryptUtf8WithAesGcmV2,
  fetchE2eeSessionAny,
  getOrCreateDeviceIdentityV2,
  publishE2eeDeviceV2,
  unwrapChatKeyForMeV2,
  unwrapChatKeyRawForMeV2,
} from '@/lib/e2ee';

/**
 * E2EE hook с dual-read (v1 + v2) поддержкой.
 *
 * - Identity: параллельно публикуется v1 ключ (`users/{uid}/e2ee/device`)
 *   и v2 device doc (`users/{uid}/e2eeDevices/{deviceId}`). v1 нужен, чтобы
 *   «старые» участники без v2-клиента могли обернуть ключ на тебя при
 *   включении legacy-сессии; v2 — для multi-device сценариев.
 * - Encrypt: по умолчанию использует v1 (совместимо с текущим ChatWindow).
 *   Новое `encryptOutgoingHtmlV2({ messageId })` даёт v2-write-path для
 *   вызывающих, которые могут детерминированно предварительно зарезервировать
 *   document id. ChatWindow интегрирует это за feature-flag'ом (Phase 9).
 * - Decrypt: `decryptMessagePayload` сам определяет версию по
 *   `payload.protocolVersion`. Это и есть основной эффект Phase 2 — web-клиент
 *   корректно читает v2-сообщения, приходящие с mobile (Phase 4) или с других
 *   web-устройств того же юзера.
 */
export function useE2eeConversation(
  firestore: Firestore | null,
  conversation: Conversation | null,
  currentUserId: string | undefined | null
) {
  const uid = currentUserId ?? null;
  /** Кэш расшифрованного ChatKey по строковому ключу `cid:epoch:version`. */
  const keyByEpochRef = useRef<Map<string, CryptoKey>>(new Map());
  /** Phase 7: сырые байты v2-chatKey для HKDF при media-wrap. */
  const rawKeyByEpochRef = useRef<Map<string, ArrayBuffer>>(new Map());
  const [identityReady, setIdentityReady] = useState(false);

  const e2eeEnabled = !!(conversation?.e2eeEnabled && (conversation?.e2eeKeyEpoch ?? 0) > 0);
  const e2eeEpoch = conversation?.e2eeKeyEpoch ?? 0;

  useEffect(() => {
    keyByEpochRef.current.clear();
    rawKeyByEpochRef.current.clear();
  }, [conversation?.id]);

  useEffect(() => {
    if (!firestore || !uid) return;
    let cancelled = false;
    (async () => {
      try {
        // v1: публикуем single-slot ключ — нужен для совместимости.
        const { privateKey: _p, publicKeySpkiB64 } = await getOrCreateDeviceIdentity();
        await publishE2eePublicKey(firestore, uid, publicKeySpkiB64);
        // v2: публикуем per-device ключ. Это не мешает v1 и даёт другим
        // v2-клиентам возможность оборачивать ключи под нас.
        const identityV2 = await getOrCreateDeviceIdentityV2();
        await publishE2eeDeviceV2(firestore, uid, identityV2);
        if (!cancelled) setIdentityReady(true);
      } catch (e) {
        console.error('[e2ee] identity init failed', e);
        if (!cancelled) setIdentityReady(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [firestore, uid]);

  /**
   * Получает chat-key для конкретной эпохи. Определяет версию session-doc'а
   * и использует соответствующий unwrap. Кэширует по `(epoch, version)`.
   */
  const getAesKeyForEpoch = useCallback(
    async (targetEpoch: number): Promise<{ key: CryptoKey; version: 'v1' | 'v2' } | null> => {
      if (!firestore || !conversation?.id || !uid || targetEpoch < 1) return null;
      const cacheKeyV1 = `${conversation.id}:${targetEpoch}:v1`;
      const cacheKeyV2 = `${conversation.id}:${targetEpoch}:v2`;
      const hitV2 = keyByEpochRef.current.get(cacheKeyV2);
      if (hitV2) return { key: hitV2, version: 'v2' };
      const hitV1 = keyByEpochRef.current.get(cacheKeyV1);
      if (hitV1) return { key: hitV1, version: 'v1' };

      const any = await fetchE2eeSessionAny(firestore, conversation.id, targetEpoch);
      if (!any) {
        // Fallback: старая коллекция может возвращать v1-документ с
        // `fetchE2eeSession` (без protocolVersion — тогда fetchE2eeSessionAny
        // уже сработал бы). Но на случай редчайших edge-кейсов:
        const legacy = await fetchE2eeSession(firestore, conversation.id, targetEpoch);
        if (!legacy) return null;
        const { privateKey } = await getOrCreateDeviceIdentity();
        try {
          const aes = await unwrapConversationChatKey(legacy, uid, privateKey);
          keyByEpochRef.current.set(cacheKeyV1, aes);
          return { key: aes, version: 'v1' };
        } catch (e) {
          console.warn('[e2ee] v1 unwrap failed', e);
          throw new Error('E2EE_UNWRAP_FAILED');
        }
      }
      if (any.version === 'v1') {
        const { privateKey } = await getOrCreateDeviceIdentity();
        try {
          const aes = await unwrapConversationChatKey(any.data, uid, privateKey);
          keyByEpochRef.current.set(cacheKeyV1, aes);
          return { key: aes, version: 'v1' };
        } catch (e) {
          console.warn('[e2ee] v1 unwrap failed', e);
          throw new Error('E2EE_UNWRAP_FAILED');
        }
      }
      // v2
      const identity = await getOrCreateDeviceIdentityV2();
      try {
        const aes = await unwrapChatKeyForMeV2(any.data, uid, identity, conversation.id);
        keyByEpochRef.current.set(cacheKeyV2, aes);
        return { key: aes, version: 'v2' };
      } catch (e) {
        console.warn('[e2ee] v2 unwrap failed', e);
        throw new Error('E2EE_UNWRAP_FAILED');
      }
    },
    [firestore, conversation?.id, uid]
  );

  /**
   * Legacy encrypt (v1): не требует messageId. Используется существующим
   * ChatWindow/ThreadWindow. Поведение не меняется.
   */
  const encryptOutgoingHtml = useCallback(
    async (html: string): Promise<ChatMessageE2eePayload> => {
      const pair = await getAesKeyForEpoch(e2eeEpoch);
      if (!pair) throw new Error('E2EE_NO_CHAT_KEY');
      const { iv, ciphertext } = await encryptUtf8WithAesGcm(pair.key, html);
      return {
        protocolVersion: E2EE_PROTOCOL_VERSION,
        epoch: e2eeEpoch,
        iv,
        ciphertext,
      };
    },
    [getAesKeyForEpoch, e2eeEpoch]
  );

  /**
   * v2 encrypt. Требует детерминистичный `messageId` (предварительно
   * зарезервированный `doc(...).id`) и `senderDeviceId` — оба идут в AAD.
   */
  const encryptOutgoingHtmlV2 = useCallback(
    async (
      html: string,
      opts: { messageId: string }
    ): Promise<ChatMessageE2eePayload> => {
      if (!conversation?.id) throw new Error('E2EE_NO_CONVERSATION');
      const pair = await getAesKeyForEpoch(e2eeEpoch);
      if (!pair) throw new Error('E2EE_NO_CHAT_KEY');
      if (pair.version !== 'v2') {
        throw new Error('E2EE_EPOCH_NOT_V2');
      }
      const identity = await getOrCreateDeviceIdentityV2();
      const { ivB64, ciphertextB64 } = await encryptUtf8WithAesGcmV2(pair.key, html, {
        conversationId: conversation.id,
        messageId: opts.messageId,
        epoch: e2eeEpoch,
      });
      return {
        protocolVersion: E2EE_V2_PROTOCOL,
        epoch: e2eeEpoch,
        iv: ivB64,
        ciphertext: ciphertextB64,
        senderDeviceId: identity.deviceId,
      };
    },
    [getAesKeyForEpoch, e2eeEpoch, conversation?.id]
  );

  /**
   * Расшифровывает payload любой версии. При ошибке возвращает пустую строку —
   * UI показывает плейсхолдер «Зашифрованное сообщение».
   */
  const decryptMessagePayload = useCallback(
    async (
      payload: ChatMessageE2eePayload,
      messageId?: string
    ): Promise<string> => {
      let pair: { key: CryptoKey; version: 'v1' | 'v2' } | null = null;
      try {
        pair = await getAesKeyForEpoch(payload.epoch);
      } catch {
        return '';
      }
      if (!pair) return '';
      try {
        if (payload.protocolVersion === E2EE_V2_PROTOCOL) {
          if (!conversation?.id || !messageId) return '';
          return await decryptUtf8WithAesGcmV2(
            pair.key,
            payload.iv,
            payload.ciphertext,
            {
              conversationId: conversation.id,
              messageId,
              epoch: payload.epoch,
            }
          );
        }
        return await decryptUtf8WithAesGcm(pair.key, payload.iv, payload.ciphertext);
      } catch {
        return '';
      }
    },
    [getAesKeyForEpoch, conversation?.id]
  );

  /**
   * Phase 7: доступ к сырым байтам ChatKey_epoch для HKDF media-wrap.
   * Возвращает `null`, если эпоха ещё v1 (media шифруется только на v2 сессиях).
   */
  const getChatKeyRawV2ForEpoch = useCallback(
    async (targetEpoch: number): Promise<ArrayBuffer | null> => {
      if (!firestore || !conversation?.id || !uid || targetEpoch < 1) return null;
      const cacheKey = `${conversation.id}:${targetEpoch}:v2-raw`;
      const hit = rawKeyByEpochRef.current.get(cacheKey);
      if (hit) return hit;
      const any = await fetchE2eeSessionAny(firestore, conversation.id, targetEpoch);
      if (!any || any.version !== 'v2') return null;
      const identity = await getOrCreateDeviceIdentityV2();
      const raw = await unwrapChatKeyRawForMeV2(any.data, uid, identity, conversation.id);
      rawKeyByEpochRef.current.set(cacheKey, raw);
      return raw;
    },
    [firestore, conversation?.id, uid]
  );

  return {
    e2eeEnabled,
    e2eeEpoch,
    e2eeIdentityReady: identityReady,
    encryptOutgoingHtml,
    encryptOutgoingHtmlV2,
    decryptMessagePayload,
    getChatKeyRawV2ForEpoch,
  };
}
