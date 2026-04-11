'use client';

import { useCallback, useMemo } from 'react';
import { deleteField, doc } from 'firebase/firestore';
import { useDoc, useFirestore, useMemoFirebase } from '@/firebase';
import { setDocumentNonBlocking, updateDocumentNonBlocking } from '@/firebase/non-blocking-updates';
import type { UserChatConversationPrefs } from '@/lib/types';

function defaultPrefs(conversationId: string): UserChatConversationPrefs {
  return { conversationId };
}

/**
 * Документ `users/{uid}/chatConversationPrefs/{conversationId}` (merge).
 */
export function useChatConversationPrefs(userId: string | undefined, conversationId: string | undefined) {
  const firestore = useFirestore();

  const prefsRef = useMemoFirebase(
    () =>
      firestore && userId && conversationId
        ? doc(firestore, 'users', userId, 'chatConversationPrefs', conversationId)
        : null,
    [firestore, userId, conversationId]
  );

  const { data, isLoading, error } = useDoc<UserChatConversationPrefs>(prefsRef);

  const prefs = useMemo((): UserChatConversationPrefs | null => {
    if (!conversationId) return null;
    return { ...defaultPrefs(conversationId), ...(data && data.conversationId === conversationId ? data : {}) };
  }, [conversationId, data]);

  const updatePrefs = useCallback(
    (patch: Partial<Omit<UserChatConversationPrefs, 'conversationId'>>) => {
      if (!firestore || !userId || !conversationId || !prefsRef) return;
      const now = new Date().toISOString();
      setDocumentNonBlocking(prefsRef, { conversationId, ...patch, updatedAt: now }, { merge: true });
    },
    [firestore, userId, conversationId, prefsRef]
  );

  const clearChatWallpaperOverride = useCallback(() => {
    if (!prefsRef || !data) return;
    updateDocumentNonBlocking(prefsRef, {
      chatWallpaper: deleteField(),
      updatedAt: new Date().toISOString(),
    });
  }, [prefsRef, data]);

  return {
    prefs,
    isLoading,
    error,
    updatePrefs,
    clearChatWallpaperOverride,
  };
}
