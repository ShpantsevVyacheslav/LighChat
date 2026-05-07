import { notFound } from 'next/navigation';

import { readLegalDocument } from '@/lib/legal/load';
import { LEGAL_SLUGS, isLegalSlug } from '@/lib/legal/slugs';
import { LegalDocumentView } from '../legal-document-view';

export const dynamic = 'force-static';
export const revalidate = false;

export async function generateStaticParams() {
  return LEGAL_SLUGS.map((slug) => ({ slug }));
}

export default async function LegalSlugPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  if (!isLegalSlug(slug)) notFound();

  const [ru, en] = await Promise.all([
    readLegalDocument(slug, 'ru'),
    readLegalDocument(slug, 'en'),
  ]);

  if (!ru && !en) notFound();

  return <LegalDocumentView slug={slug} ru={ru} en={en} />;
}
