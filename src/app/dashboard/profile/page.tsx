'use client';

import { useAuth } from '@/hooks/use-auth';
import type { UserFormSavePayload } from '@/components/admin/user-form';
import { UserForm } from '@/components/admin/user-form';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { useToast } from '@/hooks/use-toast';
import { UserCircle } from 'lucide-react';
import { Skeleton } from '@/components/ui/skeleton';
import { useRouter } from 'next/navigation';
export default function ProfilePage() {
  const { user, updateUser, isUpdatingUser, isLoading } = useAuth();
  const { toast } = useToast();
  const router = useRouter();

  const handleSave = async (data: UserFormSavePayload) => {
    const result = await updateUser(data);
    if (result.ok) {
      toast({
        title: 'Профиль обновлен',
        description: 'Ваши данные были успешно сохранены.',
      });
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
          <div className="space-y-4">
                <Card>
                    <CardHeader>
                        <Skeleton className="h-7 w-48" />
                        <Skeleton className="h-4 w-96" />
                    </CardHeader>
                    <CardContent className="space-y-4">
                        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
                            <div className="md:col-span-1">
                                <Skeleton className="w-full aspect-[3/4] rounded-xl" />
                            </div>
                            <div className="md:col-span-2 space-y-4">
                                <Skeleton className="h-10 w-full" />
                                <Skeleton className="h-10 w-full" />
                                <Skeleton className="h-10 w-full" />
                                <Skeleton className="h-10 w-full" />
                            </div>
                        </div>
                    </CardContent>
                </Card>
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
          <p className="text-xs sm:text-sm text-muted-foreground">Управление личными данными и настройками безопасности.</p>
        </div>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Редактирование профиля</CardTitle>
          <CardDescription>
            Здесь вы можете изменить свою информацию. Для смены пароля откройте блок «Изменить пароль», введите новый пароль и подтверждение (не менее 6 символов).
          </CardDescription>
        </CardHeader>
        <CardContent>
            <UserForm
              layout="horizontal"
              initialData={user}
              onSave={handleSave}
              onCancel={() => router.back()}
              isSubmitting={isUpdatingUser}
              isProfilePage={true}
              hideCancelButton={false}
            />
        </CardContent>
      </Card>
    </div>
  );
}
