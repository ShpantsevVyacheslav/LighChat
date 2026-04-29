'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import { doc, getDoc, type Firestore } from 'firebase/firestore';
import type { ChatMessageE2eePayload, Conversation } from '@/lib/types';
import {
  E2EE_V2_PROTOCOL,
  decryptUtf8WithAesGcmV2,
  encryptUtf8WithAesGcmV2,
  fetchE2eeSessionAny,
  getOrCreateDeviceIdentityV2,
  publishE2eeDeviceV2,
  unwrapChatKeyForMeV2,
  unwrapChatKeyRawForMeV2,
  healSessionForCurrentDevicesV2,
  getCachedPlaintext,
  putCachedPlaintext,
} from '@/lib/e2ee';

const E2EE_UNWRAP_MISSING_CODES = new Set([
  'E2EE_NO_WRAP_FOR_DEVICE',
  'E2EE_NO_WRAP_FOR_USER',
]);

function normalizeE2eeErrorCode(error: unknown): string {
  if (typeof error === 'string') return error;
  if (error && typeof error === 'object' && 'code' in error) {
    const code = (error as { code?: unknown }).code;
    if (typeof code === 'string' && code.trim()) return code;
  }
  if (error && typeof error === 'object' && 'message' in error) {
    const message = (error as { message?: unknown }).message;
    if (typeof message === 'string' && message.trim()) return message;
  }
  return 'E2EE_UNKNOWN';
}

/**
 * E2EE hook — v2-only (post Phase 10 cleanup, см. Gap #5 в `04-runtime-flows.md`).
 *
 * - Identity: публикуется per-device v2 ключ `users/{uid}/e2eeDevices/{deviceId}`.
 * - Encrypt: `encryptOutgoingHtmlV2({ messageId })` — вызывающий
 *   должен предварительно зарезервировать `doc(...).id`. Self-heal включён
 *   внутрь `getAesKeyWithHealing` — если chat-key под текущий device отсутствует,
 *   эпоха ротируется.
 * - Decrypt: по `payload.protocolVersion === E2EE_V2_PROTOCOL`. Сообщения
 *   иной версии (если где-то остались в истории) возвращают пустую строку
 *   и UI показывает плейсхолдер «Зашифрованное сообщение».
 *
 * Legacy v1 полностью удалён — тестовых данных с v1 в проде нет. См.
 * git-log `removed: src/lib/e2ee/{enable-conversation,session-firestore,device-identity}.ts`.
 */
