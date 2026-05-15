'use client';

import * as React from 'react';
import {
  ChevronLeft,
  ChevronRight,
  Pause,
  Play,
  Volume2,
  VolumeX,
  X,
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';
import { useI18n } from '@/hooks/use-i18n';
import { ACCENT_CLASSES } from '../features-data';
import { FeatureMockFrame } from '../feature-mock-frame';
import { SHOWREEL_SCENES, SHOWREEL_TOTAL_MS } from './showreel-scenes';
import type { ShowreelScene } from './showreel-scenes';
import { useShowreelTts } from './use-showreel-tts';

const TICK_MS = 100;

function pickLang(locale: string): 'ru' | 'en' {
  return locale === 'en' || locale.startsWith('en') ? 'en' : 'ru';
}

function ttsTag(locale: string): string {
  return locale === 'en' || locale.startsWith('en') ? 'en-US' : 'ru-RU';
}

/**
 * Полноэкранный showreel-плеер фич LighChat.
 *
 *  ## Два режима
 *
 *  1. **Pre-rendered MP4** (предпочтительно) — если задан `videoSrc`,
 *     показываем нативный `<video>` элемент с озвучкой из ffmpeg-собранного
 *     mp4 (см. `scripts/showreel-render/`). Высокое качество звука,
 *     полная синхронизация, не зависит от Web Speech API.
 *
 *  2. **Scripted fallback** — если `videoSrc` не задан, плеер играет
 *     scripted-последовательность сцен с TTS через Web Speech API. Это
 *     то же содержимое, но рендер живой, без видео-файла.
 *
 * Особенности (fallback):
 *  – auto-advance по `scene.durationMs`;
 *  – TTS-озвучка через Web Speech API (`useShowreelTts`);
 *  – элементы управления: Play/Pause, Prev/Next, Mute, Close, прогресс-бар
 *    с тиками сцен;
 *  – «Ken-Burns» лёгкий zoom на каждом мокапе для динамики;
 *  – автоматически выбирает русский/английский голос по locale `useI18n`;
 *  – на unmount: cancel TTS + останавливает таймеры.
 */
export function FeaturesShowreel({
  open,
  onClose,
  /**
   * URL до готового MP4. Может быть локальный (`/showreel/showreel-ru.mp4`)
   * или Firebase Storage / CDN. При наличии — играется как `<video>`,
   * scripted fallback отключается.
   *
   * Удобно передавать карту по локали:
   * `videoSrc={locale === 'en' ? '/showreel/en.mp4' : '/showreel/ru.mp4'}`.
   */
  videoSrc,
}: {
  open: boolean;
  onClose: () => void;
  videoSrc?: string;
}) {
  const { locale } = useI18n();
  const lang = pickLang(locale);
  const tts = useShowreelTts();

  const [sceneIdx, setSceneIdx] = React.useState(0);
  const [paused, setPaused] = React.useState(false);
  const [elapsedInScene, setElapsedInScene] = React.useState(0);

  const scene: ShowreelScene = SHOWREEL_SCENES[sceneIdx];

  // Сброс при открытии
  React.useEffect(() => {
    if (!open) return;
    setSceneIdx(0);
    setElapsedInScene(0);
    setPaused(false);
  }, [open]);

  // Озвучка сцены при её смене
  React.useEffect(() => {
    if (!open || paused) return;
    tts.speak(scene.voiceover[lang], ttsTag(locale));
    return () => {
      tts.cancel();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps -- speak/cancel — стабильные ссылки
  }, [open, paused, sceneIdx, lang, locale]);

  // Таймер прогресса
  React.useEffect(() => {
    if (!open || paused) return;
    const id = window.setInterval(() => {
      setElapsedInScene((e) => e + TICK_MS);
    }, TICK_MS);
    return () => window.clearInterval(id);
  }, [open, paused, sceneIdx]);

  // Переход к следующей сцене
  React.useEffect(() => {
    if (!open) return;
    if (elapsedInScene < scene.durationMs) return;
    if (sceneIdx >= SHOWREEL_SCENES.length - 1) {
      // конец — закрываем плеер
      const t = window.setTimeout(() => onClose(), 200);
      return () => window.clearTimeout(t);
    }
    setSceneIdx((i) => i + 1);
    setElapsedInScene(0);
  }, [elapsedInScene, scene.durationMs, sceneIdx, open, onClose]);

  // Cleanup TTS при unmount/close
  React.useEffect(() => {
    if (!open) tts.cancel();
    return () => {
      tts.cancel();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open]);

  // Esc → close
  React.useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault();
        onClose();
      } else if (e.key === ' ') {
        e.preventDefault();
        setPaused((p) => !p);
      } else if (e.key === 'ArrowRight') {
        next();
      } else if (e.key === 'ArrowLeft') {
        prev();
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open]);

  const next = React.useCallback(() => {
    setSceneIdx((i) => Math.min(SHOWREEL_SCENES.length - 1, i + 1));
    setElapsedInScene(0);
    setPaused(false);
  }, []);

  const prev = React.useCallback(() => {
    setSceneIdx((i) => Math.max(0, i - 1));
    setElapsedInScene(0);
    setPaused(false);
  }, []);

  const togglePause = React.useCallback(() => {
    setPaused((p) => {
      const next = !p;
      if (next) tts.pause();
      else tts.resume();
      return next;
    });
  }, [tts]);

  if (!open) return null;

  // Если задан videoSrc — играем native <video>. Это даёт максимальное
  // качество, синк со звуком и переживёт любые браузерные ограничения
  // Web Speech API. Cancel TTS если переключаемся в видео-режим.
  if (videoSrc) {
    return (
      <div
        role="dialog"
        aria-modal="true"
        className="fixed inset-0 z-[320] flex items-center justify-center bg-black animate-in fade-in duration-300"
      >
        <button
          type="button"
          onClick={onClose}
          aria-label="Close"
          className="absolute right-4 top-4 z-10 flex h-10 w-10 items-center justify-center rounded-full border border-white/15 bg-black/40 text-white backdrop-blur-md hover:bg-black/60"
        >
          <X className="h-5 w-5" aria-hidden />
        </button>
        <video
          key={videoSrc}
          src={videoSrc}
          controls
          autoPlay
          playsInline
          className="max-h-screen max-w-screen-2xl w-full h-full object-contain"
          onEnded={onClose}
        />
      </div>
    );
  }

  const sceneProgress = Math.min(1, elapsedInScene / scene.durationMs);
  const Mock = scene.Mock;
  const accent = ACCENT_CLASSES[scene.accent];

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-labelledby="lc-showreel-title"
      className="fixed inset-0 z-[320] flex items-center justify-center bg-black/95 backdrop-blur-2xl animate-in fade-in duration-300"
    >
      {/* Декоративный бренд-blur за сценой */}
      <div
        className={cn(
          'pointer-events-none absolute inset-0 opacity-25 bg-gradient-to-br',
          accent.gradient,
        )}
      />

      {/* Close (X) */}
      <button
        type="button"
        onClick={onClose}
        aria-label="Close"
        className="absolute right-4 top-4 z-10 flex h-10 w-10 items-center justify-center rounded-full border border-white/15 bg-black/40 text-white backdrop-blur-md hover:bg-black/60"
      >
        <X className="h-5 w-5" aria-hidden />
      </button>

      {/* Контент сцены */}
      <div className="relative z-0 mx-auto flex h-full w-full max-w-5xl flex-col justify-center px-4 py-16 sm:px-8">
        <div className="flex flex-1 flex-col items-stretch justify-center gap-6 sm:flex-row sm:items-center">
          {/* Mock (animated «scene») */}
          <div className="relative flex-1 min-w-0">
            <FeatureMockFrame
              key={scene.id /* перерендер для Ken-Burns на смене сцены */}
              ratio="aspect-[16/10]"
              className="mx-auto w-full max-w-3xl shadow-[0_40px_120px_-30px_rgba(0,0,0,0.7)] animate-feat-ken-burns"
            >
              <Mock />
            </FeatureMockFrame>
          </div>

          {/* Заголовок + субтитр */}
          <div className="w-full max-w-sm shrink-0 text-white">
            <p className={cn('text-[11px] font-bold uppercase tracking-[0.18em]', accent.text)}>
              {sceneIdx + 1} / {SHOWREEL_SCENES.length}
            </p>
            <h2
              id="lc-showreel-title"
              className="mt-2 font-headline text-2xl font-bold leading-tight sm:text-3xl"
            >
              {scene.title[lang]}
            </h2>
            <p className="mt-3 text-sm leading-relaxed text-white/75 sm:text-base">
              {scene.voiceover[lang]}
            </p>
          </div>
        </div>
      </div>

      {/* Контролы внизу */}
      <div className="absolute inset-x-4 bottom-4 z-10 mx-auto max-w-3xl rounded-2xl border border-white/10 bg-black/55 px-3 py-2 backdrop-blur-2xl">
        {/* Прогресс-бар с тиками */}
        <div className="flex items-center gap-1.5">
          {SHOWREEL_SCENES.map((s, i) => {
            const isPast = i < sceneIdx;
            const isCurrent = i === sceneIdx;
            return (
              <button
                key={s.id}
                type="button"
                aria-label={`Scene ${i + 1}`}
                onClick={() => {
                  setSceneIdx(i);
                  setElapsedInScene(0);
                  setPaused(false);
                }}
                className="relative h-1 flex-1 overflow-hidden rounded-full bg-white/15 hover:bg-white/25"
              >
                <span
                  className="absolute inset-y-0 left-0 bg-white"
                  style={{ width: isPast ? '100%' : isCurrent ? `${sceneProgress * 100}%` : '0%' }}
                />
              </button>
            );
          })}
        </div>
        {/* Кнопки */}
        <div className="mt-2 flex items-center justify-between gap-2">
          <div className="flex items-center gap-1.5">
            <Button
              type="button"
              variant="ghost"
              size="icon"
              onClick={prev}
              disabled={sceneIdx === 0}
              aria-label="Previous"
              className="h-9 w-9 rounded-full text-white hover:bg-white/15 disabled:opacity-30"
            >
              <ChevronLeft className="h-5 w-5" aria-hidden />
            </Button>
            <Button
              type="button"
              variant="ghost"
              size="icon"
              onClick={togglePause}
              aria-label={paused ? 'Play' : 'Pause'}
              className="h-10 w-10 rounded-full bg-white text-black hover:bg-white/85"
            >
              {paused ? <Play className="h-4 w-4" aria-hidden /> : <Pause className="h-4 w-4" aria-hidden />}
            </Button>
            <Button
              type="button"
              variant="ghost"
              size="icon"
              onClick={next}
              disabled={sceneIdx === SHOWREEL_SCENES.length - 1}
              aria-label="Next"
              className="h-9 w-9 rounded-full text-white hover:bg-white/15 disabled:opacity-30"
            >
              <ChevronRight className="h-5 w-5" aria-hidden />
            </Button>
          </div>
          <div className="flex items-center gap-2">
            <span className="font-mono text-[11px] text-white/70 tabular-nums">
              {formatTime(elapsedSoFar(sceneIdx, elapsedInScene))} / {formatTime(SHOWREEL_TOTAL_MS)}
            </span>
            <Button
              type="button"
              variant="ghost"
              size="icon"
              onClick={tts.toggleMute}
              aria-label={tts.muted ? 'Unmute' : 'Mute'}
              className="h-9 w-9 rounded-full text-white hover:bg-white/15"
              disabled={!tts.supported}
            >
              {tts.muted || !tts.supported ? (
                <VolumeX className="h-5 w-5" aria-hidden />
              ) : (
                <Volume2 className="h-5 w-5" aria-hidden />
              )}
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
}

function elapsedSoFar(idx: number, withinSceneMs: number): number {
  let total = 0;
  for (let i = 0; i < idx; i++) total += SHOWREEL_SCENES[i].durationMs;
  return total + withinSceneMs;
}

function formatTime(ms: number): string {
  const s = Math.floor(ms / 1000);
  const m = Math.floor(s / 60);
  const r = s % 60;
  return `${m}:${r.toString().padStart(2, '0')}`;
}
