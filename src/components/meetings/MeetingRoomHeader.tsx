'use client';

import React, { useRef, useState } from 'react';
import { Button } from '@/components/ui/button';
import { 
  PhoneOff, Wand2, Plus, Loader2, Ban, Sparkles, StopCircle, PlayCircle,
  Copy, LayoutGrid, Maximize2, Clock, User, CircleDot
} from 'lucide-react';
import { cn } from '@/lib/utils';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { ScrollArea } from '../ui/scroll-area';
import { Separator } from '@/components/ui/separator';
import { useFirestore, useStorage } from '@/firebase';
import { useAuth } from '@/hooks/use-auth';
import { doc, updateDoc, arrayUnion } from 'firebase/firestore';
import { ref as storageRef, uploadString, getDownloadURL } from 'firebase/storage';
import { useToast } from '@/hooks/use-toast';
import { compressImage } from '@/lib/image-compression';
import type { BackgroundConfig } from '@/hooks/use-meeting-webrtc';
import { useI18n } from '@/hooks/use-i18n';

interface MeetingRoomHeaderProps {
  meetingName: string;
  isRecording: boolean;
  participantCount: number;
  onExit: () => void;
  backgroundConfig: BackgroundConfig;
  onBackgroundChange: (config: BackgroundConfig) => void;
  standardBackgrounds: { id: string; url: string; name: string }[];
  isVideoOff: boolean;
  isHost: boolean;
  onStartRecording: () => void;
  onStopRecording: () => void;
  duration: string;
  viewMode: 'speaker' | 'grid';
  onToggleViewMode: () => void;
  onCopyLink: () => void;
}

