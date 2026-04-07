import { NextRequest, NextResponse } from 'next/server';

type TenorSearchItem = {
  id: string;
  url: string;
  width?: number;
  height?: number;
};

/**
 * Поиск GIF через Tenor API v2. Ключ: `TENOR_API_KEY` в .env.local (Google Cloud / Tenor).
 * @see https://developers.google.com/tenor/guides/quickstart
 */
export async function GET(req: NextRequest) {
  const q = req.nextUrl.searchParams.get('q')?.trim() ?? '';
  const key = process.env.TENOR_API_KEY;
  if (!key) {
    return NextResponse.json({ ok: false, error: 'missing_key', items: [] as TenorSearchItem[] }, { status: 200 });
  }
  if (q.length < 1) {
    return NextResponse.json({ ok: true, items: [] as TenorSearchItem[] });
  }

  const tenorUrl = new URL('https://tenor.googleapis.com/v2/search');
  tenorUrl.searchParams.set('q', q);
  tenorUrl.searchParams.set('key', key);
  tenorUrl.searchParams.set('client_key', 'lighchat_web');
  tenorUrl.searchParams.set('limit', '24');
  tenorUrl.searchParams.set('media_filter', 'gif');

  try {
    const res = await fetch(tenorUrl.toString(), { next: { revalidate: 0 } });
    if (!res.ok) {
      console.warn('[tenor/search]', res.status, await res.text().catch(() => ''));
      return NextResponse.json({ ok: false, error: 'tenor_http', items: [] });
    }
    const data = (await res.json()) as {
      results?: Array<{
        id?: string;
        media_formats?: {
          gif?: { url?: string; dims?: [number, number] };
          tinygif?: { url?: string; dims?: [number, number] };
        };
      }>;
    };
    const raw = data.results ?? [];
    const items: TenorSearchItem[] = [];
    for (const r of raw) {
      const gif = r.media_formats?.gif ?? r.media_formats?.tinygif;
      const url = gif?.url;
      const id = r.id;
      if (!url || !id) continue;
      const dims = gif?.dims;
      items.push({
        id,
        url,
        ...(dims?.[0] != null && dims?.[1] != null ? { width: dims[0], height: dims[1] } : {}),
      });
    }

    return NextResponse.json({ ok: true, items });
  } catch (e) {
    console.error('[tenor/search]', e);
    return NextResponse.json({ ok: false, error: 'fetch_failed', items: [] });
  }
}
