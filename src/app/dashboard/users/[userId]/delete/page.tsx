'use client';

import { useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useDoc, useFirestore, useMemoFirebase, useFirebaseApp } from '@/firebase';
import { doc } from 'firebase/firestore';
import { getFunctions, httpsCallable } from 'firebase/functions';
import type { User } from '@/lib/types';
import { useToast } from '@/hooks/use-toast';
import { DeleteConfirmationDialog } from '@/components/delete-confirmation-dialog';
import { Loader2 } from 'lucide-react';
import { useAuth } from '@/hooks/use-auth';
import { useI18n } from '@/hooks/use-i18n';
import { logger } from '@/lib/logger';

export default function DeleteUserPage() {
  const router = useRouter();
  const params = useParams();
  const firestore = useFirestore();
  const firebaseApp = useFirebaseApp();
  const { toast } = useToast();
  const { user: currentUser } = useAuth();
  const { t } = useI18n();
  const [isDeleting, setIsDeleting] = useState(false);

  const userId = typeof params.userId === 'string' ? params.userId : '';
  const userRef = useMemoFirebase(() => (firestore && userId ? doc(firestore, 'users', userId) : null), [firestore, userId]);
  const { data: user, isLoading } = useDoc<User>(userRef);

  const handleConfirmDelete = async () => {
    if (!userId || currentUser?.id === userId || !firebaseApp) {
        if (currentUser?.id === userId) {
            toast({ variant: 'destructive', title: t('usersAdmin.deleteUser.toastSelfDeleteTitle'), description: t('usersAdmin.deleteUser.toastSelfDeleteDesc') });
        }
        return;
    };

    setIsDeleting(true);
    try {
      // Use Cloud Function to perform the soft-delete through the server
      const functions = getFunctions(firebaseApp, 'us-central1');
      const updateUserAdminFn = httpsCallable(functions, 'updateUserAdmin');
      
      await updateUserAdminFn({
          uid: userId,
          userData: { deletedAt: new Date().toISOString() }
      });

      toast({
        title: t('usersAdmin.deleteUser.toastDeletedTitle'),
        description: t('usersAdmin.deleteUser.toastDeletedDescNamed', { name: user?.name ?? '' }),
      });
      router.push('/dashboard/users');
    } catch (error: unknown) {
      logger.error('admin-user-delete', 'delete via Cloud Function failed', error);
      const message =
        typeof error === 'object' &&
        error != null &&
        'message' in error &&
        typeof (error as { message?: unknown }).message === 'string'
          ? (error as { message: string }).message
          : undefined;
      toast({
        variant: 'destructive',
        title: t('usersAdmin.deleteUser.toastErrorTitle'),
        description: message || t('usersAdmin.deleteUser.fallbackError'),
      });
      setIsDeleting(false);
    }
  };

  if (isLoading) {
    return (
        <div className="flex h-full w-full items-center justify-center">
            <Loader2 className="h-8 w-8 animate-spin text-primary" />
        </div>
    );
  }

  return (
    <DeleteConfirmationDialog
      open={true}
      onOpenChange={(open) => {
        if (!open) {
          router.back();
        }
      }}
      onConfirm={handleConfirmDelete}
      isPending={isDeleting}
      itemName={user?.name || ''}
      itemType={t('usersAdmin.deleteUser.itemType')}
    />
  );
}