export function MeetingRoomHeader({ 
  meetingName,
  isRecording, 
  onExit,
  backgroundConfig,
  onBackgroundChange,
  standardBackgrounds,
  isVideoOff,
  isHost,
  onStartRecording,
  onStopRecording,
  duration,
  viewMode,
  onToggleViewMode,
  onCopyLink
}: MeetingRoomHeaderProps) {
  const { t } = useI18n();
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [isUploading, setIsUploading] = useState(false);
  const [isEffectsOpen, setIsEffectsOpen] = useState(false);
  
  const firestore = useFirestore();
  const storage = useStorage();
  const { user } = useAuth();
  const { toast } = useToast();

  const handleCustomBackgroundUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file || !storage || !firestore || !user?.id) return;
    
    setIsUploading(true);
    try {
      const dataUri = await compressImage(file, 0.85, 1280);
      const filename = `${Date.now()}_${file.name.replace(/\s/g, '_')}`;
      const path = `users/${user.id}/backgrounds/${filename}`;
      const fileRef = storageRef(storage, path);
      
      await uploadString(fileRef, dataUri, 'data_url');
      const publicUrl = await getDownloadURL(fileRef);
      
      const userRef = doc(firestore, 'users', user.id);
      await updateDoc(userRef, { 
        customBackgrounds: arrayUnion(publicUrl),
        lastSelectedBackground: publicUrl
      });
      
      onBackgroundChange({ type: 'image', url: publicUrl });
      toast({ title: t('meetingHeader.bgAdded') });
    } catch (err) {
      console.error("Custom background upload failed", err);
      toast({ variant: 'destructive', title: t('meetingHeader.bgUploadError') });
    } finally {
      setIsUploading(false);
    }
  };

  const selectBackground = (config: BackgroundConfig) => {
    onBackgroundChange(config);
    if (config.type === 'image' && config.url && firestore && user?.id) {
        const userRef = doc(firestore, 'users', user.id);
        updateDoc(userRef, { lastSelectedBackground: config.url }).catch(() => {});
    }
  };

  return (
    <div className="pointer-events-none absolute right-[max(1.5rem,env(safe-area-inset-right,0px))] top-[max(1.5rem,env(safe-area-inset-top,0px))] z-50 flex items-center gap-3">
      <div className="flex items-center gap-3 p-1.5 pl-4 pr-3 bg-black/30 backdrop-blur-2xl border border-white/10 rounded-full pointer-events-auto shadow-2xl transition-all hover:bg-black/40 group">
          <div className="flex flex-col min-w-0">
              <div className="flex items-center gap-2">
                <h1 className="text-xs font-bold tracking-tight truncate max-w-[120px] text-white/90">{meetingName}</h1>
                {isRecording && (
                  <div className="flex items-center gap-1 px-1.5 py-0.5 bg-red-500/20 border border-red-500/30 rounded-md animate-pulse">
                    <div className="h-1.5 w-1.5 rounded-full bg-red-500 shadow-[0_0_5px_rgba(239,68,68,0.8)]" />
                    <span className="text-[8px] font-black tracking-tighter text-red-500">REC</span>
                  </div>
                )}
              </div>
              <div className="flex items-center gap-1.5 opacity-60">
                  <div className="relative">
                      <Clock className="h-2.5 w-2.5 text-cyan-400" />
                      <div className="absolute inset-0 bg-cyan-400/20 blur-sm rounded-full animate-pulse" />
                  </div>
                  <span className="text-[10px] font-black font-mono tabular-nums tracking-tighter">{duration}</span>
              </div>
          </div>
          <Separator orientation="vertical" className="h-6 bg-white/10 mx-1" />
          <div className="flex items-center gap-1">
              <Button variant="ghost" size="icon" onClick={onCopyLink} className="rounded-full h-8 w-8 text-white/40 hover:text-white hover:bg-white/10 transition-all shadow-none border-none">
                  <Copy className="h-4 w-4" />
              </Button>
              <Button variant="ghost" size="icon" onClick={onToggleViewMode} className="rounded-full h-8 w-8 text-white/40 hover:text-white hover:bg-white/10 transition-all shadow-none border-none">
                  {viewMode === 'speaker' ? <LayoutGrid className="h-4 w-4" /> : <Maximize2 className="h-4 w-4" />}
              </Button>
          </div>
      </div>

      <div className="flex items-center gap-2 p-1.5 bg-black/30 backdrop-blur-2xl border border-white/10 rounded-full pointer-events-auto shadow-2xl">
          {isHost && (
            <Button 
                variant="ghost" size="icon" 
                onClick={isRecording ? onStopRecording : onStartRecording}
                className={cn("rounded-full h-9 w-9 transition-all border-none shadow-none", isRecording ? "text-red-500 bg-red-500/10" : "text-white/60 hover:text-white hover:bg-white/10")}
            >
                {isRecording ? <StopCircle className="h-4 w-4" /> : <CircleDot className="h-4 w-4" />}
            </Button>
          )}
          <Popover open={isEffectsOpen} onOpenChange={setIsEffectsOpen}>
              <PopoverTrigger asChild>
                <Button size="icon" variant="ghost" className={cn("h-9 w-9 rounded-full bg-white/5 hover:bg-white/15 transition-all border-none shadow-none text-white", isEffectsOpen && "bg-white/20 text-primary shadow-[0_0_15px_rgba(67,56,202,0.4)]")}>
                  {isUploading ? <Loader2 className="h-4 w-4 animate-spin" /> : <Wand2 className="h-4 w-4" />}
                </Button>
              </PopoverTrigger>
              <PopoverContent side="bottom" align="end" className="w-80 p-0 bg-black/80 backdrop-blur-3xl border-white/10 rounded-3xl mt-4 text-white shadow-2xl overflow-hidden animate-in zoom-in-95 duration-300">
                  <div className="p-5 border-b border-white/5 flex items-center justify-between bg-white/5">
                      <div className="flex flex-col">
                        <h4 className="text-[10px] font-black uppercase tracking-[0.2em] text-white/50">{t('meetingHeader.visualEffects')}</h4>
                        <p className="text-[8px] text-white/30 uppercase">{t('meetingHeader.background')}</p>
                      </div>
                      <Button variant="ghost" size="icon" className="h-8 w-8 rounded-full bg-white/10 hover:bg-white/20" onClick={() => fileInputRef.current?.click()} disabled={isUploading}>
                          {isUploading ? <Loader2 className="h-3 w-3 animate-spin" /> : <Plus className="h-4 w-4" />}
                          <input type="file" ref={fileInputRef} className="hidden" accept="image/*" onChange={handleCustomBackgroundUpload} />
                      </Button>
                  </div>
                  <ScrollArea className="h-80">
                      <div className="p-5 space-y-6">
                          <div className="grid grid-cols-2 gap-3">
                              <div role="button" tabIndex={0} className={cn("flex flex-col items-center justify-center p-3 rounded-2xl border transition-all gap-2 h-24 cursor-pointer", backgroundConfig.type === 'none' ? "border-primary bg-primary/20" : "border-white/5 bg-white/5 hover:bg-white/10")} onClick={() => selectBackground({ type: 'none' })}>
                                  <Ban className="h-5 w-5 opacity-40" /><span className="text-[10px] font-black uppercase tracking-widest">{t('meetingHeader.off')}</span>
                              </div>
                              <div role="button" tabIndex={0} className={cn("flex flex-col items-center justify-center p-3 rounded-2xl border transition-all gap-2 h-24 cursor-pointer", backgroundConfig.type === 'blur' ? "border-primary bg-primary/20 shadow-[inset_0_0_20px_rgba(67,56,202,0.2)]" : "border-white/5 bg-white/5 hover:bg-white/10")} onClick={() => selectBackground({ type: 'blur' })}>
                                  <Sparkles className="h-5 w-5 text-primary" /><span className="text-[10px] font-black uppercase tracking-widest">{t('meetingHeader.blur')}</span>
                              </div>
                          </div>
                          {user?.customBackgrounds && user.customBackgrounds.length > 0 && (
                              <div className="space-y-3"><h5 className="text-[9px] font-bold uppercase tracking-widest opacity-40 ml-1">{t('meetingHeader.yourBackgrounds')}</h5><div className="grid grid-cols-2 gap-3">{user.customBackgrounds.map((url, idx) => (<div key={`custom-${idx}`} role="button" tabIndex={0} className={cn("relative flex flex-col items-center justify-center h-24 rounded-2xl border overflow-hidden transition-all group cursor-pointer", (backgroundConfig.type === 'image' && backgroundConfig.url === url) ? "border-primary ring-2 ring-primary/50" : "border-white/5")} onClick={() => selectBackground({ type: 'image', url })}><img src={url} className="absolute inset-0 w-full h-full object-cover opacity-60 group-hover:scale-110 transition-transform duration-700" alt="" /><div className="absolute inset-0 bg-black/40" /><User className="relative z-10 h-4 w-4 text-white/40" /></div>))}</div></div>
                          )}
                          <div className="space-y-3"><h5 className="text-[9px] font-bold uppercase tracking-widest opacity-40 ml-1">{t('meetingHeader.gallery')}</h5><div className="grid grid-cols-2 gap-3">{standardBackgrounds?.map((bg: any) => (<div key={bg.id} role="button" tabIndex={0} className={cn("relative flex flex-col items-center justify-center h-24 rounded-2xl border overflow-hidden transition-all group cursor-pointer", (backgroundConfig.type === 'image' && backgroundConfig.url === bg.url) ? "border-primary ring-2 ring-primary/50" : "border-white/5")} onClick={() => selectBackground({ type: 'image', url: bg.url })}><img src={bg.url} className="absolute inset-0 w-full h-full object-cover opacity-60 group-hover:scale-110 transition-transform duration-700" alt="" /><div className="absolute inset-0 bg-black/40" /><span className="relative z-10 text-[9px] font-black uppercase tracking-widest drop-shadow-lg text-center px-2">{bg.name}</span></div>))}</div></div>
                      </div>
                  </ScrollArea>
              </PopoverContent>
          </Popover>
          <Button variant="destructive" size="icon" onClick={onExit} className="rounded-full h-9 w-9 shadow-lg shadow-red-500/30 hover:bg-red-600 transition-all active:scale-95 border-none"><PhoneOff className="h-4 w-4 text-white" /></Button>
      </div>
    </div>
  );
}
