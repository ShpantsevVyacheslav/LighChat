'use client';

import { doc } from 'firebase/firestore';
import { Loader2 } from 'lucide-react';
import { useParams } from 'next/navigation';
import { useMemo } from 'react';

import { DurakWebGameDialog } from '@/components/chat/games/durak/DurakWebGameDialog';
import { useAuth } from '@/hooks/use-auth';
import {
  useDoc,
  useFirestore,
  useMemoFirebase,
  useUser as useFirebaseAuthUser,
  useUsersByDocumentIds,
} from '@/firebase';
import type { User } from '@/lib/types';

export default function StandaloneDurakPage() {
  const params = useParams();
  const gameId = typeof params.gameId === 'string' ? params.gameId : '';
  const { user } = useAuth();
  const { user: firebaseUser } = useFirebaseAuthUser();
  const firestore = useFirestore();

  const gameRef = useMemoFirebase(
    () => (firestore && firebaseUser && gameId ? doc(firestore, 'games', gameId) : null),
    [firestore, firebaseUser, gameId]
  );
  const { data: game } = useDoc<{ playerIds?: string[] }>(gameRef);

  const userIds = useMemo(() => {
    const ids = new Set<string>(game?.playerIds ?? []);
    if (firebaseUser?.uid) ids.add(firebaseUser.uid);
    return [...ids];
  }, [game?.playerIds, firebaseUser?.uid]);
  const { usersById } = useUsersByDocumentIds(firestore, userIds);
  const allUsers = useMemo(() => [...usersById.values()] as User[], [usersById]);

  const currentUser =
    user && firebaseUser && user.id !== firebaseUser.uid ? { ...user, id: firebaseUser.uid } : user;
  if (!currentUser) {
    return (
      <main className="flex h-[100dvh] w-[100dvw] items-center justify-center bg-[#263d4d] text-white">
        <Loader2 className="h-8 w-8 animate-spin" />
      </main>
    );
  }
  return (
    <DurakWebGameDialog
      standalone
      open
      onOpenChange={(v) => {
        if (!v && typeof window !== 'undefined') window.close();
      }}
      gameId={gameId}
      currentUser={currentUser}
      allUsers={allUsers}
    />
  );
}
