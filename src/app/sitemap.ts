import type { MetadataRoute } from 'next';
import { LEGAL_SLUGS } from '@/lib/legal/slugs';

const BASE_URL = 'https://lighchat.online';

export default function sitemap(): MetadataRoute.Sitemap {
  const lastModified = new Date();

  /* ── Главная страница ── */
  const home: MetadataRoute.Sitemap = [
    {
      url: BASE_URL,
      lastModified,
      changeFrequency: 'weekly',
      priority: 1.0,
    },
  ];

  /* ── Авторизация ── */
  const auth: MetadataRoute.Sitemap = [
    {
      url: `${BASE_URL}/auth`,
      lastModified,
      changeFrequency: 'monthly',
      priority: 0.6,
    },
  ];

  /* ── Юридические страницы ── */
  const legal: MetadataRoute.Sitemap = [
    {
      url: `${BASE_URL}/legal`,
      lastModified,
      changeFrequency: 'monthly',
      priority: 0.4,
    },
    ...LEGAL_SLUGS.map((slug) => ({
      url: `${BASE_URL}/legal/${slug}`,
      lastModified,
      changeFrequency: 'monthly' as const,
      priority: 0.3,
    })),
  ];

  return [...home, ...auth, ...legal];
}
