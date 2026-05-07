'use client';

import * as React from 'react';
import Link from 'next/link';

import { useI18n } from '@/hooks/use-i18n';
import { LEGAL_SLUGS } from '@/lib/legal/slugs';

export function LegalFooterLinks() {
  const { t } = useI18n();
  return (
    <nav
      aria-label="legal"
      className="flex flex-wrap items-center justify-center gap-x-4 gap-y-1 text-[11px] text-muted-foreground"
    >
      {LEGAL_SLUGS.map((slug) => (
        <Link
          key={slug}
          href={`/legal/${slug}`}
          className="hover:text-foreground hover:underline"
        >
          {t(`legal.titles.${slug}` as never) || slug}
        </Link>
      ))}
    </nav>
  );
}
