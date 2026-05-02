/**
 * Авто-перевод non-English поисковых запросов в English перед отправкой
 * в GIPHY (он плохо ищет по кириллице, даже с `lang=ru`).
 *
 * Используем бесплатный MyMemory Translation API без ключа
 * (лимит ~5000 слов/день для анонимных запросов).
 *
 * @see https://mymemory.translated.net/doc/spec.php
 */

// Простой in-process LRU кеш (живёт пока инстанс App Hosting не перезапустится).
// На каждый translation-запрос делаем только один external fetch, повторный
// одинаковый запрос отдаётся из кеша мгновенно.
const cache = new Map<string, { ts: number; value: string }>();
const CACHE_TTL_MS = 24 * 60 * 60 * 1000; // 24h
const CACHE_MAX = 500;

function cacheGet(key: string): string | null {
  const entry = cache.get(key);
  if (!entry) return null;
  if (Date.now() - entry.ts > CACHE_TTL_MS) {
    cache.delete(key);
    return null;
  }
  // refresh insertion order (LRU)
  cache.delete(key);
  cache.set(key, entry);
  return entry.value;
}

function cacheSet(key: string, value: string) {
  if (cache.size >= CACHE_MAX) {
    const firstKey = cache.keys().next().value;
    if (firstKey !== undefined) cache.delete(firstKey);
  }
  cache.set(key, { ts: Date.now(), value });
}

/** Содержит ли строка не-латинские буквы (кириллица, греческий и т.п.). */
function hasNonAsciiLetter(s: string): boolean {
  // \p{L} = любая буква, \p{Script=Latin} = латиница.
  return /\p{L}/u.test(s) && !/^[\p{Script=Latin}\p{N}\p{P}\p{Z}\p{S}\p{M}]+$/u.test(s);
}

/**
 * Переводит запрос на английский, если он не на латинице.
 * Возвращает `{ translated, original }`. Если перевод не нужен или упал —
 * `translated === original`.
 */
export async function translateSearchQueryToEn(
  q: string,
): Promise<{ translated: string; original: string }> {
  const original = q.trim();
  if (original.length < 1 || !hasNonAsciiLetter(original)) {
    return { translated: original, original };
  }
  const cached = cacheGet(original);
  if (cached !== null) {
    return { translated: cached, original };
  }
  try {
    const url = new URL('https://api.mymemory.translated.net/get');
    url.searchParams.set('q', original);
    url.searchParams.set('langpair', 'auto|en');
    const res = await fetch(url.toString(), {
      // 5s таймаут — если переводчик подвис, не блокируем GIF-поиск.
      signal: AbortSignal.timeout(5000),
    });
    if (!res.ok) return { translated: original, original };
    const data = (await res.json()) as {
      responseData?: { translatedText?: string };
      responseStatus?: number;
    };
    let translated = data.responseData?.translatedText?.trim() ?? '';
    // Иногда API возвращает trailing dot — убираем.
    translated = translated.replace(/\.\s*$/, '').trim();
    if (
      data.responseStatus !== 200 ||
      !translated ||
      // Защита от мусора и эхо-ответов.
      translated.toLowerCase() === original.toLowerCase()
    ) {
      return { translated: original, original };
    }
    cacheSet(original, translated);
    return { translated, original };
  } catch {
    return { translated: original, original };
  }
}
