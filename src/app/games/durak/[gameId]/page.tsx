'use client';

import { collection } from 'firebase/firestore';
import { Loader2 } from 'lucide-react';
import { useParams } from 'next/navigation';

import { DurakWebGameDialog } from '@/components/chat/games/durak/DurakWebGameDialog';
import { useAuth } from '@/hooks/use-auth';
import { useCollection, useFirestore, useMemoFirebase, useUser as useFirebaseAuthUser } from '@/firebase';
import type { User } from '@/lib/types';

export default function StandaloneDurakPage() {
  const params = useParams();
  const gameId = typeof params.gameId === 'string' ? params.gameId : '';
  const { user } = useAuth();
  const { user: firebaseUser } = useFirebaseAuthUser();
  const firestore = useFirestore();
  const { data: usersData } = useCollection<User>(
    useMemoFirebase(
      () => (firestore && firebaseUser ? collection(firestore, 'users') : null),
      [firestore, firebaseUser]
    )
  );
  const currentUser = user && firebaseUser && user.id !== firebaseUser.uid ? { ...user, id: firebaseUser.uid } : user;
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
      allUsers={usersData ?? []}
    />
  );
}
