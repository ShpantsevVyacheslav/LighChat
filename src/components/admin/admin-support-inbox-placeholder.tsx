'use client';

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { MessageSquareWarning } from 'lucide-react';
import { useI18n } from '@/hooks/use-i18n';

/** Заготовка под обращения: коллекция supportTickets, ответы админа — в следующей итерации. */
export function AdminSupportInboxPlaceholder() {
  const { t } = useI18n();
  return (
    <Card className="rounded-3xl border-dashed">
      <CardHeader>
        <CardTitle className="flex items-center gap-2 text-lg">
          <MessageSquareWarning className="h-5 w-5 text-muted-foreground" />
          {t('adminPage.support.title')}
        </CardTitle>
        <CardDescription>
          {t('adminPage.support.placeholderDescription')}
        </CardDescription>
      </CardHeader>
      <CardContent>
        <p className="text-sm text-muted-foreground">
          {t('adminPage.support.placeholderContent')}
        </p>
      </CardContent>
    </Card>
  );
}
