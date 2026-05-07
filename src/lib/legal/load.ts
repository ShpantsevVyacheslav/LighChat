import 'server-only';

import { promises as fs } from 'node:fs';
import path from 'node:path';

import type { LegalSlug } from './slugs';

export type LegalLocale = 'ru' | 'en';

export async function readLegalDocument(
  slug: LegalSlug,
  locale: LegalLocale
): Promise<string | null> {
  const file = path.join(process.cwd(), 'docs', 'legal', locale, `${slug}.md`);
  try {
    return await fs.readFile(file, 'utf8');
  } catch (err) {
    if ((err as NodeJS.ErrnoException).code === 'ENOENT') return null;
    throw err;
  }
}
