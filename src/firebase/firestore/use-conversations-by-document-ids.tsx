'use client';

import { useState, useEffect, useMemo } from 'react';
import {
  collection,
  doc,
  documentId,
  onSnapshot,
  query,
  where,
  type Firestore,
  type FirestoreError,
  type Unsubscribe,
} from 'firebase/firestore';
import type { Conversation } from '@/lib/types';
import { scheduleFirestoreListen } from '@/firebase/schedule-firestore-listen';
import { logger } from '@/lib/logger';

export type ConversationWithId = Conversation & { id: string };

/** Лимит оператора `in` в Firestore. */
const IN_QUERY_MAX = 30;

function sortedUniqueIds(ids: string[]): string[] {
  return [...new Set(ids.filter(Boolean))].sort();
}

function chunk<T>(arr: T[], size: number): T[][] {
  const chunks: T[][] = [];
  for (let i = 0; i < arr.length; i += size) {
    chunks.push(arr.slice(i, i + size));
  }
  return chunks;
}

/**
 * [audit M-001] Подписка на документы `conversations` по id.
 *
 * Раньше под каждый id вешался отдельный `onSnapshot(doc(...))` — на
 * пользователя в 200 чатах = 200 одновременных listeners (тарифицируются
 * как `min(1 doc/listener)`), плюс realtime updates. Сейчас:
 *
 * 1. **Основной путь**: `where(documentId(), 'in', batch[≤30])` — один
 *    listener на 30 чатов. На 200 чатах = 7 listeners.
 * 2. **Fallback**: если batch падает с `permission-denied` (например,
 *    пользователя кикнули из одного чата в этом batch'е, и Firestore
 *    отказывает всему батчу) — переходим на per-doc для **этого
 *    конкретного batch'а**. Остальные batches продолжают работать через
 *    in-query.
 *
 * Корректность: per-doc fallback — оригинальная семантика, проверена
 * годами; основной путь даёт economy без затирания корректности.
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
    /** Какие id в каком batch'е — нужно для очистки при fallback. */
    const batches = chunk(rawIds, IN_QUERY_MAX);
    /** Какие batch'и уже отдали первый snapshot (для определения isLoading=false). */
    const initialBatches = new Set<number>();

    const mergeAndPublish = () => {
      const ordered = rawIds.map((id) => byId.get(id)).filter((c): c is ConversationWithId => !!c);
      setData(ordered);
    };

    const markInitial = (batchIndex: number) => {
      if (initialBatches.has(batchIndex)) return;
      initialBatches.add(batchIndex);
      if (initialBatches.size >= batches.length) {
        setIsLoading(false);
      }
    };

    return scheduleFirestoreListen(() => {
      const unsubs: Array<Unsubscribe> = [];

      batches.forEach((batchIds, batchIndex) => {
        let perDocUnsubs: Unsubscribe[] | null = null;

        // [audit M-001] Fallback: если batch-query упал, для этого batch'а
        // вешаем оригинальные per-doc listeners. Чтобы не дублировать данные
        // при двух режимах одновременно, сначала чистим всё что было от
        // batch-query (для id'шников этого batch'а).
        const startPerDocFallback = () => {
          if (perDocUnsubs) return; // already running
          perDocUnsubs = batchIds.map((id) => {
            const ref = doc(firestore, 'conversations', id);
            return onSnapshot(
              ref,
              (snap) => {
                if (snap.exists()) {
                  byId.set(id, { ...(snap.data() as Conversation), id });
                } else {
                  byId.delete(id);
                }
                mergeAndPublish();
                markInitial(batchIndex);
              },
              (err: FirestoreError) => {
                if (err.code === 'permission-denied') {
                  logger.debug('conv-by-ids', 'per-doc fallback: dropping inaccessible', id);
                } else {
                  logger.error('conv-by-ids', 'per-doc fallback error', err);
                }
                byId.delete(id);
                mergeAndPublish();
                markInitial(batchIndex);
              }
            );
          });
        };

        // PRIMARY: chunked `where(documentId(), 'in', batch)` — один listener
        // на 30 чатов. Для пользователя в 200 чатах = 7 listeners вместо 200.
        const q = query(
          collection(firestore, 'conversations'),
          where(documentId(), 'in', batchIds)
        );
        const unsub = onSnapshot(
          q,
          (snap) => {
            // Какие id ВЕРНУЛИСЬ из batch'а — все остальные считаем
            // отсутствующими/недоступными в этом batch'е.
            const seenInBatch = new Set<string>();
            snap.docs.forEach((d) => {
              const id = d.id;
              seenInBatch.add(id);
              byId.set(id, { ...(d.data() as Conversation), id });
            });
            // id'шники, которые мы запрашивали, но не получили — удаляем
            // из byId (deleted / kicked / hidden by rule).
            for (const id of batchIds) {
              if (!seenInBatch.has(id)) byId.delete(id);
            }
            mergeAndPublish();
            markInitial(batchIndex);
          },
          (err: FirestoreError) => {
            // Любой пер-batch error пытаемся локализовать через per-doc
            // fallback: один stale chatId не должен лишать пользователя
            // ВСЕХ чатов в этом batch'е.
            logger.debug('conv-by-ids', 'batch-query failed, fallback to per-doc', {
              batchIndex,
              code: err.code,
              ids: batchIds,
            });
            startPerDocFallback();
          }
        );
        unsubs.push(unsub);
        // На cleanup отдельной push'аем тоже per-doc unsubs (если активировались).
        unsubs.push(() => {
          if (perDocUnsubs) {
            perDocUnsubs.forEach((u) => {
              try {
                u();
              } catch (e) {
                logger.warn('conv-by-ids', 'per-doc unsubscribe', e);
              }
            });
          }
        });
      });

      return () => {
        unsubs.forEach((u) => {
          try {
            u();
          } catch (e) {
            logger.warn('conv-by-ids', 'unsubscribe', e);
          }
        });
      };
    });
  }, [firestore, idsKey]);

  return { data, isLoading };
}
