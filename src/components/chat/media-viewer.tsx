'use client';

import React, { useState, useEffect, useRef, useMemo } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '@/components/ui/dialog';
import {
  Carousel,
  CarouselContent,
  CarouselItem,
  CarouselNext,
  CarouselPrevious,
  type CarouselApi,
} from '@/components/ui/carousel';
import { ChatAttachment, User } from '@/lib/types';
import { Download, Trash2, Reply, Forward, ArrowLeft, Play, MoreVertical } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger, DropdownMenuPortal, DropdownMenuSeparator } from '@/components/ui/dropdown-menu';
import { format, parseISO } from 'date-fns';
import { ru } from 'date-fns/locale';
import { TransformWrapper, TransformComponent } from 'react-zoom-pan-pinch';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';

export type MediaViewerItem = ChatAttachment & {
    messageId: string;
    senderId: string;
    createdAt: string;
};

/** Императивный ref TransformWrapper отдаёт только getControls — scale в instance.transformState. */
function getTransformScaleFromRef(tref: { instance?: { transformState?: { scale?: number } }; state?: { scale?: number } } | null): number {
  if (!tref) return 1;
  const s = tref.instance?.transformState?.scale ?? tref.state?.scale;
  return typeof s === 'number' && Number.isFinite(s) ? s : 1;
}

interface MediaViewerProps {
  isOpen: boolean;
  onOpenChange: (open: boolean) => void;
  media: MediaViewerItem[];
  startIndex: number;
  currentUserId: string;
  allUsers: User[];
  onDelete?: (messageId: string) => void;
  onReply?: (message: any) => void;
  onForward?: (message: any) => void;
  navigateToMessage?: (messageId: string) => void;
}

