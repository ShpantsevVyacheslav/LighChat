'use client';

import * as React from 'react';
import Link from 'next/link';

import { Button } from '@/components/ui/button';
import { useI18n } from '@/hooks/use-i18n';
import { setConsent } from '@/lib/analytics';

const STORAGE_KEY = 'lc_cookie_consent_v1';

export function CookieBanner() {
  const { t } = useI18n();
  const [visible, setVisible] = React.useState(false);

  React.useEffect(() => {
    try {
      const v = window.localStorage.getItem(STORAGE_KEY);
      if (!v) setVisible(true);
    } catch {
      /* ignore */
    }
  }, []);

  const persist = React.useCallback((decision: 'all' | 'required') => {
    try {
      window.localStorage.setItem(STORAGE_KEY, decision);
    } catch {
      /* ignore */
    }
    setConsent(decision);
    setVisible(false);
  }, []);

  if (!visible) return null;

  return (
    <div className="fixed inset-x-0 bottom-0 z-50 border-t border-black/10 bg-background/95 px-4 py-3 backdrop-blur-md dark:border-white/10">
      <div className="mx-auto flex max-w-6xl flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <p className="text-xs leading-relaxed text-muted-foreground sm:text-sm">
          {t('legal.cookieBannerText')}{' '}
          <Link
            href="/legal/cookie-policy"
            className="font-medium text-primary underline-offset-2 hover:underline"
          >
            {t('legal.cookieBannerLearnMore')}
          </Link>
          .
        </p>
        <div className="flex shrink-0 gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={() => persist('required')}
            className="h-9 rounded-lg"
          >
            {t('legal.cookieBannerDecline')}
          </Button>
          <Button
            size="sm"
            onClick={() => persist('all')}
            className="h-9 rounded-lg"
          >
            {t('legal.cookieBannerAccept')}
          </Button>
        </div>
      </div>
    </div>
  );
}
