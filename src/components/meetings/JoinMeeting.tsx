'use client';

import React, { useState, useEffect, useRef, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import type { Meeting, User as AppUser } from '@/lib/types';
import { logger } from '@/lib/logger';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';
import { Loader2, Video, VideoOff, Mic, MicOff, User as UserIcon, ArrowLeft } from 'lucide-react';
import { useI18n } from '@/hooks/use-i18n';

interface JoinMeetingProps {
  meeting: Meeting;
  currentUser: AppUser | null;
  requireNameInput?: boolean;
  onJoin: (settings: { micMuted: boolean; videoOff: boolean; name: string; stream: MediaStream | null }) => void;
}

export function JoinMeeting({ meeting, currentUser, requireNameInput = false, onJoin }: JoinMeetingProps) {
  const { t } = useI18n();
  const [name, setName] = useState(requireNameInput ? '' : (currentUser?.name || ''));
  const [isJoining, setIsJoining] = useState(false);
  const [micMuted, setMicMuted] = useState(false);
  const [videoOff, setVideoOff] = useState(false);
  const [localStream, setLocalStream] = useState<MediaStream | null>(null);
  const [permissionError, setPermissionError] = useState(false);
  
  const videoRef = useRef<HTMLVideoElement>(null);
  const router = useRouter();

  useEffect(() => {
    if (requireNameInput) {
      setName('');
      return;
    }
    setName(currentUser?.name || '');
  }, [requireNameInput, currentUser?.name]);

  useEffect(() => {
    async function startPreview() {
      try {
        const stream = await navigator.mediaDevices.getUserMedia({ 
          video: { width: 640, height: 480, facingMode: 'user' }, 
          audio: true 
        });
        setLocalStream(stream);
        if (videoRef.current) {
          videoRef.current.srcObject = stream;
          videoRef.current.muted = true;
        }
      } catch (err) {
        logger.error('join-meeting', 'Lobby preview failed', err);
        setPermissionError(true);
        setVideoOff(true);
      }
    }
    startPreview();
    
    return () => {
        if (localStream) {
            localStream.getTracks().forEach(t => t.stop());
        }
    };
  }, []);

  const stopMedia = useCallback(() => {
    if (localStream) {
        localStream.getTracks().forEach(track => track.stop());
    }
  }, [localStream]);

  const handleJoinClick = async (e: React.FormEvent) => {
    e.preventDefault();
    const finalName = name.trim();
    if (!finalName) return;

    setIsJoining(true);
    stopMedia();
    
    onJoin({ 
      micMuted, 
      videoOff, 
      name: finalName,
      stream: null
    });
  };

  return (
    <div className="min-h-[100dvh] w-full flex flex-col bg-[#0a0e17] text-white relative">
      <div className="absolute left-[max(1.5rem,env(safe-area-inset-left,0px))] top-[max(1.5rem,env(safe-area-inset-top,0px))] z-50">
        <Button variant="ghost" onClick={() => router.push('/dashboard/meetings')} className="rounded-full bg-white/5 text-white hover:bg-white/10 border-none shadow-none">
          <ArrowLeft className="mr-2 h-4 w-4" /> {t('meetingJoin.back')}
        </Button>
      </div>

      <div className="flex-1 flex items-center justify-center p-4 md:p-8">
        <div className="w-full max-w-5xl grid grid-cols-1 lg:grid-cols-2 gap-8 lg:gap-12 items-center">
          <div className="space-y-4">
              <div className="relative aspect-video bg-slate-900 rounded-3xl overflow-hidden shadow-2xl flex items-center justify-center border border-white/5">
                  {videoOff ? (
                      <div className="flex flex-col items-center gap-4 text-white/20">
                          <UserIcon className="h-24 w-24" />
                          <p className="text-sm font-medium uppercase tracking-widest opacity-50">{t('meetingJoin.cameraOff')}</p>
                      </div>
                  ) : (
                      <video ref={videoRef} autoPlay muted playsInline className="w-full h-full object-cover -scale-x-100" />
                  )}
                  
                  <div className="absolute bottom-4 flex gap-3">
                      <Button size="icon" variant={micMuted ? "destructive" : "secondary"} className="rounded-full h-12 w-12 backdrop-blur-md bg-white/10 border-none shadow-xl" onClick={() => setMicMuted(!micMuted)}>
                          {micMuted ? <MicOff className="h-5 w-5" /> : <Mic className="h-5 w-5" />}
                      </Button>
                      <Button size="icon" variant={videoOff ? "destructive" : "secondary"} className="rounded-full h-12 w-12 backdrop-blur-md bg-white/10 border-none shadow-xl" onClick={() => setVideoOff(!videoOff)} disabled={permissionError}>
                          {videoOff ? <VideoOff className="h-5 w-5" /> : <Video className="h-5 w-5" />}
                      </Button>
                  </div>
              </div>
          </div>

          <Card className="rounded-3xl bg-slate-900/50 backdrop-blur-xl text-white border-none shadow-2xl">
              <CardHeader className="pt-8 px-8">
                  <CardTitle className="text-3xl font-bold">{t('meetingJoin.readyToJoin')}</CardTitle>
                  <CardDescription className="text-slate-400">{t('meetingJoin.meetingLabel', { name: meeting.name })}</CardDescription>
              </CardHeader>
              <CardContent className="p-8">
                  <form onSubmit={handleJoinClick} className="space-y-6">
                      {(requireNameInput || !currentUser) && (
                          <div className="space-y-2">
                              <Label className="text-[10px] font-bold uppercase tracking-widest opacity-50 ml-1">{t('meetingJoin.yourName')}</Label>
                              <Input value={name} onChange={e => setName(e.target.value)} className="h-14 rounded-2xl bg-white/5 border-white/10 focus:ring-primary" required placeholder={t('meetingJoin.enterName')} />
                          </div>
                      )}
                      <Button type="submit" className="w-full h-16 rounded-2xl text-lg font-bold bg-primary hover:bg-primary/90 transition-all active:scale-[0.98] shadow-xl shadow-primary/20" disabled={isJoining}>
                          {isJoining ? <Loader2 className="animate-spin h-6 w-6" /> : t('meetingJoin.join')}
                      </Button>
                  </form>
              </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
