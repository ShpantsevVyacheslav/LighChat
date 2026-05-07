export type AppLanguagePreference =
  | 'system'
  | 'ru'
  | 'en'
  | 'kk'
  | 'uz'
  | 'tr'
  | 'id'
  | 'pt-BR'
  | 'es-MX';

export type ResolvedWebLocale = Exclude<AppLanguagePreference, 'system'>;

/** Каноничный порядок: ru/en — основные, далее по приоритету целевых рынков из docs/marketing. */
export const SUPPORTED_LOCALES: readonly ResolvedWebLocale[] = [
  'ru',
  'en',
  'kk',
  'uz',
  'tr',
  'id',
  'pt-BR',
  'es-MX',
] as const;

/**
 * Имя языка в его собственной локали — стандартный UX-приём (пользователь, читающий другую
 * систему письма, всегда узнает свой язык в списке).
 */
export const LANGUAGE_NATIVE_NAMES: Record<ResolvedWebLocale, string> = {
  ru: 'Русский',
  en: 'English',
  kk: 'Қазақша',
  uz: 'Oʻzbekcha',
  tr: 'Türkçe',
  id: 'Bahasa Indonesia',
  'pt-BR': 'Português (BR)',
  'es-MX': 'Español (MX)',
};

export const APP_LANGUAGE_STORAGE_KEY = 'appLanguagePreference';

const SUPPORTED_SET: ReadonlySet<string> = new Set<string>(SUPPORTED_LOCALES);

export function parseAppLanguagePreference(raw: string | null | undefined): AppLanguagePreference {
  const v = (raw ?? '').trim();
  if (v === 'system') return 'system';
  if (SUPPORTED_SET.has(v)) return v as AppLanguagePreference;
  // Обратная совместимость: ранее значение записывалось lowercase'ом (ru/en).
  const lower = v.toLowerCase();
  if (lower === 'ru' || lower === 'en') return lower;
  return 'system';
}

/**
 * Маппинг `navigator.language` → одна из поддерживаемых локалей.
 * Работает также для серверного рендера (возвращает `ru` если navigator недоступен).
 */
export function browserDefaultLocale(): ResolvedWebLocale {
  if (typeof navigator === 'undefined') return 'ru';
  const raw = navigator.language || 'ru';
  const lower = raw.toLowerCase();

  // Точные региональные совпадения — pt-BR (other Portuguese variants → BR fallback).
  if (lower.startsWith('pt')) return 'pt-BR';
  // Все варианты испанского (es-MX, es-419, es-AR, es-ES, es-CO…) → es-MX (LATAM)
  // У нас только одна испанская локаль — нейтральная LATAM, она ближе к es-ES чем ничего.
  if (lower.startsWith('es')) return 'es-MX';
  if (lower.startsWith('kk')) return 'kk';
  // Узбекский: navigator.language обычно `uz`, `uz-UZ`, `uz-Latn-UZ`, `uz-Cyrl-UZ`.
  // У нас латиница — отдаём её.
  if (lower.startsWith('uz')) return 'uz';
  if (lower.startsWith('tr')) return 'tr';
  // Индонезийский: navigator может вернуть `id` (BCP 47) или `in` (legacy ISO 639-1).
  if (lower.startsWith('id') || lower.startsWith('in')) return 'id';
  if (lower.startsWith('en')) return 'en';
  return 'ru';
}

export function resolveWebLocale(preference: AppLanguagePreference): ResolvedWebLocale {
  if (preference !== 'system') return preference;
  return browserDefaultLocale();
}
