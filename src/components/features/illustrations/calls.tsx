'use client';

import * as React from 'react';
import { Mic, PhoneOff, Play, Video } from 'lucide-react';
import { cn } from '@/lib/utils';
import { useI18n } from '@/hooks/use-i18n';
import { getFeaturesContent } from '../features-content';

/**
 * Тема features `calls` объединяет ДВЕ разные сущности LighChat:
 *   1. Real-time audio/video звонки 1:1 (`AudioCallOverlay`) — fullscreen.
 *   2. Видео-кружки (`VideoCirclePlayer`) — самостоятельные сообщения-видео
 *      внутри ленты чата, как у Telegram.
 *
 * Раньше они были смешаны в одной композиции — пользователь правильно
 * указал, что это разные вещи. Теперь мокап разделён на две явные
 * визуальные половины со своими подписями.
 */

const PROGRESS_RADIUS = 47;
const PROGRESS_CIRCUMFERENCE = 2 * Math.PI * PROGRESS_RADIUS;

/** Реалистичная копия `AudioCallOverlay`: fullscreen `bg-slate-950`,
 *  большой аватар в центре с глоу, имя + длительность, ряд круглых кнопок. */
function AudioCallScreen({
  name,
  meta,
  initial,
}: {
  name: string;
  meta: string;
  initial: string;
}) {
  return (
    <div className="relative flex h-full w-full flex-col items-center justify-center gap-2 overflow-hidden rounded-2xl bg-slate-950 p-3 text-white">
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_center,hsl(var(--primary)/0.18),transparent_70%)]" />
      <div className="relative flex h-14 w-14 items-center justify-center rounded-full border-4 border-white/10 bg-gradient-to-br from-emerald-400 to-emerald-600 text-base font-bold text-emerald-950 shadow-[0_0_30px_rgba(52,211,153,0.45)]">
        {initial}
      </div>
      <div className="relative text-center leading-tight">
        <p className="text-[12px] font-bold">{name}</p>
        <p className="text-[10px] text-white/65">{meta}</p>
      </div>
      <div className="relative mt-1 flex items-center gap-2">
        <button
          type="button"
          className="flex h-7 w-7 items-center justify-center rounded-full bg-white/10 hover:bg-white/20"
          aria-label="mic"
        >
          <Mic className="h-3.5 w-3.5" aria-hidden />
        </button>
        <button
          type="button"
          className="flex h-8 w-8 items-center justify-center rounded-full bg-rose-500 text-white shadow-[0_0_16px_rgba(239,68,68,0.5)]"
          aria-label="end"
        >
          <PhoneOff className="h-3.5 w-3.5" aria-hidden />
        </button>
        <button
          type="button"
          className="flex h-7 w-7 items-center justify-center rounded-full bg-white/10 hover:bg-white/20"
          aria-label="cam"
        >
          <Video className="h-3.5 w-3.5" aria-hidden />
        </button>
      </div>
    </div>
  );
}

/** Реалистичная копия `VideoCirclePlayer`: круглое видео с SVG progress-кольцом
 *  вокруг, треугольником play по центру и бейджем длительности в углу.
 *  В реальном UI кружок — это inline видео-сообщение, поэтому показываем его
 *  «внутри» имитации message-bubble фрагмента. */
function VideoCircleMessage({
  initial,
  durationLabel,
  recipientName,
}: {
  initial: string;
  durationLabel: string;
  recipientName: string;
}) {
  const PROGRESS = 0.42;
  const offset = PROGRESS_CIRCUMFERENCE * (1 - PROGRESS);
  return (
    <div className="relative flex h-full w-full flex-col items-center justify-center gap-2 p-3">
      <div className="absolute inset-0 rounded-2xl bg-gradient-to-br from-violet-500/10 via-primary/5 to-transparent" />
      <div className="relative h-24 w-24 shrink-0">
        {/* SVG progress (так же как в реальном `VideoCirclePlayer`) */}
        <svg viewBox="0 0 100 100" className="absolute inset-0 h-full w-full -rotate-90 drop-shadow">
          <circle cx="50" cy="50" r={PROGRESS_RADIUS} fill="none" stroke="rgba(255,255,255,0.35)" strokeWidth="3" />
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
        <div className="absolute inset-1.5 overflow-hidden rounded-full border-2 border-background shadow-2xl">
          <div className="absolute inset-0 bg-gradient-to-br from-violet-500 to-primary" />
          <div className="absolute inset-0 flex items-center justify-center text-3xl font-bold text-white drop-shadow">
            {initial}
          </div>
          <div className="absolute inset-0 flex items-center justify-center">
            <div className="flex h-8 w-8 items-center justify-center rounded-full bg-black/50 backdrop-blur-md animate-feat-bubble-in">
              <Play className="h-3.5 w-3.5 fill-white text-white" aria-hidden />
            </div>
          </div>
          {/* Бейдж длительности — вверху центра, как в реальном `VideoCirclePlayer` */}
          <div className="absolute left-1/2 top-1 -translate-x-1/2 rounded-md bg-black/55 px-1.5 py-0.5 text-[8.5px] font-bold text-white backdrop-blur-md">
            {durationLabel}
          </div>
        </div>
      </div>
      <p className="relative text-center text-[10px] leading-tight text-muted-foreground">
        {recipientName}
      </p>
    </div>
  );
}

/**
 * Мокап темы calls: слева — экран real-time звонка, справа — видео-кружок
 * как inline сообщение. Между ними тонкий разделитель и подписи,
 * чтобы было понятно, что это РАЗНЫЕ сущности.
 */
export function MockCalls({ className, compact }: { className?: string; compact?: boolean }) {
  const { locale } = useI18n();
  const t = React.useMemo(() => getFeaturesContent(locale).mockText, [locale]);

  // Compact thumbnail — только звонок (без видео-кружка).
  if (compact) {
    return (
      <div className={cn('relative h-full w-full p-2', className)}>
        <AudioCallScreen
          name={t.peerAlice}
          meta={t.callsAudioMeta}
          initial={t.peerAlice.charAt(0)}
        />
      </div>
    );
  }

  return (
    <div className={cn('relative h-full w-full overflow-hidden p-3', className)}>
      <div className="grid h-full grid-cols-2 gap-3">
        {/* Left: Audio/Video call screen */}
        <div className="flex flex-col gap-1.5">
          <p className="px-0.5 text-[9px] font-bold uppercase tracking-wider text-muted-foreground">
            {t.callsAudioTitle}
          </p>
          <div className="flex-1 min-h-0">
            <AudioCallScreen
              name={t.peerAlice}
              meta={t.callsAudioMeta}
              initial={t.peerAlice.charAt(0)}
            />
          </div>
        </div>
        {/* Right: Video circle */}
        <div className="flex flex-col gap-1.5">
          <p className="px-0.5 text-[9px] font-bold uppercase tracking-wider text-muted-foreground">
            {t.callsCircleTitle}
          </p>
          <div className="flex-1 min-h-0 rounded-2xl border border-black/5 dark:border-white/10 bg-background/60">
            <VideoCircleMessage
              initial={t.peerMikhail.charAt(0)}
              durationLabel={t.callsCircleMeta}
              recipientName={t.callsCircleTitle}
            />
          </div>
        </div>
      </div>
    </div>
  );
}
