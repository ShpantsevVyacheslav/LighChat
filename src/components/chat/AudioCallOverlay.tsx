
'use client';

import React, { useState, useEffect, useRef, useCallback } from 'react';
import { useFirestore, useStorage, useMemoFirebase } from '@/firebase';
import {
  doc,
  onSnapshot,
  collection,
  addDoc,
  query,
  where,
  or,
  and,
  serverTimestamp,
  setDoc,
  updateDoc,
  type Firestore,
  type QuerySnapshot,
  type DocumentData,
} from 'firebase/firestore';
import { ref as storageRef, getDownloadURL } from 'firebase/storage';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { userAvatarListUrl } from '@/lib/user-avatar-display';
import { Button } from '@/components/ui/button';
import { Separator } from '@/components/ui/separator';
import { Phone, PhoneOff, Mic, MicOff, Loader2, Minimize2, Video, VideoOff, Maximize2, MonitorUp, MonitorOff, SwitchCamera } from 'lucide-react';
import type { User, Call } from '@/lib/types';
import { isEitherBlockingFromUserIds } from '@/lib/user-block-utils';
import { cn } from '@/lib/utils';
import { useToast } from '@/hooks/use-toast';
import { getWebRtcIceConfig } from '@/lib/webrtc-ice-servers';
import { logger } from '@/lib/logger';
import { useI18n } from '@/hooks/use-i18n';
import { getRingtonePreset, ringtoneUrl as ringtonePresetUrl } from '@/lib/ringtone-presets';

interface AudioCallOverlayProps {
  currentUser: User;
}

/** Firestore отдаёт { type, sdp }; проверяем перед RTCSessionDescription. */
function normalizeRtcDesc(raw: unknown): RTCSessionDescriptionInit | null {
  if (!raw || typeof raw !== 'object') return null;
  const o = raw as Record<string, unknown>;
  const type = o.type;
  const sdp = o.sdp;
  if (type !== 'offer' && type !== 'answer' && type !== 'pranswer') return null;
  if (typeof sdp !== 'string' || !sdp.trim()) return null;
  return { type, sdp };
}

/** Нельзя брать docs[0] — порядок не определён; приоритет входящего «звонит». */
function pickCallFromSnapshot(snapshot: QuerySnapshot<DocumentData>, uid: string): Call | null {
  if (snapshot.empty) return null;
  const calls: Call[] = snapshot.docs.map((d) => ({ id: d.id, ...(d.data() as Omit<Call, 'id'>) }));
  const byRecency = (a: Call, b: Call) => (b.createdAt || '').localeCompare(a.createdAt || '');
  const incoming = calls.filter((c) => c.receiverId === uid && c.status === 'calling').sort(byRecency);
  if (incoming.length) return incoming[0]!;
  const outgoing = calls
    .filter((c) => c.callerId === uid && (c.status === 'calling' || c.status === 'ongoing'))
    .sort(byRecency);
  if (outgoing.length) return outgoing[0]!;
  return [...calls].sort(byRecency)[0]!;
}

