export type AppLanguagePreference = 'system' | 'ru' | 'en';

export type ResolvedWebLocale = 'ru' | 'en';

export const APP_LANGUAGE_STORAGE_KEY = 'appLanguagePreference';

export function parseAppLanguagePreference(raw: string | null | undefined): AppLanguagePreference {
  const v = (raw ?? '').trim().toLowerCase();
  if (v === 'ru' || v === 'en' || v === 'system') return v;
  return 'system';
}

export function browserDefaultLocale(): ResolvedWebLocale {
  if (typeof navigator === 'undefined') return 'ru';
  const lang = (navigator.language || 'ru').toLowerCase();
  return lang.startsWith('en') ? 'en' : 'ru';
}

export function resolveWebLocale(preference: AppLanguagePreference): ResolvedWebLocale {
  if (preference === 'en' || preference === 'ru') return preference;
  return browserDefaultLocale();
}
