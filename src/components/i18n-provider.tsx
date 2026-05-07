'use client';

import * as React from 'react';
import {
  APP_LANGUAGE_STORAGE_KEY,
  parseAppLanguagePreference,
  resolveWebLocale,
  type AppLanguagePreference,
  type ResolvedWebLocale,
} from '@/lib/i18n/preference';
import { messagesEn } from '@/lib/i18n/messages/en';
import { messagesRu } from '@/lib/i18n/messages/ru';
import { messagesKk } from '@/lib/i18n/messages/kk';
import { messagesUz } from '@/lib/i18n/messages/uz';
import { messagesTr } from '@/lib/i18n/messages/tr';
import { messagesId } from '@/lib/i18n/messages/id';
import { messagesPtBr } from '@/lib/i18n/messages/pt-BR';
import { messagesEsMx } from '@/lib/i18n/messages/es-MX';
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

  const MESSAGES_MAP: Record<ResolvedWebLocale, AppMessages> = {
    ru: messagesRu,
    en: messagesEn,
    kk: messagesKk,
    uz: messagesUz,
    tr: messagesTr,
    id: messagesId,
    'pt-BR': messagesPtBr,
    'es-MX': messagesEsMx,
  };

  const messages = MESSAGES_MAP[locale] ?? messagesRu;

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

export function useI18nContext(): I18nContextValue {
  const ctx = React.useContext(I18nContext);
  if (!ctx) {
    throw new Error('useI18nContext must be used within I18nProvider');
  }
  return ctx;
}
