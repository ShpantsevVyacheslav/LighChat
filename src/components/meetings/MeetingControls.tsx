'use client';

import React from 'react';
import { Button } from '@/components/ui/button';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { Separator } from '@/components/ui/separator';
import { 
  Mic, MicOff, Video as VideoIcon, VideoOff, MonitorUp, MonitorOff, 
  Hand, Smile, MessageSquare, SwitchCamera, BarChart2,
  Users, CircleDot, StopCircle
} from 'lucide-react';
import { cn } from '@/lib/utils';
import { useI18n } from '@/hooks/use-i18n';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '@/components/ui/tooltip';

interface MeetingControlsProps {
  isMicMuted: boolean;
  isVideoOff: boolean;
  isScreenSharing: boolean;
  isHandRaised: boolean;
  isRecording: boolean;
  isHost: boolean;
  unreadChatCount: number;
  activePollsCount: number;
  waitingCount: number;
  activeTab: 'participants' | 'polls' | 'chat' | null;
  isDisplayMediaSupported: boolean;
  onToggleMic: () => void;
  onToggleVideo: () => void;
  onToggleHand: () => void;
  onToggleScreenShare: () => void;
  onToggleChat: () => void;
  onToggleParticipants: () => void;
  onTogglePolls: () => void;
  onSendReaction: (emoji: string) => void;
  onSwitchCamera: () => void;
  screenShareDisabled?: boolean;
}

export function MeetingControls({
  isMicMuted,
  isVideoOff,
  isScreenSharing,
  isHandRaised,
  isRecording,
  isHost,
  unreadChatCount,
  activePollsCount,
  waitingCount,
  activeTab,
  isDisplayMediaSupported,
  onToggleMic,
  onToggleVideo,
  onToggleHand,
  onToggleScreenShare,
  onToggleChat,
  onToggleParticipants,
  onTogglePolls,
  onSendReaction,
  onSwitchCamera,
  screenShareDisabled
}: MeetingControlsProps) {
  const { t } = useI18n();
  return (
    <div className="pointer-events-none absolute inset-x-0 bottom-[max(2rem,env(safe-area-inset-bottom,0px))] z-30 flex flex-col items-center gap-4 pl-[max(1rem,env(safe-area-inset-left,0px))] pr-[max(1rem,env(safe-area-inset-right,0px))]">
        <div className="flex items-center gap-3 bg-black/30 backdrop-blur-3xl p-3 rounded-full shadow-[0_32px_64px_rgba(0,0,0,0.5)] pointer-events-auto border border-white/10 animate-in slide-in-from-bottom-10 duration-1000 max-w-full overflow-x-auto no-scrollbar">
            <TooltipProvider delayDuration={0}>
                <ControlGroup>
                    <ControlButton onClick={onToggleVideo} active={!isVideoOff} variant={isVideoOff ? 'danger' : 'primary'} tooltip={isVideoOff ? t('meetingControls.cameraOn') : t('meetingControls.cameraOff')}>
                        {isVideoOff ? <VideoOff className="h-5 w-5" /> : <VideoIcon className="h-5 w-5" />}
                    </ControlButton>
                    <ControlButton onClick={onToggleMic} active={!isMicMuted} variant={isMicMuted ? 'danger' : 'primary'} tooltip={isMicMuted ? t('meetingControls.micOn') : t('meetingControls.micOff')}>
                        {isMicMuted ? <MicOff className="h-5 w-5" /> : <Mic className="h-5 w-5" />}
                    </ControlButton>
                    <ControlButton onClick={onSwitchCamera} className="md:hidden" tooltip={t('meetingControls.switchCamera')}><SwitchCamera className="h-5 w-5" /></ControlButton>
                </ControlGroup>

                <Separator orientation="vertical" className="h-8 bg-white/10 mx-1 shrink-0" />

                <ControlGroup>
                    <ControlButton onClick={onToggleHand} active={isHandRaised} variant={isHandRaised ? 'warning' : 'ghost'} tooltip={t('meetingControls.raiseHand')}><Hand className={cn("h-5 w-5", isHandRaised && "fill-current")} /></ControlButton>
                    <Popover>
                        <PopoverTrigger asChild>
                            <button className="h-12 w-12 shrink-0 rounded-full flex items-center justify-center bg-white/5 hover:bg-white/15 transition-all text-white outline-none">
                                <Smile className="h-5 w-5" />
                            </button>
                        </PopoverTrigger>
                        <PopoverContent side="top" align="center" className="w-auto p-2 bg-black/60 backdrop-blur-3xl border-white/10 rounded-full flex gap-2 shadow-2xl mb-4 animate-in slide-in-from-bottom-2">
                            {['❤️', '👍', '🔥', '🎉', '😂'].map(emoji => (
                                <button key={emoji} className="text-2xl hover:scale-125 transition-transform duration-200 p-2 filter drop-shadow-lg active:scale-90" onClick={() => onSendReaction(emoji)}>
                                    {emoji}
                                </button>
                            ))}
                        </PopoverContent>
                    </Popover>
                </ControlGroup>
                
                <Separator orientation="vertical" className="h-8 bg-white/10 mx-1 shrink-0" />
                
                <ControlGroup>
                    <ControlButton onClick={onToggleParticipants} active={activeTab === 'participants'} tooltip={t('meetingControls.participantsTab')} badge={waitingCount > 0 ? waitingCount : undefined}><Users className="h-5 w-5" /></ControlButton>
                    <ControlButton onClick={onTogglePolls} active={activeTab === 'polls'} tooltip={t('meetingControls.pollsTab')} badge={activePollsCount > 0 ? activePollsCount : undefined}><BarChart2 className="h-5 w-5" /></ControlButton>
                    <ControlButton onClick={onToggleChat} active={activeTab === 'chat'} tooltip={t('meetingControls.chatTab')} badge={unreadChatCount > 0 && activeTab !== 'chat' ? unreadChatCount : undefined}><MessageSquare className="h-5 w-5" /></ControlButton>
                    {isDisplayMediaSupported && (<ControlButton onClick={onToggleScreenShare} active={isScreenSharing} disabled={screenShareDisabled} variant={isScreenSharing ? 'primary' : 'ghost'} tooltip={isScreenSharing ? t('meetingControls.screenShareStop') : t('meetingControls.screenShareStart')} className="hidden md:flex">{isScreenSharing ? <MonitorOff className="h-5 w-5" /> : <MonitorUp className="h-5 w-5" />}</ControlButton>)}
                </ControlGroup>
            </TooltipProvider>
        </div>
    </div>
  );
}

