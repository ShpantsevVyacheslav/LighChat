'use client';

import { useMemo } from 'react';
import { doc } from 'firebase/firestore';

import { useDoc, useFirestore, useMemoFirebase } from '@/firebase';
import type { SecretChatAccessGrantDoc } from '@/lib/types';

type UseSecretChatAccessActiveArgs = {
  conversationId: string;
  userId: string;
  enabled?: boolean;
};

function toMillis(value: unknown): number | null {
  if (!value) return null;
  if (typeof value === 'string') {
    const ms = Date.parse(value);
    return Number.isFinite(ms) ? ms : null;
  }
  if (typeof value === 'object' && value) {
    if ('toMillis' in value && typeof (value as { toMillis?: unknown }).toMillis === 'function') {
      try {
        const out = (value as { toMillis: () => number }).toMillis();
        return Number.isFinite(out) ? out : null;
      } catch {
        return null;
      }
    }
    if ('seconds' in value) {
      const seconds = Number((value as { seconds?: unknown }).seconds ?? 0);
      if (Number.isFinite(seconds)) return seconds * 1000;
    }
  }
  return null;
}

export function useSecretChatAccessActive({
  conversationId,
  userId,
  enabled = true,
}: UseSecretChatAccessActiveArgs) {
  const firestore = useFirestore();
  const grantRef = useMemoFirebase(
    () =>
      firestore && enabled && conversationId && userId
        ? doc(firestore, 'conversations', conversationId, 'secretAccess', userId)
        : null,
    [firestore, enabled, conversationId, userId]
  );

  const { data, isLoading, error } = useDoc<SecretChatAccessGrantDoc>(grantRef);

  const isActive = useMemo(() => {
    if (!enabled) return true;
    if (!data) return false;
    const ms = toMillis((data as Record<string, unknown>).expiresAtTs ?? data.expiresAt);
    if (ms == null) return false;
    return ms > Date.now();
  }, [enabled, data]);

  return { isActive, isLoading, error, grant: data };
}