export function useE2eeConversation(
  firestore: Firestore | null,
  conversation: Conversation | null,
  currentUserId: string | undefined | null
) {
  const uid = currentUserId ?? null;
  /** Кэш расшифрованного ChatKey по строковому ключу `cid:epoch`. */
  const keyByEpochRef = useRef<Map<string, CryptoKey>>(new Map());
  /** Phase 7: сырые байты v2-chatKey для HKDF при media-wrap. */
  const rawKeyByEpochRef = useRef<Map<string, ArrayBuffer>>(new Map());
  /** Подавление шумных повторов unwrap-ошибок для одной и той же эпохи. */
  const unwrapFailureByEpochRef = useRef<Map<string, string>>(new Map());
  const [identityReady, setIdentityReady] = useState(false);

  const e2eeEnabled = !!(conversation?.e2eeEnabled && (conversation?.e2eeKeyEpoch ?? 0) > 0);
  const e2eeEpoch = conversation?.e2eeKeyEpoch ?? 0;

  useEffect(() => {
    keyByEpochRef.current.clear();
    rawKeyByEpochRef.current.clear();
    unwrapFailureByEpochRef.current.clear();
  }, [conversation?.id]);

  useEffect(() => {
    if (!firestore || !uid) return;
    let cancelled = false;
    (async () => {
      try {
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
   * Self-heal on mount. Раз в сессию чата (и при смене conversation/эпохи)
   * запускаем heal: если мой devices-set / чужой devices-set рассинхронизирован
   * с session-doc, тихо ротируем эпоху.
   *
   * Зависимости сериализованы (`conversation?.id`, сериализация participantIds)
   * чтобы реагировать на смысловые изменения, а не на референс каждого рендера.
   */
  const convId = conversation?.id ?? null;
  const participantsKey = (conversation?.participantIds ?? []).join('|');
  useEffect(() => {
    if (!firestore || !uid || !identityReady) return;
    if (!convId || !e2eeEnabled || !conversation) return;
    let cancelled = false;
    const snapshot = conversation;
    (async () => {
      try {
        const result = await healSessionForCurrentDevicesV2(
          firestore,
          snapshot,
          uid
        );
        if (!cancelled && result.healed) {
          keyByEpochRef.current.clear();
          rawKeyByEpochRef.current.clear();
          unwrapFailureByEpochRef.current.clear();
        }
      } catch (e) {
        console.warn('[e2ee] heal session skipped', e);
      }
    })();
    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [firestore, uid, identityReady, convId, e2eeEnabled, e2eeEpoch, participantsKey]);

  /**
   * Получает v2 chat-key для конкретной эпохи. Кэширует по `(cid, epoch)`.
   * Возвращает `null`, если session-doc нет или он не v2.
   */
  const getAesKeyForEpoch = useCallback(
    async (targetEpoch: number): Promise<CryptoKey | null> => {
      if (!firestore || !conversation?.id || !uid || targetEpoch < 1) return null;
      const cacheKey = `${conversation.id}:${targetEpoch}`;
      const hit = keyByEpochRef.current.get(cacheKey);
      if (hit) return hit;
      const unwrapFailure = unwrapFailureByEpochRef.current.get(cacheKey);
      if (unwrapFailure && E2EE_UNWRAP_MISSING_CODES.has(unwrapFailure)) {
        throw new Error(unwrapFailure);
      }

      const any = await fetchE2eeSessionAny(firestore, conversation.id, targetEpoch);
      if (!any || any.version !== 'v2') return null;
      const identity = await getOrCreateDeviceIdentityV2();
      try {
        const aes = await unwrapChatKeyForMeV2(any.data, uid, identity, conversation.id);
        keyByEpochRef.current.set(cacheKey, aes);
        unwrapFailureByEpochRef.current.delete(cacheKey);
        return aes;
      } catch (e) {
        const code = normalizeE2eeErrorCode(e);
        unwrapFailureByEpochRef.current.set(cacheKey, code);
        if (!E2EE_UNWRAP_MISSING_CODES.has(code)) {
          console.warn('[e2ee] v2 unwrap failed', e);
        }
        throw new Error(code);
      }
    },
    [firestore, conversation?.id, uid]
  );

  const getLatestConversationEpoch = useCallback(
    async (fallbackEpoch: number): Promise<number> => {
      if (!firestore || !conversation?.id) return fallbackEpoch;
      try {
        const snap = await getDoc(doc(firestore, 'conversations', conversation.id));
        if (!snap.exists()) return fallbackEpoch;
        const raw = snap.data()?.e2eeKeyEpoch;
        const parsed = typeof raw === 'number' ? raw : 0;
        return parsed > 0 ? parsed : fallbackEpoch;
      } catch {
        return fallbackEpoch;
      }
    },
    [firestore, conversation?.id]
  );

  /**
   * Пробует получить ключ для эпохи, при ошибке unwrap делает один heal-круг:
   * триггерит ротацию эпохи и перечитывает актуальный `e2eeKeyEpoch` с
   * Firestore, после чего повторяет getAesKeyForEpoch.
   *
   * Защищает от гонки "send до того, как mount-heal успел ротировать":
   * пользователь зашёл в чат и сразу отправил — heal из useEffect ещё не
   * завершился, ключ unwrap не получается. Эта функция закроет и этот кейс.
   */
  const getAesKeyWithHealing = useCallback(
    async (): Promise<{ key: CryptoKey; epoch: number } | null> => {
      if (!firestore || !conversation || !uid) return null;
      try {
        const key = await getAesKeyForEpoch(e2eeEpoch);
        if (key) return { key, epoch: e2eeEpoch };
      } catch {
        /* проваливаемся в heal-ветку ниже */
      }
      try {
        const result = await healSessionForCurrentDevicesV2(
          firestore,
          conversation,
          uid
        );
        const latestEpoch = await getLatestConversationEpoch(e2eeEpoch);
        const targetEpoch = result.healed ? result.newEpoch : latestEpoch;
        keyByEpochRef.current.clear();
        rawKeyByEpochRef.current.clear();
        unwrapFailureByEpochRef.current.clear();
        const key = await getAesKeyForEpoch(targetEpoch);
        if (!key) return null;
        return { key, epoch: targetEpoch };
      } catch (e) {
        console.warn('[e2ee] getAesKeyWithHealing failed', e);
        return null;
      }
    },
    [firestore, conversation, uid, e2eeEpoch, getAesKeyForEpoch, getLatestConversationEpoch]
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
      const pair = await getAesKeyWithHealing();
      if (!pair) throw new Error('E2EE_NO_CHAT_KEY');
      const identity = await getOrCreateDeviceIdentityV2();
      const { ivB64, ciphertextB64 } = await encryptUtf8WithAesGcmV2(pair.key, html, {
        conversationId: conversation.id,
        messageId: opts.messageId,
        epoch: pair.epoch,
      });
      return {
        protocolVersion: E2EE_V2_PROTOCOL,
        epoch: pair.epoch,
        iv: ivB64,
        ciphertext: ciphertextB64,
        senderDeviceId: identity.deviceId,
      };
    },
    [getAesKeyWithHealing, conversation?.id]
  );

  /**
   * Расшифровывает v2-payload. При ошибке (старая v1-запись в истории,
   * отсутствие ключа, повреждённые байты) возвращает пустую строку —
   * UI покажет плейсхолдер.
   */
  const decryptMessagePayload = useCallback(
    async (
      payload: ChatMessageE2eePayload,
      messageId?: string
    ): Promise<string> => {
      if (payload.protocolVersion !== E2EE_V2_PROTOCOL) return '';
      if (!conversation?.id || !messageId) return '';
      // Persistent cache hit: skip keystore + AES-GCM полностью.
      try {
        const cached = await getCachedPlaintext(conversation.id, messageId);
        if (typeof cached === 'string') return cached;
      } catch {
        // ignore, fallthrough to live decrypt
      }
      let key: CryptoKey | null = null;
      try {
        key = await getAesKeyForEpoch(payload.epoch);
      } catch {
        return '';
      }
      if (!key) return '';
      try {
        const plaintext = await decryptUtf8WithAesGcmV2(
          key,
          payload.iv,
          payload.ciphertext,
          {
            conversationId: conversation.id,
            messageId,
            epoch: payload.epoch,
          }
        );
        // Сохраняем plaintext в persistent cache. Пустая строка — валидный
        // результат для media-only E2EE сообщений, тоже кешируем, чтобы
        // повторно не гнать через AES.
        void putCachedPlaintext(conversation.id, messageId, plaintext);
        return plaintext;
      } catch {
        return '';
      }
    },
    [getAesKeyForEpoch, conversation?.id]
  );

  /**
   * Phase 7: доступ к сырым байтам ChatKey_epoch для HKDF media-wrap.
   * Возвращает `null`, если session-doc нет или не v2.
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
    encryptOutgoingHtmlV2,
    decryptMessagePayload,
    getChatKeyRawV2ForEpoch,
  };
}