function ControlGroup({ children }: { children: React.ReactNode }) {
    return <div className="flex items-center gap-2 px-1 shrink-0">{children}</div>;
}

function ControlButton({ children, onClick, active = false, disabled = false, variant = 'ghost', tooltip, badge, className }: any) {
    const variants = {
        primary: active ? "bg-blue-500 text-white shadow-[0_0_20px_rgba(59,130,246,0.5)]" : "bg-white/10 text-white hover:bg-white/20",
        danger: "bg-red-500 text-white shadow-[0_0_20px_rgba(239,68,68,0.5)]",
        warning: active ? "bg-amber-500 text-white shadow-[0_0_20px_rgba(245,158,11,0.5)]" : "bg-white/10 text-white hover:bg-white/20",
        ghost: active ? "bg-white/30 text-white" : "bg-white/10 text-white hover:bg-white/20"
    };
    return (
        <Tooltip>
            <TooltipTrigger asChild>
                <button disabled={disabled} onClick={onClick} className={cn("relative h-12 w-12 shrink-0 rounded-full flex items-center justify-center transition-all duration-300 outline-none active:scale-90", variants[variant as keyof typeof variants], disabled && "opacity-20 cursor-not-allowed grayscale", className)}>
                    {children}{badge !== undefined && (<span className="absolute -top-1 -right-1 bg-red-500 text-white text-[9px] font-black h-4 min-w-[16px] px-1 rounded-full flex items-center justify-center border-2 border-slate-900 animate-in zoom-in-50">{badge}</span>)}
                </button>
            </TooltipTrigger>
            <TooltipContent side="top" className="bg-black/80 backdrop-blur-xl border-white/10 text-white text-[10px] font-bold uppercase tracking-widest rounded-lg px-3 py-1.5 mb-2">{tooltip}</TooltipContent>
        </Tooltip>
    );
}