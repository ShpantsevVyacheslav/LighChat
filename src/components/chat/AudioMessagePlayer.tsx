'use client';

import React, { useState, useRef, useEffect, useMemo } from 'react';
import { cn } from '@/lib/utils';
import { Button } from '@/components/ui/button';
import { Play, Pause } from 'lucide-react';
import type { ChatAttachment } from '@/lib/types';

// This component simulates an audio waveform.
function AudioWaveform({ progress, isCurrentUser }: { progress: number; isCurrentUser: boolean }) {
  const bars = useMemo(() => Array.from({ length: 40 }, () => Math.random() * 0.7 + 0.3), []);

  return (
    <div className="flex items-end h-8 gap-[1.5px]">
      {bars.map((height, i) => {
        const isPlayed = (i / bars.length) * 100 < progress;
        const barColor = isCurrentUser
          ? isPlayed
            ? 'bg-outgoing-message-foreground'
            : 'bg-outgoing-message-foreground/40'
          : isPlayed
          ? 'bg-primary'
          : 'bg-primary/30';

        return (
          <div
            key={i}
            className={cn('w-0.5 rounded-full', barColor)}
            style={{ height: `${height * 100}%` }}
          />
        );
      })}
    </div>
  );
}

const PLAYBACK_RATES = [1, 1.25, 1.5, 1.75, 2];

export function AudioMessagePlayer({ attachment, isCurrentUser }: { attachment: ChatAttachment; isCurrentUser: boolean }) {
  const audioRef = useRef<HTMLAudioElement>(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [progress, setProgress] = useState(0);
  const [duration, setDuration] = useState(0);
  const [currentTime, setCurrentTime] = useState(0);
  const [playbackRate, setPlaybackRate] = useState(1);

  const togglePlay = () => {
    if (audioRef.current) {
      if (isPlaying) {
        audioRef.current.pause();
      } else {
        document.querySelectorAll('audio').forEach(audio => {
          if (audio !== audioRef.current) audio.pause();
        });
        audioRef.current.play();
      }
    }
  };

  const cyclePlaybackRate = () => {
    const currentIndex = PLAYBACK_RATES.indexOf(playbackRate);
    const nextIndex = (currentIndex + 1) % PLAYBACK_RATES.length;
    setPlaybackRate(PLAYBACK_RATES[nextIndex]);
  };

  useEffect(() => {
    if (audioRef.current) {
      audioRef.current.playbackRate = playbackRate;
    }
  }, [playbackRate]);

  const formatTime = (time: number) => {
    if (isNaN(time) || !isFinite(time) || time === 0) return '0:00';
    const minutes = Math.floor(time / 60);
    const seconds = Math.floor(time % 60);
    return `${minutes}:${seconds.toString().padStart(2, '0')}`;
  };

  useEffect(() => {
    const audio = audioRef.current;
    if (audio) {
      const handlePlay = () => setIsPlaying(true);
      const handlePause = () => setIsPlaying(false);
      const handleEnded = () => {
        setIsPlaying(false);
        setProgress(0);
        setCurrentTime(0);
      };
      const handleTimeUpdate = () => {
        if (audio.duration && isFinite(audio.duration)) {
          setProgress((audio.currentTime / audio.duration) * 100);
          setCurrentTime(audio.currentTime);
        }
      };
      const handleLoadedMetadata = () => {
        if (audio.duration && isFinite(audio.duration)) {
          setDuration(audio.duration);
        }
      };

      audio.addEventListener('play', handlePlay);
      audio.addEventListener('pause', handlePause);
      audio.addEventListener('ended', handleEnded);
      audio.addEventListener('timeupdate', handleTimeUpdate);
      audio.addEventListener('loadedmetadata', handleLoadedMetadata);

      return () => {
        audio.removeEventListener('play', handlePlay);
        audio.removeEventListener('pause', handlePause);
        audio.removeEventListener('ended', handleEnded);
        audio.removeEventListener('timeupdate', handleTimeUpdate);
        audio.removeEventListener('loadedmetadata', handleLoadedMetadata);
      };
    }
  }, []);

  const buttonClasses = isCurrentUser
    ? 'bg-outgoing-message-accent text-outgoing-message-foreground hover:bg-outgoing-message-accent/90'
    : 'bg-primary text-primary-foreground hover:bg-primary/90';

  return (
    <div className="flex items-center gap-2 w-full max-w-[250px] sm:max-w-[300px]">
      <audio ref={audioRef} src={attachment.url} preload="metadata" />
      <Button
        onClick={togglePlay}
        variant="ghost"
        size="icon"
        className={cn('h-10 w-10 rounded-full flex-shrink-0', buttonClasses)}
      >
        {isPlaying ? <Pause className="h-5 w-5 fill-current" /> : <Play className="h-5 w-5 fill-current" />}
      </Button>
      <div className="flex-1">
        <AudioWaveform progress={progress} isCurrentUser={isCurrentUser} />
        <div
          className={cn(
            'text-xs flex justify-start mt-1',
            isCurrentUser ? 'text-outgoing-message-foreground/70' : 'text-muted-foreground'
          )}
        >
          <span>{formatTime(isPlaying ? currentTime : duration)}</span>
          <span className="mx-1">&bull;</span>
          <span>{(attachment.size / 1024).toFixed(1)} KB</span>
        </div>
      </div>
      <Button onClick={cyclePlaybackRate} variant="ghost" size="sm" className="h-8 w-12 rounded-full text-xs">
        {playbackRate}x
      </Button>
    </div>
  );
}