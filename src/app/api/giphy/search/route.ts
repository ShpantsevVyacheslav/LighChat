import { NextRequest, NextResponse } from 'next/server';
import { translateSearchQueryToEn } from '@/lib/translate-search-query';

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
  const typeRaw = req.nextUrl.searchParams.get('type');
  const type: 'gifs' | 'stickers' | 'emoji' =
    typeRaw === 'stickers'
      ? 'stickers'
      : typeRaw === 'emoji'
      ? 'emoji'
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
  // Если запрос не на латинице (например русский) — переводим на английский,
  // т.к. GIPHY плохо ищет по кириллице даже с lang=ru.
  let effectiveQuery = q;
  let translatedFrom: string | null = null;
  // emoji-эндпоинт не поддерживает поиск, всегда trending.
  if (!isTrending && type !== 'emoji') {
    const t = await translateSearchQueryToEn(q);
    if (t.translated !== t.original) {
      effectiveQuery = t.translated;
      translatedFrom = t.original;
    }
  }
  // GIPHY endpoints:
  //   gifs:     /v1/gifs/{trending,search}
  //   stickers: /v1/stickers/{trending,search}
  //   emoji:    /v2/emoji  (только листинг анимированных эмодзи без поиска)
  const giphyUrl =
    type === 'emoji'
      ? new URL('https://api.giphy.com/v2/emoji')
      : new URL(
          `https://api.giphy.com/v1/${type}/${isTrending ? 'trending' : 'search'}`,
        );
  if (type !== 'emoji' && !isTrending) {
    giphyUrl.searchParams.set('q', effectiveQuery);
  }
  giphyUrl.searchParams.set('api_key', key);
  giphyUrl.searchParams.set('limit', String(PAGE_SIZE));
  giphyUrl.searchParams.set('offset', String(offset));
  if (type !== 'emoji') {
    giphyUrl.searchParams.set('rating', 'g');
    giphyUrl.searchParams.set('lang', 'en');
  }

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
        // GIPHY v2/emoji использует cursor-based pagination.
        next_cursor?: number;
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
    // Эффективный total: для gifs/stickers — total_count; для emoji
    // (cursor-based) есть next_cursor — считаем total = offset+count, плюс
    // выставляем hasMore по наличию курсора.
    let total: number;
    let hasMore: boolean;
    if (type === 'emoji') {
      const cursor = typeof pag.next_cursor === 'number' ? pag.next_cursor : 0;
      hasMore = cursor > offset + items.length || items.length >= PAGE_SIZE;
      total = hasMore ? offset + items.length + 1 : offset + items.length;
    } else {
      total = typeof pag.total_count === 'number'
        ? pag.total_count
        : items.length;
      hasMore = offset + items.length < total;
    }
    return NextResponse.json({
      ok: true,
      items,
      offset: typeof pag.offset === 'number' ? pag.offset : offset,
      count: typeof pag.count === 'number' ? pag.count : items.length,
      total,
      hasMore,
      // Если запрос был переведён — `translatedFrom` = оригинал пользователя,
      // `query` = что реально ушло в GIPHY (английский). Клиент может показать.
      query: effectiveQuery,
      translatedFrom,
    });
  } catch (e) {
    console.error('[giphy/search]', e);
    return NextResponse.json({ ok: false, error: 'fetch_failed', items: [] });
  }
}
