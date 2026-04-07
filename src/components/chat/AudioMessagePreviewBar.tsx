'use client';

import React, { useCallback, useEffect, useRef, useState } from 'react';
import { Button } from '@/components/ui/button';
import { Slider } from '@/components/ui/slider';
import { Trash2, SendHorizonal, Loader2, Mic, Play, Pause } from 'lucide-react';
import { cn } from '@/lib/utils';

function formatTime(seconds: number) {
  if (!Number.isFinite(seconds) || seconds < 0) return '0:00';
  const m = Math.floor(seconds / 60);
  const sec = Math.floor(seconds % 60);
  return `${m}:${sec.toString().padStart(2, '0')}`;
}

export type AudioMessagePreviewBarProps = {
  src: string;
  onDiscard: () => void;
  onSend: () => void;
  isSending: boolean;
};

/**
 * Однострочный предпросмотр голосового перед отправкой: прослушивание, прогресс, удалить / отправить.
 */
export function AudioMessagePreviewBar({
  src,
  onDiscard,
  onSend,
  isSending,
}: AudioMessagePreviewBarProps) {
  const audioRef = useRef<HTMLAudioElement>(null);
  const [playing, setPlaying] = useState(false);
  const [duration, setDuration] = useState(0);
  const [current, setCurrent] = useState(0);

  useEffect(() => {
    const el = audioRef.current;
    if (!el) return;
    setPlaying(false);
    setCurrent(0);
    setDuration(0);
    el.src = src;
    const onLoaded = () => setDuration(Number.isFinite(el.duration) ? el.duration : 0);
    const onTime = () => setCurrent(el.currentTime);
    const onEnded = () => {
      setPlaying(false);
      setCurrent(0);
      el.currentTime = 0;
    };
    el.addEventListener('loadedmetadata', onLoaded);
    el.addEventListener('timeupdate', onTime);
    el.addEventListener('ended', onEnded);
    return () => {
      el.pause();
      el.removeEventListener('loadedmetadata', onLoaded);
      el.removeEventListener('timeupdate', onTime);
      el.removeEventListener('ended', onEnded);
    };
  }, [src]);

  const togglePlayback = useCallback(() => {
    const el = audioRef.current;
    if (!el) return;
    if (playing) {
      el.pause();
      setPlaying(false);
      return;
    }
    void el
      .play()
      .then(() => setPlaying(true))
      .catch(() => setPlaying(false));
  }, [playing]);

  const max = Math.max(duration, 0.001);

  return (
    <div
      className={cn(
        'mb-1.5 flex w-full max-w-xl items-center gap-1 rounded-2xl border border-border/60',
        'bg-card/95 py-1 pl-1.5 pr-1 shadow-none backdrop-blur-sm',
        'dark:bg-card/90'
      )}
    >
      <audio ref={audioRef} preload="metadata" className="hidden" />

      <Button
        type="button"
        variant="ghost"
        size="icon"
        className="h-8 w-8 shrink-0 text-destructive hover:bg-destructive/10"
        onClick={onDiscard}
        disabled={isSending}
        aria-label="Удалить запись"
      >
        <Trash2 className="h-3.5 w-3.5" />
      </Button>

      <div
        className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-primary/12 dark:bg-primary/15"
        aria-hidden
      >
        <Mic className="h-3.5 w-3.5 text-primary" strokeWidth={2} />
      </div>

      <Button
        type="button"
        variant="ghost"
        size="icon"
        className="h-8 w-8 shrink-0 rounded-full text-foreground"
        onClick={togglePlayback}
        disabled={isSending}
        aria-label={playing ? 'Пауза' : 'Прослушать'}
      >
        {playing ? (
          <Pause className="h-4 w-4" />
        ) : (
          <Play className="ml-0.5 h-4 w-4" />
        )}
      </Button>

      <div className="flex min-w-0 flex-1 items-center gap-2">
        <Slider
          value={[current]}
          max={max}
          min={0}
          step={0.05}
          disabled={isSending || duration <= 0}
          onValueChange={([v]) => {
            const el = audioRef.current;
            if (el) {
              el.currentTime = v;
              setCurrent(v);
            }
          }}
          className={cn(
            'min-w-0 flex-1',
            '[&>span:first-child]:h-1 [&>span:first-child]:rounded-full',
            '[&_[role=slider]]:h-3 [&_[role=slider]]:w-3 [&_[role=slider]]:border-primary/40'
          )}
        />
        <span className="w-[4.5rem] shrink-0 tabular-nums text-right text-[10px] leading-none text-muted-foreground">
          {formatTime(current)}/{formatTime(duration)}
        </span>
      </div>

      <Button
        type="button"
        size="icon"
        className="h-9 w-9 shrink-0 rounded-full"
        onClick={onSend}
        disabled={isSending}
        aria-label="Отправить голосовое"
      >
        {isSending ? (
          <Loader2 className="h-4 w-4 animate-spin" />
        ) : (
          <SendHorizonal className="h-4 w-4" />
        )}
      </Button>
    </div>
  );
}
