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
import type { User } from '@/lib/types';
import { scheduleFirestoreListen } from '@/firebase/schedule-firestore-listen';
import { logger } from '@/lib/logger';

export type UserWithId = User & { id: string };

/** Лимит оператора `in` в Firestore (актуальные версии SDK). */
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
 * Реалтайм-подписка только на документы `users` с указанными id.
 * Не подписывается на всю коллекцию — избегает тяжёлых слушателей и сбоев SDK вроде
 * «INTERNAL ASSERTION FAILED: Unexpected state» в WatchChangeAggregator (плюс отложенный subscribe).
 */
export function useUsersByDocumentIds(
  firestore: Firestore | null,
  documentIds: string[]
): { usersById: ReadonlyMap<string, UserWithId>; isLoading: boolean } {
  const idsKey = useMemo(
    () => [...new Set(documentIds)].filter(Boolean).sort().join('\0'),
    [documentIds]
  );

  const [usersById, setUsersById] = useState<Map<string, UserWithId>>(() => new Map());
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    if (!firestore) {
      setUsersById(new Map());
      setIsLoading(false);
      return;
    }

    const rawIds = idsKey.length > 0 ? idsKey.split('\0') : [];
    const batches = chunkIds(rawIds);
    if (batches.length === 0) {
      setUsersById(new Map());
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    const perBatch = new Map<number, Map<string, UserWithId>>();
    const initialReceived = new Set<number>();

    const mergeAndPublish = () => {
      const merged = new Map<string, UserWithId>();
      for (let i = 0; i < batches.length; i++) {
        const part = perBatch.get(i);
        if (!part) continue;
        for (const [id, u] of part) merged.set(id, u);
      }
      setUsersById(new Map(merged));
    };

    return scheduleFirestoreListen(() => {
      const unsubs: Array<() => void> = [];
      batches.forEach((batch, index) => {
        const q = query(collection(firestore, 'users'), where(documentId(), 'in', batch));
        unsubs.push(
          onSnapshot(
            q,
            (snap) => {
              const m = new Map<string, UserWithId>();
              snap.docs.forEach((d) => {
                m.set(d.id, { ...(d.data() as User), id: d.id });
              });
              perBatch.set(index, m);
              mergeAndPublish();
              initialReceived.add(index);
              if (initialReceived.size >= batches.length) {
                setIsLoading(false);
              }
            },
            (err) => {
              logger.error('users-by-ids', 'snapshot error', err);
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
            logger.warn('users-by-ids', 'unsubscribe', e);
          }
        });
      };
    });
  }, [firestore, idsKey]);

  return { usersById, isLoading };
}
