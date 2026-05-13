'use client';

import * as React from 'react';
import { MapPin, X } from 'lucide-react';
import { Button } from '@/components/ui/button';
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
      {/* Базовый «ночной» тёмно-синий слой карты */}
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_30%_30%,#1a4570_0%,#142b4a_45%,#0a1a30_100%)]" />
      {/* SVG-карта: парк, вода, здания, улицы, маршрут с движущимся пином и trail */}
      <svg
        className="absolute inset-0 h-full w-full"
        viewBox="0 0 400 240"
        preserveAspectRatio="xMidYMid slice"
      >
        {/* Парк */}
        <path d="M30,30 Q120,15 180,45 Q150,100 40,110 Z" fill="#1E3A2E" />
        {/* Вода */}
        <path d="M300,130 Q380,120 420,170 L420,250 L280,250 Z" fill="#14304D" />
        {/* Здания */}
        {[
          [200, 20, 30, 22],
          [240, 30, 24, 14],
          [280, 18, 32, 26],
          [328, 50, 40, 22],
          [60, 130, 32, 22],
          [108, 145, 40, 16],
          [180, 170, 32, 26],
          [232, 158, 40, 22],
          [40, 188, 28, 22],
        ].map(([x, y, w, h], i) => (
          <rect key={i} x={x} y={y} width={w} height={h} fill="#22324A" rx="1.5" />
        ))}
        {/* Главная дорога — горизонтальная */}
        <line x1="0" y1="120" x2="400" y2="120" stroke="#4A5A6F" strokeWidth="5" />
        {/* Диагональная */}
        <line x1="0" y1="50" x2="400" y2="72" stroke="#3A4A5C" strokeWidth="3" />
        {/* Вертикальные улицы */}
        <line x1="100" y1="0" x2="100" y2="240" stroke="#3A4A5C" strokeWidth="2" />
        <line x1="220" y1="0" x2="220" y2="240" stroke="#3A4A5C" strokeWidth="2" />
        <line x1="320" y1="0" x2="320" y2="240" stroke="#3A4A5C" strokeWidth="2" />
        {/* Тонкие */}
        <line x1="0" y1="72" x2="400" y2="78" stroke="#3A4A5C" strokeWidth="1" opacity="0.55" />
        <line x1="0" y1="168" x2="400" y2="172" stroke="#3A4A5C" strokeWidth="1" opacity="0.55" />

        {/* Маршрут (статичный, виден полностью полупрозрачным) */}
        <path
          d="M48,188 C128,96 220,156 320,76"
          fill="none"
          stroke="rgba(52,211,153,0.18)"
          strokeWidth="2.5"
          strokeLinecap="round"
        />
        {/* Trail — анимированно «рисуется» от 0 до 100% длины */}
        <path
          d="M48,188 C128,96 220,156 320,76"
          fill="none"
          stroke="#34D399"
          strokeWidth="2.5"
          strokeLinecap="round"
          strokeDasharray="300"
          strokeDashoffset="300"
          className="animate-feat-live-trail"
        />
        {/* Бегущий пин по маршруту через CSS-offset-path */}
        <g className="animate-feat-live-pin" style={{ offsetPath: 'path("M48,188 C128,96 220,156 320,76")' }}>
          <circle r="14" fill="rgba(52,211,153,0.30)" className="animate-feat-pin-pulse" />
          <circle r="8" fill="white" />
          <circle r="4.5" fill="#10B981" />
        </g>
      </svg>

      {/* Watermark «Maps» */}
      <div className="absolute right-1.5 top-1.5 rounded bg-black/40 px-1.5 py-0.5 text-[8px] font-bold tracking-wider text-white/70">
        Maps
      </div>

      {/* Stop banner */}
      {!compact ? (
        <div
          className="absolute inset-x-3 bottom-3 flex items-center gap-2 rounded-2xl border border-emerald-500/50 bg-emerald-950 px-3 py-2 text-sm text-emerald-50 shadow-lg animate-feat-bubble-in"
          style={{ animationDelay: '300ms' }}
        >
          <MapPin className="h-4 w-4 shrink-0 animate-pulse text-emerald-300" aria-hidden />
          <span className="min-w-0 flex-1 font-medium">{t.liveLocationBanner}</span>
          <Button
            type="button"
            size="sm"
            variant="secondary"
            className="h-8 gap-1 bg-white/15 px-2 text-[11px] font-semibold text-white hover:bg-white/25"
            aria-label="stop"
          >
            <X className="h-3 w-3" aria-hidden />
            {t.liveLocationStop}
          </Button>
        </div>
      ) : null}
    </div>
  );
}
