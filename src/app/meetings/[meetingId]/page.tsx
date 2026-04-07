'use client';

import React, { useState, useEffect, useRef, useCallback, useMemo } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useAuth } from '@/hooks/use-auth';
import { useDoc, useFirestore, useMemoFirebase, useFirebaseApp } from '@/firebase';
import { doc, onSnapshot, deleteDoc, updateDoc } from 'firebase/firestore';
import { getFunctions, httpsCallable } from 'firebase/functions';
import type { Meeting, MeetingJoinRequest } from '@/lib/types';
import { Icons } from '@/components/icons';
import { JoinMeeting } from '@/components/meetings/JoinMeeting';
import { MeetingRoom } from '@/components/meetings/MeetingRoom';
import { Button } from '@/components/ui/button';
import { Card, CardTitle, CardDescription } from '@/components/ui/card';
import { ShieldAlert, Clock, ArrowLeft, Loader2 } from 'lucide-react';
import { signInAnonymously, updateProfile } from 'firebase/auth';
import { useToast } from '@/hooks/use-toast';

export default function MeetingPage() {
  const params = useParams();
  const meetingId = typeof params.meetingId === 'string' ? params.meetingId : '';
  const { user, isLoading: isAuthLoading } = useAuth();
  const firestore = useFirestore();
  const firebaseApp = useFirebaseApp();
  const router = useRouter();
  const { toast } = useToast();
  
  const [isJoined, setIsJoined] = useState(false);
  const [joinSettings, setJoinSettings] = useState({
    micMuted: false,
    videoOff: false,
    name: '',
    stream: null as MediaStream | null
  });

  const [requestStatus, setRequestStatus] = useState<'none' | 'pending' | 'approved' | 'denied'>('none');
  const [currentRequestId, setCurrentRequestId] = useState<string | null>(null);
  const [isCancelling, setIsCancelling] = useState(false);

  const meetingRef = useMemoFirebase(() => (firestore && meetingId ? doc(firestore, 'meetings', meetingId) : null), [firestore, meetingId]);
  const { data: meeting, isLoading: isLoadingMeeting } = useDoc<Meeting>(meetingRef);

  const isHostOrAdmin = useMemo(() => {
    if (!meeting || !user) return false;
    return meeting.hostId === user.id || meeting.adminIds?.includes(user.id);
  }, [meeting, user]);

  // Handle Heartbeat for pending requests
  useEffect(() => {
    if (requestStatus !== 'pending' || !user?.id || !firestore || isJoined) return;

    const heartbeat = setInterval(() => {
        const requestRef = doc(firestore, `meetings/${meetingId}/requests`, user.id);
        updateDoc(requestRef, { lastSeen: new Date().toISOString() }).catch(() => {});
    }, 20000);

    return () => clearInterval(heartbeat);
  }, [requestStatus, user?.id, firestore, meetingId, isJoined]);

  useEffect(() => {
    if (!meeting?.isPrivate || isHostOrAdmin || !user?.id || requestStatus === 'none' || !firestore || isJoined) return;

    const requestRef = doc(firestore, `meetings/${meeting.id}/requests`, user.id);
    const unsub = onSnapshot(requestRef, (snap) => {
        if (snap.exists()) {
            const data = snap.data() as MeetingJoinRequest;
            
            if (data.requestId !== currentRequestId) {
                return;
            }

            setRequestStatus(data.status);
            if (data.status === 'approved') {
                toast({ title: 'Вход одобрен' });
                setIsJoined(true);
            }
        } else if (requestStatus === 'pending') {
            setRequestStatus('denied');
        }
    });
    return () => unsub();
  }, [meeting, isHostOrAdmin, user?.id, requestStatus, firestore, toast, isJoined, currentRequestId]);

  const handleJoinAttempt = async (settings: { micMuted: boolean; videoOff: boolean; name: string; stream: MediaStream | null }) => {
    if (!meeting) return;
    
    if (!meeting.isPrivate || isHostOrAdmin) { 
        setJoinSettings(settings); 
        setIsJoined(true); 
        return; 
    }

    try {
      let targetUserId = user?.id;
      if (!user && firebaseApp) {
        const { getAuth } = await import('firebase/auth');
        const auth = getAuth(firebaseApp);
        const userCred = await signInAnonymously(auth);
        await updateProfile(userCred.user, { displayName: settings.name });
        targetUserId = userCred.user.uid;
      }

      if (!firebaseApp || !targetUserId) return;
      const functions = getFunctions(firebaseApp, 'us-central1');
      const requestMeetingAccess = httpsCallable(functions, 'requestMeetingAccess');
      
      const rid = Date.now().toString();
      setCurrentRequestId(rid);
      setJoinSettings(settings);
      
      await requestMeetingAccess({ 
        meetingId: meeting.id, 
        name: settings.name, 
        avatar: `https://api.dicebear.com/7.x/avataaars/svg?seed=${targetUserId}`,
        requestId: rid
      });
      
      setRequestStatus('pending');
    } catch (e: any) {
      toast({ variant: 'destructive', title: 'Ошибка доступа', description: e.message });
    }
  };

  const handleCancelRequest = async () => {
    if (!firestore || !user?.id || isCancelling) return;
    setIsCancelling(true);
    try {
        const requestRef = doc(firestore, `meetings/${meetingId}/requests`, user.id);
        await deleteDoc(requestRef);
        router.push('/dashboard/meetings');
    } catch (e) {
        router.push('/dashboard/meetings');
    }
  };

  if (isAuthLoading || isLoadingMeeting) {
    return (
      <div className="h-screen w-full flex items-center justify-center bg-[#0a0e17]">
        <Icons.spinner className="h-8 w-8 animate-spin text-primary" />
      </div>
    );
  }

  if (!meeting) {
    return (
      <div className="h-screen w-full flex flex-col items-center justify-center bg-[#0a0e17] p-4 text-center text-white">
        <h1 className="text-2xl font-bold mb-2">Встреча не найдена</h1>
        <Button variant="ghost" onClick={() => router.push('/dashboard/meetings')} className="mt-6 text-white/50"><ArrowLeft className="mr-2 h-4 w-4" /> Назад</Button>
      </div>
    );
  }

  if (requestStatus === 'pending' && !isJoined) {
      return (
          <div className="h-screen w-full flex items-center justify-center bg-[#0a0e17] p-4 text-white">
              <Card className="max-w-md w-full rounded-3xl bg-slate-900 border-none text-center p-8 border border-white/5 shadow-2xl">
                  <Clock className="h-12 w-12 mx-auto text-primary animate-pulse mb-6" />
                  <CardTitle className="text-2xl mb-4 text-white">Зал ожидания</CardTitle>
                  <CardDescription className="text-slate-400">Пожалуйста, подождите одобрения входа организатором.</CardDescription>
                  <Button variant="ghost" onClick={handleCancelRequest} disabled={isCancelling} className="mt-8 text-white/50 hover:text-white">
                      {isCancelling ? <Loader2 className="mr-2 h-4 w-4 animate-spin"/> : <ArrowLeft className="mr-2 h-4 w-4" />} Назад к списку встреч
                  </Button>
              </Card>
          </div>
      )
  }

  if (requestStatus === 'denied') {
      return (
          <div className="h-screen w-full flex items-center justify-center bg-[#0a0e17] p-4 text-white">
              <Card className="max-w-md w-full rounded-3xl bg-slate-900 border-none text-center p-8 border border-white/5 shadow-2xl">
                  <ShieldAlert className="h-12 w-12 mx-auto text-red-500 mb-6" />
                  <CardTitle className="text-2xl mb-6 text-white">Вход отклонен</CardTitle>
                  <Button onClick={() => router.push('/dashboard/meetings')} className="w-full rounded-full">Вернуться назад</Button>
              </Card>
          </div>
      )
  }

  return isJoined && user ? (
    <MeetingRoom 
      meeting={meeting} currentUser={user} initialMicMuted={joinSettings.micMuted}
      initialVideoOff={joinSettings.videoOff} initialName={joinSettings.name} initialStream={joinSettings.stream}
    />
  ) : isJoined && !user ? (
    <div className="h-screen w-full flex items-center justify-center bg-[#0a0e17]">
      <div className="flex flex-col items-center gap-4">
        <Icons.spinner className="h-8 w-8 animate-spin text-primary" />
        <p className="text-sm font-bold uppercase tracking-widest text-white/40">Авторизация...</p>
      </div>
    </div>
  ) : (
    <JoinMeeting meeting={meeting} currentUser={user} onJoin={handleJoinAttempt} />
  );
}