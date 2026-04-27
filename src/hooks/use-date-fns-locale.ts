'use client';

import { enUS, ru } from 'date-fns/locale';
import { useI18n } from '@/hooks/use-i18n';

export function useDateFnsLocale() {
  const { locale } = useI18n();
  return locale === 'en' ? enUS : ru;
}
