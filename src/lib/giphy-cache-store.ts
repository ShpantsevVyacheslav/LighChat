/**
 * Локальный кеш GIPHY-выдач в `localStorage`:
 * - **query-cache**: результаты поиска по любой паре `(type, query)` с TTL 24h
 *   (trending = пустой query). LRU-лимит на 20 ключей.
 * - **recent**: последние 30 «просмотренных» (отправленных) GIF.
 *
 * Паритет с мобильным `mobile/app/lib/features/chat/data/giphy_cache_store.dart`.
 */

export type GiphyItem = {
  id: string;
  url: string;
  width?: number;
  height?: number;
};

export type GiphyType = 'gifs' | 'stickers' | 'emoji';

type CacheEntry = {
  ts: number;
  items: GiphyItem[];
};

const TTL_MS = 24 * 60 * 60 * 1000;
const MAX_KEYS = 20;
const RECENT_MAX = 30;
const QUERY_CACHE_KEY = 'giphy_query_cache_v2';
const RECENT_KEY = 'giphy_recent_gifs_v1';

function isBrowser() {
  return typeof window !== 'undefined' && typeof localStorage !== 'undefined';
}

function safeParse<T>(raw: string | null): T | null {
  if (!raw) return null;
  try {
    return JSON.parse(raw) as T;
  } catch {
    return null;
  }
}

function makeKey(type: GiphyType, query: string): string {
  return `${type}:${query.trim()}`;
}

function loadAll(): Record<string, CacheEntry> {
  if (!isBrowser()) return {};
  const m = safeParse<Record<string, CacheEntry>>(
    localStorage.getItem(QUERY_CACHE_KEY),
  );
  return m && typeof m === 'object' ? m : {};
}

function saveAll(all: Record<string, CacheEntry>) {
  if (!isBrowser()) return;
  try {
    localStorage.setItem(QUERY_CACHE_KEY, JSON.stringify(all));
  } catch {
    /* quota / private mode */
  }
}

export const giphyCache = {
  /** Возвращает items для пары (type, query) если запись не старше 24h.
   *
   *  Исключение: для type='emoji' (анимированные эмодзи) TTL не применяется —
   *  каталог стабильный, новые позиции добираются только пагинацией,
   *  а старые остаются в кеше навсегда.
   */
  get(type: GiphyType, query: string): GiphyItem[] | null {
    const all = loadAll();
    const entry = all[makeKey(type, query)];
    if (!entry) return null;
    if (type !== 'emoji' && Date.now() - entry.ts > TTL_MS) return null;
    return Array.isArray(entry.items) ? entry.items : null;
  },

  /** Сохраняет items по (type, query). LRU: при > 20 ключей удаляем самые старые.
   *  Эмодзи-ключи (`emoji:*`) защищены от вытеснения. */
  save(type: GiphyType, query: string, items: GiphyItem[]) {
    if (!items.length) return;
    const all = loadAll();
    all[makeKey(type, query)] = { ts: Date.now(), items };
    const keys = Object.keys(all);
    if (keys.length > MAX_KEYS) {
      const sorted = keys
        .filter((k) => !k.startsWith('emoji:'))
        .map((k) => ({ k, ts: all[k].ts ?? 0 }))
        .sort((a, b) => a.ts - b.ts);
      const toRemove = keys.length - MAX_KEYS;
      for (let i = 0; i < toRemove && i < sorted.length; i++) {
        delete all[sorted[i].k];
      }
    }
    saveAll(all);
  },

  // Удобные обёртки для trending (q='').
  getTrending(type: GiphyType): GiphyItem[] | null {
    return giphyCache.get(type, '');
  },
  saveTrending(type: GiphyType, items: GiphyItem[]) {
    giphyCache.save(type, '', items);
  },

  // Recent — последние отправленные GIF.
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
