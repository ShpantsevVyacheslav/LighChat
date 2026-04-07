'use client';

import { useState, useEffect, useMemo } from 'react';
import { doc, onSnapshot, type Firestore, type FirestoreError } from 'firebase/firestore';
import type { Conversation } from '@/lib/types';
import { scheduleFirestoreListen } from '@/firebase/schedule-firestore-listen';

export type ConversationWithId = Conversation & { id: string };

function sortedUniqueIds(ids: string[]): string[] {
  return [...new Set(ids.filter(Boolean))].sort();
}

/**
 * Подписка на документы `conversations` по id из `userChats/{uid}.conversationIds`.
 * По одному `onSnapshot(doc(...))` на id — обходит отказ правил на list-query (`array-contains` / `documentId in`).
 */
export function useConversationsByDocumentIds(
  firestore: Firestore | null,
  conversationIds: string[]
): { data: ConversationWithId[] | null; isLoading: boolean } {
  const idsKey = useMemo(() => sortedUniqueIds(conversationIds).join('\0'), [conversationIds]);

  const [data, setData] = useState<ConversationWithId[] | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    if (!firestore) {
      setData(null);
      setIsLoading(false);
      return;
    }

    const rawIds = idsKey.length > 0 ? idsKey.split('\0') : [];
    if (rawIds.length === 0) {
      setData([]);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    const byId = new Map<string, ConversationWithId>();
    const firstEventPerId = new Set<string>();

    const mergeAndPublish = () => {
      const ordered = rawIds.map((id) => byId.get(id)).filter((c): c is ConversationWithId => !!c);
      setData(ordered);
    };

    const markInitialEvent = (id: string) => {
      if (firstEventPerId.has(id)) return;
      firstEventPerId.add(id);
      if (firstEventPerId.size >= rawIds.length) {
        setIsLoading(false);
      }
    };

    return scheduleFirestoreListen(() => {
      const unsubs = rawIds.map((id) => {
        const ref = doc(firestore, 'conversations', id);
        return onSnapshot(
          ref,
          (snap) => {
            markInitialEvent(id);
            if (snap.exists()) {
              byId.set(id, { ...(snap.data() as Conversation), id });
            } else {
              byId.delete(id);
            }
            mergeAndPublish();
          },
          (err: FirestoreError) => {
            markInitialEvent(id);
            // После удаления чата или отзыва доступа документ недоступен — Firestore отдаёт permission-denied
            // вместо «not exists»; это ожидаемо, не спамим консоль и support-debug.
            if (err.code === 'permission-denied') {
              if (process.env.NODE_ENV === 'development') {
                console.debug(
                  '[useConversationsByDocumentIds] conversation no longer readable, dropping from list:',
                  id
                );
              }
            } else {
              console.error('[useConversationsByDocumentIds] snapshot error', err);
            }
            byId.delete(id);
            mergeAndPublish();
          }
        );
      });
      return () => {
        unsubs.forEach((u) => {
          try {
            u();
          } catch (e) {
            console.warn('[useConversationsByDocumentIds] unsubscribe', e);
          }
        });
      };
    });
  }, [firestore, idsKey]);

  return { data, isLoading };
}
