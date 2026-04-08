'use client';

import { useState, useEffect, useRef, useCallback } from 'react';
import { 
  doc, onSnapshot, collection, setDoc, deleteDoc, updateDoc, 
  serverTimestamp, query, where 
} from 'firebase/firestore';
import { useFirestore, useStorage } from '@/firebase';
import { useToast } from '@/hooks/use-toast';
import { useRouter } from 'next/navigation';
import type { Meeting, User, MeetingSignal } from '@/lib/types';

if (typeof window !== 'undefined' && !window.process) {
    (window as any).process = { env: {} };
}

export type BackgroundConfig = {
  type: 'none' | 'blur' | 'image';
  url?: string | null;
};

export interface ParticipantState {
  id: string;
  name: string;
  avatar: string;
  /** Круглое превью (как в профиле) — денормализация в meetings/.../participants */
  avatarThumb?: string;
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
  forceMuteAudio?: boolean;
  forceMuteVideo?: boolean;
}

export interface UseMeetingWebRTCResult {
  participants: Record<string, ParticipantState>;
  localStream: MediaStream | null;
  isMicMuted: boolean;
  isVideoOff: boolean;
  isScreenSharing: boolean;
  isHandRaised: boolean;
  backgroundConfig: BackgroundConfig;
  facingMode: 'user' | 'environment';
  toggleMic: () => void;
  toggleVideo: () => void;
  toggleHand: () => void;
  switchCamera: () => Promise<void>;
  toggleScreenShare: () => Promise<void>;
  setBackgroundConfig: (config: BackgroundConfig) => void;
  stopAllMedia: () => void;
  setIsHandRaised: (val: boolean) => void;
}

