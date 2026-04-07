'use client';

import { useState, useEffect, useMemo } from 'react';
import {
  collection,
  query,
  where,
  documentId,
  onSnapshot,
  type Firestore,
} from 'firebase/firestore';
import type { Call } from '@/lib/types';
import { scheduleFirestoreListen } from '@/firebase/schedule-firestore-listen';

export type CallWithId = Call & { id: string };

const IN_QUERY_MAX = 30;

function chunkIds(ids: string[]): string[][] {
  const unique = [...new Set(ids.filter(Boolean))];
  const chunks: string[][] = [];
  for (let i = 0; i < unique.length; i += IN_QUERY_MAX) {
    chunks.push(unique.slice(i, i + IN_QUERY_MAX));
  }
  return chunks;
}

/**
 * Подписка на документы `calls` по списку id (батчи по 30 — лимит `in`).
 */
export function useCallsByDocumentIds(
  firestore: Firestore | null,
  callIds: string[]
): { data: CallWithId[] | null; isLoading: boolean } {
  const idsKey = useMemo(
    () => [...new Set(callIds)].filter(Boolean).sort().join('\0'),
    [callIds]
  );

  const [data, setData] = useState<CallWithId[] | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    if (!firestore) {
      setData(null);
      setIsLoading(false);
      return;
    }

    const rawIds = idsKey.length > 0 ? idsKey.split('\0') : [];
    const batches = chunkIds(rawIds);
    if (batches.length === 0) {
      setData([]);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    const perBatch = new Map<number, Map<string, CallWithId>>();
    const initialReceived = new Set<number>();

    const mergeAndPublish = () => {
      const merged = new Map<string, CallWithId>();
      for (let i = 0; i < batches.length; i++) {
        const part = perBatch.get(i);
        if (!part) continue;
        for (const [id, c] of part) merged.set(id, c);
      }
      setData([...merged.values()]);
    };

    return scheduleFirestoreListen(() => {
      const unsubs: Array<() => void> = [];
      batches.forEach((batch, index) => {
        const q = query(collection(firestore, 'calls'), where(documentId(), 'in', batch));
        unsubs.push(
          onSnapshot(
            q,
            (snap) => {
              const m = new Map<string, CallWithId>();
              snap.docs.forEach((d) => {
                m.set(d.id, { ...(d.data() as Call), id: d.id });
              });
              perBatch.set(index, m);
              mergeAndPublish();
              initialReceived.add(index);
              if (initialReceived.size >= batches.length) {
                setIsLoading(false);
              }
            },
            (err) => {
              console.error('[useCallsByDocumentIds] snapshot error', err);
              setIsLoading(false);
            }
          )
        );
      });
      return () => {
        unsubs.forEach((u) => {
          try {
            u();
          } catch (e) {
            console.warn('[useCallsByDocumentIds] unsubscribe', e);
          }
        });
      };
    });
  }, [firestore, idsKey]);

  return { data, isLoading };
}
