'use client';

import React, { useEffect, useState, useRef } from 'react';
import { useParams } from 'next/navigation';
import type { Meeting, User } from '@/lib/types';
import { useAuth } from '@/hooks/use-auth';
import { useDoc, useFirestore, useMemoFirebase } from '@/firebase';
import { doc } from 'firebase/firestore';
import { Icons } from '@/components/icons';
import { JoinMeeting } from '@/components/meetings/JoinMeeting';
import { MeetingRoom } from '@/components/meetings/MeetingRoom';

export default function MeetingPage() {
  const params = useParams();
  const meetingId = typeof params.meetingId === 'string' ? params.meetingId : '';
  const firestore = useFirestore();
  const { user, isLoading: isAuthLoading } = useAuth();
  
  const [isJoined, setIsJoined] = useState(false);
  const [joinSettings, setJoinSettings] = useState({
    micMuted: false,
    videoOff: false,
    name: '',
    stream: null as MediaStream | null
  });

  const meetingRef = useMemoFirebase(() => (firestore && meetingId ? doc(firestore, 'meetings', meetingId) : null), [firestore, meetingId]);
  const { data: meeting, isLoading: isLoadingMeeting } = useDoc<Meeting>(meetingRef);

  if (isAuthLoading || isLoadingMeeting) {
    return (
      <div className="h-screen w-full flex items-center justify-center bg-background text-white">
        <Icons.spinner className="h-8 w-8 animate-spin text-primary" />
      </div>
    );
  }

  if (!meeting) {
    return (
      <div className="h-screen w-full flex flex-col items-center justify-center bg-background p-4 text-center text-white">
        <h1 className="text-2xl font-bold mb-2">Встреча не найдена</h1>
        <p className="text-muted-foreground">Возможно, ссылка неверна или встреча уже завершена.</p>
      </div>
    );
  }

  const handleJoin = (settings: { micMuted: boolean; videoOff: boolean; name: string; stream: MediaStream | null }) => {
    setJoinSettings(settings);
    setIsJoined(true);
  };

  if (!isJoined) {
    return <JoinMeeting meeting={meeting} currentUser={user} onJoin={handleJoin} />;
  }

  return (
    <MeetingRoom 
      meeting={meeting} 
      currentUser={user!} 
      initialMicMuted={joinSettings.micMuted}
      initialVideoOff={joinSettings.videoOff}
      initialName={joinSettings.name}
      initialStream={joinSettings.stream}
    />
  );
}
