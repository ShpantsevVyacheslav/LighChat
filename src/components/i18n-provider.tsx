'use client';

import * as React from 'react';
import {
  APP_LANGUAGE_STORAGE_KEY,
  browserDefaultLocale,
  parseAppLanguagePreference,
  resolveWebLocale,
  type AppLanguagePreference,
  type ResolvedWebLocale,
} from '@/lib/i18n/preference';
import { messagesEn } from '@/lib/i18n/messages/en';
import { messagesRu } from '@/lib/i18n/messages/ru';
import { translate } from '@/lib/i18n/translate';
import type { AppMessages } from '@/lib/i18n/messages/en';

export type TranslateFn = (path: string, params?: Record<string, string | number>) => string;

type I18nContextValue = {
  preference: AppLanguagePreference;
  locale: ResolvedWebLocale;
  setPreference: (next: AppLanguagePreference) => void;
  t: TranslateFn;
  messages: AppMessages;
};

const I18nContext = React.createContext<I18nContextValue | null>(null);

function readPreferenceFromStorage(): AppLanguagePreference {
  try {
    return parseAppLanguagePreference(
      typeof window !== 'undefined' ? window.localStorage.getItem(APP_LANGUAGE_STORAGE_KEY) : null
    );
  } catch {
    return 'system';
  }
}

export function I18nProvider({ children }: { children: React.ReactNode }) {
  const [preference, setPreferenceState] = React.useState<AppLanguagePreference>('system');
  const [hydrated, setHydrated] = React.useState(false);

  React.useEffect(() => {
    setPreferenceState(readPreferenceFromStorage());
    setHydrated(true);
  }, []);

  const locale = React.useMemo(() => resolveWebLocale(preference), [preference]);

  const messages = locale === 'en' ? messagesEn : messagesRu;

  const t = React.useCallback(
    (path: string, params?: Record<string, string | number>) => translate(messages, path, params),
    [messages]
  );

  const setPreference = React.useCallback((next: AppLanguagePreference) => {
    setPreferenceState(next);
    try {
      window.localStorage.setItem(APP_LANGUAGE_STORAGE_KEY, next);
    } catch {
      /* ignore */
    }
  }, []);

  React.useEffect(() => {
    if (!hydrated) return;
    try {
      document.documentElement.lang = locale;
    } catch {
      /* ignore */
    }
  }, [hydrated, locale]);

  const value = React.useMemo<I18nContextValue>(
    () => ({
      preference,
      locale,
      setPreference,
      t,
      messages,
    }),
    [preference, locale, setPreference, t, messages]
  );

  return <I18nContext.Provider value={value}>{children}</I18nContext.Provider>;
}

/**
 * Используется в `not-found.tsx` и `error.tsx`, которые в Next.js App Router
 * могут оказаться вне provider'ов при определённых ошибочных рендерах. Раньше
 * мы кидали — это превращало любую runtime-ошибку в "Критическую ошибку"
 * (`global-error.tsx`), маскируя оригинальный bug. Теперь при отсутствии
 * provider'а возвращаем degradate-значение по `navigator.language`.
 */
export function useI18nContext(): I18nContextValue {
  const ctx = React.useContext(I18nContext);
  if (ctx) return ctx;
  return FALLBACK_I18N_CONTEXT;
}

const FALLBACK_I18N_CONTEXT: I18nContextValue = (() => {
  const locale = browserDefaultLocale();
  const messages = locale === 'en' ? messagesEn : messagesRu;
  return {
    preference: 'system',
    locale,
    setPreference: () => {},
    t: (path, params) => translate(messages, path, params),
    messages,
  };
})();
