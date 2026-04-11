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

/**
 * Ключи чата по эпохам, публикация identity, шифрование/дешифрование для текущего conversation.
 */
export function useE2eeConversation(
  firestore: Firestore | null,
  conversation: Conversation | null,
  currentUserId: string | undefined | null
) {
  const uid = currentUserId ?? null;
  const keyByEpochRef = useRef<Map<string, CryptoKey>>(new Map());
  const [identityReady, setIdentityReady] = useState(false);

  const e2eeEnabled = !!(conversation?.e2eeEnabled && (conversation?.e2eeKeyEpoch ?? 0) > 0);
  const e2eeEpoch = conversation?.e2eeKeyEpoch ?? 0;

  useEffect(() => {
    keyByEpochRef.current.clear();
  }, [conversation?.id]);

  useEffect(() => {
    if (!firestore || !uid) return;
    let cancelled = false;
    (async () => {
      try {
        const { privateKey: _p, publicKeySpkiB64 } = await getOrCreateDeviceIdentity();
        await publishE2eePublicKey(firestore, uid, publicKeySpkiB64);
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

  const getAesKeyForEpoch = useCallback(
    async (targetEpoch: number): Promise<CryptoKey | null> => {
      if (!firestore || !conversation?.id || !uid || targetEpoch < 1) return null;
      const cacheKey = `${conversation.id}:${targetEpoch}`;
      const hit = keyByEpochRef.current.get(cacheKey);
      if (hit) return hit;
      const session = await fetchE2eeSession(firestore, conversation.id, targetEpoch);
      if (!session) return null;
      const { privateKey } = await getOrCreateDeviceIdentity();
      try {
        const aes = await unwrapConversationChatKey(session, uid, privateKey);
        keyByEpochRef.current.set(cacheKey, aes);
        return aes;
      } catch (e) {
        console.warn('[e2ee] unwrap failed', e);
        /**
         * Обычно означает, что этот браузер/устройство не соответствует ключу,
         * под который создавалась эпоха (вход с другого устройства, очистка IndexedDB).
         */
        throw new Error('E2EE_UNWRAP_FAILED');
      }
    },
    [firestore, conversation?.id, uid]
  );

  const encryptOutgoingHtml = useCallback(
    async (html: string): Promise<ChatMessageE2eePayload> => {
      const k = await getAesKeyForEpoch(e2eeEpoch);
      if (!k) throw new Error('E2EE_NO_CHAT_KEY');
      const { iv, ciphertext } = await encryptUtf8WithAesGcm(k, html);
      return {
        protocolVersion: E2EE_PROTOCOL_VERSION,
        epoch: e2eeEpoch,
        iv,
        ciphertext,
      };
    },
    [getAesKeyForEpoch, e2eeEpoch]
  );

  const decryptMessagePayload = useCallback(
    async (payload: ChatMessageE2eePayload): Promise<string> => {
      let k: CryptoKey | null = null;
      try {
        k = await getAesKeyForEpoch(payload.epoch);
      } catch {
        return '';
      }
      if (!k) return '';
      try {
        return await decryptUtf8WithAesGcm(k, payload.iv, payload.ciphertext);
      } catch {
        return '';
      }
    },
    [getAesKeyForEpoch]
  );

  return {
    e2eeEnabled,
    e2eeEpoch,
    e2eeIdentityReady: identityReady,
    encryptOutgoingHtml,
    decryptMessagePayload,
  };
}