export function AudioCallOverlay({ currentUser }: AudioCallOverlayProps) {
  // Call State
  const [activeCall, setActiveCall] = useState<Call | null>(null);
  const [otherUser, setOtherUser] = useState<{
    name: string;
    avatar: string;
    avatarThumb?: string;
  } | null>(null);
  const [localStream, setLocalStream] = useState<MediaStream | null>(null);
  const [remoteStream, setRemoteStream] = useState<MediaStream | null>(null);
  
  // UI State
  const [isMicMuted, setIsMicMuted] = useState(false);
  const [isVideoOff, setIsVideoOff] = useState(false);
  const [isConnecting, setIsConnecting] = useState(false);
  const [isMinimized, setIsMinimized] = useState(false);
  const [showLocalPreview, setShowLocalPreview] = useState(true);
  const [callDuration, setCallDuration] = useState(0);
  const [storageUrls, setStorageUrls] = useState<{ ringtone: string | null, ringback: string | null }>({ ringtone: null, ringback: null });
  
  // Drag and Resize State
  const [previewPos, setPreviewPos] = useState({ bottom: 100, right: 20 });
  const [previewScale, setPreviewScale] = useState(1);
  const [isDragging, setIsDragging] = useState(false);
  const [isResizing, setIsResizing] = useState(false);
  
  const dragStartPos = useRef({ x: 0, y: 0 });
  const initialPreviewPos = useRef({ bottom: 0, right: 0 });
  const initialScale = useRef(1);

  // Feature State
  const [isScreenSharing, setIsScreenSharing] = useState(false);
  const [facingMode, setFacingMode] = useState<'user' | 'environment'>('user');

  // WebRTC Refs
  const peerConnection = useRef<RTCPeerConnection | null>(null);
  const remoteVideoRef = useRef<HTMLVideoElement>(null);
  const remoteAudioRef = useRef<HTMLAudioElement>(null);
  const localVideoRef = useRef<HTMLVideoElement>(null);
  
  // Audio Playback Refs
  const ringtoneAudioRef = useRef<HTMLAudioElement>(null);
  const ringbackAudioRef = useRef<HTMLAudioElement>(null);
  
  const timerRef = useRef<NodeJS.Timeout | null>(null);
  const screenStreamRef = useRef<MediaStream | null>(null);
  
  // Signaling Control Refs
  const mediaRequestInProgress = useRef(false);
  const isSettingUp = useRef(false);
  const isHandlingAnswer = useRef(false);
  const iceCandidatesQueue = useRef<unknown[]>([]);
  const candidatesUnsubscribeRef = useRef<(() => void) | null>(null);
  const processedCandidateIds = useRef<Set<string>>(new Set());
  const activeCallRef = useRef<Call | null>(null);

  const { t } = useI18n();
  const firestore = useFirestore();
  const storage = useStorage();
  const { toast } = useToast();

  useEffect(() => {
    activeCallRef.current = activeCall;
  }, [activeCall]);

  const isDisplayMediaSupported = !!(typeof navigator !== 'undefined' && navigator.mediaDevices && navigator.mediaDevices.getDisplayMedia);

  const handleDragStart = (e: React.MouseEvent | React.TouchEvent) => {
    const clientX = 'touches' in e ? e.touches[0].clientX : e.clientX;
    const clientY = 'touches' in e ? e.touches[0].clientY : e.clientY;
    
    // Check if clicked near top-left corner for resizing
    const rect = (e.currentTarget as HTMLElement).getBoundingClientRect();
    const isNearTopLeft = (clientX - rect.left < 40) && (clientY - rect.top < 40);

    if (isNearTopLeft) {
      setIsResizing(true);
    } else {
      setIsDragging(true);
    }

    dragStartPos.current = { x: clientX, y: clientY };
    initialPreviewPos.current = { ...previewPos };
    initialScale.current = previewScale;
  };

  const handleMouseMove = useCallback((e: MouseEvent | TouchEvent) => {
    const clientX = 'touches' in e ? e.touches[0].clientX : e.clientX;
    const clientY = 'touches' in e ? e.touches[0].clientY : e.clientY;
    
    if (isDragging) {
      const deltaX = dragStartPos.current.x - clientX;
      const deltaY = dragStartPos.current.y - clientY;
      
      setPreviewPos({
        bottom: Math.max(20, initialPreviewPos.current.bottom + deltaY),
        right: Math.max(20, initialPreviewPos.current.right + deltaX),
      });
    } else if (isResizing) {
      // Resize logic: moving cursor TOP-LEFT (smaller X and Y) increases scale
      // because anchor is BOTTOM-RIGHT.
      const deltaX = dragStartPos.current.x - clientX;
      const deltaY = dragStartPos.current.y - clientY;
      // We use average delta for smooth scaling
      const delta = (deltaX + deltaY) / 250; 
      setPreviewScale(Math.max(0.5, Math.min(2.5, initialScale.current + delta)));
    }
  }, [isDragging, isResizing, previewPos, previewScale]);

  const handleMouseUp = useCallback(() => {
    setIsDragging(false);
    setIsResizing(false);
  }, []);

  useEffect(() => {
    if (isDragging || isResizing) {
      window.addEventListener('mousemove', handleMouseMove);
      window.addEventListener('mouseup', handleMouseUp);
      window.addEventListener('touchmove', handleMouseMove);
      window.addEventListener('touchend', handleMouseUp);
    }
    return () => {
      window.removeEventListener('mousemove', handleMouseMove);
      window.removeEventListener('mouseup', handleMouseUp);
      window.removeEventListener('touchmove', handleMouseMove);
      window.removeEventListener('touchend', handleMouseUp);
    };
  }, [isDragging, isResizing, handleMouseMove, handleMouseUp]);

  // --- 1. INITIALIZATION: FETCH RINGTONES ---
  const callRingtoneId = currentUser.notificationSettings?.callRingtoneId ?? null;
  useEffect(() => {
    if (!storage) return;
    const presetForRingtone = getRingtonePreset(callRingtoneId);
    const fetchAudio = async () => {
        try {
            const ringtone = presetForRingtone
              ? ringtonePresetUrl(presetForRingtone, 'calls')
              : await getDownloadURL(storageRef(storage, 'audio/ringtone.mp3'));
            const ringbackUrl = await getDownloadURL(storageRef(storage, 'audio/ringback.mp3'));
            setStorageUrls({ ringtone, ringback: ringbackUrl });
        } catch {
            logger.warn('webrtc', 'Audio files not found in Storage (audio/ringtone.mp3, audio/ringback.mp3). Upload them to enable call sounds.');
            setStorageUrls({ ringtone: null, ringback: null });
        }
    };
    fetchAudio();
  }, [storage, callRingtoneId]);

  // --- 2. CLEANUP LOGIC ---
  const handleCleanup = useCallback(() => {
    logger.debug('webrtc-call', 'cleanup');
    if (candidatesUnsubscribeRef.current) {
      candidatesUnsubscribeRef.current();
      candidatesUnsubscribeRef.current = null;
    }

    if (localStream) {
      localStream.getTracks().forEach(track => track.stop());
      setLocalStream(null);
    }

    if (screenStreamRef.current) {
      screenStreamRef.current.getTracks().forEach(track => track.stop());
      screenStreamRef.current = null;
    }
    
    if (peerConnection.current) {
      peerConnection.current.close();
      peerConnection.current = null;
    }
    
    if (ringtoneAudioRef.current) ringtoneAudioRef.current.pause();
    if (ringbackAudioRef.current) ringbackAudioRef.current.pause();
    
    if (timerRef.current) {
        clearInterval(timerRef.current);
        timerRef.current = null;
    }
    
    setRemoteStream(null);
    setActiveCall(null);
    setOtherUser(null);
    setIsConnecting(false);
    setIsMinimized(false);
    setShowLocalPreview(true);
    setCallDuration(0);
    setIsVideoOff(false);
    setIsScreenSharing(false);
    setFacingMode('user');
    setPreviewScale(1);
    setPreviewPos({ bottom: 100, right: 20 });
    
    iceCandidatesQueue.current = [];
    isHandlingAnswer.current = false;
    isSettingUp.current = false;
    mediaRequestInProgress.current = false;
    processedCandidateIds.current.clear();
  }, [localStream]);

  const cleanupRef = useRef(handleCleanup);
  useEffect(() => {
    cleanupRef.current = handleCleanup;
  }, [handleCleanup]);

  // --- 3. PEER CONNECTION & MEDIA ---
  const setupPeerConnection = useCallback(async (callId: string, isVideoCall: boolean) => {
    logger.debug('webrtc-call', 'setupPC', { callId, isVideoCall });
    const pc = new RTCPeerConnection(await getWebRtcIceConfig());
    peerConnection.current = pc;

    try {
        if (!localStream) {
            if (mediaRequestInProgress.current) {
              mediaRequestInProgress.current = false;
            }
            mediaRequestInProgress.current = true;
            logger.debug('webrtc-call', 'requesting local media');
            const stream = await navigator.mediaDevices.getUserMedia({
                audio: true,
                video: isVideoCall ? { facingMode: 'user' } : false,
            });
            setLocalStream(stream);
            setIsVideoOff(!isVideoCall);
            stream.getTracks().forEach((track) => pc.addTrack(track, stream));
            mediaRequestInProgress.current = false;
        } else {
            localStream.getTracks().forEach((track) => pc.addTrack(track, localStream));
        }
    } catch (e) {
        logger.error('webrtc', 'Media capture failed', e);
        mediaRequestInProgress.current = false;
        toast({ variant: 'destructive', title: t('chat.audioCall.accessErrorTitle'), description: t('chat.audioCall.accessErrorDesc') });
        throw e;
    }

    pc.ontrack = (event) => {
      logger.debug('webrtc-call', 'remote track received', { kind: event.track.kind });
      if (event.streams && event.streams[0]) {
        setRemoteStream(event.streams[0]);
      }
    };

    pc.onicecandidate = (event) => {
      if (event.candidate && firestore) {
        const candidateCollection = collection(firestore, `calls/${callId}/candidates`);
        addDoc(candidateCollection, { 
          ...event.candidate.toJSON(), 
          userId: currentUser.id, 
          createdAt: serverTimestamp() 
        });
      }
    };

    const candidateCollection = collection(firestore, `calls/${callId}/candidates`);
    candidatesUnsubscribeRef.current = onSnapshot(candidateCollection, (snapshot) => {
      snapshot.docChanges().forEach((change) => {
        if (change.type === 'added') {
          const data = change.doc.data();
          if (data.userId !== currentUser.id && !processedCandidateIds.current.has(change.doc.id)) {
            processedCandidateIds.current.add(change.doc.id);
            if (pc.remoteDescription && pc.remoteDescription.type) {
                pc.addIceCandidate(new RTCIceCandidate(data)).catch(() => {});
            } else {
                iceCandidatesQueue.current.push(data);
            }
          }
        }
      });
    });

    return pc;
  }, [firestore, currentUser.id, toast, localStream]);

  // --- 4. SIGNALING: CALLER & RECEIVER ---
  useEffect(() => {
    if (!firestore || !currentUser) return;
    const callsQuery = query(
      collection(firestore, 'calls'),
      and(
        or(where('receiverId', '==', currentUser.id), where('callerId', '==', currentUser.id)),
        where('status', 'in', ['calling', 'ongoing']),
      ),
    );

    const unsubscribe = onSnapshot(
      callsQuery,
      (snapshot) => {
        if (snapshot.empty) {
          if (activeCallRef.current) cleanupRef.current();
          return;
        }
        const picked = pickCallFromSnapshot(snapshot, currentUser.id);
        if (picked) setActiveCall(picked);
      },
      (err) => {
        logger.error('audio-call', 'calls subscription error', err);
        toast({
          variant: 'destructive',
          title: t('chat.audioCall.callsTitle'),
          description: t('chat.audioCall.callsSubscriptionDesc'),
        });
      },
    );

    return () => unsubscribe();
  }, [firestore, currentUser.id, toast]);

  useEffect(() => {
    if (activeCall && activeCall.callerId === currentUser.id && activeCall.status === 'calling' && !activeCall.offer && !isSettingUp.current) {
      isSettingUp.current = true;
      const startCaller = async () => {
        setIsConnecting(true);
        try {
          const pc = await setupPeerConnection(activeCall.id, activeCall.isVideo);
          const offer = await pc.createOffer();
          await pc.setLocalDescription(offer);
          await updateDoc(doc(firestore!, 'calls', activeCall.id), {
            offer: { type: offer.type, sdp: offer.sdp },
          });
        } catch (e) {
          logger.error('webrtc', 'Caller setup error', e);
          isSettingUp.current = false;
          toast({
            variant: 'destructive',
            title: t('chat.audioCall.callTitle'),
            description: t('chat.audioCall.callInviteError'),
          });
        } finally {
          setIsConnecting(false);
        }
      };
      startCaller();
    }
  }, [activeCall, currentUser.id, setupPeerConnection, firestore]);

  const acceptCall = async () => {
    if (!activeCall || isConnecting) return;
    const offerInit = normalizeRtcDesc(activeCall.offer);
    if (!offerInit) {
      toast({
        variant: 'destructive',
        title: t('chat.audioCall.callNotReadyTitle'),
        description: t('chat.audioCall.callNotReadyDesc'),
      });
      return;
    }
    setIsConnecting(true);
    try {
      const pc = await setupPeerConnection(activeCall.id, activeCall.isVideo);
      await pc.setRemoteDescription(new RTCSessionDescription(offerInit));

      while (iceCandidatesQueue.current.length > 0) {
        pc.addIceCandidate(new RTCIceCandidate(iceCandidatesQueue.current.shift()!)).catch(() => {});
      }

      const answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);
      await updateDoc(doc(firestore!, 'calls', activeCall.id), {
        answer: { type: answer.type, sdp: answer.sdp },
        status: 'ongoing',
        startedAt: new Date().toISOString(),
      });
    } catch (e) {
      logger.error('webrtc', 'acceptCall', e);
      toast({
        variant: 'destructive',
        title: t('chat.audioCall.acceptFailedTitle'),
        description:
          e instanceof Error
            ? e.message
            : t('chat.audioCall.acceptFailedFallbackDesc'),
      });
      handleReject();
    } finally {
      setIsConnecting(false);
    }
  };

  useEffect(() => {
    const ans = activeCall ? normalizeRtcDesc(activeCall.answer) : null;
    if (
      activeCall?.status === 'ongoing' &&
      activeCall.callerId === currentUser.id &&
      ans &&
      peerConnection.current &&
      !isHandlingAnswer.current
    ) {
      isHandlingAnswer.current = true;
      peerConnection.current
        .setRemoteDescription(new RTCSessionDescription(ans))
        .then(() => {
          while (iceCandidatesQueue.current.length > 0) {
            peerConnection.current?.addIceCandidate(new RTCIceCandidate(iceCandidatesQueue.current.shift()!)).catch(() => {});
          }
        })
        .catch((err) => logger.error('webrtc', 'Answer apply failed', err));
    }
  }, [activeCall?.status, activeCall?.answer, activeCall?.callerId, currentUser.id]);

  // --- 5. RINGTONE & OTHER UI LOGIC ---
  useEffect(() => {
    if (!activeCall || !storageUrls.ringtone) return;
    const isIncoming = activeCall.receiverId === currentUser.id && activeCall.status === 'calling';
    const isOutgoing = activeCall.callerId === currentUser.id && activeCall.status === 'calling';
    
    if (isIncoming && ringtoneAudioRef.current) {
        ringtoneAudioRef.current.play().catch(() => {});
    } else if (isOutgoing && ringbackAudioRef.current) {
        ringbackAudioRef.current.play().catch(() => {});
    } else {
        if (ringtoneAudioRef.current) { ringtoneAudioRef.current.pause(); ringtoneAudioRef.current.currentTime = 0; }
        if (ringbackAudioRef.current) { ringbackAudioRef.current.pause(); ringbackAudioRef.current.currentTime = 0; }
    }
  }, [activeCall?.status, activeCall?.id, currentUser.id, storageUrls]);

  // Auto-timeout unanswered outgoing calls after 60s: mark as missed.
  useEffect(() => {
    if (!firestore || !activeCall) return;
    if (activeCall.status !== 'calling' || activeCall.callerId !== currentUser.id) return;

    const createdAtMs = Date.parse(activeCall.createdAt);
    if (!Number.isFinite(createdAtMs)) return;

    const markMissedIfNeeded = async () => {
      if (!activeCallRef.current || activeCallRef.current.id !== activeCall.id) return true;
      if (activeCallRef.current.status !== 'calling') return true;
      if (Date.now() - createdAtMs < 60_000) return false;
      try {
        await updateDoc(doc(firestore, 'calls', activeCall.id), {
          status: 'missed',
          endedAt: new Date().toISOString(),
        });
      } catch {
        // ignore retry noise; snapshot subscription will eventually close call.
      }
      return true;
    };

    let intervalId: number | null = null;
    void markMissedIfNeeded().then((done) => {
      if (!done) {
        intervalId = window.setInterval(() => {
          void markMissedIfNeeded().then((finished) => {
            if (finished && intervalId != null) {
              window.clearInterval(intervalId);
              intervalId = null;
            }
          });
        }, 1000);
      }
    });

    return () => {
      if (intervalId != null) window.clearInterval(intervalId);
    };
  }, [firestore, activeCall?.id, activeCall?.status, activeCall?.callerId, activeCall?.createdAt, currentUser.id]);

  const peerUserDocRef = useMemoFirebase(() => {
    if (!firestore || !activeCall) return null;
    const peerId =
      activeCall.callerId === currentUser.id ? activeCall.receiverId : activeCall.callerId;
    return doc(firestore, 'users', peerId);
  }, [firestore, activeCall?.id, activeCall?.callerId, activeCall?.receiverId, currentUser.id]);

  /** Актуальное имя/аватар собеседника из `users/{peerId}` (подписка). */
  useEffect(() => {
    if (!activeCall) {
      setOtherUser(null);
      return;
    }
    const fallbackName = (
      activeCall.callerId === currentUser.id ? activeCall.receiverName : activeCall.callerName
    )?.trim() || t('chat.audioCall.participant');

    if (!peerUserDocRef) {
      setOtherUser({ name: fallbackName, avatar: '', avatarThumb: undefined });
      return;
    }

    const unsub = onSnapshot(
      peerUserDocRef,
      (snap) => {
        if (!snap.exists()) {
          setOtherUser({ name: fallbackName, avatar: '', avatarThumb: undefined });
          return;
        }
        const d = snap.data() as Partial<User>;
        setOtherUser({
          name: (typeof d.name === 'string' && d.name.trim()) || fallbackName,
          avatar: typeof d.avatar === 'string' ? d.avatar : '',
          avatarThumb: typeof d.avatarThumb === 'string' ? d.avatarThumb : undefined,
        });
      },
      (err) => {
        logger.error('audio-call', 'peer profile snapshot failed', err);
        setOtherUser({ name: fallbackName, avatar: '', avatarThumb: undefined });
      }
    );
    return () => unsub();
  }, [peerUserDocRef, activeCall, currentUser.id]);

  useEffect(() => {
    if (activeCall?.status === 'ongoing') {
        if (!timerRef.current) timerRef.current = setInterval(() => setCallDuration(prev => prev + 1), 1000);
    } else {
        if (timerRef.current) { clearInterval(timerRef.current); timerRef.current = null; }
    }
    return () => { if (timerRef.current) clearInterval(timerRef.current); };
  }, [activeCall?.status, activeCall?.id]);

  useEffect(() => {
    if (remoteStream) {
      if (remoteVideoRef.current) remoteVideoRef.current.srcObject = remoteStream;
      if (remoteAudioRef.current) remoteAudioRef.current.srcObject = remoteStream;
    }
  }, [remoteStream, isMinimized]);

  useEffect(() => {
    if (localStream && localVideoRef.current) localVideoRef.current.srcObject = localStream;
  }, [localStream, isMinimized, showLocalPreview]);

  // --- 7. ACTIONS ---
  const handleEndCall = () => {
    if (activeCall) {
      const nextStatus = activeCall.status === 'ongoing' ? 'ended' : activeCall.callerId === currentUser.id ? 'missed' : 'cancelled';
      updateDoc(doc(firestore!, 'calls', activeCall.id), { status: nextStatus, endedAt: new Date().toISOString() });
    }
    handleCleanup();
  };

  const handleReject = () => {
    if (activeCall) {
      const nextStatus = activeCall.callerId === currentUser.id ? 'missed' : 'cancelled';
      updateDoc(doc(firestore!, 'calls', activeCall.id), { status: nextStatus, endedAt: new Date().toISOString() });
    }
    handleCleanup();
  };

  const toggleMic = () => {
    if (localStream) {
      const track = localStream.getAudioTracks()[0];
      if (track) {
        track.enabled = isMicMuted;
        setIsMicMuted(!isMicMuted);
      }
    }
  };

  const toggleVideo = () => {
    if (localStream) {
      const track = localStream.getVideoTracks()[0];
      if (track) {
        track.enabled = isVideoOff;
        setIsVideoOff(!isVideoOff);
      }
    }
  };

  const stopScreenShare = async () => {
    if (screenStreamRef.current) {
      screenStreamRef.current.getTracks().forEach(t => t.stop());
      screenStreamRef.current = null;
    }
    
    setIsScreenSharing(false);
    
    // Switch back to camera
    try {
        const stream = await navigator.mediaDevices.getUserMedia({ 
            audio: true, 
            video: activeCall?.isVideo ? { facingMode } : false 
        });
        
        if (localStream) {
            localStream.getTracks().forEach(t => t.stop());
        }
        
        setLocalStream(stream);
        
        if (peerConnection.current) {
            const sender = peerConnection.current.getSenders().find(s => s.track?.kind === 'video');
            if (sender) {
                sender.replaceTrack(stream.getVideoTracks()[0]);
            }
        }
    } catch (e) {
        logger.error('webrtc', 'Reverting to camera failed', e);
    }
  };

  const toggleScreenShare = async () => {
    if (!isScreenSharing) {
      try {
        const stream = await navigator.mediaDevices.getDisplayMedia({ video: true });
        screenStreamRef.current = stream;
        
        const screenTrack = stream.getVideoTracks()[0];
        if (peerConnection.current) {
          const sender = peerConnection.current.getSenders().find(s => s.track?.kind === 'video');
          if (sender) {
            sender.replaceTrack(screenTrack);
          }
        }
        
        setLocalStream(prev => {
            if (!prev) return stream;
            return new MediaStream([
                ...prev.getAudioTracks(),
                screenTrack
            ]);
        });

        setIsScreenSharing(true);
        setIsVideoOff(false);

        screenTrack.onended = () => {
          stopScreenShare();
        };
      } catch (e) {
        logger.error('webrtc', 'Screen share error', e);
      }
    } else {
      stopScreenShare();
    }
  };

  const switchCamera = async () => {
    if (isScreenSharing || !activeCall?.isVideo) return;
    const nextMode = facingMode === 'user' ? 'environment' : 'user';
    setFacingMode(nextMode);
    
    try {
        const stream = await navigator.mediaDevices.getUserMedia({ 
            audio: true, 
            video: { facingMode: nextMode } 
        });
        
        if (localStream) {
            localStream.getTracks().forEach(t => t.stop());
        }
        
        setLocalStream(stream);
        setIsVideoOff(false);

        if (peerConnection.current) {
            const sender = peerConnection.current.getSenders().find(s => s.track?.kind === 'video');
            if (sender) {
                sender.replaceTrack(stream.getVideoTracks()[0]);
            }
        }
    } catch (e) {
        logger.error('webrtc', 'Switch camera failed', e);
        toast({ variant: 'destructive', title: t('chat.audioCall.errorTitle'), description: t('chat.audioCall.switchCameraErrorDesc') });
    }
  };

  if (!activeCall) return null;

  const isIncoming = activeCall.receiverId === currentUser.id && activeCall.status === 'calling';
  const formatTime = (s: number) => `${Math.floor(s/60).toString().padStart(2,'0')}:${(s%60).toString().padStart(2,'0')}`;

  if (isMinimized) {
    return (
        <div onClick={() => setIsMinimized(false)} className="fixed bottom-[max(5rem,env(safe-area-inset-bottom,0px)+1rem)] right-[max(1rem,env(safe-area-inset-right,0px))] z-[100] w-48 cursor-pointer rounded-2xl border border-primary/20 bg-background/90 p-3 shadow-2xl backdrop-blur-xl animate-in zoom-in-95">
            <div className="relative aspect-video rounded-xl overflow-hidden bg-muted flex items-center justify-center">
                {activeCall.status === 'ongoing' && remoteStream?.getVideoTracks().length ? <video ref={remoteVideoRef} autoPlay playsInline className="w-full h-full object-contain" /> : <Avatar className="h-12 w-12"><AvatarImage src={userAvatarListUrl(otherUser)} /><AvatarFallback>{otherUser?.name?.[0]}</AvatarFallback></Avatar>}
            </div>
            <p className="text-xs font-bold truncate mt-2 px-1 text-center">{otherUser?.name}</p>
            <p className="text-[10px] text-primary font-mono text-center">{activeCall.status === 'ongoing' ? formatTime(callDuration) : '...'}</p>
        </div>
    );
  }

  return (
    <div className="fixed inset-0 z-[100] flex flex-col bg-slate-950 animate-in fade-in duration-500 overflow-hidden text-white font-body">
      {/* Hidden Audio Elements for Call Sounds */}
      <audio ref={ringtoneAudioRef} src={storageUrls.ringtone || undefined} loop preload="auto" />
      <audio ref={ringbackAudioRef} src={storageUrls.ringback || undefined} loop preload="auto" />
      <audio ref={remoteAudioRef} autoPlay playsInline style={{ display: 'none' }} />

      <div className="absolute inset-0 flex items-center justify-center">
        <video 
          ref={remoteVideoRef} 
          autoPlay 
          playsInline 
          className={cn(
            "w-full h-full object-contain transition-opacity duration-500", 
            (activeCall.status !== 'ongoing' || !remoteStream?.getVideoTracks().some(t => t.enabled)) ? "opacity-0 absolute" : "opacity-100"
          )} 
        />
        
        {(activeCall.status !== 'ongoing' || !remoteStream?.getVideoTracks().some(t => t.enabled)) && (
            <div className="flex flex-col items-center justify-center p-6 text-center z-10">
                <div className="relative mb-8">
                    <Avatar className="h-48 w-48 md:h-64 md:w-64 border-4 border-white/10 shadow-2xl">
                        <AvatarImage src={userAvatarListUrl(otherUser)} className="object-cover" />
                        <AvatarFallback className="text-6xl bg-muted text-foreground">{otherUser?.name?.[0]}</AvatarFallback>
                    </Avatar>
                    {(activeCall.status === 'ongoing' || isConnecting) && (
                      <div className="absolute -bottom-2 -right-2 bg-green-500 h-10 w-10 md:h-12 md:w-12 rounded-full border-[6px] border-slate-950 animate-pulse" />
                    )}
                </div>
                <h2 className="text-2xl md:text-4xl font-bold max-w-2xl drop-shadow-lg leading-tight">{otherUser?.name}</h2>
                <p className="text-cyan-400 mt-4 font-mono tracking-widest text-sm md:text-base uppercase">
                    {activeCall.status === 'ongoing' ? formatTime(callDuration) : (activeCall.isVideo ? t('chat.audioCall.videoCallStatus') : t('chat.audioCall.audioCallStatus'))}
                </p>
            </div>
        )}
      </div>

      {localStream && activeCall.isVideo && (
        <div 
          className={cn("fixed z-[110] transition-opacity duration-300", !showLocalPreview && "opacity-0 pointer-events-none scale-50 translate-y-20")}
          style={{ bottom: `${previewPos.bottom}px`, right: `${previewPos.right}px`, transform: `scale(${previewScale})`, transformOrigin: 'bottom right' }}
          onMouseDown={handleDragStart}
          onTouchStart={handleDragStart}
        >
            <div className="relative w-32 md:w-44 aspect-[3/4] bg-black rounded-2xl overflow-hidden border-2 border-white/20 shadow-2xl group/preview cursor-move touch-none">
                <video ref={localVideoRef} autoPlay muted playsInline className={cn("w-full h-full object-cover transition-opacity", isVideoOff ? "opacity-0" : "opacity-100")} />
                {isVideoOff && <div className="absolute inset-0 flex items-center justify-center bg-slate-900"><Avatar className="h-12 w-12"><AvatarImage src={userAvatarListUrl(currentUser)} /><AvatarFallback>{currentUser.name[0]}</AvatarFallback></Avatar></div>}
                
                {/* Resize Handle at Top-Left */}
                <div className="absolute top-0 left-0 w-10 h-10 cursor-nwse-resize z-[120] flex items-center justify-center bg-black/30 opacity-0 group-hover/preview:opacity-100 transition-opacity rounded-br-xl">
                    <div className="w-4 h-4 border-t-2 border-l-2 border-white/70" />
                </div>

                <div className="absolute inset-0 bg-black/40 opacity-0 group-hover/preview:opacity-100 transition-opacity flex items-center justify-center pointer-events-none">
                  <Button variant="ghost" size="icon" className="rounded-full h-10 w-10 bg-white/20 text-white border-none shadow-none pointer-events-auto" onClick={(e) => { e.stopPropagation(); setShowLocalPreview(false); }}><Minimize2 className="h-5 w-5" /></Button>
                </div>
            </div>
        </div>
      )}

      {localStream && activeCall.isVideo && !showLocalPreview && (
        <Button variant="outline" size="sm" className="fixed bottom-[max(8rem,env(safe-area-inset-bottom,0px)+5.5rem)] right-[max(1.5rem,env(safe-area-inset-right,0px))] z-40 h-10 rounded-full border-white/20 bg-black/40 px-4 text-white shadow-xl backdrop-blur-md animate-in slide-in-from-right-4" onClick={() => setShowLocalPreview(true)}><Maximize2 className="mr-2 h-4 w-4" /> {t('chat.audioCall.ownVideo')}</Button>
      )}
      
      <div className="absolute right-[max(1rem,env(safe-area-inset-right,0px))] top-[max(1rem,env(safe-area-inset-top,0px))] z-40">
          <Button variant="ghost" size="icon" className="h-10 w-10 rounded-full border-none bg-black/20 text-white/50 shadow-none" onClick={() => setIsMinimized(true)}><Minimize2 className="h-5 w-5"/></Button>
      </div>

      <div className="absolute inset-x-0 bottom-[max(3rem,env(safe-area-inset-bottom,0px))] z-30 flex flex-col items-center pl-[max(1rem,env(safe-area-inset-left,0px))] pr-[max(1rem,env(safe-area-inset-right,0px))]">
        <div className="flex items-center gap-2 md:gap-4 bg-black/40 backdrop-blur-2xl p-2.5 md:p-3 rounded-full border border-white/10 shadow-2xl max-w-full overflow-x-auto no-scrollbar transition-all duration-300">
            {isIncoming && activeCall.status === 'calling' && (
                <Button size="icon" className="h-10 w-10 md:h-12 md:w-12 rounded-full bg-green-500 hover:bg-green-600 animate-pulse shadow-lg border-none" onClick={acceptCall} disabled={isConnecting}>
                    {isConnecting ? <Loader2 className="h-5 w-5 animate-spin" /> : <Phone className="h-5 w-5 text-white" />}
                </Button>
            )}
            
            <Button size="icon" variant="ghost" className={cn("h-10 w-10 md:h-12 md:w-12 rounded-full border-none shadow-none transition-all", !isMicMuted ? "bg-white text-slate-950 hover:bg-white/90" : "bg-white/10 text-white hover:bg-white/20")} onClick={toggleMic}>
                {!isMicMuted ? <Mic className="h-5 w-5" /> : <MicOff className="h-5 w-5" />}
            </Button>
            
            {activeCall.isVideo && (
                <>
                    <Button size="icon" variant="ghost" className={cn("h-10 w-10 md:h-12 md:w-12 rounded-full border-none shadow-none transition-all", !isVideoOff ? "bg-white text-slate-950 hover:bg-white/90" : "bg-white/10 text-white hover:bg-white/20")} onClick={toggleVideo}>
                        {!isVideoOff ? <Video className="h-5 w-5" /> : <VideoOff className="h-5 w-5" />}
                    </Button>
                    
                    <Button 
                        size="icon" 
                        variant="ghost" 
                        className="h-10 w-10 md:h-12 md:w-12 rounded-full bg-white/10 backdrop-blur-md hover:bg-white/20 md:hidden border-none shadow-none" 
                        onClick={switchCamera}
                    >
                        <SwitchCamera className="h-5 w-5" />
                    </Button>

                    {isDisplayMediaSupported && (
                        <Button 
                            size="icon" 
                            variant="ghost" 
                            className={cn("h-10 w-10 md:h-12 md:w-12 rounded-full border-none shadow-none hidden md:flex transition-all", isScreenSharing ? "bg-white text-slate-950 hover:bg-white/90" : "bg-white/10 text-white hover:bg-white/20")} 
                            onClick={toggleScreenShare}
                        >
                            {isScreenSharing ? <MonitorOff className="h-5 w-5" /> : <MonitorUp className="h-5 w-5" />}
                        </Button>
                    )}
                </>
            )}
            
            <Separator orientation="vertical" className="h-8 bg-white/10 mx-1" />
            
            <Button size="icon" variant="destructive" className="h-10 w-10 md:h-12 md:w-12 rounded-full shadow-lg border-none" onClick={isIncoming ? handleReject : handleEndCall}>
                <PhoneOff className="h-5 w-5 text-white" />
            </Button>
        </div>
      </div>
    </div>
  );
}

