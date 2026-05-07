import type { MetadataRoute } from 'next';

const BASE_URL = 'https://lighchat.online';

export default function sitemap(): MetadataRoute.Sitemap {
  const lastModified = new Date();

  return [
    {
      url: BASE_URL,
      lastModified,
      changeFrequency: 'weekly',
      priority: 1.0,
    },
  ];
}
