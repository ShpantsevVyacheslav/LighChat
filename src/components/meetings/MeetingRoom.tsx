'use client';

import React, { useEffect, useRef, useState, useMemo, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import type { Meeting, User, MeetingJoinRequest } from '@/lib/types';
import { useDoc, useFirestore, useMemoFirebase, useCollection, useStorage } from '@/firebase';
import { collection, doc, onSnapshot, serverTimestamp, query, where, orderBy, deleteDoc, setDoc, updateDoc, increment, limitToLast } from 'firebase/firestore';
import { ref as storageRef, getDownloadURL } from 'firebase/storage';
import { cn } from '@/lib/utils';
import { useToast } from '@/hooks/use-toast';
import { Check, XCircle, ChevronRight, ChevronLeft } from 'lucide-react';
import { format } from 'date-fns';

import { ParticipantView } from './ParticipantView';
import {
  MeetingParticipantTileStage,
  MEETING_TILES_PER_PAGE,
  chunkMeetingTiles,
} from './MeetingParticipantTileStage';
import { MeetingRoomHeader } from './MeetingRoomHeader';
import { MeetingControls } from './MeetingControls';
import { MeetingSidebar } from './MeetingSidebar';
import { MeetingPolls } from './MeetingPolls';
import { useMeetingWebRTC, type BackgroundConfig } from '@/hooks/use-meeting-webrtc';
import { Avatar, AvatarFallback, AvatarImage } from '../ui/avatar';
import { userAvatarListUrl } from '@/lib/user-avatar-display';
import { Button } from '../ui/button';

interface MeetingRoomProps {
  meeting: Meeting;
  currentUser: User;
  initialMicMuted?: boolean;
  initialVideoOff?: boolean;
  initialName?: string;
  initialStream?: MediaStream | null;
}

interface FlyingEmoji {
  id: string;
  emoji: string;
  left: number;
}

const STANDARD_BG_LIST = [
    { id: 'office', name: 'Офис', filename: 'office.jpg' },
    { id: 'home', name: 'Дом', filename: 'home.jpg' },
    { id: 'studio', name: 'Студия', filename: 'studio.jpg' },
    { id: 'nature', name: 'Природа', filename: 'nature.jpg' }
];

export function MeetingRoom({ 
  meeting: initialMeeting, 
  currentUser, 
  initialMicMuted = false, 
  initialVideoOff = false,
  initialName = '',
  initialStream = null
}: MeetingRoomProps) {
  const router = useRouter();
  const firestore = useFirestore();
  const storage = useStorage();
  const { toast } = useToast();
  
  const [meeting, setMeeting] = useState<Meeting>(initialMeeting);
  const [activeSidebarTab, setActiveSidebarTab] = useState<'participants' | 'polls' | 'chat' | null>(null);
  const [unreadChatCount, setUnreadChatCount] = useState(0);
  const [activePollsCount, setActivePollsCount] = useState(0);
  const [chatMessages, setChatMessages] = useState<any[]>([]);
  const [newMessageText, setNewMessageText] = useState('');
  const [isRecording, setIsRecording] = useState(false);
  const [waitingCount, setWaitingCount] = useState(0);
  const [viewMode, setViewMode] = useState<'speaker' | 'grid'>('grid');
  const [activeSpeakerId, setActiveSpeakerId] = useState<string | null>(null);
  const [manualFocusId, setManualFocusId] = useState<string | null>(null);
  const [standardBackgrounds, setStandardBackgrounds] = useState<{ id: string; url: string; name: string }[]>([]);
  const [meetingDuration, setMeetingDuration] = useState(0);
  const [flyingEmojis, setFlyingEmojis] = useState<FlyingEmoji[]>([]);
  const reactionsSeenRef = useRef<Record<string, string | null | undefined>>({});
  
  const lastSpeakerSwitchTime = useRef<number>(0);
  const SPEAKER_SWITCH_GRACE_PERIOD = 2500; 

  const chatEndRef = useRef<HTMLDivElement>(null);
  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const recordedChunksRef = useRef<Blob[]>([]);
  const meetingStartTimeRef = useRef(Date.now());

  const rtcSettings = useMemo(() => ({
    micMuted: initialMicMuted,
    videoOff: initialVideoOff,
    name: initialName,
    stream: initialStream
  }), [initialMicMuted, initialVideoOff, initialName, initialStream]);

  const rtc = useMeetingWebRTC(meeting, currentUser, rtcSettings);

  const isAdmin = useMemo<boolean>(() => 
    !!(meeting.hostId === currentUser.id || (meeting.adminIds && meeting.adminIds.includes(currentUser.id)))
  , [meeting, currentUser.id]);

  const spawnFlyingEmoji = useCallback((emoji: string) => {
    const id = `${Date.now()}-${Math.random()}`;
    const left = 40 + Math.random() * 20; 
    setFlyingEmojis(prev => [...prev, { id, emoji, left }]);
    setTimeout(() => {
      setFlyingEmojis(prev => prev.filter(e => e.id !== id));
    }, 4000);
  }, []);

  useEffect(() => {
    const timer = setInterval(() => {
      setMeetingDuration(Math.floor((Date.now() - meetingStartTimeRef.current) / 1000));
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  useEffect(() => {
    if (!storage) return;
    const loadBgs = async () => {
        const loaded: any[] = [];
        for (const item of STANDARD_BG_LIST) {
            try {
                const url = await getDownloadURL(storageRef(storage, `meeting-assets/backgrounds/${item.filename}`));
                loaded.push({ ...item, url });
            } catch (e) {}
        }
        setStandardBackgrounds(loaded);
    };
    loadBgs();
  }, [storage]);

  useEffect(() => {
    if (!firestore) return;
    return onSnapshot(doc(firestore, 'meetings', initialMeeting.id), (snap) => {
      if (snap.exists()) setMeeting(snap.data() as Meeting);
    });
  }, [firestore, initialMeeting.id]);

  useEffect(() => {
    if (!firestore) return;
    const messagesLimit = activeSidebarTab === 'chat' ? 120 : 40;
    const q = query(
      collection(firestore, `meetings/${meeting.id}/messages`),
      orderBy('createdAt', 'asc'),
      limitToLast(messagesLimit)
    );
    
    let isInitial = true;
    return onSnapshot(q, (snap) => {
      const messages = snap.docs.map(d => ({ id: d.id, ...d.data() }));
      setChatMessages(messages);
      
      if (isInitial) {
          isInitial = false;
          return;
      }

      const newAdded = snap.docChanges().filter(c => c.type === 'added');
      if (newAdded.length > 0 && activeSidebarTab !== 'chat') {
          setUnreadChatCount(prev => prev + newAdded.length);
      }
    });
  }, [firestore, meeting.id, activeSidebarTab]);

  useEffect(() => {
    if (!firestore) return;
    const q = query(collection(firestore, `meetings/${meeting.id}/polls`), where('status', '==', 'active'));
    return onSnapshot(q, (snap) => {
        setActivePollsCount(snap.size);
    });
  }, [firestore, meeting.id]);

  useEffect(() => {
    Object.values(rtc.participants).forEach((p) => {
      const prevReaction = reactionsSeenRef.current[p.id];
      const nextReaction = p.reaction ?? null;
      if (nextReaction && nextReaction !== prevReaction) {
        spawnFlyingEmoji(nextReaction);
      }
      reactionsSeenRef.current[p.id] = nextReaction;
    });
  }, [rtc.participants, spawnFlyingEmoji]);

  useEffect(() => {
    if (!firestore || !isAdmin) return;
    const q = query(collection(firestore, `meetings/${meeting.id}/requests`), where('status', '==', 'pending'));
    return onSnapshot(q, (snap) => setWaitingCount(snap.size));
  }, [firestore, meeting.id, isAdmin]);

  const participantList = Object.values(rtc.participants);
  const totalPeople = participantList.length + 1;

  const tileScrollRef = useRef<HTMLDivElement>(null);
  const [tileScrollState, setTileScrollState] = useState({ left: false, right: false });

  const syncTileScrollArrows = useCallback(() => {
    const el = tileScrollRef.current;
    if (!el) return;
    const { scrollLeft, scrollWidth, clientWidth } = el;
    setTileScrollState({
      left: scrollLeft > 8,
      right: scrollLeft < scrollWidth - clientWidth - 8,
    });
  }, []);

  const scrollTilePage = useCallback(
    (dir: 1 | -1) => {
      const el = tileScrollRef.current;
      if (!el) return;
      el.scrollBy({ left: dir * el.clientWidth, behavior: 'smooth' });
      window.setTimeout(syncTileScrollArrows, 350);
    },
    [syncTileScrollArrows]
  );

  useEffect(() => {
    syncTileScrollArrows();
  }, [totalPeople, viewMode, syncTileScrollArrows]);

  const screenSharingParticipant = useMemo(() => {
    if (rtc.isScreenSharing) return { id: currentUser.id, name: currentUser.name, avatar: currentUser.avatar, avatarThumb: currentUser.avatarThumb, stream: rtc.localStream, isScreenSharing: true };
    return participantList.find(p => p.isScreenSharing);
  }, [rtc.isScreenSharing, rtc.localStream, currentUser, participantList]);

  const effectiveFocusId = useMemo(() => {
    if (screenSharingParticipant) return screenSharingParticipant.id;
    if (manualFocusId && (manualFocusId === currentUser.id || rtc.participants[manualFocusId])) {
      return manualFocusId;
    }
    return activeSpeakerId || currentUser.id;
  }, [screenSharingParticipant, manualFocusId, activeSpeakerId, currentUser.id, rtc.participants]);

  const focusedParticipant = useMemo(() => {
    if (effectiveFocusId === currentUser.id) {
      return { 
        id: currentUser.id, 
        name: currentUser.name, 
        avatar: currentUser.avatar, 
        avatarThumb: currentUser.avatarThumb,
        stream: rtc.localStream, 
        isAudioMuted: rtc.isMicMuted, 
        isVideoMuted: rtc.isVideoOff, 
        isHandRaised: rtc.isHandRaised,
        isScreenSharing: rtc.isScreenSharing,
        backgroundConfig: rtc.backgroundConfig,
        facingMode: rtc.facingMode
      };
    }
    return rtc.participants[effectiveFocusId];
  }, [effectiveFocusId, currentUser, rtc.participants, rtc.localStream, rtc.isMicMuted, rtc.isVideoOff, rtc.isHandRaised, rtc.isScreenSharing, rtc.backgroundConfig, rtc.facingMode]);

  const handleSpeakerChange = useCallback((id: string | null) => {
    if (screenSharingParticipant) return;

    const now = Date.now();
    if (now - lastSpeakerSwitchTime.current < SPEAKER_SWITCH_GRACE_PERIOD) {
        return; 
    }
    
    lastSpeakerSwitchTime.current = now;
    setActiveSpeakerId(id);
  }, [screenSharingParticipant]);

  const gridTilePages = useMemo(() => {
    const tiles: React.ReactNode[] = [
      <ParticipantView
        key={currentUser.id}
        participant={
          {
            id: currentUser.id,
            name: currentUser.name,
            avatar: currentUser.avatar,
            avatarThumb: currentUser.avatarThumb,
            stream: rtc.localStream,
            isAudioMuted: rtc.isMicMuted,
            isVideoMuted: rtc.isVideoOff,
            isHandRaised: rtc.isHandRaised,
            isScreenSharing: rtc.isScreenSharing,
            backgroundConfig: rtc.backgroundConfig,
            facingMode: rtc.facingMode,
          } as any
        }
        isLocal
        isHost={meeting.hostId === currentUser.id}
        layout="grid"
        gridTileSizing="fill"
        onClick={() => {
          setViewMode('speaker');
          setManualFocusId(currentUser.id);
        }}
      />,
      ...participantList.map((p) => (
        <ParticipantView
          key={p.id}
          participant={p}
          isHost={p.id === meeting.hostId}
          layout="grid"
          gridTileSizing="fill"
          onClick={() => {
            setViewMode('speaker');
            setManualFocusId(p.id);
          }}
          onSpeaking={(isSpeaking) => isSpeaking && handleSpeakerChange(p.id)}
        />
      )),
    ];
    return chunkMeetingTiles(tiles, MEETING_TILES_PER_PAGE);
  }, [
    currentUser.id,
    currentUser.name,
    currentUser.avatar,
    currentUser.avatarThumb,
    meeting.hostId,
    participantList,
    rtc.localStream,
    rtc.isMicMuted,
    rtc.isVideoOff,
    rtc.isHandRaised,
    rtc.isScreenSharing,
    rtc.backgroundConfig,
    rtc.facingMode,
    handleSpeakerChange,
  ]);

  useEffect(() => {
    if (viewMode !== 'grid') return;
    const needsPaging = totalPeople > MEETING_TILES_PER_PAGE;
    if (!needsPaging) return;
    const el = tileScrollRef.current;
    if (!el || typeof ResizeObserver === 'undefined') return;
    const ro = new ResizeObserver(() => {
      window.requestAnimationFrame(() => syncTileScrollArrows());
    });
    ro.observe(el);
    window.requestAnimationFrame(() => syncTileScrollArrows());
    return () => ro.disconnect();
  }, [viewMode, totalPeople, syncTileScrollArrows]);

  const formattedStopwatch = useMemo(() => {
    const min = Math.floor(meetingDuration / 60).toString().padStart(2, '0');
    const sec = (meetingDuration % 60).toString().padStart(2, '0');
    return `${min}:${sec}`;
  }, [meetingDuration]);

  const handleStartRecording = async () => {
    try {
        const screenStreamOptions: any = {
            video: { 
              displaySurface: "browser", 
              cursor: "always" 
            },
            audio: { 
              echoCancellation: true, 
              noiseSuppression: true, 
              autoGainControl: true, 
              suppressLocalAudioPlayback: false 
            },
            preferCurrentTab: true,
            selfBrowserSurface: "include",
            systemAudio: "include"
        };
        const screenStream = await navigator.mediaDevices.getDisplayMedia(screenStreamOptions);
        
        const mimeType = MediaRecorder.isTypeSupported('video/webm;codecs=vp9') ? 'video/webm;codecs=vp9' : 'video/webm';
        const recorder = new MediaRecorder(screenStream, { mimeType });
        mediaRecorderRef.current = recorder;
        recordedChunksRef.current = [];
        
        recorder.ondataavailable = (e) => { if (e.data.size > 0) recordedChunksRef.current.push(e.data); };
        
        recorder.onstop = () => {
            const blob = new Blob(recordedChunksRef.current, { type: 'video/webm' });
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a'); 
            a.href = url; 
            a.download = `meeting-record-${meeting.name}-${format(new Date(), 'yyyy-MM-dd-HH-mm')}.webm`; 
            a.click();
            URL.revokeObjectURL(url);
            screenStream.getTracks().forEach(t => t.stop());
            
            if (firestore) {
              updateDoc(doc(firestore, 'meetings', meeting.id), { isRecording: false });
            }
        };

        screenStream.getVideoTracks()[0].onended = () => {
            if (mediaRecorderRef.current?.state === 'recording') {
                mediaRecorderRef.current.stop();
                setIsRecording(false);
            }
        };

        recorder.start(1000);
        setIsRecording(true);
        if (firestore) {
          await updateDoc(doc(firestore, 'meetings', meeting.id), { isRecording: true });
        }
        toast({ title: 'Запись конференции начата' });
    } catch (e) { 
        toast({ variant: 'destructive', title: 'Ошибка записи' }); 
    }
  };

  const handleStopRecording = async () => {
    if (mediaRecorderRef.current && mediaRecorderRef.current.state === 'recording') {
        mediaRecorderRef.current.stop();
    }
    setIsRecording(false);
    if (firestore) {
      await updateDoc(doc(firestore, 'meetings', meeting.id), { isRecording: false });
    }
  };

  const handleSendMessagePlaceholder = (e?: React.FormEvent) => {
      // Logic moved into Sidebar, keeping prop for compatibility
      e?.preventDefault();
  };

  const handleManagement = {
    onForceMuteAudio: (id: string) => updateDoc(doc(firestore!, `meetings/${meeting.id}/participants`, id), { forceMuteAudio: true }),
    onForceMuteVideo: (id: string) => updateDoc(doc(firestore!, `meetings/${meeting.id}/participants`, id), { forceMuteVideo: true }),
    onKick: (id: string) => deleteDoc(doc(firestore!, `meetings/${meeting.id}/participants`, id)),
    onToggleAdmin: (id: string) => {
        const newAdmins = meeting.adminIds?.includes(id) ? meeting.adminIds.filter(a => a !== id) : [...(meeting.adminIds || []), id];
        updateDoc(doc(firestore!, 'meetings', meeting.id), { adminIds: newAdmins });
    }
  };

  const handleToggleTab = (tab: 'participants' | 'polls' | 'chat') => {
      if (activeSidebarTab === tab) {
          setActiveSidebarTab(null);
      } else {
          if (tab === 'chat') setUnreadChatCount(0);
          setActiveSidebarTab(tab);
      }
  };

  return (
    <div className="fixed inset-0 z-[100] flex flex-col bg-[#0a0e17] text-white overflow-hidden font-body select-none">
      <MeetingRoomHeader 
        meetingName={meeting.name} isRecording={!!meeting.isRecording} participantCount={totalPeople}
        onExit={() => { rtc.stopAllMedia(); router.push('/dashboard/meetings'); }} 
        backgroundConfig={rtc.backgroundConfig} onBackgroundChange={rtc.setBackgroundConfig}
        standardBackgrounds={standardBackgrounds} isVideoOff={rtc.isVideoOff}
        isHost={isAdmin} onStartRecording={handleStartRecording} onStopRecording={handleStopRecording}
        duration={formattedStopwatch} viewMode={viewMode} onToggleViewMode={() => { setViewMode(viewMode === 'speaker' ? 'grid' : 'speaker'); setManualFocusId(null); }}
        onCopyLink={() => {
          const origin = typeof window !== 'undefined' ? window.location.origin : '';
          const url = `${origin}/meetings/${meeting.id}`;
          void navigator.clipboard.writeText(url);
          toast({ title: 'Ссылка скопирована' });
        }}
      />

      <div className="flex-1 flex relative min-h-0 overflow-hidden">
        <div className={cn("flex-1 flex flex-col min-h-0 transition-all duration-300 w-full")}>
            {viewMode === 'speaker' && (
                <div className="h-28 sm:h-36 bg-black/40 border-b border-white/5 flex gap-2 p-2 overflow-x-auto no-scrollbar shrink-0">
                    <ParticipantView 
                        participant={{ id: currentUser.id, name: currentUser.name, avatar: currentUser.avatar, avatarThumb: currentUser.avatarThumb, stream: rtc.localStream, isAudioMuted: rtc.isMicMuted, isVideoMuted: rtc.isVideoOff, isHandRaised: rtc.isHandRaised, isScreenSharing: rtc.isScreenSharing, backgroundConfig: rtc.backgroundConfig, facingMode: rtc.facingMode } as any}
                        isLocal={true} isCompact={true} isHost={meeting.hostId === currentUser.id}
                        className={cn("w-44 sm:w-56 shrink-0", effectiveFocusId === currentUser.id && "ring-2 ring-primary")}
                        onClick={() => setManualFocusId(currentUser.id)}
                    />
                    {participantList.map(p => (
                        <ParticipantView 
                            key={p.id} participant={p} isCompact={true} isHost={p.id === meeting.hostId} 
                            className={cn("w-44 sm:w-56 shrink-0", effectiveFocusId === p.id && "ring-2 ring-primary")}
                            onClick={() => setManualFocusId(p.id)}
                            onSpeaking={(isSpeaking) => isSpeaking && handleSpeakerChange(p.id)}
                        />
                    ))}
                </div>
            )}

            <main className="flex-1 p-4 flex items-center justify-center bg-slate-950 relative overflow-hidden">
                {viewMode === 'speaker' && focusedParticipant ? (
                    <div className="w-full h-full flex items-center justify-center animate-in zoom-in-95 duration-500 px-2">
                        <ParticipantView 
                            participant={focusedParticipant as any} 
                            isLocal={focusedParticipant.id === currentUser.id} 
                            isHost={focusedParticipant.id === meeting.hostId} 
                            layout="stage"
                            className="max-w-6xl w-full shadow-2xl"
                        />
                    </div>
                ) : (
                    <div className="relative h-full w-full min-h-0">
                      <div
                        ref={tileScrollRef}
                        onScroll={syncTileScrollArrows}
                        className={cn(
                          'flex h-full w-full min-h-0 overflow-x-auto overflow-y-hidden scroll-smooth',
                          gridTilePages.length > 1 && 'snap-x snap-mandatory',
                          /** Скрыть горизонтальный скроллбар — листание через стрелки при >9 участников */
                          '[scrollbar-width:none] [-ms-overflow-style:none] [&::-webkit-scrollbar]:hidden'
                        )}
                      >
                        {gridTilePages.map((pageTiles, pageIdx) => (
                          <div
                            key={pageIdx}
                            className={cn(
                              'h-full w-full min-h-0 shrink-0 basis-full',
                              gridTilePages.length > 1 && 'snap-center snap-always'
                            )}
                          >
                            <MeetingParticipantTileStage tiles={pageTiles} />
                          </div>
                        ))}
                      </div>
                      {gridTilePages.length > 1 && (
                        <>
                          {tileScrollState.left ? (
                            <Button
                              type="button"
                              variant="secondary"
                              size="icon"
                              className="absolute left-2 top-1/2 z-20 h-11 w-11 -translate-y-1/2 rounded-full border border-white/15 bg-black/55 text-white shadow-lg backdrop-blur-md hover:bg-black/70"
                              aria-label="Предыдущая страница участников"
                              onClick={() => scrollTilePage(-1)}
                            >
                              <ChevronLeft className="h-6 w-6" />
                            </Button>
                          ) : null}
                          {tileScrollState.right ? (
                            <Button
                              type="button"
                              variant="secondary"
                              size="icon"
                              className="absolute right-2 top-1/2 z-20 h-11 w-11 -translate-y-1/2 rounded-full border border-white/15 bg-black/55 text-white shadow-lg backdrop-blur-md hover:bg-black/70"
                              aria-label="Следующие участники"
                              onClick={() => scrollTilePage(1)}
                            >
                              <ChevronRight className="h-6 w-6" />
                            </Button>
                          ) : null}
                        </>
                      )}
                    </div>
                )}
                
                <MeetingControls 
                    isMicMuted={rtc.isMicMuted} isVideoOff={rtc.isVideoOff} isScreenSharing={rtc.isScreenSharing} isHandRaised={rtc.isHandRaised} isRecording={isRecording} isHost={isAdmin} unreadChatCount={unreadChatCount} activePollsCount={activePollsCount} waitingCount={waitingCount} activeTab={activeSidebarTab} isDisplayMediaSupported={!!navigator.mediaDevices?.getDisplayMedia}
                    onToggleMic={rtc.toggleMic} onToggleVideo={rtc.toggleVideo} onToggleHand={rtc.toggleHand} onToggleScreenShare={rtc.toggleScreenShare} 
                    onToggleChat={() => handleToggleTab('chat')} 
                    onToggleParticipants={() => handleToggleTab('participants')}
                    onTogglePolls={() => handleToggleTab('polls')}
                    onSendReaction={(emoji) => { 
                        updateDoc(doc(firestore!, `meetings/${meeting.id}/participants`, currentUser.id), { reaction: emoji });
                        setTimeout(() => updateDoc(doc(firestore!, `meetings/${meeting.id}/participants`, currentUser.id), { reaction: null }), 3000);
                    }} onSwitchCamera={rtc.switchCamera}
                    screenShareDisabled={participantList.some(p => p.isScreenSharing) && !rtc.isScreenSharing}
                />
            </main>
        </div>

        <MeetingSidebar 
          activeTab={activeSidebarTab} onActiveTabChange={setActiveSidebarTab} onClose={() => setActiveSidebarTab(null)} currentUser={currentUser as any} chatMessages={chatMessages} newMessageText={newMessageText} setNewMessageText={setNewMessageText} onSendMessage={handleSendMessagePlaceholder} participants={participantList} isHost={isAdmin} hostId={meeting.hostId} adminIds={meeting.adminIds || []} chatEndRef={chatEndRef} {...handleManagement}
          pollsNode={activeSidebarTab === 'polls' ? <MeetingPolls meetingId={meeting.id} currentUser={currentUser as any} participantsCount={totalPeople} allParticipants={[currentUser, ...participantList] as any} isHost={isAdmin} /> : null}
          requestsNode={isAdmin && activeSidebarTab === 'participants' ? <MeetingRequests meetingId={meeting.id} /> : null}
          meetingId={meeting.id}
        />
      </div>

      <div className="fixed inset-0 pointer-events-none z-[100] overflow-hidden">
        {flyingEmojis.map(item => (
          <div key={item.id} className="absolute bottom-[calc(5rem+env(safe-area-inset-bottom,0px))] text-6xl animate-reaction-float select-none will-change-transform" style={{ left: `${item.left}%` }}>{item.emoji}</div>
        ))}
      </div>
    </div>
  );
}

function MeetingRequests({ meetingId }: { meetingId: string }) {
    const firestore = useFirestore();
    const [requests, setRequests] = useState<any[]>([]);
    const { toast } = useToast();

    useEffect(() => {
        if (!firestore) return;
        return onSnapshot(query(collection(firestore, `meetings/${meetingId}/requests`), where('status', '==', 'pending')), (snap) => {
            setRequests(snap.docs.map(d => ({ id: d.id, ...d.data() })));
        });
    }, [firestore, meetingId]);

    const respond = async (uid: string, approve: boolean) => {
        try { 
            await updateDoc(doc(firestore!, `meetings/${meetingId}/requests`, uid), { status: approve ? 'approved' : 'denied' }); 
            toast({ title: approve ? 'Доступ разрешен' : 'Вход отклонен' });
        } catch (e) { 
            toast({ variant: 'destructive', title: 'Ошибка' }); 
        }
    };

    if (requests.length === 0) return null;

    return (
        <div className="p-4 space-y-3 bg-white/5 border-b border-white/10 mb-4 animate-in slide-in-from-top-2 duration-500">
            <h4 className="text-[10px] font-bold uppercase tracking-widest text-primary flex items-center gap-2">
                <span className="relative flex h-2 w-2">
                    <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-primary opacity-75"></span>
                    <span className="relative inline-flex rounded-full h-2 w-2 bg-primary"></span>
                </span>
                Зал ожидания ({requests.length})
            </h4>
            <div className="space-y-2">
                {requests.map(req => (
                    <div key={req.userId} className="flex flex-col gap-3 p-3 bg-black/40 rounded-2xl border border-white/5">
                        <div className="flex items-center gap-3 min-w-0">
                            <Avatar className="h-9 w-9 shrink-0 border-2 border-white/5 shadow-md">
                                <AvatarImage src={userAvatarListUrl({ avatar: req.avatar, avatarThumb: req.avatarThumb })} className="object-cover" />
                                <AvatarFallback className="bg-slate-800 text-slate-400 font-bold">{req.name[0]}</AvatarFallback>
                            </Avatar>
                            <span className="text-sm font-bold truncate leading-tight">{req.name}</span>
                        </div>
                        <div className="grid grid-cols-2 gap-2">
                            <Button 
                                size="sm" 
                                variant="ghost" 
                                className="h-9 rounded-xl bg-green-500/20 text-green-500 hover:bg-green-500 hover:text-white border-none shadow-none font-bold text-xs" 
                                onClick={() => respond(req.userId, true)}
                            >
                                <Check className="h-4 w-4 mr-1.5" /> Принять
                            </Button>
                            <Button 
                                size="sm" 
                                variant="ghost" 
                                className="h-9 rounded-xl bg-red-500/20 text-red-500 hover:bg-red-500 hover:text-white border-none shadow-none font-bold text-xs" 
                                onClick={() => respond(req.userId, false)}
                            >
                                <XCircle className="h-4 w-4 mr-1.5" /> Отказать
                            </Button>
                        </div>
                    </div>
                ))}
            </div>
        </div>
    );
}
