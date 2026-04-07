
'use client';

import React from 'react';
import Image from 'next/image';
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

interface ImageViewerProps {
  isOpen: boolean;
  onOpenChange: (open: boolean) => void;
  images: ChatAttachment[];
  startIndex: number;
}

export function ImageViewer({ isOpen, onOpenChange, images, startIndex }: ImageViewerProps) {
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

  return (
    <Dialog open={isOpen} onOpenChange={onOpenChange}>
      <DialogContent 
        showCloseButton={false}
        className="bg-black/90 backdrop-blur-sm border-none shadow-none p-0 w-screen h-screen max-w-full max-h-full rounded-none flex flex-col items-center justify-center">
        
        <DialogHeader className="sr-only">
          <DialogTitle>Просмотр изображения</DialogTitle>
          <DialogDescription>Полноэкранный просмотр фотографий из чата</DialogDescription>
        </DialogHeader>

        {/* Header */}
        <header className="absolute top-0 left-0 right-0 z-50 h-24 bg-gradient-to-b from-black/70 to-transparent flex items-start justify-between p-4 text-white">
          <div className="flex flex-col">
            <p className="font-semibold truncate max-w-xs sm:max-w-md">{currentImageName}</p>
            {count > 1 && (
              <p className="text-sm text-white/80">
                {current} из {count}
              </p>
            )}
          </div>
          <DialogClose asChild>
            <Button
              variant="ghost"
              size="icon"
              className="text-white hover:bg-white/20 hover:text-white"
              aria-label="Закрыть"
            >
              <X className="h-6 w-6" />
            </Button>
          </DialogClose>
        </header>
        
        {/* Carousel */}
        <Carousel setApi={setApi} className="w-full h-full flex items-center">
          <CarouselContent>
            {images.map((image, index) => (
              <CarouselItem key={index} className="flex items-center justify-center">
                <div className="relative h-[85vh] w-[95vw]">
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
              <CarouselPrevious className="absolute left-4 top-1/2 -translate-y-1/2 z-50 h-10 w-10 text-white bg-black/30 hover:bg-black/50 border-white/50 hover:border-white disabled:bg-black/10 disabled:text-white/50" />
              <CarouselNext className="absolute right-4 top-1/2 -translate-y-1/2 z-50 h-10 w-10 text-white bg-black/30 hover:bg-black/50 border-white/50 hover:border-white disabled:bg-black/10 disabled:text-white/50" />
            </>
          )}
        </Carousel>

        {/* Footer with Dots */}
        {count > 1 && (
             <footer className="absolute bottom-0 left-0 right-0 z-50 h-20 bg-gradient-to-t from-black/70 to-transparent flex items-center justify-center p-4 gap-2">
                {Array.from({ length: count }).map((_, index) => (
                    <button
                        key={index}
                        onClick={() => api?.scrollTo(index)}
                        className={cn(
                            "h-2 w-2 rounded-full transition-all duration-300",
                            current === index + 1 ? "w-4 bg-white" : "bg-white/50 hover:bg-white/80"
                        )}
                        aria-label={`Перейти к изображению ${index + 1}`}
                    />
                ))}
            </footer>
        )}

      </DialogContent>
    </Dialog>
  );
}
