'use client';

import { useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useDoc, useFirestore, useMemoFirebase, useFirebaseApp } from '@/firebase';
import { doc } from 'firebase/firestore';
import { getFunctions, httpsCallable } from 'firebase/functions';
import type { User } from '@/lib/types';
import { useToast } from '@/hooks/use-toast';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from '@/components/ui/dialog';
import { UserForm, type UserFormSavePayload } from '@/components/admin/user-form';
import { Loader2 } from 'lucide-react';
import { useI18n } from '@/hooks/use-i18n';

export default function EditUserPage() {
  const router = useRouter();
  const params = useParams();
  const { toast } = useToast();
  const { t } = useI18n();
  const [isSaving, setIsSaving] = useState(false);

  const userId = typeof params.userId === 'string' ? params.userId : '';
  const firestore = useFirestore();
  const firebaseApp = useFirebaseApp();
  
  const userRef = useMemoFirebase(() => (firestore && userId ? doc(firestore, 'users', userId) : null), [firestore, userId]);
  const { data: user, isLoading } = useDoc<User>(userRef);

  const handleSave = async (data: UserFormSavePayload) => {
    if (!userId || !firebaseApp) return;
    setIsSaving(true);
    
    const { password, ...dataToSave } = data;

    try {
        // Use Cloud Function instead of direct client-side update to bypass security rule restrictions
        // and handle password updates in one transaction.
        const functions = getFunctions(firebaseApp, 'us-central1');
        const updateUserAdminFn = httpsCallable(functions, 'updateUserAdmin');
        
        await updateUserAdminFn({
            uid: userId,
            userData: dataToSave,
            password: password && password.length >= 6 ? password : null
        });
        
        toast({
            title: t('usersAdmin.edit.toastUpdatedTitle'),
            description: t('usersAdmin.edit.toastUpdatedDescNamed', { name: data.name }),
        });
        router.push('/dashboard/users');
    } catch (e: unknown) {
        console.error("Failed to update user via Cloud Function:", e);
        const message =
          typeof e === 'object' &&
          e != null &&
          'message' in e &&
          typeof (e as { message?: unknown }).message === 'string'
            ? (e as { message: string }).message
            : undefined;
        toast({
            variant: 'destructive',
            title: t('usersAdmin.edit.toastErrorTitle'),
            description: message || t('usersAdmin.edit.fallbackError'),
        });
        setIsSaving(false);
    }
  };

  return (
    <Dialog
      open={true}
      onOpenChange={(open) => {
        if (!open) {
          router.back();
        }
      }}
    >
      <DialogContent className="rounded-2xl">
        <DialogHeader>
          <DialogTitle>{t('usersAdmin.edit.dialogTitle')}</DialogTitle>
          <DialogDescription>
            {t('usersAdmin.edit.dialogDescription')}
          </DialogDescription>
        </DialogHeader>
        {isLoading ? (
            <div className="flex h-96 items-center justify-center">
                <Loader2 className="h-8 w-8 animate-spin text-primary" />
            </div>
        ) : (
            <UserForm
                initialData={user}
                onSave={handleSave}
                onCancel={() => router.back()}
                isSubmitting={isSaving}
            />
        )}
      </DialogContent>
    </Dialog>
  );
}