export function useMeetingWebRTC(meeting: Meeting, currentUser: User, initialSettings: any): UseMeetingWebRTCResult {
  const [participants, setParticipants] = useState<Record<string, ParticipantState>>({});
  const [localStream, setLocalStream] = useState<MediaStream | null>(null);
  const [isMicMuted, setIsMicMuted] = useState(!!initialSettings.micMuted);
  const [isVideoOff, setIsVideoOff] = useState(!!initialSettings.videoOff);
  const [isScreenSharing, setIsScreenSharing] = useState(false);
  const [isHandRaised, setIsHandRaised] = useState(false);
  const [backgroundConfig, setBackgroundConfig] = useState<BackgroundConfig>({ type: 'none' });
  const [facingMode, setFacingMode] = useState<'user' | 'environment'>('user');
  const [isMediaReady, setIsMediaReady] = useState(false);

  const peers = useRef<Record<string, any>>({});
  const creatingPeers = useRef<Set<string>>(new Set());
  const rawStreamRef = useRef<MediaStream | null>(null);
  const screenStreamRef = useRef<MediaStream | null>(null);
  const localStreamRef = useRef<MediaStream | null>(null);
  const isMountedRef = useRef(true);
  const firestore = useFirestore();
  const { toast } = useToast();
  const router = useRouter();

  const selfieSegmentationRef = useRef<any>(null);
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const offscreenCanvasRef = useRef<HTMLCanvasElement | null>(null);
  const requestAnimationRef = useRef<number | null>(null);
  const backgroundConfigRef = useRef<BackgroundConfig>(backgroundConfig);
  const bgImageCache = useRef<Record<string, HTMLImageElement>>({});

  useEffect(() => {
    isMountedRef.current = true;
    if (typeof document !== 'undefined') {
        canvasRef.current = document.createElement('canvas');
        offscreenCanvasRef.current = document.createElement('canvas');
    }
    return () => { 
        isMountedRef.current = false;
        if (requestAnimationRef.current) cancelAnimationFrame(requestAnimationRef.current);
    };
  }, []);

  useEffect(() => {
    backgroundConfigRef.current = backgroundConfig;
  }, [backgroundConfig]);

  useEffect(() => {
    localStreamRef.current = localStream;
  }, [localStream]);

  const getBgImage = useCallback((url: string) => {
    if (bgImageCache.current[url]) return bgImageCache.current[url];
    const img = new window.Image();
    img.crossOrigin = "anonymous";
    img.src = url;
    bgImageCache.current[url] = img;
    return img;
  }, []);

  const safeReplaceTrack = useCallback((newTrack: MediaStreamTrack) => {
    Object.values(peers.current).forEach(p => {
        if (!p || p.destroyed || !p._pc || p._pc.signalingState === 'closed') return;
        try {
            const senders = p._pc.getSenders();
            const sender = senders.find((s: RTCRtpSender) => s.track?.kind === newTrack.kind);
            if (sender) {
                sender.replaceTrack(newTrack).catch((err: Error) => {
                    console.warn("[WebRTC] RTC replacement failed", err);
                });
            }
        } catch (e) {
            console.warn(`[WebRTC] replaceTrack error:`, e);
        }
    });
  }, []);

  const stopAllMedia = useCallback(() => {
    if (requestAnimationRef.current) cancelAnimationFrame(requestAnimationRef.current);
    if (rawStreamRef.current) rawStreamRef.current.getTracks().forEach(t => t.stop());
    if (localStreamRef.current) localStreamRef.current.getTracks().forEach(t => t.stop());
    if (screenStreamRef.current) screenStreamRef.current.getTracks().forEach(t => t.stop());
    setLocalStream(null);
    setIsMediaReady(false);
  }, []);

  const toggleMic = useCallback(() => {
    const next = !isMicMuted;
    [rawStreamRef.current, localStreamRef.current].forEach(s => s?.getAudioTracks().forEach(t => t.enabled = !next));
    setIsMicMuted(next);
    if (firestore && currentUser.id) {
        updateDoc(doc(firestore, `meetings/${meeting.id}/participants`, currentUser.id), { 
            isAudioMuted: next,
            lastSeen: new Date().toISOString()
        }).catch(() => {});
    }
  }, [isMicMuted, firestore, meeting.id, currentUser.id]);

  const toggleVideo = useCallback(() => {
    const next = !isVideoOff;
    [rawStreamRef.current, localStreamRef.current].forEach(s => s?.getVideoTracks().forEach(t => t.enabled = !next));
    setIsVideoOff(next);
    if (firestore && currentUser.id) {
        updateDoc(doc(firestore, `meetings/${meeting.id}/participants`, currentUser.id), { 
            isVideoMuted: next,
            lastSeen: new Date().toISOString()
        }).catch(() => {});
    }
  }, [isVideoOff, firestore, meeting.id, currentUser.id]);

  const toggleHand = useCallback(() => {
    const next = !isHandRaised;
    setIsHandRaised(next);
    if (firestore && currentUser.id) {
        updateDoc(doc(firestore, `meetings/${meeting.id}/participants`, currentUser.id), { 
            isHandRaised: next,
            lastSeen: new Date().toISOString()
        }).catch(() => {});
    }
  }, [isHandRaised, firestore, meeting.id, currentUser.id]);

  const switchCamera = useCallback(async () => {
    const next = facingMode === 'user' ? 'environment' : 'user';
    setFacingMode(next);
    try {
        const stream = await navigator.mediaDevices.getUserMedia({ 
            audio: true, 
            video: { facingMode: next, width: 1280, height: 720 } 
        });
        const newTrack = stream.getVideoTracks()[0];
        
        if (rawStreamRef.current) {
            rawStreamRef.current.getVideoTracks().forEach(t => t.stop());
            rawStreamRef.current = stream;
        }

        if (backgroundConfigRef.current.type === 'none' && localStreamRef.current) {
            safeReplaceTrack(newTrack);
            const audioTracks = localStreamRef.current.getAudioTracks();
            setLocalStream(new MediaStream([newTrack, ...audioTracks]));
        }
        
        if (firestore && currentUser.id) {
            updateDoc(doc(firestore, `meetings/${meeting.id}/participants`, currentUser.id), { 
                lastSeen: new Date().toISOString()
            }).catch(() => {});
        }
    } catch (e) { toast({ variant: 'destructive', title: 'Ошибка камеры' }); }
  }, [facingMode, safeReplaceTrack, firestore, meeting.id, currentUser.id, toast]);

  const toggleScreenShare = useCallback(async () => {
    if (!isScreenSharing) {
        try {
            const screenStreamOptions: any = {
                video: { cursor: "always", displaySurface: "browser" },
                audio: { echoCancellation: true, noiseSuppression: true }
            };
            const stream = await navigator.mediaDevices.getDisplayMedia(screenStreamOptions);
            screenStreamRef.current = stream;
            const screenTrack = stream.getVideoTracks()[0];
            
            if (localStreamRef.current && screenTrack) {
                safeReplaceTrack(screenTrack);
                const audioTracks = localStreamRef.current.getAudioTracks();
                setLocalStream(new MediaStream([screenTrack, ...audioTracks]));
                setIsScreenSharing(true); 
                setIsVideoOff(false);
                screenTrack.onended = () => toggleScreenShare();
                
                if (firestore && currentUser.id) {
                    updateDoc(doc(firestore, `meetings/${meeting.id}/participants`, currentUser.id), { 
                        isScreenSharing: true,
                        lastSeen: new Date().toISOString()
                    });
                }
            }
        } catch (e) {}
    } else {
        if (screenStreamRef.current) {
            screenStreamRef.current.getTracks().forEach(t => t.stop());
            screenStreamRef.current = null; 
        }
        setIsScreenSharing(false);
        const cameraTrack = rawStreamRef.current?.getVideoTracks()[0];
        if (cameraTrack && localStreamRef.current) {
            safeReplaceTrack(cameraTrack);
            const audioTracks = localStreamRef.current.getAudioTracks();
            setLocalStream(new MediaStream([cameraTrack, ...audioTracks]));
        }
        
        if (firestore && currentUser.id) {
            updateDoc(doc(firestore, `meetings/${meeting.id}/participants`, currentUser.id), { 
                isScreenSharing: false,
                lastSeen: new Date().toISOString()
            });
        }
    }
  }, [isScreenSharing, safeReplaceTrack, firestore, meeting.id, currentUser.id]);

  const setupPeer = useCallback(async (remoteId: string, initiator: boolean) => {
    if (!isMountedRef.current || peers.current[remoteId] || creatingPeers.current.has(remoteId) || !localStreamRef.current) return null;
    creatingPeers.current.add(remoteId);
    
    try {
        const Peer = (await import('simple-peer')).default;
        const p = new Peer({
          initiator,
          trickle: true,
          stream: localStreamRef.current || undefined,
          config: { iceServers: [{ urls: ['stun:stun1.l.google.com:19302', 'stun:stun2.l.google.com:19302'] }] }
        });

        p.on('signal', (data: any) => {
          if (firestore && !p.destroyed && isMountedRef.current) {
            setDoc(doc(collection(firestore, `meetings/${meeting.id}/signals`)), {
              from: currentUser.id, to: remoteId, type: data.type || 'candidate', data, createdAt: serverTimestamp()
            });
          }
        });

        p.on('stream', (remoteStream: MediaStream) => {
          if (!isMountedRef.current) return;
          setParticipants(prev => ({ ...prev, [remoteId]: { ...prev[remoteId], id: remoteId, stream: remoteStream } }));
        });

        p.on('error', (err: any) => { 
            console.error(`[WebRTC] [${remoteId}] Peer error:`, err); 
            creatingPeers.current.delete(remoteId); 
        });

        p.on('close', () => { 
            if (!isMountedRef.current) return;
            setParticipants(prev => {
                const next = { ...prev };
                delete next[remoteId];
                return next;
            });
            delete peers.current[remoteId]; 
            creatingPeers.current.delete(remoteId); 
        });

        peers.current[remoteId] = p;
        creatingPeers.current.delete(remoteId);
        return p;
    } catch (err) {
        console.error("[WebRTC] Peer load error", err);
        creatingPeers.current.delete(remoteId);
        return null;
    }
  }, [firestore, meeting.id, currentUser.id]);

  useEffect(() => {
    if (typeof window === 'undefined') return;
    const setupEngine = async () => {
        try {
            const { SelfieSegmentation } = await import('@mediapipe/selfie_segmentation');
            const segmentation = new SelfieSegmentation({
                locateFile: (file) => `https://cdn.jsdelivr.net/npm/@mediapipe/selfie_segmentation/${file}`,
            });
            segmentation.setOptions({ modelSelection: 0, selfieMode: false });
            
            segmentation.onResults((results: any) => {
                if (!isMountedRef.current) return;
                const canvas = canvasRef.current;
                const ctx = canvas?.getContext('2d', { alpha: false });
                if (!canvas || !ctx || !results.image || results.image.width === 0) return;
                
                const targetW = results.image.width;
                const targetH = results.image.height;
                
                if (canvas.width !== targetW || canvas.height !== targetH) {
                    canvas.width = targetW;
                    canvas.height = targetH;
                }

                if (!offscreenCanvasRef.current) offscreenCanvasRef.current = document.createElement('canvas');
                const offscreen = offscreenCanvasRef.current;
                const oCtx = offscreen.getContext('2d');
                if (!oCtx) return;

                offscreen.width = targetW;
                offscreen.height = targetH;

                const currentConfig = backgroundConfigRef.current;
                
                ctx.save();
                ctx.clearRect(0, 0, targetW, targetH);
                
                if (currentConfig.type === 'blur') {
                    ctx.save();
                    ctx.filter = 'blur(12px) brightness(0.8)';
                    ctx.drawImage(results.image, -20, -20, targetW + 40, targetH + 40);
                    ctx.restore();
                } else if (currentConfig.type === 'image' && currentConfig.url) {
                    const bgImg = getBgImage(currentConfig.url);
                    if (bgImg.complete && bgImg.naturalWidth > 0) {
                        const canvasAspect = targetW / targetH;
                        const imgAspect = bgImg.naturalWidth / bgImg.naturalHeight;
                        let drawW, drawH, offsetX, offsetY;
                        if (imgAspect > canvasAspect) {
                            drawH = targetH; drawW = targetH * imgAspect;
                            offsetX = (targetW - drawW) / 2; offsetY = 0;
                        } else {
                            drawW = targetW; drawH = targetW / imgAspect;
                            offsetX = 0; offsetY = (targetH - drawH) / 2;
                        }
                        ctx.drawImage(bgImg, offsetX, offsetY, drawW, drawH);
                    } else {
                        ctx.fillStyle = '#000000';
                        ctx.fillRect(0, 0, targetW, targetH);
                    }
                } else {
                    ctx.drawImage(results.image, 0, 0, targetW, targetH);
                }

                oCtx.clearRect(0, 0, targetW, targetH);
                oCtx.drawImage(results.image, 0, 0, targetW, targetH);
                oCtx.globalCompositeOperation = 'destination-in';
                oCtx.drawImage(results.segmentationMask, 0, 0, targetW, targetH);
                ctx.drawImage(offscreen, 0, 0);
                ctx.restore();
            });
            selfieSegmentationRef.current = segmentation;
        } catch (e) { console.error("[WebRTC] Engine initialization failed", e); }
    };
    setupEngine();
    return () => { 
        if (selfieSegmentationRef.current) { 
            selfieSegmentationRef.current.close().catch(() => {}); 
            selfieSegmentationRef.current = null; 
        } 
    };
  }, [getBgImage]);

  useEffect(() => {
    let isMounted = true;
    const startMedia = async () => {
      try {
        const stream = await navigator.mediaDevices.getUserMedia({ 
          video: !isVideoOff ? { facingMode: 'user', width: 1280, height: 720 } : false, 
          audio: true 
        });
        if (!isMounted) { stream.getTracks().forEach(t => t.stop()); return; }
        rawStreamRef.current = stream;
        
        setLocalStream(new MediaStream(stream.getTracks()));
        
        stream.getAudioTracks().forEach(t => t.enabled = !isMicMuted);
        if (stream.getVideoTracks().length > 0) stream.getVideoTracks()[0].enabled = !isVideoOff;
        setIsMediaReady(true);
      } catch (e) { console.error("[WebRTC] Media capture error:", e); if (isMounted) setIsMediaReady(true); }
    };
    startMedia();
    return () => { isMounted = false; stopAllMedia(); };
  }, []);

  useEffect(() => {
    let isDestroyed = false;
    const canvas = canvasRef.current;
    
    if (backgroundConfig.type === 'none') {
        if (requestAnimationRef.current) cancelAnimationFrame(requestAnimationRef.current);
        
        if (rawStreamRef.current && localStream) {
            const rawVideoTrack = rawStreamRef.current.getVideoTracks()[0];
            const currentLocalTrack = localStream.getVideoTracks()[0];
            
            if (rawVideoTrack && currentLocalTrack && currentLocalTrack.id !== rawVideoTrack.id) {
                safeReplaceTrack(rawVideoTrack);
                const audioTracks = localStream.getAudioTracks();
                setLocalStream(new MediaStream([rawVideoTrack, ...audioTracks]));
            }
        }
        return;
    }

    if (isVideoOff || !rawStreamRef.current || !selfieSegmentationRef.current || !canvas) {
        if (requestAnimationRef.current) cancelAnimationFrame(requestAnimationRef.current);
        return;
    }

    const video = document.createElement('video');
    video.srcObject = rawStreamRef.current; 
    video.muted = true; 
    video.play().catch(() => {});

    const processFrame = async (timestamp: number) => {
        if (isDestroyed || !selfieSegmentationRef.current) return;
        if (video.videoWidth > 0 && video.videoHeight > 0) {
            try { await selfieSegmentationRef.current.send({ image: video }); } catch (e) {}
        }
        requestAnimationRef.current = requestAnimationFrame(processFrame);
    };
    requestAnimationRef.current = requestAnimationFrame(processFrame);

    try {
        const canvasStream = (canvas as any).captureStream(25);
        const canvasTrack = canvasStream.getVideoTracks()[0];
        if (canvasTrack && localStream) {
            const currentTrack = localStream.getVideoTracks()[0];
            if (currentTrack?.id !== canvasTrack.id) {
                safeReplaceTrack(canvasTrack);
                const audioTracks = localStream.getAudioTracks();
                setLocalStream(new MediaStream([canvasTrack, ...audioTracks]));
            }
        }
    } catch (e) {}

    return () => { 
        isDestroyed = true; 
        if (requestAnimationRef.current) cancelAnimationFrame(requestAnimationRef.current); 
        video.pause(); 
        video.srcObject = null; 
    };
  }, [backgroundConfig.type, backgroundConfig.url, isVideoOff, localStream === null, safeReplaceTrack]);

  useEffect(() => {
    if (!firestore || !currentUser.id || !isMediaReady) return;
    const myRef = doc(firestore, `meetings/${meeting.id}/participants`, currentUser.id);
    updateDoc(myRef, { 
        backgroundConfig: { type: backgroundConfig.type, url: backgroundConfig.url || null }, 
        lastSeen: new Date().toISOString() 
    }).catch(() => {});
  }, [backgroundConfig, firestore, meeting.id, currentUser.id, isMediaReady]);

  useEffect(() => {
    if (!firestore || !currentUser.id || !isMediaReady) return;
    let isMounted = true;
    const myRef = doc(firestore, `meetings/${meeting.id}/participants`, currentUser.id);
    
    setDoc(myRef, {
      id: currentUser.id,
      name: initialSettings.name || currentUser.name,
      avatar: currentUser.avatar || '',
      avatarThumb: currentUser.avatarThumb?.trim() || '',
      role: currentUser.role || 'worker', joinedAt: serverTimestamp(), lastSeen: new Date().toISOString(),
      isAudioMuted: isMicMuted, isVideoMuted: isVideoOff, isHandRaised: isHandRaised,
      backgroundConfig: { type: backgroundConfig.type, url: backgroundConfig.url || null }
    }, { merge: true });

    const heartbeat = setInterval(() => {
        if (!isMounted) return;
        updateDoc(myRef, { lastSeen: new Date().toISOString() }).catch(() => {});
    }, 20000);

    const unsubMyDoc = onSnapshot(myRef, (snap) => {
        if (!isMounted) return;
        if (!snap.exists()) {
            // Ejection logic: if our document is gone, we are out
            if (isMediaReady) {
                stopAllMedia();
                router.push('/dashboard/meetings');
                toast({ variant: 'destructive', title: 'Вы были исключены', description: 'Вас удалили из конференции.' });
            }
            return;
        }
        const data = snap.data();
        if (data.forceMuteAudio && !isMicMuted) {
            setIsMicMuted(true);
            [rawStreamRef.current, localStreamRef.current].forEach(s => s?.getAudioTracks().forEach(t => t.enabled = false));
            updateDoc(myRef, { forceMuteAudio: false, isAudioMuted: true, lastSeen: new Date().toISOString() }).catch(() => {});
        }
        if (data.forceMuteVideo && !isVideoOff) {
            setIsVideoOff(true);
            [rawStreamRef.current, localStreamRef.current].forEach(s => s?.getVideoTracks().forEach(t => t.enabled = false));
            updateDoc(myRef, { forceMuteVideo: false, isVideoMuted: true, lastSeen: new Date().toISOString() }).catch(() => {});
        }
    });

    const unsubParticipants = onSnapshot(collection(firestore, `meetings/${meeting.id}/participants`), (snap) => {
      if (!isMounted) return;
      snap.docChanges().forEach(async (change) => {
        const remoteId = change.doc.id;
        if (remoteId === currentUser.id) return;
        if (change.type === 'added') {
          setParticipants(prev => ({ ...prev, [remoteId]: { ...change.doc.data(), id: remoteId } as ParticipantState }));
          if (currentUser.id < remoteId) setupPeer(remoteId, true);
        } else if (change.type === 'modified') {
          setParticipants(prev => ({ ...prev, [remoteId]: { ...prev[remoteId], ...change.doc.data() } as ParticipantState }));
        } else if (change.type === 'removed') {
          setParticipants(prev => { const next = { ...prev }; delete next[remoteId]; return next; });
          const peerToDestroy = peers.current[remoteId];
          if (peerToDestroy) {
            delete peers.current[remoteId];
            creatingPeers.current.delete(remoteId);
            setTimeout(() => {
                try { if (peerToDestroy && !peerToDestroy.destroyed) peerToDestroy.destroy(); } catch (e) {}
            }, 0);
          }
        }
      });
    });

    const unsubSignals = onSnapshot(query(collection(firestore, `meetings/${meeting.id}/signals`), where('to', '==', currentUser.id)), (snap) => {
      if (!isMounted) return;
      snap.docChanges().forEach(async (change) => {
        if (change.type === 'added') {
          const signal = change.doc.data() as MeetingSignal;
          let p = peers.current[signal.from];
          if (!p && !creatingPeers.current.has(signal.from)) p = await setupPeer(signal.from, false);
          if (p && !p.destroyed) try { p.signal(signal.data); } catch(e) {}
          deleteDoc(change.doc.ref).catch(() => {});
        }
      });
    });

    return () => {
        isMounted = false; clearInterval(heartbeat); unsubMyDoc(); unsubParticipants(); unsubSignals();
        if (firestore && currentUser.id) deleteDoc(doc(firestore, `meetings/${meeting.id}/participants`, currentUser.id)).catch(() => {});
    };
  }, [firestore, meeting.id, currentUser.id, isMediaReady, setupPeer, router, stopAllMedia, toast]);

  return {
    participants, localStream, isMicMuted, isVideoOff, isScreenSharing, isHandRaised, backgroundConfig, facingMode,
    toggleMic, toggleVideo, toggleHand, switchCamera, toggleScreenShare, setBackgroundConfig, stopAllMedia, 
    setIsHandRaised: (val: boolean) => { 
        setIsHandRaised(val); 
        if (firestore) updateDoc(doc(firestore, `meetings/${meeting.id}/participants`, currentUser.id), { isHandRaised: val, lastSeen: new Date().toISOString() });
    }
  };
}
