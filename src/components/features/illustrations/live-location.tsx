'use client';

import * as React from 'react';
import { MapPin, X } from 'lucide-react';
import { cn } from '@/lib/utils';
import { useI18n } from '@/hooks/use-i18n';
import { getFeaturesContent } from '../features-content';

/**
 * Карта (gradient + grid) с пульсирующим пином и баннером в стиле реального
 * `LiveLocationStopBanner` — тёмно-зелёный, с MapPin и кнопкой «Остановить».
 * Раньше у меня баннер был красный — это было неверно.
 */
export function MockLiveLocation({
  className,
  compact,
}: {
  className?: string;
  compact?: boolean;
}) {
  const { locale } = useI18n();
  const t = React.useMemo(() => getFeaturesContent(locale).mockText, [locale]);
  return (
    <div className={cn('relative flex h-full w-full overflow-hidden', className)}>
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_30%_30%,#9be7c4_0%,#6ec5e8_45%,#3a4f86_100%)] dark:bg-[radial-gradient(circle_at_30%_30%,#3b6857_0%,#1f4566_45%,#0e1a3a_100%)]" />
      <svg className="absolute inset-0 h-full w-full opacity-30" viewBox="0 0 400 240" preserveAspectRatio="none">
        <path d="M0,160 C60,140 120,180 180,150 C240,120 300,160 400,130" fill="none" stroke="white" strokeWidth="1" />
        <path d="M0,90 C80,80 160,110 220,90 C280,70 340,100 400,80" fill="none" stroke="white" strokeWidth="1" />
        <path d="M40,0 L40,240 M180,0 L180,240 M320,0 L320,240" stroke="white" strokeWidth="0.5" opacity="0.4" />
      </svg>
      <div className="relative flex h-full w-full flex-col items-center justify-center gap-3 p-3">
        {/* Пульсирующий пин по центру */}
        <div className="relative mx-auto h-24 w-24">
          <span className="absolute inset-0 rounded-full bg-emerald-500/40 animate-feat-pin-pulse" />
          <span
            className="absolute inset-0 rounded-full bg-emerald-500/40 animate-feat-pin-pulse"
            style={{ animationDelay: '1.2s' }}
          />
          <span className="absolute inset-3 rounded-full bg-emerald-500/70" />
          <span className="absolute inset-7 rounded-full bg-white/95 shadow-lg flex items-center justify-center">
            <MapPin className="h-5 w-5 text-emerald-600" aria-hidden />
          </span>
        </div>
        {/* Реальный `LiveLocationStopBanner`: тёмно-зелёный */}
        {!compact ? (
          <div
            className="flex w-full max-w-sm items-center gap-2 rounded-2xl border border-emerald-500/40 bg-emerald-950/90 px-3 py-2 text-sm text-emerald-50 shadow-lg backdrop-blur-md animate-feat-bubble-in"
            style={{ animationDelay: '300ms' }}
          >
            <MapPin className="h-4 w-4 shrink-0 animate-pulse text-emerald-300" aria-hidden />
            <span className="min-w-0 flex-1 font-medium">{t.liveLocationBanner}</span>
            <button
              type="button"
              className="flex h-7 items-center gap-1 rounded-xl bg-white/15 px-2 text-[11px] font-semibold text-white"
              aria-label="stop"
            >
              <X className="h-3 w-3" aria-hidden />
              {t.liveLocationStop}
            </button>
          </div>
        ) : null}
      </div>
    </div>
  );
}
