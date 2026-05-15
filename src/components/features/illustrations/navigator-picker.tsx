'use client';

import * as React from 'react';
import { Car, CalendarDays, MapPin, Navigation, Pin } from 'lucide-react';
import { cn } from '@/lib/utils';
import { useI18n } from '@/hooks/use-i18n';
import { getFeaturesContent } from '../features-content';

/**
 * Мокап navigator/calendar picker sheet: bottom-sheet с двумя группами —
 * «Maps» (Apple/Google/Yandex Maps + Yandex Navi) и «Taxi» (Yandex Go,
 * Uber). Внизу — CalendarDays и кнопка «Добавить в календарь» как реальный
 * `CalendarPickerSheet`.
 */

type Option = {
  id: string;
  label: { ru: string; en: string };
  /** Brand-цвет круглой иконки. */
  bg: string;
  Icon: typeof MapPin;
};

const MAPS: Option[] = [
  { id: 'apple', label: { ru: 'Apple Карты', en: 'Apple Maps' }, bg: '#1F8AF1', Icon: MapPin },
  { id: 'google', label: { ru: 'Google Maps', en: 'Google Maps' }, bg: '#1AAA56', Icon: Pin },
  { id: 'yandex', label: { ru: 'Яндекс.Карты', en: 'Yandex Maps' }, bg: '#FFCC00', Icon: Navigation },
  { id: 'navi', label: { ru: 'Яндекс.Навигатор', en: 'Yandex Navi' }, bg: '#FF8B00', Icon: Navigation },
];

const TAXI: Option[] = [
  { id: 'yandex-go', label: { ru: 'Яндекс Go', en: 'Yandex Go' }, bg: '#FFD81E', Icon: Car },
  { id: 'uber', label: { ru: 'Uber', en: 'Uber' }, bg: '#000000', Icon: Car },
];

function Row({ opt, isRu }: { opt: Option; isRu: boolean }) {
  const { Icon } = opt;
  // Тёмные бренд-фоны на чёрном плохо видны — подсветим лёгкой обводкой.
  const isDarkBg = opt.bg === '#000000';
  return (
    <div className="flex items-center gap-2 rounded-xl bg-background/55 px-2.5 py-1.5">
      <span
        className={cn(
          'flex h-7 w-7 shrink-0 items-center justify-center rounded-lg',
          isDarkBg && 'border border-white/15',
        )}
        style={{ backgroundColor: opt.bg }}
      >
        <Icon
          className="h-3.5 w-3.5"
          style={{ color: opt.bg === '#FFCC00' || opt.bg === '#FFD81E' ? '#1A1A1A' : '#FFFFFF' }}
          aria-hidden
        />
      </span>
      <span className="truncate text-[11px] font-semibold text-foreground">
        {opt.label[isRu ? 'ru' : 'en']}
      </span>
    </div>
  );
}

export function MockNavigatorPicker({
  className,
  compact,
}: {
  className?: string;
  compact?: boolean;
}) {
  const { locale } = useI18n();
  const t = React.useMemo(() => getFeaturesContent(locale).mockText, [locale]);
  const isRu = locale !== 'en';

  return (
    <div className={cn('relative h-full w-full overflow-hidden', className)}>
      {/* «Карта» под sheet'ом — слабая, чтобы не отвлекать */}
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_30%_30%,#1a4570_0%,#142b4a_45%,#0a1a30_100%)]" />
      <svg
        className="absolute inset-0 h-full w-full opacity-50"
        viewBox="0 0 400 240"
        preserveAspectRatio="xMidYMid slice"
        aria-hidden
      >
        <path d="M30,30 Q120,15 180,45 Q150,100 40,110 Z" fill="#1E3A2E" />
        <line x1="0" y1="120" x2="400" y2="120" stroke="#4A5A6F" strokeWidth="5" />
        <line x1="100" y1="0" x2="100" y2="240" stroke="#3A4A5C" strokeWidth="2" />
        <line x1="220" y1="0" x2="220" y2="240" stroke="#3A4A5C" strokeWidth="2" />
      </svg>
      <div className="absolute left-1/2 top-1/3 -translate-x-1/2 -translate-y-1/2">
        <span className="block h-3 w-3 rounded-full bg-emerald-500 ring-4 ring-emerald-400/40" />
      </div>

      {/* Bottom Sheet — реальный `NavigatorPickerSheet` (Material bottom-sheet) */}
      <div className="absolute inset-x-3 bottom-3 rounded-2xl border border-black/5 dark:border-white/10 bg-background/95 shadow-2xl backdrop-blur-2xl animate-feat-bubble-in">
        <div className="flex justify-center pt-1.5">
          <span className="block h-1 w-10 rounded-full bg-foreground/25" />
        </div>
        <div className="px-3 py-2">
          {/* Maps group */}
          <p className="px-0.5 text-[9px] font-bold uppercase tracking-wider text-muted-foreground">
            {t.navOpenInMaps}
          </p>
          <div className="mt-1.5 grid grid-cols-2 gap-1.5">
            {MAPS.map((opt) => (
              <Row key={opt.id} opt={opt} isRu={isRu} />
            ))}
          </div>

          {!compact ? (
            <>
              {/* Taxi group */}
              <p className="mt-2 px-0.5 text-[9px] font-bold uppercase tracking-wider text-muted-foreground">
                {t.navOpenInTaxi}
              </p>
              <div className="mt-1.5 grid grid-cols-2 gap-1.5">
                {TAXI.map((opt) => (
                  <Row key={opt.id} opt={opt} isRu={isRu} />
                ))}
              </div>

              {/* Calendar */}
              <div className="mt-2 flex items-center gap-2 rounded-xl border border-primary/20 bg-primary/10 px-2.5 py-1.5">
                <CalendarDays className="h-4 w-4 shrink-0 text-primary" aria-hidden />
                <span className="flex-1 truncate text-[11px] font-semibold text-primary">
                  {t.navAddToCalendar}
                </span>
              </div>
            </>
          ) : null}
        </div>
      </div>
    </div>
  );
}
