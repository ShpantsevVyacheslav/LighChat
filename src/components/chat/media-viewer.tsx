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
import { ChatAttachment, ChatMessage, User } from '@/lib/types';
import {
  Download,
  Trash2,
  Reply,
  Forward,
  ArrowLeft,
  Play,
  MoreVertical,
  CornerUpLeft,
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger, DropdownMenuPortal, DropdownMenuSeparator } from '@/components/ui/dropdown-menu';
import { format, parseISO } from 'date-fns';
import { ru } from 'date-fns/locale';
import { TransformWrapper, TransformComponent } from 'react-zoom-pan-pinch';
import { Badge } from '@/components/ui/badge';
import { useChatAttachmentDisplaySrc } from '@/components/chat/use-chat-attachment-display-src';
import { useElectronCachedUrl } from '@/hooks/use-electron-cached-url';

/** Тёмное «стекло»: контраст и на светлом, и на тёмном фоне кадра (светлая заливка терялась на белых фото). */
const mediaViewerFloatingActionClass = cn(
  'inline-flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl',
  'border border-white/30 bg-black/55 text-white shadow-lg shadow-black/40 backdrop-blur-xl',
  'transition-transform duration-150 hover:border-white/45 hover:bg-black/70 active:scale-[0.94]',
  'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white/55 focus-visible:ring-offset-2 focus-visible:ring-offset-transparent'
);

const mediaViewerFloatingDangerClass = cn(
  mediaViewerFloatingActionClass,
  'border-red-400/60 text-red-200 hover:border-red-400/85 hover:bg-red-950/75'
);

export type MediaViewerItem = ChatAttachment & {
    messageId: string;
    senderId: string;
    createdAt: string;
};

interface MediaViewerProps {
  isOpen: boolean;
  onOpenChange: (open: boolean) => void;
  media: MediaViewerItem[];
  startIndex: number;
  currentUserId: string;
  allUsers: User[];
  allowSave?: boolean;
  allowForward?: boolean;
  onDelete?: (messageId: string) => void;
  onReply?: (message: ChatMessage) => void;
  onForward?: (message: ChatMessage) => void;
  navigateToMessage?: (messageId: string) => void;
}

type TransformRefHandle = {
  instance?: {
    transformState: { scale: number };
  };
  centerView: (scale?: number, animationTime?: number) => void;
  zoomIn: (step?: number, animationTime?: number) => void;
};

