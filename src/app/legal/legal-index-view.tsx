'use client';

import * as React from 'react';
import Link from 'next/link';
import { ChevronRight } from 'lucide-react';

import { useI18n } from '@/hooks/use-i18n';
import { LEGAL_SLUGS } from '@/lib/legal/slugs';

export function LegalIndexView() {
  const { t } = useI18n();
  return (
    <div className="mx-auto w-full max-w-3xl px-4 py-10 sm:px-6">
      <h1 className="mb-3 text-3xl font-bold tracking-tight sm:text-4xl">
        {t('legal.indexTitle')}
      </h1>
      <p className="mb-8 text-muted-foreground">{t('legal.indexSubtitle')}</p>
      <ul className="divide-y divide-border rounded-xl border border-border bg-card">
        {LEGAL_SLUGS.map((slug) => (
          <li key={slug}>
            <Link
              href={`/legal/${slug}`}
              className="flex items-center justify-between gap-3 px-4 py-3 transition-colors hover:bg-muted/40"
            >
              <span className="font-medium">
                {t(`legal.titles.${slug}` as never) || slug}
              </span>
              <ChevronRight className="h-4 w-4 text-muted-foreground" aria-hidden />
            </Link>
          </li>
        ))}
      </ul>
    </div>
  );
}
