'use client';

import { WifiOff } from 'lucide-react';
import { useI18n } from '@/hooks/use-i18n';

export default function OfflinePage() {
  const { t } = useI18n();
  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-background text-foreground text-center p-4">
      <WifiOff className="h-16 w-16 text-muted-foreground mb-4" />
      <h1 className="text-2xl font-bold mb-2">{t('offline.pageTitle')}</h1>
      <p className="text-muted-foreground max-w-md">
        {t('offline.pageDescription')}
      </p>
      <p className="text-muted-foreground max-w-md mt-2">
        {t('offline.pageSyncHint')}
      </p>
    </div>
  );
}
