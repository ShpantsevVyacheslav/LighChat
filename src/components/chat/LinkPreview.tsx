'use client';

import React, { useCallback, useEffect, useRef, useState } from 'react';
import { getLinkMetadata } from '@/actions/link-preview-actions';
import { Skeleton } from '@/components/ui/skeleton';
import { ExternalLink, Play, Pause, Volume2, VolumeX } from 'lucide-react';
import { cn } from '@/lib/utils';

interface Metadata {
  title?: string | null;
  description?: string | null;
  image?: string | null;
  siteName?: string | null;
  url: string;
  videoUrl?: string | null;
  videoType?: string | null;
}

interface LinkPreviewProps {
    url: string;
    isLive?: boolean;
}

const previewCache = new Map<string, Metadata>();

function isPlayableVideo(meta: Metadata): boolean {
  const v = meta.videoUrl?.trim();
  if (!v) return false;
  const type = meta.videoType ?? '';
  if (type.startsWith('video/')) return true;
  if (type.startsWith('application/x-mpegurl') || type.startsWith('application/vnd.apple.mpegurl')) return true;
  if (type.startsWith('text/html')) return false;
  try {
    const path = new URL(v).pathname.toLowerCase();
    return path.endsWith('.mp4') || path.endsWith('.m4v') || path.endsWith('.webm') || path.endsWith('.mov');
  } catch {
    return false;
  }
}

export function LinkPreview({ url, isLive = false }: LinkPreviewProps) {
  const [metadata, setMetadata] = useState<Metadata | null>(previewCache.get(url) || null);
  const [loading, setLoading] = useState(!previewCache.get(url));

  useEffect(() => {
    if (previewCache.has(url)) {
        setLoading(false);
        return;
    }

    let isMounted = true;
    setLoading(true);

    getLinkMetadata(url).then((data) => {
      if (isMounted) {
        const result = data as Metadata | null;
        if (result && (result.title || result.description)) {
            previewCache.set(url, result);
        }
        setMetadata(result);
        setLoading(false);
      }
    });

    return () => { isMounted = false; };
  }, [url]);

  const containerBaseClass = cn(
    "max-w-sm my-1 overflow-hidden shrink-0 w-full transition-all duration-300 border border-black/5 dark:border-white/10 rounded-xl",
    isLive ? "max-w-full bg-muted/5 border-dashed" : "bg-muted/10"
  );

  if (loading) {
    return (
      <div className={cn(containerBaseClass, "h-[80px] min-h-[80px] flex items-center")}>
        <div className="h-[40px] w-[40px] shrink-0 border-r border-black/5 dark:border-white/5 overflow-hidden">
            <Skeleton className="h-full w-full rounded-none opacity-20" />
        </div>
        <div className="flex-1 flex flex-col justify-center gap-2 p-3 min-w-0 overflow-hidden">
            <Skeleton className="h-3 w-3/4 rounded-full opacity-30" />
            <Skeleton className="h-2 w-1/2 rounded-full opacity-20" />
        </div>
      </div>
    );
  }

  if (!metadata || (!metadata.title && !metadata.description)) {
    return null;
  }

  const hasVideo = isPlayableVideo(metadata);

  const textSection = (
    <div className="flex-1 min-w-0 p-3 flex flex-col justify-center overflow-hidden h-full">
      {metadata.siteName && (
        <p className="text-[8px] font-black text-primary uppercase tracking-[0.2em] leading-none mb-1 truncate">{metadata.siteName}</p>
      )}
      <p className="font-bold text-xs line-clamp-1 leading-tight group-hover/link:text-primary transition-colors">{metadata.title}</p>
      {metadata.description && (
        <p className="text-[10px] text-muted-foreground line-clamp-1 leading-relaxed mt-0.5">{metadata.description}</p>
      )}
      <div className="flex items-center gap-1 mt-1 opacity-30">
          <p className="text-[8px] font-mono truncate uppercase tracking-tighter">{(() => { try { return new URL(url).hostname; } catch { return url; } })()}</p>
          <ExternalLink className="h-2 w-2" />
      </div>
    </div>
  );

  if (hasVideo) {
    return (
      <div className={cn(containerBaseClass, "flex flex-col")}>
        <InlineVideoPlayer
          videoUrl={metadata.videoUrl!}
          posterUrl={metadata.image}
        />
        <a href={url} target="_blank" rel="noopener noreferrer" className="group/link flex items-center hover:bg-muted/10 transition-colors">
          {textSection}
        </a>
      </div>
    );
  }

  return (
    <a href={url} target="_blank" rel="noopener noreferrer" className={cn("block my-1 group/link shrink-0", isLive ? "w-full" : "max-w-sm")}>
      <div className={cn(containerBaseClass, "h-[80px] min-h-[80px] flex items-center")}>
          {metadata.image && (
            <div className="h-[40px] w-[40px] overflow-hidden bg-muted shrink-0 border-r border-black/5 dark:border-white/5">
              <img
                src={metadata.image}
                alt=""
                className="object-cover w-full h-full transition-transform group-hover/link:scale-105 duration-500"
                onError={(e) => { e.currentTarget.style.display = 'none'; }}
              />
            </div>
          )}
          {textSection}
      </div>
    </a>
  );
}