export function MediaViewer({ isOpen, onOpenChange, media, startIndex, currentUserId, allUsers, onDelete, onReply, onForward, navigateToMessage }: MediaViewerProps) {
  const [api, setApi] = React.useState<CarouselApi>();
  const [current, setCurrent] = React.useState(0);
  const [isMediaLoading, setIsMediaLoading] = useState<Record<number, boolean>>({});
  const [isZoomed, setIsZoomed] = useState(false);
  const [translateY, setTranslateY] = useState(0);
  
  const transformRefs = useRef<Record<number, any>>({});
  const touchStartRef = useRef<{ x: number, y: number } | null>(null);
  const swipeDirectionRef = useRef<'none' | 'horizontal' | 'vertical'>('none');
  const lastTapRef = useRef<{ t: number; index: number } | null>(null);
  const lastToggleAtRef = useRef(0);

  const ZOOMED_EPS = 1.02;

  const toggleSlideZoom = React.useCallback((index: number) => {
    const now = Date.now();
    if (now - lastToggleAtRef.current < 400) return;
    lastToggleAtRef.current = now;
    const tref = transformRefs.current[index];
    if (!tref) return;
    const scale = getTransformScaleFromRef(tref);
    if (scale > ZOOMED_EPS) {
      tref.resetTransform(200);
    } else {
      tref.zoomIn(0.7, 200);
    }
  }, []);

  const onImageDoubleTapOrClick = React.useCallback(
    (e: React.MouseEvent | React.TouchEvent, index: number) => {
      e.preventDefault();
      e.stopPropagation();
      toggleSlideZoom(index);
    },
    [toggleSlideZoom],
  );

  const onImageTouchEnd = React.useCallback(
    (e: React.TouchEvent, index: number) => {
      const now = Date.now();
      const prev = lastTapRef.current;
      if (prev && prev.index === index && now - prev.t < 320) {
        lastTapRef.current = null;
        onImageDoubleTapOrClick(e, index);
      } else {
        lastTapRef.current = { t: now, index };
        window.setTimeout(() => {
          if (lastTapRef.current?.t === now) lastTapRef.current = null;
        }, 360);
      }
    },
    [onImageDoubleTapOrClick],
  );

  useEffect(() => {
    if (!api) return;
    api.reInit({ watchDrag: !isZoomed });
  }, [api, isZoomed]);

  useEffect(() => {
    if (!api) return;

    const onSelect = () => {
      const newIndex = api.selectedScrollSnap();
      setCurrent(newIndex + 1);
      lastTapRef.current = null;

      Object.entries(transformRefs.current).forEach(([idx, ref]) => {
        if (Number(idx) !== newIndex && ref) {
            ref.resetTransform(0);
        }
      });
      setIsZoomed(false);
      setTranslateY(0);
    };

    api.on('select', onSelect);
    
    if (isOpen) {
      setCurrent(startIndex + 1);
      api.scrollTo(startIndex, true);
      setIsZoomed(false);
      setTranslateY(0);
    }

    return () => {
        if (api) api.off('select', onSelect);
    };
  }, [api, isOpen, startIndex]);

  const currentMedia = media[current - 1];
  const sender = useMemo(() => allUsers.find(u => u.id === currentMedia?.senderId), [currentMedia, allUsers]);
  const canDelete = currentMedia && currentMedia.senderId === currentUserId;

  const handleDownload = async () => {
    if (!currentMedia) return;
    try {
      const response = await fetch(currentMedia.url);
      const blob = await response.blob();
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = currentMedia.name || 'download';
      document.body.appendChild(a);
      a.click();
      setTimeout(() => {
        window.URL.revokeObjectURL(url);
        document.body.removeChild(a);
      }, 100);
    } catch (e) {
      window.open(currentMedia.url, '_blank');
    }
  };

  const handleDelete = () => {
    if (currentMedia && onDelete) {
      onDelete(currentMedia.messageId);
      if (media.length <= 1) onOpenChange(false);
    }
  };

  const handleReply = () => {
    if (onReply && currentMedia) {
        onReply({
            id: currentMedia.messageId,
            senderId: currentMedia.senderId,
            createdAt: currentMedia.createdAt,
            attachments: [currentMedia]
        });
        onOpenChange(false);
    }
  };

  const onTouchStart = (e: React.TouchEvent) => {
    if (isZoomed) return;
    e.stopPropagation(); // Prevent global chat back swipe
    const touch = e.touches[0];
    touchStartRef.current = { x: touch.clientX, y: touch.clientY };
    swipeDirectionRef.current = 'none';
  };

  const onTouchMove = (e: React.TouchEvent) => {
    if (isZoomed || !touchStartRef.current) return;
    e.stopPropagation(); // Prevent global chat back swipe
    const touch = e.touches[0];
    const deltaX = touch.clientX - touchStartRef.current.x;
    const deltaY = touch.clientY - touchStartRef.current.y;

    if (swipeDirectionRef.current === 'none') {
      if (Math.abs(deltaY) > Math.abs(deltaX) && Math.abs(deltaY) > 10) swipeDirectionRef.current = 'vertical';
      else if (Math.abs(deltaX) > Math.abs(deltaY) && Math.abs(deltaX) > 10) swipeDirectionRef.current = 'horizontal';
    }

    if (swipeDirectionRef.current === 'vertical') {
      setTranslateY(deltaY);
      if (e.cancelable) e.preventDefault();
    }
  };

  const onTouchEnd = (e: React.TouchEvent) => {
    if (!isZoomed && swipeDirectionRef.current === 'vertical') {
      e.stopPropagation();
      if (Math.abs(translateY) > 120) onOpenChange(false);
      else setTranslateY(0);
    } else if (swipeDirectionRef.current === 'horizontal') {
      e.stopPropagation(); // Ensure horizontal swipes stay within viewer
    }
    touchStartRef.current = null;
    swipeDirectionRef.current = 'none';
  };

  const formatMediaDate = (dateStr?: string) => {
    if (!dateStr) return '';
    const date = parseISO(dateStr);
    return format(date, 'd MMMM yyyy, HH:mm', { locale: ru });
  };

  return (
    <Dialog open={isOpen} onOpenChange={onOpenChange}>
      <DialogContent 
        showCloseButton={false}
        className={cn(
          "fixed inset-0 left-0 top-0 translate-x-0 translate-y-0 w-screen h-screen max-w-none max-h-none m-0 bg-transparent border-none shadow-none p-0 rounded-none flex flex-col items-center justify-center z-[150] overflow-hidden",
          touchStartRef.current === null ? "transition-all duration-300 ease-out" : "transition-none"
        )}
        style={{ 
          transform: `translateY(${translateY}px)`,
          opacity: 1 - Math.min(Math.abs(translateY) / 500, 0.6)
        }}
        onTouchStart={onTouchStart}
        onTouchMove={onTouchMove}
        onTouchEnd={onTouchEnd}
      >
        <DialogHeader className="sr-only">
          <DialogTitle>Просмотр медиа</DialogTitle>
          <DialogDescription>Просмотр изображений и видео из чата</DialogDescription>
        </DialogHeader>

        {/* Размытый фон по текущему кадру (не сплошной чёрный) */}
        <div className="pointer-events-none absolute inset-0 z-0 overflow-hidden" aria-hidden>
          {currentMedia?.type.startsWith('image/') ? (
            <img
              key={currentMedia.url}
              src={currentMedia.url}
              alt=""
              className="absolute inset-0 h-full w-full scale-125 object-cover opacity-55 blur-3xl"
            />
          ) : currentMedia ? (
            <div className="absolute inset-0 bg-gradient-to-br from-zinc-800 via-zinc-950 to-black" />
          ) : (
            <div className="absolute inset-0 bg-zinc-950" />
          )}
          <div className="absolute inset-0 bg-black/60" />
        </div>

        <header className={cn(
          "absolute top-0 left-0 right-0 z-[160] h-20 bg-gradient-to-b from-black/80 to-transparent flex items-center justify-between px-4 text-white transition-opacity duration-300",
          isZoomed ? "opacity-0 pointer-events-none" : "opacity-100"
        )}>
          <div className="flex items-center gap-3 min-w-0">
            <Button variant="ghost" size="icon" className="rounded-full text-white hover:bg-white/10 h-10 w-10 border-none shadow-none" onClick={() => onOpenChange(false)}>
              <ArrowLeft className="h-6 w-6" />
            </Button>
            <div className="flex flex-col min-w-0">
              <div className="flex items-center gap-2">
                <p className="text-sm font-bold truncate leading-tight">{sender?.name || 'Участник'}</p>
                <Badge variant="outline" className="h-4 px-1.5 text-[9px] bg-white/10 border-white/20 text-white/80 font-bold rounded-full">
                  {current} / {media.length}
                </Badge>
              </div>
              <p className="text-[10px] font-bold tracking-widest text-white/50 mt-0.5 uppercase">
                {formatMediaDate(currentMedia?.createdAt)}
              </p>
            </div>
          </div>
          
          <div className="flex items-center gap-1 sm:gap-2">
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button variant="ghost" size="icon" className="rounded-full text-white hover:bg-white/10 border-none shadow-none">
                  <MoreVertical className="h-5 w-5" />
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuPortal>
                <DropdownMenuContent collisionPadding={16} align="end" className="w-56 rounded-2xl bg-popover/90 backdrop-blur-xl border-none shadow-2xl z-[170]">
                  <DropdownMenuItem className="rounded-xl h-11 px-4" onSelect={() => handleReply()}><Reply className="mr-3 h-4 w-4" /> Ответить</DropdownMenuItem>
                  <DropdownMenuItem className="rounded-xl h-11 px-4" onSelect={() => onForward?.(currentMedia)}><Forward className="mr-3 h-4 w-4" /> Переслать</DropdownMenuItem>
                  <DropdownMenuItem className="rounded-xl h-11 px-4" onSelect={() => { handleDownload(); }}><Download className="mr-3 h-4 w-4" /> Сохранить</DropdownMenuItem>
                  {canDelete && (
                    <>
                      <DropdownMenuSeparator className="bg-border/50" />
                      <DropdownMenuItem className="text-destructive focus:text-destructive rounded-xl h-11 px-4" onSelect={() => { handleDelete(); }}><Trash2 className="mr-3 h-4 w-4" /> Удалить</DropdownMenuItem>
                    </>
                  )}
                </DropdownMenuContent>
              </DropdownMenuPortal>
            </DropdownMenu>
          </div>
        </header>
        
        <Carousel setApi={setApi} className="relative z-10 w-full h-full flex items-center justify-center overflow-hidden">
          <CarouselContent className="h-full ml-0 items-center">
            {media.map((item, index) => (
              <CarouselItem key={index} className="flex items-center justify-center p-0 h-full w-full shrink-0 overflow-hidden">
                <TransformWrapper
                  ref={(ref: any) => { transformRefs.current[index] = ref; }}
                  initialScale={1}
                  minScale={1}
                  maxScale={10}
                  centerOnInit
                  limitToBounds={true}
                  panning={{ disabled: !isZoomed }}
                  wheel={{ step: 0.5, smoothStep: 0.05 }}
                  doubleClick={{ disabled: true }}
                  onTransformed={(ref) => {
                    const scale = ref.state?.scale ?? (ref as any).instance?.transformState?.scale ?? 1;
                    setIsZoomed(scale > 1.05);
                  }}
                >
                  <TransformComponent 
                    wrapperClass="!w-screen !h-screen overflow-hidden" 
                    contentClass="w-screen h-screen flex items-center justify-center"
                  >
                    {item.type.startsWith('image/') ? (
                      <img
                        src={item.url}
                        alt={item.name}
                        className={cn(
                          // react-zoom-pan-pinch задаёт .content img { pointer-events: none } — без !pointer-events-auto тапы не попадают в img
                          "w-screen h-screen object-contain transition-opacity duration-300 touch-manipulation select-none !pointer-events-auto",
                          isMediaLoading[index] ? "opacity-0" : "opacity-100"
                        )}
                        draggable={false}
                        onDoubleClick={(e) => onImageDoubleTapOrClick(e, index)}
                        onTouchEnd={(e) => onImageTouchEnd(e, index)}
                        onLoad={() => setIsMediaLoading(prev => ({ ...prev, [index]: false }))}
                        onLoadStart={() => setIsMediaLoading(prev => ({ ...prev, [index]: true }))}
                      />
                    ) : (
                      <VideoPlayer 
                        url={item.url} 
                        onLoadStart={() => setIsMediaLoading(prev => ({ ...prev, [index]: true }))} 
                        onCanPlay={() => setIsMediaLoading(prev => ({ ...prev, [index]: false }))} 
                      />
                    )}
                  </TransformComponent>
                </TransformWrapper>
              </CarouselItem>
            ))}
          </CarouselContent>
          
          {media.length > 1 && !isZoomed && (
            <>
              <CarouselPrevious className="hidden sm:flex absolute left-6 top-1/2 -translate-y-1/2 z-[160] h-12 w-12 rounded-full text-white bg-black/20 hover:bg-black/40 border-white/10 hover:border-white shadow-none" />
              <CarouselNext className="hidden sm:flex absolute right-6 top-1/2 -translate-y-1/2 z-[160] h-12 w-12 rounded-full text-white bg-black/20 hover:bg-black/40 border-white/10 hover:border-white shadow-none" />
            </>
          )}
        </Carousel>

        <footer className={cn(
          "absolute bottom-8 left-1/2 -translate-x-1/2 z-[160] transition-all duration-300",
          isZoomed ? "opacity-0 pointer-events-none translate-y-10" : "opacity-100 translate-y-0"
        )}>
          <div className="flex items-center gap-4 bg-black/40 backdrop-blur-md px-6 py-3 rounded-full border border-white/10 shadow-2xl">
            <Button variant="ghost" size="icon" className="rounded-full text-white hover:bg-white/10 border-none shadow-none" onClick={(e) => { e.stopPropagation(); handleReply(); }}><Reply className="h-5 w-5" /></Button>
            <Separator orientation="vertical" className="h-6 bg-white/10" />
            <Button variant="ghost" size="icon" className="rounded-full text-white hover:bg-white/10 border-none shadow-none" onClick={(e) => { e.stopPropagation(); onForward?.(currentMedia); }}><Forward className="h-5 w-5" /></Button>
            {canDelete && (
                <>
                    <Separator orientation="vertical" className="h-6 bg-white/10" />
                    <Button variant="ghost" size="icon" className="rounded-full text-destructive hover:bg-destructive/10 border-none shadow-none" onClick={(e) => { e.stopPropagation(); handleDelete(); }}><Trash2 className="h-5 w-5" /></Button>
                </>
            )}
          </div>
        </footer>
      </DialogContent>
    </Dialog>
  );
}