export function MediaViewer({
  isOpen,
  onOpenChange,
  media,
  startIndex,
  currentUserId,
  allUsers,
  allowSave = true,
  allowForward = true,
  onDelete,
  onReply,
  onForward,
}: MediaViewerProps) {
  const [api, setApi] = React.useState<CarouselApi>();
  const [current, setCurrent] = React.useState(0);
  const [isMediaLoading, setIsMediaLoading] = useState<Record<number, boolean>>({});
  const [isZoomed, setIsZoomed] = useState(false);
  const [translateY, setTranslateY] = useState(0);
  
  const transformRefs = useRef<Record<number, TransformRefHandle | null>>({});
  /** Синхронно для `watchDrag` карусели: не вызывать `reInit` при зуме (ломает pinch на мобильных). */
  const isZoomedRef = useRef(false);
  const pinchActiveRef = useRef(false);
  /** После pinch не обрабатывать «двойной тап» (иначе touchend двух пальцев даёт ложное срабатывание). */
  const suppressDoubleTapUntilRef = useRef(0);
  const lastTapRef = useRef<{ t: number; index: number } | null>(null);
  const lastToggleAtRef = useRef(0);
  const gestureScopeRef = useRef<'none' | 'media' | 'overlay'>('none');
  const touchStartRef = useRef<{ x: number, y: number } | null>(null);
  const swipeDirectionRef = useRef<'none' | 'horizontal' | 'vertical'>('none');

  const toggleSlideZoomFromRef = React.useCallback((index: number) => {
    const now = Date.now();
    if (now - lastToggleAtRef.current < 350) return;
    lastToggleAtRef.current = now;
    const tref = transformRefs.current[index];
    if (!tref?.instance) return;
    const scale = tref.instance.transformState.scale;
    /** resetTransform даёт 0,0 — кадр уезжает от центра; centerView(1) = масштаб 1 и позиция по центру вьюпорта */
    if (scale > 1.05) tref.centerView(1, 200);
    else tref.zoomIn(0.7, 200);
  }, []);

  const onImageTouchEnd = React.useCallback(
    (e: React.TouchEvent, index: number) => {
      if (pinchActiveRef.current || Date.now() < suppressDoubleTapUntilRef.current) return;
      if (e.changedTouches.length !== 1) return;
      const now = Date.now();
      const prev = lastTapRef.current;
      if (prev && prev.index === index && now - prev.t < 300) {
        lastTapRef.current = null;
        e.preventDefault();
        toggleSlideZoomFromRef(index);
      } else {
        lastTapRef.current = { t: now, index };
        window.setTimeout(() => {
          if (lastTapRef.current?.t === now) lastTapRef.current = null;
        }, 320);
      }
    },
    [toggleSlideZoomFromRef]
  );

  useEffect(() => {
    if (!api) return;

    const onSelect = () => {
      const newIndex = api.selectedScrollSnap();
      setCurrent(newIndex + 1);
      lastTapRef.current = null;

      Object.entries(transformRefs.current).forEach(([idx, ref]) => {
        if (Number(idx) !== newIndex && ref?.centerView) {
          ref.centerView(1, 0);
        }
      });
      isZoomedRef.current = false;
      setIsZoomed(false);
      setTranslateY(0);
    };

    api.on('select', onSelect);
    
    if (isOpen) {
      setCurrent(startIndex + 1);
      api.scrollTo(startIndex, true);
      isZoomedRef.current = false;
      setIsZoomed(false);
      setTranslateY(0);
    }

    return () => {
        if (api) api.off('select', onSelect);
    };
  }, [api, isOpen, startIndex]);

  const currentMedia = media[current - 1];
  const currentIndex = current > 0 ? current - 1 : startIndex;
  const sender = useMemo(() => allUsers.find(u => u.id === currentMedia?.senderId), [currentMedia, allUsers]);
  const canDelete = currentMedia && currentMedia.senderId === currentUserId;

  const toChatMessage = React.useCallback((item: MediaViewerItem): ChatMessage => {
    return {
      id: item.messageId,
      senderId: item.senderId,
      createdAt: item.createdAt,
      readAt: null,
      attachments: [item],
    };
  }, []);

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
    } catch {
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
        onReply(toChatMessage(currentMedia));
        onOpenChange(false);
    }
  };

  const onTouchStart = (e: React.TouchEvent) => {
    const target = e.target;
    const fromMediaZone =
      target instanceof Element &&
      Boolean(target.closest('[data-media-interactive="true"]'));

    /** Зум: жесты остаются у TransformWrapper; без зума — свайп вверх/вниз закрывает с любой точки, включая фото/видео */
    if (fromMediaZone && isZoomedRef.current) {
      gestureScopeRef.current = 'media';
      return;
    }

    gestureScopeRef.current = 'overlay';
    e.stopPropagation(); // Prevent global chat back swipe
    const touch = e.touches[0];
    touchStartRef.current = { x: touch.clientX, y: touch.clientY };
    swipeDirectionRef.current = 'none';
  };

  const onTouchMove = (e: React.TouchEvent) => {
    if (gestureScopeRef.current === 'media') return;
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
    if (gestureScopeRef.current === 'media') {
      touchStartRef.current = null;
      swipeDirectionRef.current = 'none';
      gestureScopeRef.current = 'none';
      return;
    }

    if (!isZoomed && swipeDirectionRef.current === 'vertical') {
      e.stopPropagation();
      if (Math.abs(translateY) > 120) onOpenChange(false);
      else setTranslateY(0);
    } else if (swipeDirectionRef.current === 'horizontal') {
      e.stopPropagation(); // Ensure horizontal swipes stay within viewer
    }
    touchStartRef.current = null;
    swipeDirectionRef.current = 'none';
    gestureScopeRef.current = 'none';
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
          /* Без justify-center/items-center: иначе карусель по высоте = «полоска» под object-contain, зум не на весь экран */
          "fixed inset-0 left-0 top-0 translate-x-0 translate-y-0 w-screen h-screen max-w-none max-h-none m-0 bg-transparent border-none shadow-none p-0 rounded-none flex min-h-0 flex-col items-stretch z-[150] overflow-hidden",
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
            <MediaViewerBackdropImage item={currentMedia} />
          ) : currentMedia ? (
            <div className="absolute inset-0 bg-gradient-to-br from-zinc-800 via-zinc-950 to-black" />
          ) : (
            <div className="absolute inset-0 bg-zinc-950" />
          )}
          <div className="absolute inset-0 bg-black/60" />
        </div>

        <header className={cn(
          "absolute top-0 left-0 right-0 z-[160] min-h-[5rem] bg-gradient-to-b from-black/80 to-transparent flex items-center justify-between px-4 pt-[env(safe-area-inset-top,0px)] pb-2 text-white transition-opacity duration-300 box-border",
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
                  {allowForward ? (
                    <DropdownMenuItem className="rounded-xl h-11 px-4" onSelect={() => onForward?.(toChatMessage(currentMedia))}>
                      <Forward className="mr-3 h-4 w-4" /> Переслать
                    </DropdownMenuItem>
                  ) : null}
                  {allowSave ? (
                    <DropdownMenuItem className="rounded-xl h-11 px-4" onSelect={() => { handleDownload(); }}>
                      <Download className="mr-3 h-4 w-4" /> Сохранить
                    </DropdownMenuItem>
                  ) : null}
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
        
        <Carousel
          setApi={setApi}
          opts={{
            watchDrag: () => !isZoomedRef.current,
          }}
          className="relative z-10 flex min-h-0 flex-1 w-full flex-col overflow-hidden"
        >
          <CarouselContent
            viewportClassName="h-full min-h-0"
            className="ml-0 flex h-full min-h-0 items-stretch pl-0"
          >
            {media.map((item, index) => (
              <CarouselItem
                key={index}
                className="flex h-full min-h-0 w-full shrink-0 basis-full flex-col overflow-hidden p-0 pl-0"
              >
                {Math.abs(index - currentIndex) <= 1 ? (
                  <TransformWrapper
                    ref={(ref: unknown) => {
                      transformRefs.current[index] = ref as TransformRefHandle | null;
                    }}
                    initialScale={1}
                    minScale={1}
                    maxScale={10}
                    centerOnInit
                    /** Ограничение pan; контент трансформа = весь вьюпорт, чтобы max-h/w % у img давали object-contain */
                    limitToBounds
                    disablePadding
                    centerZoomedOut
                    panning={{ disabled: !isZoomed, velocityDisabled: true }}
                    wheel={{ step: 0.5, smoothStep: 0.05 }}
                    /** Встроенный dblclick использует resetTransform — смещение; тоггл — свой touch + onDoubleClick */
                    doubleClick={{ disabled: true }}
                    onPinchingStart={() => {
                      pinchActiveRef.current = true;
                    }}
                    onPinchingStop={() => {
                      pinchActiveRef.current = false;
                      suppressDoubleTapUntilRef.current = Date.now() + 450;
                    }}
                    onTransformed={(_ref, state) => {
                      const scale = state?.scale ?? 1;
                      const z = scale > 1.05;
                      isZoomedRef.current = z;
                      setIsZoomed(z);
                    }}
                  >
                    <TransformComponent
                      wrapperClass="!h-full !w-full !max-w-none min-h-0 overflow-hidden"
                      wrapperStyle={{ width: '100%', height: '100%' }}
                      contentClass="!flex !h-full !w-full min-h-0 min-w-0 items-center justify-center"
                      contentStyle={{ width: '100%', height: '100%' }}
                    >
                      {item.type.startsWith('image/') ? (
                        <div
                          data-media-interactive="true"
                          className="flex h-full min-h-0 w-full min-w-0 touch-none items-center justify-center"
                          onDoubleClick={(e) => {
                            e.preventDefault();
                            e.stopPropagation();
                            toggleSlideZoomFromRef(index);
                          }}
                        >
                          <MediaViewerMainImage
                            item={item}
                            index={index}
                            isMediaLoading={isMediaLoading}
                            setIsMediaLoading={setIsMediaLoading}
                            onImageTouchEnd={onImageTouchEnd}
                          />
                        </div>
                      ) : (
                        <div
                          data-media-interactive="true"
                          className="flex h-full min-h-0 w-full min-w-0 items-center justify-center touch-none"
                        >
                          <VideoPlayer
                            url={item.url}
                            onLoadStart={() => setIsMediaLoading((prev) => ({ ...prev, [index]: true }))}
                            onCanPlay={() => setIsMediaLoading((prev) => ({ ...prev, [index]: false }))}
                          />
                        </div>
                      )}
                    </TransformComponent>
                  </TransformWrapper>
                ) : (
                  <div className="flex h-full w-full items-center justify-center bg-black/10" aria-hidden>
                    <div className="h-10 w-10 rounded-full border-2 border-white/25 border-t-white/70 animate-spin" />
                  </div>
                )}
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

        <footer
          className={cn(
            'absolute left-1/2 z-[160] flex -translate-x-1/2 justify-center transition-all duration-300 bottom-[max(1.25rem,env(safe-area-inset-bottom,0px))]',
            isZoomed ? 'pointer-events-none translate-y-10 opacity-0' : 'translate-y-0 opacity-100'
          )}
        >
          <div className="flex items-center gap-3">
            <button
              type="button"
              className={mediaViewerFloatingActionClass}
              aria-label="Ответить"
              title="Ответить"
              onClick={(e) => {
                e.stopPropagation();
                handleReply();
              }}
            >
              <CornerUpLeft className="h-5 w-5" strokeWidth={1.85} />
            </button>
            {allowForward ? (
              <button
                type="button"
                className={mediaViewerFloatingActionClass}
                aria-label="Переслать"
                title="Переслать"
                onClick={(e) => {
                  e.stopPropagation();
                  onForward?.(toChatMessage(currentMedia));
                }}
              >
                <Forward className="h-5 w-5" strokeWidth={1.85} />
              </button>
            ) : null}
            {canDelete ? (
              <button
                type="button"
                className={mediaViewerFloatingDangerClass}
                aria-label="Удалить"
                title="Удалить"
                onClick={(e) => {
                  e.stopPropagation();
                  handleDelete();
                }}
              >
                <Trash2 className="h-5 w-5" strokeWidth={1.85} />
              </button>
            ) : null}
          </div>
        </footer>
      </DialogContent>
    </Dialog>
  );
}

function MediaViewerBackdropImage({ item }: { item: MediaViewerItem }) {
  const src = useChatAttachmentDisplaySrc(item);
  return (
    <img
      key={src}
      src={src}
      alt=""
      className="absolute inset-0 h-full w-full scale-125 object-cover opacity-55 blur-3xl"
    />
  );
}

function MediaViewerMainImage({
  item,
  index,
  isMediaLoading,
  setIsMediaLoading,
  onImageTouchEnd,
}: {
  item: MediaViewerItem;
  index: number;
  isMediaLoading: Record<number, boolean>;
  setIsMediaLoading: React.Dispatch<React.SetStateAction<Record<number, boolean>>>;
  onImageTouchEnd: (e: React.TouchEvent, index: number) => void;
}) {
  const src = useChatAttachmentDisplaySrc(item);
  return (
    <img
      src={src}
      alt={item.name}
      className={cn(
        /* Родитель на весь слайд — object-contain, картинка целиком в кадре при масштабе 1 */
        "block max-h-full max-w-full h-auto w-auto min-h-0 min-w-0 object-contain transition-opacity duration-300 select-none !pointer-events-auto",
        isMediaLoading[index] ? "opacity-0" : "opacity-100"
      )}
      draggable={false}
      onTouchEnd={(e) => onImageTouchEnd(e, index)}
      onLoad={() => setIsMediaLoading((prev) => ({ ...prev, [index]: false }))}
      onLoadStart={() => setIsMediaLoading((prev) => ({ ...prev, [index]: true }))}
    />
  );
}

function VideoPlayer({ url, onLoadStart, onCanPlay }: { url: string, onLoadStart: () => void, onCanPlay: () => void }) {
  const videoRef = useRef<HTMLVideoElement>(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const cachedUrl = useElectronCachedUrl(url);

  const handleSystemFullscreen = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (videoRef.current) {
      if (videoRef.current.paused) videoRef.current.play().catch(() => {});
      if (videoRef.current.requestFullscreen) {
        videoRef.current.requestFullscreen();
      } else if ('webkitEnterFullscreen' in videoRef.current) {
        (videoRef.current as HTMLVideoElement & { webkitEnterFullscreen?: () => void }).webkitEnterFullscreen?.();
      }
    }
  };

  return (
    <div className="relative flex h-full min-h-0 w-full min-w-0 items-center justify-center bg-black">
      <video
        ref={videoRef}
        src={cachedUrl || url}
        className="max-h-full max-w-full object-contain"
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
