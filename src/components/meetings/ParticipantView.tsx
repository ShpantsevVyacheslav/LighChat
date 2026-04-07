'use client';

import React, { useRef, useEffect, useState } from 'react';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';
import { 
  VideoOff, MicOff, Maximize, Hand, CircleDot, MonitorPlay
} from 'lucide-react';
import type { BackgroundConfig } from '@/hooks/use-meeting-webrtc';

interface ParticipantState {
  id: string;
  name: string;
  avatar: string;
  stream?: MediaStream | null;
  isAudioMuted?: boolean;
  isVideoMuted?: boolean;
  isHandRaised?: boolean;
  isScreenSharing?: boolean;
  reaction?: string | null;
  role?: string;
  lastSeen?: any;
  backgroundConfig?: BackgroundConfig;
  facingMode?: 'user' | 'environment';
}

/** grid — квадратные плитки в сетке; stage — крупное видео в режиме докладчика; strip задаётся через isCompact */
export type ParticipantTileLayout = 'grid' | 'stage';

interface ParticipantViewProps {
  participant: ParticipantState | null;
  isLocal?: boolean;
  className?: string;
  isCompact?: boolean;
  /** Только при isCompact === false: сетка конференции или крупный кадр */
  layout?: ParticipantTileLayout;
  isHost?: boolean;
  onSpeaking?: (isSpeaking: boolean) => void;
  onClick?: () => void;
}

function SmallReactionIndicator({ reaction }: { reaction: string | null }) {
  const [activeReaction, setActiveReaction] = useState<string | null>(null);

  useEffect(() => {
    if (reaction) {
      setActiveReaction(reaction);
      const timer = setTimeout(() => setActiveReaction(null), 3000);
      return () => clearTimeout(timer);
    } else {
      setActiveReaction(null);
    }
  }, [reaction]);

  if (!activeReaction) return null;

  return (
    <div className="absolute top-2 right-2 z-[60] animate-in zoom-in-50 duration-300">
      <div className="bg-black/60 backdrop-blur-md rounded-full w-10 h-10 flex items-center justify-center text-2xl shadow-xl border border-white/10">
        {activeReaction}
      </div>
    </div>
  );
}

