'use client';

import { useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { RefreshCcw, AlertTriangle } from 'lucide-react';
import { useI18n } from '@/hooks/use-i18n';

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  const { t } = useI18n();

  useEffect(() => {
    // Log the error to an error reporting service
    console.error('Runtime Error:', error);
  }, [error]);

  return (
    <div className="flex flex-col items-center justify-center min-h-[60vh] p-6 text-center space-y-6">
      <div className="p-4 bg-destructive/10 rounded-full">
        <AlertTriangle className="h-12 w-12 text-destructive" />
      </div>
      <div className="space-y-2">
        <h2 className="text-2xl font-bold font-headline">{t('errors.runtimeTitle')}</h2>
        <p className="text-muted-foreground max-w-md mx-auto text-sm">
          {t('errors.runtimeDescription')}
          {error.message && <span className="block mt-2 font-mono text-[10px] opacity-50">{error.message}</span>}
        </p>
      </div>
      <div className="flex flex-col sm:flex-row gap-3">
        <Button
          variant="default"
          onClick={() => reset()}
          className="rounded-full px-8 h-12 font-bold shadow-lg shadow-primary/20"
        >
          <RefreshCcw className="mr-2 h-4 w-4" />
          {t('errors.runtimeRetry')}
        </Button>
        <Button
          variant="outline"
          onClick={() => window.history.back()}
          className="rounded-full px-8 h-12 font-bold"
        >
          {t('errors.runtimeBack')}
        </Button>
      </div>
    </div>
  );
}
