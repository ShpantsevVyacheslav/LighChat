'use client';

import React, { useRef, useEffect, useLayoutEffect, useState, useMemo } from 'react';
import { format } from 'date-fns';
import { cn } from '@/lib/utils';
import { videoUrlWithPreviewFrame } from '@/lib/media-utils';
import { useVideoCircleTailOptional } from '@/components/chat/video-circle-tail-context';
import { Button } from '@/components/ui/button';
import { Clock, Check, AlertTriangle, Volume2, VolumeX, Play } from 'lucide-react';
import type { ChatAttachment } from '@/lib/types';

interface VideoCirclePlayerProps {
  attachment: ChatAttachment;
  isCurrentUser: boolean;
  createdAt: string;
  deliveryStatus?: 'sending' | 'sent' | 'failed';
  readAt: string | null;
  onPlaybackStateChange?: (isPlaying: boolean) => void;
  onClick?: (e: React.MouseEvent) => void;
  hideTimestamp?: boolean;
  /** Последнее сообщение в ленте — включает нижний резерв Virtuoso под развёрнутый круг */
  isLastInChat?: boolean;
  /** Сетка в медиа-панели профиля: вписать в ячейку (иначе фикс. 192px наезжает на соседей). */
  layout?: 'message' | 'grid';
}

