'use client';

import React, { useState, useRef, useEffect } from 'react';
import { Dialog, DialogContent, DialogClose, DialogHeader, DialogTitle, DialogDescription } from '@/components/ui/dialog';
import { type ChatAttachment } from '@/lib/types';
import { X, Volume2, VolumeX, Maximize, Minimize } from 'lucide-react';
import { Button } from '../ui/button';
import { cn } from '@/lib/utils';
import { useVerticalSwipeToDismiss } from '@/hooks/use-vertical-swipe-dismiss';

interface VideoViewerProps {
  isOpen: boolean;
  onOpenChange: (open: boolean) => void;
  video: ChatAttachment | null;
}

export function VideoViewer({ isOpen, onOpenChange, video }: VideoViewerProps) {
  const videoRef = useRef<HTMLVideoElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const [isMuted, setIsMuted] = useState(false);
  const [isControlsVisible, setIsControlsVisible] = useState(true);
  const [isFullscreen, setIsFullscreen] = useState(false);
  const controlsTimeoutRef = useRef<NodeJS.Timeout | null>(null);

  const hideControls = () => {
    if (videoRef.current && !videoRef.current.paused) {
        setIsControlsVisible(false);
    }
  };

  const showControls = () => {
    setIsControlsVisible(true);
    if (controlsTimeoutRef.current) {
      clearTimeout(controlsTimeoutRef.current);
    }
    controlsTimeoutRef.current = setTimeout(hideControls, 3000);
  };
  
  useEffect(() => {
    if(isOpen) {
        showControls();
        videoRef.current?.play();
    } else {
        videoRef.current?.pause();
        if (controlsTimeoutRef.current) {
          clearTimeout(controlsTimeoutRef.current);
        }
    }
  }, [isOpen]);

  const handlePlayPause = () => {
    if (videoRef.current) {
      if (videoRef.current.paused) {
        videoRef.current.play();
        showControls();
      } else {
        videoRef.current.pause();
        if (controlsTimeoutRef.current) {
            clearTimeout(controlsTimeoutRef.current);
        }
        setIsControlsVisible(true);
      }
    }
  };

  const handleMuteToggle = () => {
    if (videoRef.current) {
      const currentlyMuted = !videoRef.current.muted;
      videoRef.current.muted = currentlyMuted;
      setIsMuted(currentlyMuted);
    }
  };

  const handleFullscreenToggle = () => {
    if (!containerRef.current) return;
    const elem = containerRef.current;
    const doc = document as any;
    const isFullscreenNow = doc.fullscreenElement || doc.webkitFullscreenElement || doc.mozFullScreenElement || doc.msFullscreenElement;

    if (!isFullscreenNow) {
        if (elem.requestFullscreen) {
            elem.requestFullscreen().catch(() => {});
        } else if ((elem as any).webkitRequestFullscreen) {
            (elem as any).webkitRequestFullscreen();
        } else if (videoRef.current && (videoRef.current as any).webkitEnterFullscreen) {
            (videoRef.current as any).webkitEnterFullscreen();
        }
    } else {
        if (document.exitFullscreen) {
            document.exitFullscreen();
        } else if (doc.webkitExitFullscreen) {
            doc.webkitExitFullscreen();
        }
    }
  };

  useEffect(() => {
    const onFullscreenChange = () => setIsFullscreen(!!(document.fullscreenElement || (document as any).webkitFullscreenElement));
    document.addEventListener('fullscreenchange', onFullscreenChange);
    document.addEventListener('webkitfullscreenchange', onFullscreenChange);

    const video = videoRef.current;
    const onPlay = () => showControls();
    if (video) {
        video.addEventListener('play', onPlay);
    }

    return () => {
      document.removeEventListener('fullscreenchange', onFullscreenChange);
      document.removeEventListener('webkitfullscreenchange', onFullscreenChange);
      if (video) {
        video.removeEventListener('play', onPlay);
      }
    };
  }, []);

  const swipeDismiss = useVerticalSwipeToDismiss({
    enabled: isOpen && !isFullscreen,
    onDismiss: () => onOpenChange(false),
    thresholdPx: 100,
  });

  if(!video) return null;

  return (
    <Dialog open={isOpen} onOpenChange={onOpenChange}>
      <DialogContent 
        showCloseButton={false}
        style={swipeDismiss.contentStyle}
        onTouchStart={swipeDismiss.onTouchStart}
        onTouchMove={swipeDismiss.onTouchMove}
        onTouchEnd={swipeDismiss.onTouchEnd}
        className={cn(
          'bg-black/90 backdrop-blur-sm border-none shadow-none p-0 w-screen h-[100dvh] max-w-full max-h-[100dvh] rounded-none flex items-center justify-center pl-[env(safe-area-inset-left,0px)] pr-[env(safe-area-inset-right,0px)]',
          swipeDismiss.transitionClass
        )}
        onMouseMove={showControls}
        onMouseLeave={hideControls}
        ref={containerRef}
      >
        <DialogHeader className="sr-only">
          <DialogTitle>Просмотр видео: {video.name}</DialogTitle>
          <DialogDescription>Просмотр видео из чата в полноэкранном режиме.</DialogDescription>
        </DialogHeader>

        <video
          ref={videoRef}
          src={video.url}
          autoPlay
          loop
          onClick={handlePlayPause}
          onPlay={() => showControls()}
          className="max-h-[calc(100dvh-env(safe-area-inset-top,0px)-env(safe-area-inset-bottom,0px)-0.5rem)] max-w-full object-contain"
        />

        <DialogClose asChild>
            <Button variant="ghost" size="icon" className={cn("absolute z-50 text-white hover:bg-white/20 hover:text-white transition-opacity top-[calc(1rem+env(safe-area-inset-top,0px))] right-[calc(1rem+env(safe-area-inset-right,0px))]", isControlsVisible ? "opacity-100" : "opacity-0")} aria-label="Закрыть">
            <X className="h-6 w-6" />
            </Button>
        </DialogClose>
        
        <div className={cn(
            "absolute z-50 flex items-center gap-2 transition-opacity bottom-[calc(1rem+env(safe-area-inset-bottom,0px))] right-[calc(1rem+env(safe-area-inset-right,0px))]",
            isControlsVisible ? "opacity-100" : "opacity-0"
        )}>
            <Button variant="ghost" size="icon" onClick={handleMuteToggle} className="text-white hover:bg-white/20">
                {isMuted ? <VolumeX /> : <Volume2 />}
            </Button>
             <Button variant="ghost" size="icon" onClick={handleFullscreenToggle} className="text-white hover:bg-white/20">
                {isFullscreen ? <Minimize /> : <Maximize />}
            </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}
