/**
 * Нормализация для поиска контактов/пользователей: запрос на русском находит латиницу в имени и наоборот.
 * Таблицы — упрощённая транслитерация (имена, @username).
 */

const CYR_TO_LAT: Record<string, string> = {
  а: 'a',
  б: 'b',
  в: 'v',
  г: 'g',
  д: 'd',
  е: 'e',
  ё: 'e',
  ж: 'zh',
  з: 'z',
  и: 'i',
  й: 'y',
  к: 'k',
  л: 'l',
  м: 'm',
  н: 'n',
  о: 'o',
  п: 'p',
  р: 'r',
  с: 's',
  т: 't',
  у: 'u',
  ф: 'f',
  х: 'h',
  ц: 'ts',
  ч: 'ch',
  ш: 'sh',
  щ: 'sch',
  ъ: '',
  ы: 'y',
  ь: '',
  э: 'e',
  ю: 'yu',
  я: 'ya',
};

/** Латиница → кириллица: сначала диграфы, затем одна буква. */
const LATIN_MULTI: [string, string][] = [
  ['sch', 'щ'],
  ['sh', 'ш'],
  ['ch', 'ч'],
  ['zh', 'ж'],
  ['ts', 'ц'],
  ['kh', 'х'],
  ['yu', 'ю'],
  ['ya', 'я'],
  ['yo', 'ё'],
  ['ye', 'е'],
];

const LATIN_SINGLE: Record<string, string> = {
  a: 'а',
  b: 'б',
  v: 'в',
  w: 'в',
  g: 'г',
  d: 'д',
  e: 'е',
  z: 'з',
  i: 'и',
  y: 'й',
  j: 'й',
  k: 'к',
  l: 'л',
  m: 'м',
  n: 'н',
  o: 'о',
  p: 'п',
  r: 'р',
  s: 'с',
  t: 'т',
  u: 'у',
  f: 'ф',
  h: 'х',
  x: 'кс',
  c: 'к',
  q: 'к',
};

export function cyrillicToLatin(input: string): string {
  let out = '';
  const s = input.toLowerCase();
  for (let i = 0; i < s.length; i++) {
    const ch = s[i];
    if (ch && CYR_TO_LAT[ch] !== undefined) {
      out += CYR_TO_LAT[ch];
    } else {
      out += ch;
    }
  }
  return out;
}

export function latinToCyrillic(input: string): string {
  const s = input.toLowerCase();
  let out = '';
  let i = 0;
  while (i < s.length) {
    let matched = false;
    for (const [lat, cyr] of LATIN_MULTI) {
      if (s.startsWith(lat, i)) {
        out += cyr;
        i += lat.length;
        matched = true;
        break;
      }
    }
    if (matched) continue;
    const c = s[i];
    if (c && LATIN_SINGLE[c]) {
      out += LATIN_SINGLE[c];
    } else {
      out += c ?? '';
    }
    i++;
  }
  return out;
}

const HAS_CYR = /[а-яё]/i;
const HAS_LAT = /[a-z]/i;

/** Варианты строки для сопоставления с запросом (нижний регистр). */
export function haystackSearchVariants(text: string): string[] {
  const t = text.trim().toLowerCase();
  if (!t) return [];
  const set = new Set<string>([t]);
  if (HAS_CYR.test(t)) {
    const lat = cyrillicToLatin(t);
    if (lat && lat !== t) set.add(lat);
  }
  if (HAS_LAT.test(t)) {
    const cyr = latinToCyrillic(t);
    if (cyr && cyr !== t) set.add(cyr);
  }
  return [...set];
}

/** Варианты подстроки запроса (нижний регистр). */
export function querySearchNeedles(query: string): string[] {
  const q = query.trim().toLowerCase();
  if (!q) return [];
  const set = new Set<string>([q]);
  if (HAS_CYR.test(q)) {
    const lat = cyrillicToLatin(q);
    if (lat && lat !== q) set.add(lat);
  }
  if (HAS_LAT.test(q)) {
    const cyr = latinToCyrillic(q);
    if (cyr && cyr !== q) set.add(cyr);
  }
  return [...set].filter(Boolean);
}

/** Подстрока: хотя бы одна пара needle ⊆ hay совпала. */
export function ruEnSubstringMatch(haystack: string, needle: string): boolean {
  const needles = querySearchNeedles(needle);
  if (needles.length === 0) return true;
  const hays = haystackSearchVariants(haystack);
  for (const hay of hays) {
    for (const n of needles) {
      if (n && hay.includes(n)) return true;
    }
  }
  return false;
}