const ParticipantViewComponent = ({ 
  participant,
  isLocal = false,
  className,
  isCompact = false,
  layout = 'grid',
  isHost = false,
  onSpeaking,
  onClick
}: ParticipantViewProps) => {
  const videoRef = useRef<HTMLVideoElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const [hasVideo, setHasVideo] = useState(false);
  const [volumeLevel, setVolumeLevel] = useState(0);
  const [isPipAvailable, setIsPipAvailable] = useState(false);
  const analyserRef = useRef<AnalyserNode | null>(null);
  const animationFrameRef = useRef<number | null>(null);
  const lastSpeakingState = useRef(false);

  useEffect(() => {
    const checkPip = () => {
        if (typeof document !== 'undefined') {
            const video = videoRef.current;
            const hasSupport = !!(document as any).pictureInPictureEnabled || 
                               !!(video as any)?.webkitSupportsPresentationMode?.('picture-in-picture');
            setIsPipAvailable(hasSupport);
        }
    };
    checkPip();
  }, [videoRef]);

  useEffect(() => {
    const video = videoRef.current;
    if (video && participant?.stream) {
      if (video.srcObject !== participant.stream) {
        video.srcObject = participant.stream;
        try {
            video.load(); 
        } catch (e) {}
      }
    } else if (video && !participant?.stream) {
        if (video.srcObject) {
            video.srcObject = null;
        }
    }
  }, [participant?.stream, participant?.id]);

  useEffect(() => {
    if (!participant?.stream || participant.isAudioMuted || participant.stream.getAudioTracks().length === 0) {
      setVolumeLevel(0);
      if (lastSpeakingState.current && onSpeaking) {
        lastSpeakingState.current = false;
        onSpeaking(false);
      }
      return;
    }

    try {
      const audioContext = new (window.AudioContext || (window as any).webkitAudioContext)();
      const source = audioContext.createMediaStreamSource(participant.stream);
      const analyser = audioContext.createAnalyser();
      analyser.fftSize = 256;
      source.connect(analyser);
      analyserRef.current = analyser;

      const bufferLength = analyser.frequencyBinCount;
      const dataArray = new Uint8Array(bufferLength);

      const checkVolume = () => {
        if (!analyserRef.current) return;
        analyserRef.current.getByteFrequencyData(dataArray);
        let sum = 0;
        for (let i = 0; i < bufferLength; i++) {
          sum += dataArray[i];
        }
        const average = sum / bufferLength;
        setVolumeLevel(average);
        
        const isSpeakingNow = average > 15;
        if (isSpeakingNow !== lastSpeakingState.current) {
          lastSpeakingState.current = isSpeakingNow;
          if (onSpeaking) onSpeaking(isSpeakingNow);
        }
        
        animationFrameRef.current = requestAnimationFrame(checkVolume);
      };

      checkVolume();

      return () => {
        if (animationFrameRef.current) cancelAnimationFrame(animationFrameRef.current);
        if (audioContext.state !== 'closed') audioContext.close();
        analyserRef.current = null;
      };
    } catch (e) {
      console.warn("Audio analysis failed", e);
    }
  }, [participant?.stream, participant?.isAudioMuted, onSpeaking]);

  useEffect(() => {
    const checkVideo = () => {
        if (!participant) {
            setHasVideo(false);
            return;
        }
        const videoTrack = participant.stream?.getVideoTracks()[0];
        const isActive = !!videoTrack && videoTrack.enabled && videoTrack.readyState === 'live' && !participant.isVideoMuted;
        if (isActive !== hasVideo) {
            setHasVideo(isActive);
        }
    };

    const interval = setInterval(checkVideo, 1000);
    checkVideo();
    return () => clearInterval(interval);
  }, [participant?.stream, participant?.isVideoMuted, hasVideo]);

  const toggleFullscreen = (e: React.MouseEvent) => {
    e.stopPropagation();
    const elem = containerRef.current;
    const video = videoRef.current;
    if (!elem) return;

    if (!document.fullscreenElement && 
        !(document as any).webkitFullscreenElement && 
        !(document as any).mozFullScreenElement && 
        !(document as any).msFullscreenElement) {
      if (elem.requestFullscreen) {
        elem.requestFullscreen();
      } else if ((elem as any).webkitRequestFullscreen) {
        (elem as any).webkitRequestFullscreen();
      } else if (video && (video as any).webkitEnterFullscreen) {
        (video as any).webkitEnterFullscreen();
      }
    } else {
      if (document.exitFullscreen) {
        document.exitFullscreen();
      } else if ((document as any).webkitExitFullscreen) {
        (document as any).webkitExitFullscreen();
      }
    }
  };

  const togglePip = async (e: React.MouseEvent) => {
    e.stopPropagation();
    const video = videoRef.current;
    if (!video) return;

    try {
        if (document.pictureInPictureElement) {
            await document.exitPictureInPicture();
        } else if (document.pictureInPictureEnabled) {
            await video.requestPictureInPicture();
        } else if ((video as any).webkitSetPresentationMode) {
            const currentMode = (video as any).webkitPresentationMode;
            (video as any).webkitSetPresentationMode(currentMode === 'picture-in-picture' ? 'inline' : 'picture-in-picture');
        }
    } catch (error) {
        console.error("Picture-in-Picture failed", error);
    }
  };

  if (!participant) return null;

  // Mirror only if front camera is used and not screen sharing
  const shouldMirror = participant.facingMode === 'user' && !participant.isScreenSharing;

  const tileLayout = isCompact ? 'strip' : layout;

  return (
    <div 
      ref={containerRef} 
      onClick={onClick}
      className={cn(
        "relative bg-slate-950 overflow-hidden group border border-white/10 shadow-lg transition-all duration-500 cursor-pointer",
        participant.isHandRaised && "ring-2 ring-yellow-400 ring-offset-0 ring-offset-slate-950",
        (volumeLevel > 15) && "ring-2 ring-primary ring-offset-0 ring-offset-slate-950 shadow-[0_0_16px_rgba(67,56,202,0.35)]",
        tileLayout === 'strip' && "aspect-video h-full min-h-0 shrink-0 rounded-xl",
        tileLayout === 'grid' && "aspect-square w-full max-w-full rounded-xl",
        tileLayout === 'stage' && "aspect-video w-full max-h-[min(85vh,100%)] rounded-2xl",
        className
      )}
    >
      <div className={cn(
          "relative w-full h-full flex items-center justify-center transition-all duration-500",
          !hasVideo ? "opacity-0" : "opacity-100",
          shouldMirror && "-scale-x-100" 
      )}>
        <video 
            ref={videoRef} 
            autoPlay 
            muted={isLocal} 
            playsInline 
            webkit-playsinline="true"
            className="w-full h-full z-10 object-cover" 
        />
      </div>
      
      {!hasVideo && (
        <div className="absolute inset-0 bg-slate-900 flex items-center justify-center z-20">
          <Avatar className={cn(isCompact ? "h-12 w-12" : "h-24 w-24 sm:h-32 sm:w-32", "rounded-full border-4 border-white/10 shadow-2xl")}>
            <AvatarImage src={participant.avatar} className="object-cover w-full h-full" />
            <AvatarFallback className="bg-slate-800 text-slate-400 text-2xl">
                {(participant.name || '?').charAt(0)}
            </AvatarFallback>
          </Avatar>
          <div className="absolute inset-0 bg-black/40 flex items-center justify-center pointer-events-none">
             <VideoOff className={cn(isCompact ? "h-6 w-6" : "h-16 w-16", "text-white/5")} />
          </div>
        </div>
      )}

      {participant.isHandRaised && (
        <div className={cn("absolute z-40 animate-bounce", isCompact ? "top-1 right-1" : "top-4 right-4")}>
          <div className={cn("bg-yellow-400 text-black p-1.5 rounded-full shadow-2xl border-2 border-black/10")}>
            <Hand className={cn("fill-current", isCompact ? "h-3 w-3" : "h-7 w-7")} />
          </div>
        </div>
      )}

      <SmallReactionIndicator reaction={participant.reaction || null} />

      <div className={cn(
          "absolute flex items-center gap-2 bg-black/40 backdrop-blur-md z-30 shadow-lg border border-white/10",
          isCompact ? "top-1.5 left-1.5 px-2 py-0.5 rounded-lg" : "top-4 left-4 px-3 py-1.5 rounded-full"
      )}>
        {(volumeLevel > 15) && <div className="flex gap-0.5 items-end h-3 mb-0.5">
          <div className="w-0.5 bg-primary animate-[audio-bar_0.5s_ease-in-out_infinite]" style={{ height: '40%' }}></div>
          <div className="w-0.5 bg-primary animate-[audio-bar_0.7s_ease-in-out_infinite]" style={{ height: '80%' }}></div>
          <div className="w-0.5 bg-primary animate-[audio-bar_0.6s_ease-in-out_infinite]" style={{ height: '60%' }}></div>
        </div>}
        <div className={cn("font-bold tracking-tight text-white flex items-center gap-2", isCompact ? "text-[9px]" : "text-xs")}>
            <span className="truncate max-w-[80px] sm:max-w-[120px]">
                {isLocal ? `${participant.name} (Вы)` : (participant.name || 'Гость')}
            </span>
            {isHost && (
              <div className="flex items-center">
                <CircleDot className="h-2 w-2 text-cyan-400 fill-current" />
              </div>
            )}
        </div>
        {participant.isAudioMuted && <MicOff className="h-2.5 w-2.5 text-red-500" />}
      </div>

      {!isCompact && (
        <div className="absolute top-4 right-4 z-40 transition-opacity opacity-0 group-hover:opacity-100 flex gap-2">
            {isPipAvailable && hasVideo && (
                <Button variant="ghost" size="icon" className="h-8 w-8 rounded-full bg-black/40 text-white hover:bg-black/60 shadow-none border-none" onClick={togglePip}>
                    <MonitorPlay className="h-4 w-4" />
                </Button>
            )}
            <Button variant="ghost" size="icon" className="h-8 w-8 rounded-full bg-black/40 text-white hover:bg-black/60 shadow-none border-none" onClick={toggleFullscreen}>
                <Maximize className="h-4 w-4" />
            </Button>
        </div>
      )}
    </div>
  );
};

export const ParticipantView = React.memo(ParticipantViewComponent, (prev, next) => {
    const p1 = prev.participant;
    const p2 = next.participant;
    
    if (!p1 || !p2) return p1 === p2;
    
    return (
        p1.id === p2.id &&
        p1.stream?.id === p2.stream?.id &&
        p1.isAudioMuted === p2.isAudioMuted &&
        p1.isVideoMuted === p2.isVideoMuted &&
        p1.isHandRaised === p2.isHandRaised &&
        p1.isScreenSharing === p2.isScreenSharing &&
        p1.reaction === p2.reaction &&
        p1.facingMode === p2.facingMode &&
        prev.isLocal === next.isLocal &&
        prev.isCompact === next.isCompact &&
        prev.layout === next.layout &&
        prev.isHost === next.isHost &&
        JSON.stringify(p1.backgroundConfig) === JSON.stringify(p2.backgroundConfig)
    );
});

ParticipantView.displayName = 'ParticipantView';
