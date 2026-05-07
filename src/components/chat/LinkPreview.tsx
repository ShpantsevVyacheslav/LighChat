'use client';

import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { getLinkMetadata } from '@/actions/link-preview-actions';
import { Skeleton } from '@/components/ui/skeleton';
import { ExternalLink, Play, Pause, Volume2, VolumeX } from 'lucide-react';
import { cn } from '@/lib/utils';
import { useFirestore } from '@/firebase';
import { doc, getDoc, type Firestore } from 'firebase/firestore';
import { registrationUsernameKey } from '@/lib/registration-index-keys';
import { extractProfileTargetFromQrPayload, type ProfileQrTarget } from '@/lib/profile-qr-link';

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

type ContactPreviewProfile = {
  id: string;
  name: string;
  username?: string;
  avatar?: string;
  avatarThumb?: string;
};

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

async function resolveContactProfile(
  firestore: Firestore,
  target: ProfileQrTarget
): Promise<ContactPreviewProfile | null> {
  let userId = (target.userId ?? '').trim();
  if (!userId) {
    const username = (target.username ?? '').trim();
    if (username) {
      const key = registrationUsernameKey(username);
      if (key) {
        const regSnap = await getDoc(doc(firestore, 'registrationIndex', key));
        const uid = regSnap.data()?.uid;
        if (typeof uid === 'string' && uid.trim()) {
          userId = uid.trim();
        }
      }
    }
  }
  if (!userId) return null;
  const userSnap = await getDoc(doc(firestore, 'users', userId));
  if (!userSnap.exists()) return null;
  const d = userSnap.data() as Record<string, unknown>;
  const name = typeof d.name === 'string' ? d.name.trim() : '';
  if (!name) return null;
  return {
    id: userSnap.id,
    name,
    username: typeof d.username === 'string' ? d.username.trim() : undefined,
    avatar: typeof d.avatar === 'string' ? d.avatar.trim() : undefined,
    avatarThumb: typeof d.avatarThumb === 'string' ? d.avatarThumb.trim() : undefined,
  };
}

export function LinkPreview({ url, isLive = false }: LinkPreviewProps) {
  const firestore = useFirestore();
  const contactTarget = useMemo(() => extractProfileTargetFromQrPayload(url), [url]);
  const isContactLink = Boolean(contactTarget.userId || contactTarget.username);
  const [contactProfile, setContactProfile] = useState<ContactPreviewProfile | null>(null);
  const [contactLoading, setContactLoading] = useState(isContactLink);
  const [metadata, setMetadata] = useState<Metadata | null>(previewCache.get(url) || null);
  const [loading, setLoading] = useState(!previewCache.get(url) && !isContactLink);

  useEffect(() => {
    let isMounted = true;
    if (!isContactLink || !firestore) {
      setContactProfile(null);
      setContactLoading(false);
      return;
    }
    setContactLoading(true);
    resolveContactProfile(firestore, contactTarget)
      .then((profile) => {
        if (!isMounted) return;
        setContactProfile(profile);
      })
      .finally(() => {
        if (!isMounted) return;
        setContactLoading(false);
      });
    return () => {
      isMounted = false;
    };
  }, [isContactLink, firestore, contactTarget]);

  useEffect(() => {
    if (isContactLink) return;
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
  }, [url, isContactLink]);

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

  if (isContactLink && (contactLoading || contactProfile)) {
    if (contactLoading && !contactProfile) {
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
    if (contactProfile) {
      const displayUsername = (contactProfile.username ?? contactTarget.username ?? '')
        .trim()
        .replace(/^@/, '');
      return (
        <a
          href={url}
          target="_blank"
          rel="noopener noreferrer"
          className={cn("block my-1 group/link shrink-0", isLive ? "w-full" : "max-w-sm")}
        >
          <div className={cn(containerBaseClass, "min-h-[86px] flex items-center p-3 gap-3")}>
            <div className="h-11 w-11 shrink-0 overflow-hidden rounded-full bg-muted/40">
              {(contactProfile.avatarThumb || contactProfile.avatar) ? (
                <img
                  src={contactProfile.avatarThumb || contactProfile.avatar}
                  alt=""
                  className="h-full w-full object-cover"
                  onError={(e) => { e.currentTarget.style.display = 'none'; }}
                />
              ) : null}
            </div>
            <div className="min-w-0 flex-1">
              <p className="text-[9px] font-black uppercase text-primary tracking-[0.12em] opacity-80 leading-none mb-1">
                LighChat Contact
              </p>
              <p className="font-bold text-sm leading-tight truncate">
                {contactProfile.name}
              </p>
              <p className="text-[11px] text-muted-foreground mt-1 truncate">
                {displayUsername ? `@${displayUsername}` : "Open profile"}
              </p>
            </div>
            <ExternalLink className="h-4 w-4 opacity-40 shrink-0" />
          </div>
        </a>
      );
    }
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
