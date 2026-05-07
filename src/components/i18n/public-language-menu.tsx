'use client';

import { useI18n } from '@/hooks/use-i18n';
import type { AppLanguagePreference } from '@/lib/i18n/preference';
import { SUPPORTED_LOCALES, LANGUAGE_NATIVE_NAMES } from '@/lib/i18n/preference';
import { cn } from '@/lib/utils';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';

export function PublicLanguageMenu({ className }: { className?: string }) {
  const { preference, setPreference, t } = useI18n();

  return (
    <div className={cn(className)}>
      <Select
        value={preference}
        onValueChange={(v) => setPreference(v as AppLanguagePreference)}
      >
        <SelectTrigger
          className="h-9 w-[min(11rem,calc(100vw-1.5rem))] rounded-xl border-white/35 bg-white/20 text-xs font-medium text-slate-800 backdrop-blur-md dark:border-white/12 dark:bg-white/[0.08] dark:text-white/90"
          aria-label={t('settings.language.title')}
        >
          <SelectValue />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value="system">{t('settings.language.system')}</SelectItem>
          {SUPPORTED_LOCALES.map((loc) => (
            <SelectItem key={loc} value={loc}>
              {LANGUAGE_NATIVE_NAMES[loc]}
            </SelectItem>
          ))}
        </SelectContent>
      </Select>
    </div>
  );
}