function InlineVideoPlayer({ videoUrl, posterUrl }: { videoUrl: string; posterUrl?: string | null }) {
  const videoRef = useRef<HTMLVideoElement>(null);
  const [playing, setPlaying] = useState(false);
  const [muted, setMuted] = useState(true);
  const [failed, setFailed] = useState(false);
  const [started, setStarted] = useState(false);

  const toggle = useCallback(() => {
    const v = videoRef.current;
    if (!v) return;
    if (!started) {
      setStarted(true);
      v.play().catch(() => setFailed(true));
      return;
    }
    if (v.paused) {
      v.play().catch(() => setFailed(true));
    } else {
      v.pause();
    }
  }, [started]);

  const toggleMute = useCallback((e: React.MouseEvent) => {
    e.stopPropagation();
    const v = videoRef.current;
    if (!v) return;
    v.muted = !v.muted;
    setMuted(v.muted);
  }, []);

  return (
    <div className="relative aspect-video bg-black cursor-pointer select-none" onClick={toggle}>
      <video
        ref={videoRef}
        src={started ? videoUrl : undefined}
        poster={posterUrl || undefined}
        loop
        muted={muted}
        playsInline
        className="w-full h-full object-cover"
        onPlay={() => setPlaying(true)}
        onPause={() => setPlaying(false)}
        onError={() => setFailed(true)}
      />
      {!started && posterUrl && (
        <img
          src={posterUrl}
          alt=""
          className="absolute inset-0 w-full h-full object-cover"
          onError={(e) => { e.currentTarget.style.display = 'none'; }}
        />
      )}
      {!playing && (
        <div className="absolute inset-0 flex items-center justify-center bg-black/25">
          <div className="flex h-14 w-14 items-center justify-center rounded-full bg-black/55">
            {failed ? (
              <span className="text-white text-xs">Ошибка</span>
            ) : (
              <Play className="h-7 w-7 text-white ml-0.5" fill="white" />
            )}
          </div>
        </div>
      )}
      {playing && (
        <div className="absolute inset-0 flex items-center justify-center opacity-0 hover:opacity-100 transition-opacity">
          <div className="flex h-14 w-14 items-center justify-center rounded-full bg-black/55">
            <Pause className="h-7 w-7 text-white" fill="white" />
          </div>
        </div>
      )}
      {started && (
        <button
          type="button"
          onClick={toggleMute}
          className="absolute right-2 bottom-2 flex h-8 w-8 items-center justify-center rounded-full bg-black/55 text-white hover:bg-black/70 transition-colors"
        >
          {muted ? <VolumeX className="h-4 w-4" /> : <Volume2 className="h-4 w-4" />}
        </button>
      )}
    </div>
  );
}
