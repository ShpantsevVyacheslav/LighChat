'use client';

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Lightbulb } from 'lucide-react';
import { useI18n } from '@/hooks/use-i18n';

/**
 * Идеи развития админки под LighChat (мессенджер + конференции + PWA).
 */
export function AdminCapabilitiesRoadmapCard() {
  const { t } = useI18n();

  const itemKeys = [
    'adminPage.roadmap.items.moderation',
    'adminPage.roadmap.items.audit',
    'adminPage.roadmap.items.analytics',
    'adminPage.roadmap.items.meetings',
    'adminPage.roadmap.items.featureFlags',
    'adminPage.roadmap.items.gdpr',
    'adminPage.roadmap.items.rateLimit',
    'adminPage.roadmap.items.backup',
    'adminPage.roadmap.items.customRoles',
    'adminPage.roadmap.items.billing',
  ];

  return (
    <Card className="rounded-3xl">
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-lg">
          <Lightbulb className="h-5 w-5 text-amber-500" />
          {t('adminPage.roadmap.title')}
        </CardTitle>
        <CardDescription>{t('adminPage.roadmap.description')}</CardDescription>
      </CardHeader>
      <CardContent>
        <ul className="list-disc space-y-2 pl-5 text-sm text-muted-foreground">
          {itemKeys.map((key) => (
            <li key={key}>{t(key)}</li>
          ))}
        </ul>
      </CardContent>
    </Card>
  );
}
