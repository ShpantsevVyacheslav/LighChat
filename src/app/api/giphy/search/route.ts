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
export async function GET(req: NextRequest) {
  const q = req.nextUrl.searchParams.get('q')?.trim() ?? '';
  const type = req.nextUrl.searchParams.get('type') === 'stickers'
    ? 'stickers'
    : 'gifs';
  const key = process.env.GIPHY_API_KEY;
  if (!key) {
    console.warn(
      '[giphy/search] GIPHY_API_KEY is not set. ' +
        'Add it via `firebase apphosting:secrets:set GIPHY_API_KEY` ' +
        'and update apphosting.yaml.',
    );
    return NextResponse.json(
      { ok: false, error: 'missing_key', items: [] as GifSearchItem[] },
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
  giphyUrl.searchParams.set('limit', '24');
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

    return NextResponse.json({ ok: true, items });
  } catch (e) {
    console.error('[giphy/search]', e);
    return NextResponse.json({ ok: false, error: 'fetch_failed', items: [] });
  }
}
