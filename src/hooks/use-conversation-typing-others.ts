'use client';

import { useState, useEffect } from 'react';
import { collection, onSnapshot, type Firestore } from 'firebase/firestore';
import { scheduleFirestoreListen } from '@/firebase/schedule-firestore-listen';

/** Считаем «печатает» устаревшим, если нет heartbeat дольше этого времени (мс). */
const TYPING_STALE_MS = 8000;

/**
 * Подписка на `conversations/{id}/typing`: кто-то кроме текущего пользователя недавно обновил свой документ.
 */
export function useConversationTypingOthers(
  firestore: Firestore | null,
  conversationId: string | undefined,
  currentUserId: string | undefined,
  enabled: boolean = true
): boolean {
  const [othersTyping, setOthersTyping] = useState(false);

  useEffect(() => {
    if (!enabled || !firestore || !conversationId || !currentUserId) {
      setOthersTyping(false);
      return;
    }

    const col = collection(firestore, 'conversations', conversationId, 'typing');
    return scheduleFirestoreListen(() =>
      onSnapshot(
        col,
        (snap) => {
          const now = Date.now();
          let any = false;
          snap.forEach((d) => {
            if (d.id === currentUserId) return;
            const at = d.data()?.at;
            if (typeof at === 'string') {
              const t = new Date(at).getTime();
              if (!Number.isNaN(t) && now - t < TYPING_STALE_MS) any = true;
            }
          });
          setOthersTyping(any);
        },
        () => setOthersTyping(false)
      )
    );
  }, [enabled, firestore, conversationId, currentUserId]);

  return othersTyping;
}
