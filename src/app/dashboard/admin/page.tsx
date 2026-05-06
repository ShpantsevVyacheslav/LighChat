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
import { AdminSupportInbox } from '@/components/admin/admin-support-inbox';
import { AdminCapabilitiesRoadmapCard } from '@/components/admin/admin-capabilities-roadmap-card';
import { AdminBackfillConversationMembersPanel } from '@/components/admin/admin-backfill-conversation-members-panel';
import { AdminAuditLogPanel } from '@/components/admin/admin-audit-log-panel';
import { AdminAnalyticsPanel } from '@/components/admin/admin-analytics-panel';
import { AdminModerationPanel } from '@/components/admin/admin-moderation-panel';
import { AdminFeatureFlagsPanel } from '@/components/admin/admin-feature-flags-panel';
import { AdminAnnouncementsPanel } from '@/components/admin/admin-announcements-panel';
import { UsersClient } from '@/components/admin/users-client';
import { useI18n } from '@/hooks/use-i18n';

export const dynamic = 'force-dynamic';

export default function AdminPage() {
  const { user, isLoading } = useAuth();
  const router = useRouter();
  const { t } = useI18n();

  useEffect(() => {
    if (!isLoading && user && user.role !== 'admin') {
      router.replace('/dashboard/chat');
    }
  }, [isLoading, user, router]);

  if (isLoading || !user || user.role !== 'admin') {
    return (
      <div className="flex min-h-[40vh] items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-primary" aria-hidden />
        <span className="sr-only">{t('errors.loadingSr')}</span>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="animate-in fade-in slide-in-from-top-4 duration-700 flex items-center gap-2">
        <div className="min-w-0">
          <h1 className="text-2xl sm:text-3xl font-bold flex items-center gap-2 leading-tight">
            <Shield className="text-primary h-6 w-6 sm:h-8 sm:w-8" /> {t('adminPage.pageTitle')}
          </h1>
          <p className="text-xs sm:text-sm text-muted-foreground">
            {t('adminPage.pageSubtitle')}
          </p>
        </div>
      </div>

      <Tabs defaultValue="overview" className="space-y-6">
        <TabsList className="flex h-auto w-full flex-wrap justify-start gap-1 rounded-2xl bg-muted/50 p-1">
          <TabsTrigger value="overview" className="rounded-xl">
            {t('adminPage.tabOverview')}
          </TabsTrigger>
          <TabsTrigger value="users" className="rounded-xl">
            {t('adminPage.tabUsers')}
          </TabsTrigger>
          <TabsTrigger value="analytics" className="rounded-xl">
            {t('adminPage.tabAnalytics')}
          </TabsTrigger>
          <TabsTrigger value="moderation" className="rounded-xl">
            {t('adminPage.tabModeration')}
          </TabsTrigger>
          <TabsTrigger value="storage" className="rounded-xl">
            {t('adminPage.tabStorage')}
          </TabsTrigger>
          <TabsTrigger value="push" className="rounded-xl">
            {t('adminPage.tabPush')}
          </TabsTrigger>
          <TabsTrigger value="audit" className="rounded-xl">
            {t('adminPage.tabAudit')}
          </TabsTrigger>
          <TabsTrigger value="support" className="rounded-xl">
            {t('adminPage.tabSupport')}
          </TabsTrigger>
          <TabsTrigger value="platform" className="rounded-xl">
            {t('adminPage.tabPlatform')}
          </TabsTrigger>
          <TabsTrigger value="roadmap" className="rounded-xl">
            {t('adminPage.tabRoadmap')}
          </TabsTrigger>
        </TabsList>

        <TabsContent value="overview" className="mt-0 space-y-4">
          <Card className="rounded-3xl">
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-lg">
                <Users className="h-5 w-5 text-primary" />
                {t('adminPage.overviewUsersTitle')}
              </CardTitle>
              <CardDescription>
                {t('adminPage.overviewUsersDescription')}
              </CardDescription>
            </CardHeader>
            <CardContent>
              <Button asChild className="rounded-full">
                <Link href="/dashboard/users">{t('adminPage.overviewUsersOpen')}</Link>
              </Button>
            </CardContent>
          </Card>

          <AdminBackfillConversationMembersPanel />

          <p className="text-sm text-muted-foreground">
            {t('adminPage.overviewStorageHint')}
          </p>
        </TabsContent>

        <TabsContent value="users" className="mt-0">
          <div className="max-h-[min(70vh,900px)] overflow-y-auto pr-1">
            <UsersClient embedded />
          </div>
        </TabsContent>

        <TabsContent value="analytics" className="mt-0">
          <AdminAnalyticsPanel />
        </TabsContent>

        <TabsContent value="moderation" className="mt-0">
          <AdminModerationPanel />
        </TabsContent>

        <TabsContent value="storage" className="mt-0">
          <AdminStorageSettingsPanel />
        </TabsContent>

        <TabsContent value="push" className="mt-0">
          <AdminPushNotificationsPanel />
        </TabsContent>

        <TabsContent value="audit" className="mt-0">
          <AdminAuditLogPanel />
        </TabsContent>

        <TabsContent value="support" className="mt-0">
          <AdminSupportInbox />
        </TabsContent>

        <TabsContent value="platform" className="mt-0 space-y-4">
          <AdminAnnouncementsPanel />
          <AdminFeatureFlagsPanel />
        </TabsContent>

        <TabsContent value="roadmap" className="mt-0">
          <AdminCapabilitiesRoadmapCard />
        </TabsContent>
      </Tabs>
    </div>
  );
}
