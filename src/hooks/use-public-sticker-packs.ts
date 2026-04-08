'use client';

import { useCallback, useEffect, useState } from 'react';
import { collection, orderBy, query } from 'firebase/firestore';

import { useCollection, useFirestore, useMemoFirebase } from '@/firebase';
import type { PublicStickerItemDoc, PublicStickerPackDoc } from '@/lib/public-sticker-packs';

/**
 * Подписка на общие стикерпаки (`publicStickerPacks`) и стикеры выбранного пака.
 * Только чтение; создавать/менять паки может админ (консоль, скрипт Admin SDK).
 */
export function usePublicStickerPacks() {
  const firestore = useFirestore();

  const packsQuery = useMemoFirebase(() => {
    if (!firestore) return null;
    return query(collection(firestore, 'publicStickerPacks'), orderBy('sortOrder', 'asc'));
  }, [firestore]);

  const { data: packs, isLoading: packsLoading, error: packsError } = useCollection<PublicStickerPackDoc>(packsQuery);

  const [selectedPackId, setSelectedPackId] = useState<string | null>(null);

  useEffect(() => {
    if (!packs?.length) {
      setSelectedPackId(null);
      return;
    }
    setSelectedPackId((prev) => {
      if (prev && packs.some((p) => p.id === prev)) return prev;
      return packs[0].id;
    });
  }, [packs]);

  const itemsQuery = useMemoFirebase(() => {
    if (!firestore || !selectedPackId) return null;
    return query(
      collection(firestore, 'publicStickerPacks', selectedPackId, 'items'),
      orderBy('createdAt', 'asc')
    );
  }, [firestore, selectedPackId]);

  const { data: items, isLoading: itemsLoading, error: itemsError } = useCollection<PublicStickerItemDoc>(itemsQuery);

  const selectedPack = packs?.find((p) => p.id === selectedPackId);

  const setSelectedPackIdStable = useCallback((id: string | null) => {
    setSelectedPackId(id);
  }, []);

  return {
    packs,
    items,
    packsLoading,
    itemsLoading,
    packsError,
    itemsError,
    selectedPackId,
    setSelectedPackId: setSelectedPackIdStable,
    selectedPack,
  };
}
