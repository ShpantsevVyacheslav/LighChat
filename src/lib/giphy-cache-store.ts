/**
 * Локальный кеш GIPHY-выдач в `localStorage`:
 * - trending GIF/stickers (TTL 24 часа) — не дёргает API чаще раза в сутки
 * - последние 30 «просмотренных» (отправленных) GIF
 *
 * Паритет с мобильным `mobile/app/lib/features/chat/data/giphy_cache_store.dart`.
 */

export type GiphyItem = {
  id: string;
  url: string;
  width?: number;
  height?: number;
};

export type GiphyType = 'gifs' | 'stickers';

const TRENDING_TTL_MS = 24 * 60 * 60 * 1000;
const RECENT_MAX = 30;

const trendingKey = (type: GiphyType) =>
  type === 'stickers' ? 'giphy_trending_stickers_v1' : 'giphy_trending_gifs_v1';
const RECENT_KEY = 'giphy_recent_gifs_v1';

function safeParse<T>(raw: string | null): T | null {
  if (!raw) return null;
  try {
    return JSON.parse(raw) as T;
  } catch {
    return null;
  }
}

function isBrowser() {
  return typeof window !== 'undefined' && typeof localStorage !== 'undefined';
}

export const giphyCache = {
  /** Возвращает trending из кеша, если он не старше 24h, иначе null. */
  getTrending(type: GiphyType): GiphyItem[] | null {
    if (!isBrowser()) return null;
    const raw = localStorage.getItem(trendingKey(type));
    const parsed = safeParse<{ ts: number; items: GiphyItem[] }>(raw);
    if (!parsed) return null;
    if (Date.now() - parsed.ts > TRENDING_TTL_MS) return null;
    return Array.isArray(parsed.items) ? parsed.items : null;
  },

  saveTrending(type: GiphyType, items: GiphyItem[]) {
    if (!isBrowser()) return;
    try {
      localStorage.setItem(
        trendingKey(type),
        JSON.stringify({ ts: Date.now(), items }),
      );
    } catch {
      /* quota / private mode */
    }
  },

  getRecent(): GiphyItem[] {
    if (!isBrowser()) return [];
    const parsed = safeParse<GiphyItem[]>(localStorage.getItem(RECENT_KEY));
    return Array.isArray(parsed) ? parsed : [];
  },

  addRecent(item: GiphyItem) {
    if (!isBrowser()) return;
    const list = giphyCache.getRecent().filter(
      (a) => a.url !== item.url && a.id !== item.id,
    );
    list.unshift(item);
    if (list.length > RECENT_MAX) list.length = RECENT_MAX;
    try {
      localStorage.setItem(RECENT_KEY, JSON.stringify(list));
    } catch {
      /* quota */
    }
  },
};