function VideoPlayer({ url, onLoadStart, onCanPlay }: { url: string, onLoadStart: () => void, onCanPlay: () => void }) {
  const videoRef = useRef<HTMLVideoElement>(null);
  const [isPlaying, setIsPlaying] = useState(false);

  const handleSystemFullscreen = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (videoRef.current) {
      if (videoRef.current.paused) videoRef.current.play().catch(() => {});
      if (videoRef.current.requestFullscreen) {
        videoRef.current.requestFullscreen();
      } else if ((videoRef.current as any).webkitEnterFullscreen) {
        (videoRef.current as any).webkitEnterFullscreen();
      }
    }
  };

  return (
    <div className="relative w-screen h-screen flex items-center justify-center bg-black">
      <video
        ref={videoRef}
        src={url}
        className="w-screen h-screen object-contain"
        onLoadStart={onLoadStart}
        onCanPlay={onCanPlay}
        controls
        playsInline
        onPlay={() => setIsPlaying(true)}
        onPause={() => setIsPlaying(false)}
      />
      {!isPlaying && (
        <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
          <Button 
            variant="secondary" 
            size="icon" 
            className="h-16 w-16 rounded-full bg-white/10 backdrop-blur-md text-white pointer-events-auto border-none hover:scale-110 transition-transform shadow-2xl"
            onClick={handleSystemFullscreen}
          >
            <Play className="h-8 w-8 fill-current ml-1" />
          </Button>
        </div>
      )}
    </div>
  );
}
