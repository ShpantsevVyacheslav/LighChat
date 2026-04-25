'use client';

import { doc } from 'firebase/firestore';
import { useMemo, useCallback } from 'react';

import { useDoc, useFirestore, useMemoFirebase } from '@/firebase';
import { resolveContactDisplayName } from '@/lib/contact-display-name';
import type { UserContactsIndex } from '@/lib/types';

export function useContactDisplayNames(ownerId: string | null | undefined) {
  const firestore = useFirestore();
  const ref = useMemoFirebase(
    () => (firestore && ownerId ? doc(firestore, 'userContacts', ownerId) : null),
    [firestore, ownerId]
  );
  const { data, isLoading, error } = useDoc<UserContactsIndex>(ref);

  const contactIds = useMemo(() => data?.contactIds ?? [], [data?.contactIds]);
  const contactProfiles = useMemo(
    () => data?.contactProfiles ?? {},
    [data?.contactProfiles]
  );

  const resolveName = useCallback(
    (contactUserId: string | null | undefined, fallbackName: string) =>
      resolveContactDisplayName(contactProfiles, contactUserId, fallbackName),
    [contactProfiles]
  );

  return {
    contactIds,
    contactProfiles,
    resolveName,
    isLoading,
    error,
  };
}
