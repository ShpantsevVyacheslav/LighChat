import { NextRequest, NextResponse } from 'next/server';

type GifSearchItem = {
  id: string;
  url: string;
  width?: number;
  height?: number;
};

/**
 * Поиск GIF/Stickers через GIPHY API. Ключ: `GIPHY_API_KEY` в .env.local.
 * Endpoint называется `/api/tenor/search` по историческим причинам — фактически
 * это GIPHY API, обёрнутый в серверный прокси для скрытия ключа.
 *
 * Параметры:
 *   - q: текстовый запрос (опционально). Пусто → trending.
 *   - type: 'gifs' (по умолчанию) | 'stickers' (анимированные эмодзи).
 *
 * @see https://developers.giphy.com/docs/api/endpoint
 */
const PAGE_SIZE = 24;
const MAX_OFFSET = 4975; // GIPHY hard cap

export async function GET(req: NextRequest) {
  const q = req.nextUrl.searchParams.get('q')?.trim() ?? '';
  const type = req.nextUrl.searchParams.get('type') === 'stickers'
    ? 'stickers'
    : 'gifs';
  const offsetRaw = req.nextUrl.searchParams.get('offset');
  let offset = 0;
  if (offsetRaw != null) {
    const n = parseInt(offsetRaw, 10);
    if (Number.isFinite(n) && n >= 0) offset = Math.min(n, MAX_OFFSET);
  }
  const key = process.env.GIPHY_API_KEY;
  if (!key) {
    console.warn(
      '[giphy/search] GIPHY_API_KEY is not set. ' +
        'Add it via `firebase apphosting:secrets:set GIPHY_API_KEY` ' +
        'and update apphosting.yaml.',
    );
    return NextResponse.json(
      {
        ok: false,
        error: 'missing_key',
        items: [] as GifSearchItem[],
        offset: 0,
        total: 0,
      },
      { status: 200 },
    );
  }

  const isTrending = q.length < 1;
  // GIPHY endpoints:
  //   gifs:     /v1/gifs/{trending,search}
  //   stickers: /v1/stickers/{trending,search}
  const path = `/v1/${type}/${isTrending ? 'trending' : 'search'}`;
  const giphyUrl = new URL(`https://api.giphy.com${path}`);
  if (!isTrending) giphyUrl.searchParams.set('q', q);
  giphyUrl.searchParams.set('api_key', key);
  giphyUrl.searchParams.set('limit', String(PAGE_SIZE));
  giphyUrl.searchParams.set('offset', String(offset));
  giphyUrl.searchParams.set('rating', 'g');
  giphyUrl.searchParams.set('lang', 'ru');

  try {
    const res = await fetch(giphyUrl.toString(), { next: { revalidate: 0 } });
    if (!res.ok) {
      console.warn('[giphy/search]', res.status, await res.text().catch(() => ''));
      return NextResponse.json({ ok: false, error: 'giphy_http', items: [] });
    }
    const data = (await res.json()) as {
      data?: Array<{
        id?: string;
        images?: {
          fixed_height?: { url?: string; width?: string; height?: string };
          original?: { url?: string; width?: string; height?: string };
        };
      }>;
      pagination?: {
        total_count?: number;
        count?: number;
        offset?: number;
      };
    };
    const raw = data.data ?? [];
    const items: GifSearchItem[] = [];
    for (const r of raw) {
      const img = r.images?.fixed_height ?? r.images?.original;
      const url = img?.url;
      const id = r.id;
      if (!url || !id) continue;
      const w = img?.width ? parseInt(img.width, 10) : undefined;
      const h = img?.height ? parseInt(img.height, 10) : undefined;
      items.push({
        id,
        url,
        ...(w && h ? { width: w, height: h } : {}),
      });
    }

    const pag = data.pagination ?? {};
    return NextResponse.json({
      ok: true,
      items,
      offset: typeof pag.offset === 'number' ? pag.offset : offset,
      count: typeof pag.count === 'number' ? pag.count : items.length,
      total: typeof pag.total_count === 'number' ? pag.total_count : items.length,
    });
  } catch (e) {
    console.error('[giphy/search]', e);
    return NextResponse.json({ ok: false, error: 'fetch_failed', items: [] });
  }
}
