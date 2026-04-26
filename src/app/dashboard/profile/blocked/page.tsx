'use client';

import { Loader2 } from 'lucide-react';
import { useAuth } from '@/hooks/use-auth';
import { useUser as useFirebaseAuthUser } from '@/firebase';
import { BlockedUsersPageClient } from '@/components/profile/BlockedUsersPageClient';

export default function ProfileBlockedPage() {
  const { user, isLoading } = useAuth();
  const { user: firebaseAuthUser } = useFirebaseAuthUser();
  const authUid = firebaseAuthUser?.uid ?? user?.id ?? null;

  if (isLoading || !user || !authUid) {
    return (
      <div className="flex min-h-[40vh] items-center justify-center text-muted-foreground">
        <Loader2 className="h-8 w-8 animate-spin" aria-hidden />
      </div>
    );
  }

  return <BlockedUsersPageClient currentUserId={authUid} />;
}
