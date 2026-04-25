'use client';

import { useAuth } from '@/hooks/use-auth';
import type { UserFormSavePayload } from '@/components/admin/user-form';
import { UserForm } from '@/components/admin/user-form';
import { useToast } from '@/hooks/use-toast';
import { UserCircle } from 'lucide-react';
import { Skeleton } from '@/components/ui/skeleton';
import { useRouter } from 'next/navigation';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { Button } from '@/components/ui/button';
export default function ProfilePage() {
  const { user, updateUser, resendPendingEmailVerification, isUpdatingUser, isLoading } = useAuth();
  const { toast } = useToast();
  const router = useRouter();

  const pendingEmail =
    user?.pendingEmail && user.pendingEmail.trim().length > 0
      ? user.pendingEmail.trim()
      : '';

  const handleSave = async (data: UserFormSavePayload) => {
    const result = await updateUser(data);
    if (result.ok) {
      if (result.emailVerificationSent) {
        toast({
          title: 'Подтвердите новый email',
          description:
            'Отправлено письмо на новый адрес. Перейдите по ссылке в письме, чтобы завершить смену. Остальные изменения профиля сохранены.',
        });
      } else {
        toast({
          title: 'Профиль обновлен',
          description: 'Ваши данные были успешно сохранены.',
        });
      }
    } else {
      toast({
        variant: 'destructive',
        title: 'Ошибка',
        description: result.message,
      });
    }
  };

  if (isLoading || !user) {
      return (
          <div className="space-y-4 max-w-5xl mx-auto pb-10">
                <div className="animate-in fade-in slide-in-from-top-4 duration-700 flex items-center gap-2">
                  <Skeleton className="h-9 w-64" />
                </div>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-8 pt-2">
                    <div className="md:col-span-1 flex justify-center">
                        <Skeleton className="h-20 w-20 rounded-full" />
                    </div>
                    <div className="md:col-span-2 space-y-4">
                        <Skeleton className="h-10 w-full" />
                        <Skeleton className="h-10 w-full" />
                        <Skeleton className="h-10 w-full" />
                        <Skeleton className="h-10 w-full" />
                    </div>
                </div>
          </div>
      )
  }

  return (
    <div className="space-y-6 max-w-5xl mx-auto pb-10">
      <div className="animate-in fade-in slide-in-from-top-4 duration-700 flex items-center gap-2">
        <div className="min-w-0">
          <h1 className="text-2xl sm:text-3xl font-bold flex items-center gap-2 leading-tight">
            <UserCircle className="text-primary h-6 w-6 sm:h-8 sm:w-8" /> Мой профиль
          </h1>
        </div>
      </div>

      {pendingEmail && pendingEmail.toLowerCase() !== (user.email ?? '').trim().toLowerCase() ? (
        <Alert>
          <AlertTitle>Ожидает подтверждения email</AlertTitle>
          <AlertDescription className="mt-1 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <div className="min-w-0">
              <div className="text-sm text-muted-foreground">
                Мы отправили письмо на новый адрес: <span className="font-medium text-foreground">{pendingEmail}</span>
              </div>
              <div className="text-xs text-muted-foreground">
                Перейдите по ссылке в письме, чтобы завершить смену. Если письма нет — проверьте спам.
              </div>
            </div>
            <Button
              type="button"
              variant="secondary"
              onClick={async () => {
                const res = await resendPendingEmailVerification();
                if (res.ok) {
                  toast({
                    title: 'Письмо отправлено повторно',
                    description: 'Проверьте почту и перейдите по ссылке для подтверждения.',
                  });
                } else {
                  toast({
                    variant: 'destructive',
                    title: 'Не удалось отправить письмо',
                    description: res.message,
                  });
                }
              }}
            >
              Отправить письмо ещё раз
            </Button>
          </AlertDescription>
        </Alert>
      ) : null}

      <UserForm
        layout="horizontal"
        initialData={user}
        onSave={handleSave}
        onCancel={() => router.back()}
        isSubmitting={isUpdatingUser}
        isProfilePage={true}
        hideCancelButton={false}
      />
    </div>
  );
}
