
'use server';

import ogs from 'open-graph-scraper';

/**
 * Server Action to fetch metadata from a URL for rich link previews.
 * Uses open-graph-scraper for robust parsing and reliability.
 */
export async function getLinkMetadata(url: string) {
  if (!url) return null;

  try {
    // Basic URL validation and normalization
    let targetUrl = url.trim();
    if (!/^https?:\/\//i.test(targetUrl)) {
      targetUrl = 'https://' + targetUrl;
    }

    // Security: Basic check to prevent SSRF on internal/local addresses
    try {
        const domain = new URL(targetUrl).hostname;
        if (['localhost', '127.0.0.1', '0.0.0.0'].includes(domain) || domain.startsWith('192.168.') || domain.startsWith('10.')) {
          return null;
        }
    } catch (e) {
        return null;
    }

    const options = {
      url: targetUrl,
      timeout: 10000,
      fetchOptions: {
        headers: {
          'user-agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
          'accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
          'accept-language': 'ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7',
        },
      },
    };

    const { result, error } = await ogs(options);

    if (error || !result || !result.success) {
      console.warn(`[getLinkMetadata] Failed for ${targetUrl}:`, error);
      return null;
    }

    // Clean up strings
    const clean = (str: any) => typeof str === 'string' ? str.trim() : null;

    // Map result to a clean interface for the frontend
    // ogs provides a very rich set of data, we pick the most useful ones
    const metadata = {
      title: clean(result.ogTitle || result.twitterTitle || result.dcTitle || result.requestUrl),
      description: clean(result.ogDescription || result.twitterDescription || result.dcDescription),
      image: result.ogImage?.[0]?.url || result.twitterImage?.[0]?.url || null,
      siteName: clean(result.ogSiteName || result.twitterSite || result.alIosAppName),
      url: targetUrl,
    };

    // If we don't even have a title or description, it's not a very good preview
    if (!metadata.title && !metadata.description) {
        return null;
    }

    return metadata;
  } catch (err) {
    console.error('[getLinkMetadata] Critical Error:', err);
    return null;
  }
}
