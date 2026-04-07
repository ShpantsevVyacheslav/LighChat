
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

export default function NewUserPage() {
  const router = useRouter();
  const firebaseApp = useFirebaseApp();
  const { toast } = useToast();
  const [isSaving, setIsSaving] = useState(false);

  const handleSave = async (data: UserFormSavePayload) => {
    setIsSaving(true);
    if (!data.password) {
        toast({ variant: 'destructive', title: 'Ошибка', description: 'Пароль обязателен для нового пользователя.'});
        setIsSaving(false);
        return;
    }
    if (!firebaseApp) {
        toast({ variant: 'destructive', title: 'Ошибка', description: 'Сервис Firebase не доступен.'});
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
        title: 'Пользователь создан',
        description: `Аккаунт для "${data.name}" был успешно создан на сервере.`,
      });
      router.push('/dashboard/users');
    } catch (error: any) {
      let errorMessage = 'Произошла неизвестная ошибка.';
      if (typeof error.message === 'string') {
          errorMessage = error.message;
      }
      
      if (error.code) {
        switch (error.code) {
            case 'functions/already-exists':
                errorMessage = 'Этот email уже используется.';
                break;
            case 'functions/permission-denied':
                errorMessage = 'У вас нет прав для выполнения этой операции.';
                break;
            case 'functions/internal':
                errorMessage = 'Произошла внутренняя ошибка сервера при создании пользователя.';
                break;
        }
      }
      
      toast({
        variant: 'destructive',
        title: 'Ошибка при создании',
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
          <DialogTitle>Новый пользователь</DialogTitle>
          <DialogDescription>
            Создайте новую учетную запись. Все данные будут сохранены в облаке.
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