export const initiateCall = async (
  firestore: Firestore,
  caller: User,
  receiver: Pick<User, 'id' | 'name'> & { blockedUserIds?: string[] },
  isVideo: boolean,
  toast: (opts: { variant?: 'default' | 'destructive' | null; title: string; description?: string }) => void,
  t: (key: string) => string = (k) => k,
) => {
    if (!firestore || !caller || !receiver?.id) return;
    if (!navigator.mediaDevices || !window.RTCPeerConnection) {
        toast({ variant: 'destructive', title: t('chat.audioCall.callErrorTitle'), description: t('chat.audioCall.browserUnsupportedDesc') });
        return;
    }
    if (
      isEitherBlockingFromUserIds(
        caller.id,
        caller.blockedUserIds,
        receiver.id,
        receiver.blockedUserIds ?? null
      )
    ) {
      toast({
        variant: 'destructive',
        title: t('chat.audioCall.callUnavailableTitle'),
        description: t('chat.audioCall.callUnavailableDesc'),
      });
      return;
    }
    try {
        const callId = `call_${Date.now()}`;
        const callData: Call = {
            id: callId,
            callerId: caller.id,
            receiverId: receiver.id,
            callerName: caller.name,
            receiverName: receiver.name,
            status: 'calling',
            isVideo: isVideo,
            createdAt: new Date().toISOString()
        };
        await setDoc(doc(firestore, 'calls', callId), callData);
        return { callId };
    } catch {
        toast({ variant: 'destructive', title: t('chat.audioCall.callErrorTitle'), description: t('chat.audioCall.callCreateErrorDesc') });
    }
};
