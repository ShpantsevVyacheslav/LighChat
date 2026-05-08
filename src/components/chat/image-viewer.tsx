
'use client';

import React from 'react';
import Image from 'next/image';
import { useI18n } from '@/hooks/use-i18n';
import { Dialog, DialogContent, DialogClose, DialogHeader, DialogTitle, DialogDescription } from '@/components/ui/dialog';
import {
  Carousel,
  CarouselContent,
  CarouselItem,
  CarouselNext,
  CarouselPrevious,
  type CarouselApi,
} from '@/components/ui/carousel';
import { ChatAttachment } from '@/lib/types';
import { X } from 'lucide-react';
import { Button } from '../ui/button';
import { cn } from '@/lib/utils';
import { useVerticalSwipeToDismiss } from '@/hooks/use-vertical-swipe-dismiss';

interface ImageViewerProps {
  isOpen: boolean;
  onOpenChange: (open: boolean) => void;
  images: ChatAttachment[];
  startIndex: number;
}

export function ImageViewer({ isOpen, onOpenChange, images, startIndex }: ImageViewerProps) {
  const { t } = useI18n();
  const [api, setApi] = React.useState<CarouselApi>();
  const [current, setCurrent] = React.useState(0);
  const [count, setCount] = React.useState(0);

  React.useEffect(() => {
    if (!api) {
      return;
    }

    const onSelect = () => {
      setCurrent(api.selectedScrollSnap() + 1);
    };

    api.on('select', onSelect);
    
    if (isOpen) {
        setCount(api.scrollSnapList().length);
        setCurrent(api.selectedScrollSnap() + 1);
        api.scrollTo(startIndex, true);
    }

    return () => {
      api.off('select', onSelect);
    };
  }, [api, isOpen, startIndex]);

  const currentImageName = images[current - 1]?.name || '';

  const swipeDismiss = useVerticalSwipeToDismiss({
    enabled: isOpen,
    onDismiss: () => onOpenChange(false),
    thresholdPx: 100,
  });

  return (
    <Dialog open={isOpen} onOpenChange={onOpenChange}>
      <DialogContent 
        showCloseButton={false}
        style={swipeDismiss.contentStyle}
        onTouchStart={swipeDismiss.onTouchStart}
        onTouchMove={swipeDismiss.onTouchMove}
        onTouchEnd={swipeDismiss.onTouchEnd}
        className={cn(
          'bg-black/90 backdrop-blur-sm border-none shadow-none p-0 w-screen h-[100dvh] max-w-full max-h-[100dvh] rounded-none flex flex-col items-center justify-center',
          swipeDismiss.transitionClass
        )}
        >
        
        <DialogHeader className="sr-only">
          <DialogTitle>{t('chat.imageViewer.title')}</DialogTitle>
          <DialogDescription>{t('chat.imageViewer.description')}</DialogDescription>
        </DialogHeader>

        {/* Header */}
        <header className="absolute top-0 left-0 right-0 z-50 min-h-[5.5rem] bg-gradient-to-b from-black/70 to-transparent flex items-start justify-between gap-3 px-4 pb-2 pt-[calc(1rem+env(safe-area-inset-top,0px))] text-white box-border">
          <div className="flex flex-col">
            <p className="font-semibold truncate max-w-xs sm:max-w-md">{currentImageName}</p>
            {count > 1 && (
              <p className="text-sm text-white/80">
                {t('chat.imageViewer.ofCount', { current, count })}
              </p>
            )}
          </div>
          <DialogClose asChild>
            <Button
              variant="ghost"
              size="icon"
              className="text-white hover:bg-white/20 hover:text-white"
              aria-label={t('chat.imageViewer.close')}
            >
              <X className="h-6 w-6" />
            </Button>
          </DialogClose>
        </header>
        
        {/* Carousel */}
        <Carousel setApi={setApi} className="flex h-full min-h-0 w-full flex-1 items-center pl-[env(safe-area-inset-left,0px)] pr-[env(safe-area-inset-right,0px)]">
          <CarouselContent viewportClassName="h-full min-h-0">
            {images.map((image, index) => (
              <CarouselItem key={index} className="flex items-center justify-center">
                <div className="relative mx-auto h-[calc(100dvh-env(safe-area-inset-top,0px)-env(safe-area-inset-bottom,0px)-6.5rem)] w-[95vw] max-w-full">
                  <Image
                    src={image.url}
                    alt={image.name}
                    fill
                    sizes="(max-width: 768px) 100vw, (max-width: 1200px) 80vw, 60vw"
                    className="object-contain w-full h-full"
                  />
                </div>
              </CarouselItem>
            ))}
          </CarouselContent>
          {images.length > 1 && (
            <>
              <CarouselPrevious className="absolute left-[max(1rem,env(safe-area-inset-left,0px))] top-1/2 z-50 h-10 w-10 -translate-y-1/2 text-white bg-black/30 hover:bg-black/50 border-white/50 hover:border-white disabled:bg-black/10 disabled:text-white/50" />
              <CarouselNext className="absolute right-[max(1rem,env(safe-area-inset-right,0px))] top-1/2 z-50 h-10 w-10 -translate-y-1/2 text-white bg-black/30 hover:bg-black/50 border-white/50 hover:border-white disabled:bg-black/10 disabled:text-white/50" />
            </>
          )}
        </Carousel>

        {/* Footer with Dots */}
        {count > 1 && (
             <footer className="absolute bottom-0 left-0 right-0 z-50 min-h-[4.5rem] bg-gradient-to-t from-black/70 to-transparent flex items-center justify-center gap-2 px-4 pt-2 pb-[calc(1rem+env(safe-area-inset-bottom,0px))] box-border">
                {Array.from({ length: count }).map((_, index) => (
                    <button
                        key={index}
                        onClick={() => api?.scrollTo(index)}
                        className={cn(
                            "h-2 w-2 rounded-full transition-all duration-300",
                            current === index + 1 ? "w-4 bg-white" : "bg-white/50 hover:bg-white/80"
                        )}
                        aria-label={t('chat.imageViewer.goToImage', { index: index + 1 })}
                    />
                ))}
            </footer>
        )}

      </DialogContent>
    </Dialog>
  );
}
