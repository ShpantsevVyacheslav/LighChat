import { NextRequest, NextResponse } from 'next/server';
import { translateSearchQueryToEn } from '@/lib/translate-search-query';
import { callerIpFromRequest, requireUserFromRequest } from '@/lib/server/route-auth';
import { consumeRouteRateLimit } from '@/lib/server/route-rate-limit';
import { logger } from '@/lib/logger';

export const runtime = 'nodejs';

type GifSearchItem = {
  id: string;
  url: string;
  width?: number;
  height?: number;
  emoji?: string;
  label?: string;
};

function _emojiFromHexSequence(raw: string): string | null {
  const parts = raw
    .split('-')
    .map((p) => p.trim())
    .filter((p) => p.length > 0);
  if (parts.length === 0 || parts.length > 10) return null;
  const cps: number[] = [];
  for (const p of parts) {
    if (!/^[0-9a-f]{2,6}$/i.test(p)) return null;
    const cp = Number.parseInt(p, 16);
    if (!Number.isFinite(cp) || cp <= 0 || cp > 0x10ffff) return null;
    cps.push(cp);
  }
  try {
    return String.fromCodePoint(...cps);
  } catch {
    return null;
  }
}

function _extractEmojiFromText(raw: string | null | undefined): string | null {
  if (!raw) return null;
  const s = raw.trim();
  if (!s) return null;
  // Частый кейс в slug/title: "...-1f44d" или "1f469-200d-1f4bb".
  const hexSeqMatch = s.match(/([0-9a-f]{4,6}(?:-[0-9a-f]{4,6}){0,9})/i);
  if (hexSeqMatch != null) {
    const decoded = _emojiFromHexSequence(hexSeqMatch[1]);
    if (decoded != null) return decoded;
  }
  // Иногда API уже отдаёт "нативный" символ в строковом поле.
  // Берём первую расширенную пиктограмму.
  const pictMatch = s.match(/\p{Extended_Pictographic}(?:\uFE0F|\u200D\p{Extended_Pictographic})*/u);
  if (pictMatch != null) return pictMatch[0];
  return null;
}

function _extractEmojiFromGiphyItem(
  item: Record<string, unknown>,
): string | null {
  const direct = [
    item.emoji,
    item.character,
    item.native,
    item.symbol,
  ];
  for (const candidate of direct) {
    if (typeof candidate != 'string') continue;
    const parsed = _extractEmojiFromText(candidate);
    if (parsed != null) return parsed;
  }
  const fallback = [
    item.slug,
    item.title,
    item.alt_text,
    item.id,
  ];
  for (const candidate of fallback) {
    if (typeof candidate != 'string') continue;
    const parsed = _extractEmojiFromText(candidate);
    if (parsed != null) return parsed;
  }
  return null;
}

function _extractLabelFromGiphyItem(
  item: Record<string, unknown>,
): string | null {
  const direct = [
    item.emoji,
    item.character,
    item.native,
    item.symbol,
    item.title,
    item.slug,
    item.alt_text,
    item.id,
  ];
  for (const candidate of direct) {
    if (typeof candidate != 'string') continue;
    const v = candidate.trim();
    if (v.length > 0) return v;
  }
  return null;
}

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
  // SECURITY: previously this was an anonymous proxy — any visitor on any
  // domain could call it, which (1) burned the project's GIPHY quota, and
  // (2) leaked GIPHY's IP-based rate limits to an attacker who could trace
  // billing back to us. Now we require a Firebase ID token plus a per-uid
  // burst limit (60 req / minute is roomy for the typical user typing into
  // the GIF picker, while making automated abuse expensive).
  const auth = await requireUserFromRequest(req);
  if (!auth.ok) return auth.response;
  const rl = await consumeRouteRateLimit({
    key: `giphy:uid:${auth.uid}`,
    limit: 60,
    windowSec: 60,
  });
  if (!rl.allowed) {
    return NextResponse.json(
      { ok: false, error: 'rate_limited', items: [] },
      { status: 429, headers: { 'Retry-After': String(rl.retryAfterSec) } },
    );
  }

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
    logger.warn(
      'giphy',
      'GIPHY_API_KEY is not set. Add it via `firebase apphosting:secrets:set GIPHY_API_KEY` and update apphosting.yaml.',
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
      logger.warn('giphy', 'response not ok', { status: res.status, body: await res.text().catch(() => '') });
      return NextResponse.json({ ok: false, error: 'giphy_http', items: [] });
    }
    const data = (await res.json()) as {
      data?: Array<{
        id?: string;
        slug?: string;
        title?: string;
        alt_text?: string;
        emoji?: string;
        character?: string;
        native?: string;
        symbol?: string;
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
      const emoji =
        type === 'emoji'
          ? _extractEmojiFromGiphyItem(r as Record<string, unknown>)
          : null;
      const label =
        type === 'emoji'
          ? _extractLabelFromGiphyItem(r as Record<string, unknown>)
          : null;
      items.push({
        id,
        url,
        ...(emoji ? { emoji } : {}),
        ...(label ? { label } : {}),
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
    logger.error('giphy', 'fetch failed', e);
    return NextResponse.json({ ok: false, error: 'fetch_failed', items: [] });
  }
}
