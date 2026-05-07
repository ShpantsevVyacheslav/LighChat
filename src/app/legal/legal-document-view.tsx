'use client';

import * as React from 'react';
import Link from 'next/link';
import { useI18n } from '@/hooks/use-i18n';
import { renderMarkdown } from '@/lib/legal/render';
import type { LegalSlug } from '@/lib/legal/slugs';

type Props = {
  slug: LegalSlug;
  ru: string | null;
  en: string | null;
};

export function LegalDocumentView({ slug, ru, en }: Props) {
  const { locale, t } = useI18n();
  const md = locale === 'en' ? en ?? ru : ru ?? en;
  const title = t(`legal.titles.${slug}` as never) || slug;

  return (
    <article className="mx-auto w-full max-w-3xl px-4 py-10 sm:px-6">
      <Link
        href="/legal"
        className="mb-6 inline-block text-sm text-muted-foreground hover:text-foreground"
      >
        {t('legal.backToIndex')}
      </Link>
      <h1 className="mb-6 text-3xl font-bold tracking-tight sm:text-4xl">{title}</h1>
      {md ? (
        <div className="prose-like">{renderMarkdown(md)}</div>
      ) : (
        <p className="text-muted-foreground">{t('legal.notFound')}</p>
      )}
    </article>
  );
}