export function VideoCirclePlayer({ 
  attachment, 
  isCurrentUser, 
  createdAt, 
  deliveryStatus, 
  readAt,
  onPlaybackStateChange,
  onClick,
  hideTimestamp = false,
  isLastInChat = false,
  layout = 'message',
}: VideoCirclePlayerProps) {
  const tailCtx = useVideoCircleTailOptional();
  const rootRef = useRef<HTMLDivElement>(null);
  const videoRef = useRef<HTMLVideoElement>(null);
  const progressRef = useRef<SVGCircleElement>(null);
  const isPlayingRef = useRef(false);
  /** Не вызывать scrollIntoView сразу после жеста скролла ленты — иначе борется с пальцем / резинкой. */
  const suppressScrollIntoViewUntilRef = useRef(0);
  const [isPlaying, setIsPlaying] = useState(false);
  const [isHovered, setIsHovered] = useState(false);
  /** По умолчанию muted — так браузеры чаще декодируют первый кадр для превью (особенно iOS). */
  const [isMuted, setIsMuted] = useState(true);

  const videoSrc = useMemo(
    () => videoUrlWithPreviewFrame(attachment.url ?? ''),
    [attachment.url]
  );

  // SVG parameters for the progress circle (relative to 100x100 viewBox)
  // Radius 49 + strokeWidth 2 means the outer edge is exactly at 50 (the edge of the circle)
  const svgRadius = 49; 
  const circumference = 2 * Math.PI * svgRadius;

  const togglePlay = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (videoRef.current) {
      if (videoRef.current.paused) {
        // Pause all other videos on the page before playing this one
        document.querySelectorAll('video').forEach(v => {
            if (v !== videoRef.current) v.pause();
        });
        videoRef.current.play().catch(() => { });
      } else {
        videoRef.current.pause();
      }
    }
    onClick?.(e);
  };

  const toggleMute = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (videoRef.current) {
      videoRef.current.muted = !videoRef.current.muted;
      setIsMuted(!isMuted);
    }
  };

  useEffect(() => {
    const video = videoRef.current;
    const progressCircle = progressRef.current;
    if (!video || !progressCircle) return;

    let animationFrameId: number;

    const handlePlay = () => {
        isPlayingRef.current = true;
        setIsPlaying(true);
        onPlaybackStateChange?.(true);
    };
    const handlePause = () => {
        isPlayingRef.current = false;
        setIsPlaying(false);
        onPlaybackStateChange?.(false);
    };
    
    const updateProgress = () => {
      if (video.duration > 0 && isFinite(video.duration)) {
        const progress = video.currentTime / video.duration;
        const offset = circumference - progress * circumference;
        if (progressCircle) {
          progressCircle.style.strokeDashoffset = String(offset);
        }
      }
      if (!video.paused) {
        animationFrameId = requestAnimationFrame(updateProgress);
      }
    };

    video.addEventListener('play', handlePlay);
    video.addEventListener('pause', handlePause);
    video.addEventListener('ended', () => {
      video.currentTime = 0;
      video.pause();
    });

    const handleTimeUpdate = () => {
      cancelAnimationFrame(animationFrameId);
      animationFrameId = requestAnimationFrame(updateProgress);
    };

    video.addEventListener('timeupdate', handleTimeUpdate);

    return () => {
      if (video) {
        video.removeEventListener('play', handlePlay);
        video.removeEventListener('pause', handlePause);
        video.removeEventListener('timeupdate', handleTimeUpdate);
      }
      cancelAnimationFrame(animationFrameId);
    };
  }, [circumference, onPlaybackStateChange, videoSrc]);

  /** Пауза, когда круг почти не виден в области скролла чата (не viewport), чтобы скролл не ломал верстку в паре с tail-reserve. */
  useEffect(() => {
    const el = rootRef.current;
    if (!el) return;
    const scroller = el.closest('[data-virtuoso-scroller]') as HTMLElement | null;
    const MIN_VISIBLE_RATIO = 0.12;
    const observer = new IntersectionObserver(
      (entries) => {
        const entry = entries[0];
        if (!entry) return;
        const v = videoRef.current;
        if (!v || v.paused) return;
        const visibleEnough = entry.isIntersecting && entry.intersectionRatio >= MIN_VISIBLE_RATIO;
        if (!visibleEnough) v.pause();
      },
      {
        root: scroller ?? undefined,
        rootMargin: '0px',
        threshold: [0, 0.02, 0.04, 0.06, 0.08, 0.1, 0.12, 0.15, 0.2, 0.25, 0.33, 0.5, 0.66, 0.75, 1],
      }
    );
    observer.observe(el);
    return () => observer.disconnect();
  }, [videoSrc]);

  useEffect(() => {
    const mark = (e: Event) => {
      const root = rootRef.current;
      if (!root) return;
      const scroller = root.closest('[data-virtuoso-scroller]');
      if (!scroller) return;
      const t = e.target;
      if (!(t instanceof Node) || !scroller.contains(t)) return;
      suppressScrollIntoViewUntilRef.current = performance.now() + 520;
    };
    document.addEventListener('wheel', mark, { capture: true, passive: true });
    document.addEventListener('touchmove', mark, { capture: true, passive: true });
    return () => {
      document.removeEventListener('wheel', mark, { capture: true });
      document.removeEventListener('touchmove', mark, { capture: true });
    };
  }, []);

  const [duration, setDuration] = useState(0);
  const formatTime = (time: number) => {
    if (isNaN(time) || !isFinite(time) || time === 0) return '0:00';
    const minutes = Math.floor(time / 60);
    const seconds = Math.floor(time % 60);
    return `${minutes}:${seconds.toString().padStart(2, '0')}`;
  };

  useEffect(() => {
    const video = videoRef.current;
    if (!video) return;

    const bumpPreviewFrame = () => {
      try {
        if (video.readyState < HTMLMediaElement.HAVE_CURRENT_DATA) return;
        const d = video.duration;
        if (!isFinite(d) || d <= 0) return;
        const t = Math.min(0.1, Math.max(0.001, d * 0.02));
        if (video.currentTime < 0.05) {
          video.currentTime = t;
        }
      } catch {
        /* seek может бросить до готовности дорожки */
      }
    };

    const handleLoadedMetadata = () => {
      if (video.duration && isFinite(video.duration)) {
        setDuration(video.duration);
      }
      bumpPreviewFrame();
    };

    video.addEventListener('loadedmetadata', handleLoadedMetadata);
    video.addEventListener('loadeddata', bumpPreviewFrame);
    return () => {
      video.removeEventListener('loadedmetadata', handleLoadedMetadata);
      video.removeEventListener('loadeddata', bumpPreviewFrame);
    };
  }, [videoSrc]);

  /** Нижний резерв футера: последнее сообщение + воспроизведение, если низ круга ниже низа скроллера. */
  useEffect(() => {
    if (!isLastInChat || !tailCtx) return;
    const root = rootRef.current;
    if (!root) return;

    const measure = () => {
      if (!isPlayingRef.current) {
        tailCtx.setTailReservePx(0);
        return;
      }
      const scroller = root.closest('[data-virtuoso-scroller]') as HTMLElement | null;
      if (!scroller) {
        tailCtx.setTailReservePx(0);
        return;
      }
      const rr = root.getBoundingClientRect();
      const sr = scroller.getBoundingClientRect();
      const overflow = rr.bottom - sr.bottom;
      /* Минимальный запас; раньше +8 давало лишний зазор под кругом */
      tailCtx.setTailReservePx(overflow > 2 ? Math.ceil(overflow) + 2 : 0);
    };

    let raf = 0;
    const schedule = () => {
      cancelAnimationFrame(raf);
      raf = requestAnimationFrame(measure);
    };

    const ro = new ResizeObserver(schedule);
    ro.observe(root);
    window.addEventListener('resize', schedule);
    schedule();

    return () => {
      cancelAnimationFrame(raf);
      ro.disconnect();
      window.removeEventListener('resize', schedule);
      tailCtx.setTailReservePx(0);
    };
  }, [isLastInChat, tailCtx, isPlaying]);

  /** После разворота круга прокручиваем список так, чтобы весь круг был в зоне видимости (учёт поля ввода через scroll-margin). */
  useLayoutEffect(() => {
    if (!isPlaying) return;
    if (performance.now() < suppressScrollIntoViewUntilRef.current) return;
    const el = rootRef.current;
    if (!el) return;
    let cancelled = false;
    const run = () => {
      if (cancelled) return;
      if (performance.now() < suppressScrollIntoViewUntilRef.current) return;
      /* auto: иначе при smooth IntersectionObserver может кратковременно увидеть малый ratio и поставить паузу */
      el.scrollIntoView({ behavior: 'auto', block: 'center', inline: 'nearest' });
    };
    requestAnimationFrame(() => {
      requestAnimationFrame(run);
    });
    return () => {
      cancelled = true;
    };
  }, [isPlaying]);

  return (
    <div
      ref={rootRef}
      className={cn(
        'relative cursor-pointer group/circle bg-transparent transition-all duration-500 ease-in-out overflow-visible origin-center flex items-center justify-center border-none shadow-none',
        isPlaying
          ? 'z-[100] mx-auto aspect-square w-[min(448px,calc(100dvw-2rem),calc(100dvh-12rem))]'
          : layout === 'grid'
            ? 'aspect-square z-0 h-full w-full min-h-0 max-w-full'
            : 'aspect-square w-[192px] z-0'
      )}
      style={{
        scrollMarginTop: '4.5rem',
        scrollMarginBottom: 'max(6rem, env(safe-area-inset-bottom, 0px) + 5rem)',
      }}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
      onClick={togglePlay}
    >
      {/* Controls Overlay */}
      <div className={cn(
          "absolute inset-0 z-30 pointer-events-none transition-opacity duration-300", 
          (isHovered && !isPlaying) ? "opacity-100" : "opacity-0"
      )}>
        <Button onClick={toggleMute} variant="ghost" size="icon" className="pointer-events-auto absolute bottom-[max(0.5rem,env(safe-area-inset-bottom,0px))] left-1/2 h-8 w-8 -translate-x-1/2 rounded-full border-none bg-black/50 text-white shadow-none hover:bg-black/60">
          {isMuted ? <VolumeX className="h-4 w-4" /> : <Volume2 className="h-4 w-4" />}
        </Button>
        <div className="absolute left-1/2 top-[max(0.5rem,env(safe-area-inset-top,0px))] -translate-x-1/2 whitespace-nowrap rounded-full bg-black/40 px-2 py-0.5 text-[10px] font-bold text-white/90">
            {formatTime(duration)}
        </div>
      </div>

      {/* Info Badge */}
      {!hideTimestamp && (
        <div className={cn(
            "absolute bottom-2 right-2 z-30 flex items-center gap-1 bg-black/50 backdrop-blur-md text-white/90 text-[10px] px-1.5 py-0.5 rounded-full pointer-events-none transition-opacity duration-300 border border-white/5",
            isPlaying ? "opacity-0" : "opacity-100"
        )}>
          <span>{format(new Date(createdAt), 'HH:mm')}</span>
          {isCurrentUser && (
            <span className="flex items-center ml-0.5">
              {deliveryStatus === 'sending' && <Clock className="h-2.5 w-2.5" />}
              {deliveryStatus === 'failed' && <AlertTriangle className="h-2.5 w-2.5 text-destructive" />}
              {deliveryStatus !== 'sending' && deliveryStatus !== 'failed' && (
                readAt ? (
                  <div className="relative flex items-center w-3.5 h-3 text-blue-400">
                      <Check className="h-3 w-3 absolute left-0" />
                      <Check className="h-3 w-3 absolute left-[3px]" />
                  </div>
                ) : <Check className="h-3 w-3" />
              )}
            </span>
          )}
        </div>
      )}
      
      {/* Video container */}
      <div className="absolute inset-0 rounded-full overflow-hidden bg-black shadow-none border-none">
        <video
          ref={videoRef}
          src={videoSrc}
          className="pointer-events-none w-full h-full object-cover rounded-full bg-black shadow-none border-none"
          playsInline
          loop
          preload="metadata"
          muted={isMuted}
        />
        
        {/* Play Overlay */}
        <div className={cn(
          "absolute inset-0 z-20 transition-opacity duration-300 pointer-events-none",
          isPlaying ? "opacity-0" : "opacity-100"
        )}>
          <div className="absolute inset-0 flex items-center justify-center bg-black/20 rounded-full">
            <Play className="h-[30%] w-[30%] text-white fill-white ml-[5%]" />
          </div>
        </div>
      </div>

      {/* Progress Circle - Moved outside overflow-hidden to be visible on the very edge */}
      <svg className={cn(
          "absolute inset-0 w-full h-full overflow-visible -rotate-90 pointer-events-none transition-opacity duration-300 z-20",
          (isPlaying || isHovered) ? "opacity-100" : "opacity-0"
      )} viewBox="0 0 100 100">
        {/* Track */}
        <circle
          cx="50" cy="50" r={svgRadius}
          stroke="rgba(255, 255, 255, 0.15)"
          strokeWidth="2"
          fill="transparent"
        />
        {/* Progress bar */}
        <circle
          ref={progressRef}
          cx="50" cy="50" r={svgRadius}
          stroke="rgba(255, 255, 255, 0.6)"
          strokeWidth="2"
          fill="transparent"
          strokeDasharray={circumference}
          strokeDashoffset={circumference}
          style={{ transition: 'stroke-dashoffset 0.1s linear' }}
        />
      </svg>
    </div>
  );
}