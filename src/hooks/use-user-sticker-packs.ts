'use client';

import { useCallback, useEffect, useState } from 'react';
import { addDoc, collection, doc, orderBy, query, updateDoc } from 'firebase/firestore';
import type { Firestore } from 'firebase/firestore';
import type { FirebaseStorage } from 'firebase/storage';

import { useCollection, useFirestore, useMemoFirebase, useStorage } from '@/firebase';
import { deleteDocumentNonBlocking } from '@/firebase/non-blocking-updates';
import {
  addImageFilesToUserStickerPack,
  createUserStickerPack,
  deleteUserStickerPack,
} from '@/lib/user-sticker-packs-client';
import type { UserStickerItemDoc, UserStickerPackDoc } from '@/lib/user-sticker-packs';

type PackRow = UserStickerPackDoc & { id: string };
type ItemRow = UserStickerItemDoc & { id: string };

/**
 * Подписка на стикерпаки пользователя и стикеры выбранного пака.
 * Запись в `users/{uid}/stickerPacks` и Storage `users/{uid}/sticker-packs/{packId}/…`.
 */
export function useUserStickerPacks(userId: string | undefined) {
  const firestore = useFirestore();
  const storage = useStorage();

  const packsQuery = useMemoFirebase(() => {
    if (!firestore || !userId) return null;
    return query(collection(firestore, 'users', userId, 'stickerPacks'), orderBy('updatedAt', 'desc'));
  }, [firestore, userId]);

  const { data: packs, isLoading: packsLoading, error: packsError } = useCollection<UserStickerPackDoc>(packsQuery);

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
    if (!firestore || !userId || !selectedPackId) return null;
    return query(
      collection(firestore, 'users', userId, 'stickerPacks', selectedPackId, 'items'),
      orderBy('createdAt', 'asc')
    );
  }, [firestore, userId, selectedPackId]);

  const { data: items, isLoading: itemsLoading, error: itemsError } = useCollection<UserStickerItemDoc>(itemsQuery);

  const createPack = useCallback(
    async (rawName: string): Promise<string | null> => {
      if (!firestore || !userId) return null;
      const id = await createUserStickerPack(firestore, userId, rawName);
      if (id) console.info('[LighChat:stickers] pack created', { packId: id, userId });
      return id;
    },
    [firestore, userId]
  );

  const duplicateCurrentPack = useCallback(
    async (sourcePack: PackRow | undefined, sourceItems: ItemRow[] | null | undefined): Promise<string | null> => {
      if (!firestore || !userId || !sourcePack) return null;
      const newPackId = await createPack(`Копия: ${sourcePack.name}`);
      if (!newPackId || !sourceItems?.length) {
        if (newPackId) setSelectedPackId(newPackId);
        return newPackId;
      }
      const itemsCol = collection(firestore, 'users', userId, 'stickerPacks', newPackId, 'items');
      const nowBase = Date.now();
      for (let i = 0; i < sourceItems.length; i++) {
        const it = sourceItems[i];
        await addDoc(itemsCol, {
          downloadUrl: it.downloadUrl,
          storagePath: it.storagePath,
          contentType: it.contentType,
          size: it.size,
          ...(it.width && it.height ? { width: it.width, height: it.height } : {}),
          createdAt: new Date(nowBase + i).toISOString(),
        });
      }
      const now = new Date().toISOString();
      await updateDoc(doc(firestore, 'users', userId, 'stickerPacks', newPackId), { updatedAt: now });
      setSelectedPackId(newPackId);
      console.info('[LighChat:stickers] pack duplicated', { from: sourcePack.id, to: newPackId });
      return newPackId;
    },
    [createPack, firestore, userId]
  );

  const addFilesToPack = useCallback(
    async (packId: string, files: File[], fs: Firestore, st: FirebaseStorage): Promise<{ ok: number; skipped: number; errors: string[] }> => {
      if (!userId) return { ok: 0, skipped: files.length, errors: ['no_user'] };
      return addImageFilesToUserStickerPack(packId, files, userId, fs, st);
    },
    [userId]
  );

  const deleteItem = useCallback(
    (packId: string, itemId: string) => {
      if (!firestore || !userId) return;
      const itemRef = doc(firestore, 'users', userId, 'stickerPacks', packId, 'items', itemId);
      deleteDocumentNonBlocking(itemRef);
      const now = new Date().toISOString();
      updateDoc(doc(firestore, 'users', userId, 'stickerPacks', packId), { updatedAt: now }).catch(() => {});
      console.info('[LighChat:stickers] item delete requested', { packId, itemId });
    },
    [firestore, userId]
  );

  const deletePack = useCallback(
    async (packId: string): Promise<boolean> => {
      if (!firestore || !userId || !storage) return false;
      const res = await deleteUserStickerPack(firestore, storage, userId, packId);
      return res.ok;
    },
    [firestore, storage, userId]
  );

  const selectedPack = packs?.find((p) => p.id === selectedPackId);

  return {
    firestore,
    storage,
    packs: packs ?? null,
    items: items ?? null,
    packsLoading,
    itemsLoading,
    packsError,
    itemsError,
    selectedPackId,
    setSelectedPackId,
    selectedPack,
    createPack,
    duplicateCurrentPack,
    addFilesToPack,
    deleteItem,
    deletePack,
  };
}
