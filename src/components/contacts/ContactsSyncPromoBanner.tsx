'use client';

import * as React from 'react';
import { UserPlus } from 'lucide-react';
import { cn } from '@/lib/utils';
import { useI18n } from '@/hooks/use-i18n';

type ContactsSyncPromoBannerProps = {
  onClick: () => void;
  disabled?: boolean;
  className?: string;
};

/**
 * CTA в духе «Связать все контакты»: синий блок с водяным знаком и круглой кнопкой.
 */
export function ContactsSyncPromoBanner({ onClick, disabled, className }: ContactsSyncPromoBannerProps) {
  const { t } = useI18n();
  return (
    <button
      type="button"
      disabled={disabled}
      onClick={onClick}
      className={cn(
        'relative mt-5 w-full overflow-hidden rounded-3xl px-4 py-3.5 text-left shadow-lg transition-all active:scale-[0.99] disabled:opacity-60',
        'bg-[#007AFF] text-white ring-1 ring-white/10',
        className
      )}
      aria-label={t('contacts.syncPromo.ariaLabel')}
    >
      <div
        className="pointer-events-none absolute inset-0 opacity-[0.14]"
        style={{
          backgroundImage: `url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='56' height='56' viewBox='0 0 24 24' fill='none' stroke='white' stroke-width='1.25' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2'/%3E%3Ccircle cx='9' cy='7' r='4'/%3E%3Cline x1='19' x2='19' y1='8' y2='14'/%3E%3Cline x1='22' x2='16' y1='11' y2='11'/%3E%3C/svg%3E")`,
          backgroundSize: '52px 52px',
        }}
        aria-hidden
      />
      <div className="relative flex items-center gap-3">
        <div className="min-w-0 flex-1 pr-1">
          <p className="text-[0.95rem] font-bold leading-snug tracking-tight">{t('contacts.syncPromo.title')}</p>
          <p className="mt-0.5 text-xs font-medium leading-snug text-white/90">
            {t('contacts.syncPromo.subtitle')}
          </p>
        </div>
        <div
          className="flex h-12 w-12 shrink-0 items-center justify-center rounded-full bg-white/22 ring-1 ring-white/25"
          aria-hidden
        >
          <UserPlus className="h-6 w-6 text-white" strokeWidth={2} />
        </div>
      </div>
    </button>
  );
}
