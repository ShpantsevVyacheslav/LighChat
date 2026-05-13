'use client';

import * as React from 'react';
import { Mic, PhoneOff, Play, Video } from 'lucide-react';
import { cn } from '@/lib/utils';
import { useI18n } from '@/hooks/use-i18n';
import { getFeaturesContent } from '../features-content';

/**
 * Левая часть мокапа — компактная копия `AudioCallOverlay` (реально это
 * fullscreen-overlay `fixed inset-0 bg-slate-950`). Большой аватар в центре,
 * имя + длительность, круглые кнопки mic/end по центру.
 *
 * Правая часть — `VideoCirclePlayer`-стиль: круглое видео с SVG progress
 * вокруг (strokeDashoffset → текущая позиция), значок треугольника play и
 * бейдж длительности в правом-верхнем углу.
 *
 * Эквалайзер убран — в реальном `AudioCallOverlay` его нет.
 */

const PROGRESS_RADIUS = 47;
const PROGRESS_CIRCUMFERENCE = 2 * Math.PI * PROGRESS_RADIUS;

function VideoCircle({ initial, durationLabel }: { initial: string; durationLabel: string }) {
  // 42% от длительности — индикатор «играет».
  const PROGRESS = 0.42;
  const offset = PROGRESS_CIRCUMFERENCE * (1 - PROGRESS);
  return (
    <div className="relative h-24 w-24 shrink-0">
      {/* SVG progress (как в реальном VideoCirclePlayer) */}
      <svg viewBox="0 0 100 100" className="absolute inset-0 h-full w-full -rotate-90 drop-shadow">
        <circle cx="50" cy="50" r={PROGRESS_RADIUS} fill="none" stroke="rgba(255,255,255,0.15)" strokeWidth="3" />
        <circle
          cx="50"
          cy="50"
          r={PROGRESS_RADIUS}
          fill="none"
          stroke="hsl(var(--primary))"
          strokeWidth="3"
          strokeLinecap="round"
          strokeDasharray={PROGRESS_CIRCUMFERENCE}
          strokeDashoffset={offset}
          className="transition-[stroke-dashoffset] duration-700"
        />
      </svg>
      {/* Сам кружок */}
      <div className="absolute inset-1.5 overflow-hidden rounded-full border-2 border-background shadow-2xl">
        <div className="absolute inset-0 bg-gradient-to-br from-violet-500 to-primary" />
        <div className="absolute inset-0 flex items-center justify-center text-3xl font-bold text-white drop-shadow">
          {initial}
        </div>
        {/* Play overlay (как в реальном VideoCirclePlayer при паузе) */}
        <div className="absolute inset-0 flex items-center justify-center">
          <div className="flex h-8 w-8 items-center justify-center rounded-full bg-black/50 backdrop-blur-md animate-feat-bubble-in">
            <Play className="h-3.5 w-3.5 fill-white text-white" aria-hidden />
          </div>
        </div>
        {/* Длительность в правом-верхнем углу */}
        <div className="absolute right-1 top-1 rounded-md bg-black/55 px-1.5 py-0.5 text-[9px] font-bold text-white backdrop-blur-md">
          {durationLabel}
        </div>
      </div>
    </div>
  );
}

/** Аудио-звонок (`AudioCallOverlay`-стиль) + видео-кружок (`VideoCirclePlayer`). */
export function MockCalls({ className, compact }: { className?: string; compact?: boolean }) {
  const { locale } = useI18n();
  const t = React.useMemo(() => getFeaturesContent(locale).mockText, [locale]);
  return (
    <div className={cn('relative h-full w-full overflow-hidden', className)}>
      {/* Реально AudioCallOverlay — fullscreen `bg-slate-950`. */}
      <div className="absolute inset-0 bg-slate-950" />
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_center,hsl(var(--primary)/0.18),transparent_70%)]" />
      <div className="relative flex h-full w-full flex-col items-center justify-center gap-3 p-4 text-white">
        {/* Большой аватар с свечением */}
        <div className="relative flex h-16 w-16 items-center justify-center rounded-full border-4 border-white/10 bg-gradient-to-br from-emerald-400 to-emerald-600 text-xl font-bold text-emerald-950 shadow-[0_0_40px_rgba(52,211,153,0.45)]">
          {t.peerAlice.charAt(0)}
        </div>
        <div className="text-center leading-tight">
          <p className="text-sm font-bold">{t.peerAlice}</p>
          <p className="text-[11px] text-white/65">{t.callsAudioMeta}</p>
        </div>
        {!compact ? (
          <div className="mt-1 flex items-center gap-4">
            <button type="button" className="flex h-8 w-8 items-center justify-center rounded-full bg-white/10 hover:bg-white/20" aria-label="mic">
              <Mic className="h-4 w-4" aria-hidden />
            </button>
            <button type="button" className="flex h-9 w-9 items-center justify-center rounded-full bg-rose-500 text-white shadow-[0_0_20px_rgba(239,68,68,0.5)]" aria-label="end">
              <PhoneOff className="h-4 w-4" aria-hidden />
            </button>
            <button type="button" className="flex h-8 w-8 items-center justify-center rounded-full bg-white/10 hover:bg-white/20" aria-label="cam">
              <Video className="h-4 w-4" aria-hidden />
            </button>
          </div>
        ) : null}

        {/* Видео-кружок справа-снизу, как inline-плеер в чате */}
        {!compact ? (
          <div className="mt-3 flex items-center gap-3 rounded-2xl border border-white/10 bg-white/5 px-3 py-2 backdrop-blur-md">
            <VideoCircle initial={t.peerMikhail.charAt(0)} durationLabel="0:25 / 1:00" />
            <div className="min-w-0 leading-tight">
              <p className="text-xs font-bold">{t.callsCircleTitle}</p>
              <p className="text-[11px] text-white/65">{t.callsCircleMeta}</p>
            </div>
          </div>
        ) : null}
      </div>
    </div>
  );
}
