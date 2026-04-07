'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { Shield, Users, Loader2 } from 'lucide-react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { useAuth } from '@/hooks/use-auth';
import { AdminStorageSettingsPanel } from '@/components/admin/admin-storage-settings-panel';
import { AdminPushNotificationsPanel } from '@/components/admin/admin-push-notifications-panel';
import { AdminSupportInboxPlaceholder } from '@/components/admin/admin-support-inbox-placeholder';
import { AdminCapabilitiesRoadmapCard } from '@/components/admin/admin-capabilities-roadmap-card';
import { AdminBackfillConversationMembersPanel } from '@/components/admin/admin-backfill-conversation-members-panel';
import { UsersClient } from '@/components/admin/users-client';

export const dynamic = 'force-dynamic';

export default function AdminPage() {
  const { user, isLoading } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (!isLoading && user && user.role !== 'admin') {
      router.replace('/dashboard/chat');
    }
  }, [isLoading, user, router]);

  if (isLoading || !user || user.role !== 'admin') {
    return (
      <div className="flex min-h-[40vh] items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-primary" aria-hidden />
        <span className="sr-only">Загрузка…</span>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="animate-in fade-in slide-in-from-top-4 duration-700 flex items-center gap-2">
        <div className="min-w-0">
          <h1 className="text-2xl sm:text-3xl font-bold flex items-center gap-2 leading-tight">
            <Shield className="text-primary h-6 w-6 sm:h-8 sm:w-8" /> Администрирование
          </h1>
          <p className="text-xs sm:text-sm text-muted-foreground">
            Блокировки, роли и пароли — в разделе «Пользователи»; глобальные настройки — ниже.
          </p>
        </div>
      </div>

      <Tabs defaultValue="overview" className="space-y-6">
        <TabsList className="flex h-auto w-full flex-wrap justify-start gap-1 rounded-2xl bg-muted/50 p-1">
          <TabsTrigger value="overview" className="rounded-xl">
            Обзор
          </TabsTrigger>
          <TabsTrigger value="users" className="rounded-xl">
            Пользователи
          </TabsTrigger>
          <TabsTrigger value="storage" className="rounded-xl">
            Хранилище
          </TabsTrigger>
          <TabsTrigger value="push" className="rounded-xl">
            Уведомления
          </TabsTrigger>
          <TabsTrigger value="support" className="rounded-xl">
            Обращения
          </TabsTrigger>
          <TabsTrigger value="roadmap" className="rounded-xl">
            Развитие
          </TabsTrigger>
        </TabsList>

        <TabsContent value="overview" className="mt-0 space-y-4">
          <Card className="rounded-3xl">
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-lg">
                <Users className="h-5 w-5 text-primary" />
                Пользователи
              </CardTitle>
              <CardDescription>
                Блокировка учётных записей (временная или постоянная), разблокировка, сброс пароля через Firebase Admin
                и назначение администраторов выполняются в списке пользователей.
              </CardDescription>
            </CardHeader>
            <CardContent>
              <Button asChild className="rounded-full">
                <Link href="/dashboard/users">Открыть список пользователей</Link>
              </Button>
            </CardContent>
          </Card>

          <AdminBackfillConversationMembersPanel />

          <p className="text-sm text-muted-foreground">
            Политики хранения медиа, общая квота Storage и лимиты по пользователям/чатам настраиваются во вкладке «Хранилище».
            Реальное удаление файлов и FIFO при переполнении квоты выполняется Cloud Functions (подключите отдельно).
          </p>
        </TabsContent>

        <TabsContent value="users" className="mt-0">
          <div className="max-h-[min(70vh,900px)] overflow-y-auto pr-1">
            <UsersClient embedded />
          </div>
        </TabsContent>

        <TabsContent value="storage" className="mt-0">
          <AdminStorageSettingsPanel />
        </TabsContent>

        <TabsContent value="push" className="mt-0">
          <AdminPushNotificationsPanel />
        </TabsContent>

        <TabsContent value="support" className="mt-0">
          <AdminSupportInboxPlaceholder />
        </TabsContent>

        <TabsContent value="roadmap" className="mt-0">
          <AdminCapabilitiesRoadmapCard />
        </TabsContent>
      </Tabs>
    </div>
  );
}
