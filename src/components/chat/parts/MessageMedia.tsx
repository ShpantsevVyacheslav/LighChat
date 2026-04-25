
'use client';

import React, { useMemo, useState } from 'react';
import { cn } from '@/lib/utils';
import type { ChatAttachment } from '@/lib/types';
import { Play } from 'lucide-react';
import { thumbHashToUrl } from '@/lib/media-utils';
import { isGridGalleryAttachment, isGridGalleryVideo } from '@/components/chat/attachment-visual';
import { isChatGalleryMediaUrlSeen, markChatGalleryMediaUrlSeen } from '@/components/chat/chat-media-session-cache';
import {
  CHAT_MEDIA_PREVIEW_MAX_WIDTH_PX,
  CHAT_GIF_ALBUM_GRID_MAX_WIDTH_PX,
} from '@/lib/chat-media-preview-max';
import { CHAT_GRID_VIDEO_GIFLIKE_MAX_SEC } from '@/lib/sticker-media-normalize';
import { HeicAwareChatImage } from '@/components/chat/parts/HeicAwareChatImage';
import { useChatAttachmentDisplaySrc } from '@/components/chat/use-chat-attachment-display-src';
/** Если в БД нет width/height — квадрат в пределах max-width. */
const FALLBACK_ASPECT_RATIO = '1 / 1';

interface MessageMediaProps {
  attachments: ChatAttachment[];
  isCurrentUser: boolean;
  onImageClick: (att: ChatAttachment) => void;
}

function cellAspectRatio(att: ChatAttachment, count: number, index: number): string {
  if (count === 3 && index === 0) return '16 / 9';
  if (count === 1) {
    const w = att.width;
    const h = att.height;
    if (w && h && w > 0 && h > 0) return `${w} / ${h}`;
    return FALLBACK_ASPECT_RATIO;
  }
  return '1 / 1';
}

/** Высота блока = width × (h/w); надёжнее, чем aspect-ratio при только abspos-детях (иначе 0px). */
function paddingBottomPercentFromAspect(ar: string): string {
  const parts = ar.split('/').map((s) => parseFloat(s.trim()));
  if (parts.length !== 2 || !Number.isFinite(parts[0]) || !Number.isFinite(parts[1]) || parts[0] <= 0) {
    return '100%';
  }
  return `${(parts[1] / parts[0]) * 100}%`;
}

/** Только анимированный GIF в сетке (не video). */
function isGridCellGif(att: ChatAttachment): boolean {
  if (isGridGalleryVideo(att)) return false;
  const t = (att.type || '').toLowerCase();
  if (t === 'image/gif') return true;
  return /\.gif(\?|#|$)/i.test(att.name);
}

/**
 * Управляет отображением сетки медиафайлов.
 * Высота ячеек задаётся только aspect-ratio + ширина сетки; img/video — position:absolute,
 * чтобы интринсик-размеры файла не раздували верстку до/после загрузки (CLS).
 */
export function MessageMedia({ attachments, isCurrentUser, onImageClick }: MessageMediaProps) {
  if (!attachments || attachments.length === 0) return null;

  const visualAttachments = attachments.filter(isGridGalleryAttachment);

  if (visualAttachments.length === 0) return null;

  const count = visualAttachments.length;
  const allGifs =
    visualAttachments.length > 0 && visualAttachments.every(isGridCellGif);
  const gridMaxPx = allGifs ? CHAT_GIF_ALBUM_GRID_MAX_WIDTH_PX : CHAT_MEDIA_PREVIEW_MAX_WIDTH_PX;

  return (
    <div
      className={cn(
        'grid gap-0.5 relative max-w-full overflow-hidden rounded-2xl w-full shrink-0 bg-transparent',
        count === 1 && 'grid-cols-1',
        count === 2 && 'grid-cols-2',
        count === 3 && 'grid-cols-2',
        count >= 4 && 'grid-cols-2'
      )}
      style={{
        maxWidth: gridMaxPx,
        width: `min(100%, ${gridMaxPx}px)`,
        minWidth: `min(100%, ${gridMaxPx}px)`,
      }}
    >
      {visualAttachments.slice(0, 10).map((att, idx) => {
        const isLastVisible = idx === 9 && count > 10;
        const ar = cellAspectRatio(att, count, idx);

        return (
          <div
            key={`${att.url}-${idx}`}
            className="relative w-full min-w-0 overflow-hidden bg-muted/20 group/media cursor-pointer"
            style={{ paddingBottom: paddingBottomPercentFromAspect(ar) }}
            onClick={(e) => {
                e.stopPropagation();
                onImageClick(att);
            }}
          >
            <div className="absolute inset-0 overflow-hidden">
              <MediaItem att={att} />
            </div>
            {isLastVisible && (
              <div className="absolute inset-0 z-30 flex items-center justify-center bg-black/40 backdrop-blur-[2px] pointer-events-none">
                <span className="text-white font-black text-base">+{count - 10}</span>
              </div>
            )}
          </div>
        );
      })}
    </div>
  );
}

function MediaItem({ att }: { att: ChatAttachment }) {
  const [shortLoopVideo, setShortLoopVideo] = useState(false);
  const placeholderUrl = useMemo(() => thumbHashToUrl(att.thumbHash), [att.thumbHash]);
  const isVideo = isGridGalleryVideo(att);
  const isBlobPreview = att.url.startsWith('blob:');
  const eagerLoad = isBlobPreview || isChatGalleryMediaUrlSeen(att.url);
  const displaySrc = useChatAttachmentDisplaySrc(att);

  return (
    <div className="absolute inset-0 overflow-hidden">
      {placeholderUrl && (
        <img
          src={placeholderUrl}
          className="absolute inset-0 w-full h-full object-cover blur-xl scale-110 opacity-50 pointer-events-none"
          alt=""
          aria-hidden
        />
      )}
      {isVideo ? (
        <>
          <video
            src={`${displaySrc}#t=0.1`}
            preload="metadata"
            loop={shortLoopVideo}
            autoPlay={shortLoopVideo}
            className="pointer-events-none absolute inset-0 h-full w-full object-cover bg-black"
            muted
            playsInline
            onLoadedMetadata={(e) => {
              const el = e.currentTarget;
              const d = el.duration;
              if (Number.isFinite(d) && d > 0 && d <= CHAT_GRID_VIDEO_GIFLIKE_MAX_SEC) {
                setShortLoopVideo(true);
                el.play().catch(() => {});
              }
            }}
            onLoadedData={() => markChatGalleryMediaUrlSeen(att.url)}
          />
          {!shortLoopVideo ? (
            <div className="absolute inset-0 flex items-center justify-center bg-black/10 pointer-events-none">
              <Play className="h-5 w-5 text-white/80 fill-white" />
            </div>
          ) : null}
        </>
      ) : (
        <HeicAwareChatImage
          attachment={att}
          alt={att.name}
          className="absolute inset-0 h-full w-full object-cover transition-transform group-hover/media:scale-105 duration-500 bg-muted/30"
          loading={eagerLoad ? 'eager' : 'lazy'}
          decoding="async"
          onLoad={() => markChatGalleryMediaUrlSeen(att.url)}
        />
      )}
    </div>
  );
}
