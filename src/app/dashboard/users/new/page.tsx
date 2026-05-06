
'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useFirebaseApp } from '@/firebase';
import { useToast } from '@/hooks/use-toast';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from '@/components/ui/dialog';
import { UserForm, type UserFormSavePayload } from '@/components/admin/user-form';
import { getFunctions, httpsCallable } from 'firebase/functions';
import { useI18n } from '@/hooks/use-i18n';

export default function NewUserPage() {
  const router = useRouter();
  const firebaseApp = useFirebaseApp();
  const { toast } = useToast();
  const { t } = useI18n();
  const [isSaving, setIsSaving] = useState(false);

  const handleSave = async (data: UserFormSavePayload) => {
    setIsSaving(true);
    if (!data.password) {
        toast({ variant: 'destructive', title: t('usersAdmin.create.toastPasswordRequiredTitle'), description: t('usersAdmin.create.toastPasswordRequiredDesc')});
        setIsSaving(false);
        return;
    }
    if (!firebaseApp) {
        toast({ variant: 'destructive', title: t('usersAdmin.create.toastFirebaseUnavailableTitle'), description: t('usersAdmin.create.toastFirebaseUnavailableDesc')});
        setIsSaving(false);
        return;
    }

    try {
      // 1. Get a reference to the Cloud Function
      const functions = getFunctions(firebaseApp, 'us-central1');
      const createUserFn = httpsCallable(functions, 'createNewUser');

      // 2. Call the function to create both Auth account AND Firestore document
      await createUserFn({
          email: data.email,
          password: data.password,
          name: data.name,
          role: data.role,
          phone: data.phone,
          avatar: data.avatar
      });

      toast({
        title: t('usersAdmin.create.toastCreatedTitle'),
        description: t('usersAdmin.create.toastCreatedDescNamed', { name: data.name }),
      });
      router.push('/dashboard/users');
    } catch (error: unknown) {
      let errorMessage = t('usersAdmin.create.errorUnknown');
      if (
        typeof error === 'object' &&
        error != null &&
        'message' in error &&
        typeof (error as { message?: unknown }).message === 'string'
      ) {
        errorMessage = (error as { message: string }).message;
      }

      const code =
        typeof error === 'object' && error != null && 'code' in error
          ? (error as { code?: unknown }).code
          : undefined;
      if (typeof code === 'string') {
        switch (code) {
            case 'functions/already-exists':
                errorMessage = t('usersAdmin.create.errorAlreadyExists');
                break;
            case 'functions/permission-denied':
                errorMessage = t('usersAdmin.create.errorPermissionDenied');
                break;
            case 'functions/internal':
                errorMessage = t('usersAdmin.create.errorInternal');
                break;
        }
      }

      toast({
        variant: 'destructive',
        title: t('usersAdmin.create.toastErrorTitle'),
        description: errorMessage,
      });
    } finally {
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
          <DialogTitle>{t('usersAdmin.create.dialogTitle')}</DialogTitle>
          <DialogDescription>
            {t('usersAdmin.create.dialogDescription')}
          </DialogDescription>
        </DialogHeader>
        <UserForm
            initialData={null}
            onSave={handleSave}
            onCancel={() => router.back()}
            isSubmitting={isSaving}
        />
      </DialogContent>
    </Dialog>
  );
}
