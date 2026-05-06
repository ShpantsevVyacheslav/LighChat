
'use server';

import ogs from 'open-graph-scraper';

import { assertSafeUrl, SsrfGuardError } from '@/lib/server/ssrf-guard';

/**
 * Server Action to fetch metadata from a URL for rich link previews.
 * Uses open-graph-scraper for robust parsing and reliability.
 *
 * SECURITY: this is an unauthenticated server action callable from any client
 * page. Without strict URL validation it becomes an SSRF primitive: an
 * attacker pastes `http://169.254.169.254/...` (or a DNS-rebinding host) into
 * a chat link, our server fetches it, and on App Hosting / GCP we leak the
 * runtime service-account token. The previous filter only blocked literal
 * `localhost`/`127.0.0.1`/`192.168.*`/`10.*` — it missed link-local 169.254/
 * cloud metadata, IPv6, CG-NAT, 172.16/12, and any DNS-rebound hostname.
 *
 * Layers we apply now:
 *   1. assertSafeUrl: scheme=https, no userinfo, no literal-IP, hostname
 *      DNS-resolves to a public IP for ALL records.
 *   2. fetchOptions.redirect = 'error': any redirect aborts the fetch.
 *      Otherwise an attacker-controlled host could 302 to 169.254.169.254
 *      and bypass step 1 (which only validates the original hop).
 *   3. Hard timeout (open-graph-scraper option), small UA string.
 */
export async function getLinkMetadata(url: string) {
  if (!url) return null;

  try {
    let targetUrl = url.trim();
    if (targetUrl.length > 4096) return null;
    // Allow callers to omit the scheme (typing "github.com" in a chat is
    // common). We coerce to https; http is never accepted by assertSafeUrl.
    if (!/^https?:\/\//i.test(targetUrl)) {
      targetUrl = 'https://' + targetUrl;
    }

    let safe: URL;
    try {
      safe = await assertSafeUrl(targetUrl, { allowedSchemes: ['https:'] });
    } catch (e) {
      if (e instanceof SsrfGuardError) {
        // Quietly drop — we don't want to leak which hostnames are blocked.
        return null;
      }
      throw e;
    }
    targetUrl = safe.toString();

    const options = {
      url: targetUrl,
      timeout: 10000,
      fetchOptions: {
        // SECURITY: refuse to follow redirects — every hop would need a fresh
        // SSRF check. A 302 to http://169.254.169.254/... would otherwise
        // bypass the pre-flight validation above.
        redirect: 'error' as const,
        headers: {
          'user-agent': 'Mozilla/5.0 (compatible; LighChatBot/1.0; +https://ligh.chat) facebookexternalhit/1.1',
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
    const clean = (str: unknown) => typeof str === 'string' ? str.trim() : null;

    // Map result to a clean interface for the frontend
    // ogs provides a very rich set of data, we pick the most useful ones
    const ogVideo = result.ogVideo?.[0];
    const twitterPlayer = result.twitterPlayer?.[0];
    const videoUrl = ogVideo?.url || twitterPlayer?.url || null;
    const videoType = ogVideo?.type || null;

    const metadata = {
      title: clean(result.ogTitle || result.twitterTitle || result.dcTitle || result.requestUrl),
      description: clean(result.ogDescription || result.twitterDescription || result.dcDescription),
      image: result.ogImage?.[0]?.url || result.twitterImage?.[0]?.url || null,
      siteName: clean(result.ogSiteName || result.twitterSite || result.alIosAppName),
      url: targetUrl,
      videoUrl: videoUrl || null,
      videoType: clean(videoType),
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
