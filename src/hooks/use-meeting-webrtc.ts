'use client';

import { useState, useEffect, useRef, useCallback } from 'react';
import { 
  doc, onSnapshot, collection, setDoc, deleteDoc, updateDoc, 
  serverTimestamp, query, where 
} from 'firebase/firestore';
import { useFirestore } from '@/firebase';
import { logger } from '@/lib/logger';
import { firebaseConfig } from '@/firebase/config';
import { getAuth } from 'firebase/auth';
import { useToast } from '@/hooks/use-toast';
import { useRouter } from 'next/navigation';
import type { Meeting, User, MeetingSignal } from '@/lib/types';
import { getWebRtcIceConfig } from '@/lib/webrtc-ice-servers';
import {
  meetingWebRtcLog,
  summarizeRtcConfiguration,
  summarizeSignalPayload,
} from '@/lib/meeting-webrtc-logger';
import { normalizeInboundSignalForSimplePeer } from '@/lib/meeting-signaling-normalize';
import { watchPeerStats, type PeerConnectionQuality } from '@/lib/webrtc/peer-stats';

if (typeof window !== 'undefined' && !window.process) {
    (window as any).process = { env: {} };
}

/** В рантайме simple-peer кладёт нативный PC в `_pc`; в @types/simple-peer этого поля нет. */
function getSimplePeerRTCPeerConnection(peer: unknown): RTCPeerConnection | undefined {
  const pc = (peer as { _pc?: RTCPeerConnection | null } | null)?._pc;
  return pc ?? undefined;
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
  /**
   * Качество соединения до удалённого peer по последней выборке getStats.
   * Локальный признак (в Firestore не пишется): используется в UI для индикатора
   * «слабый сигнал». См. `src/lib/webrtc/peer-stats.ts`.
   */
  connectionQuality?: PeerConnectionQuality;
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
  /**
   * `true` после успешного `setDoc` в `meetings/{id}/participants/{uid}`.
   * До этого момента подписки на messages/polls в комнате дадут permission-denied.
   */
  isParticipantSynced: boolean;
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
  const [isParticipantSynced, setIsParticipantSynced] = useState(false);

  const peers = useRef<Record<string, any>>({});
  const creatingPeers = useRef<Set<string>>(new Set());
  /** Сигналы (SDP/ICE), пришедшие пока simple-peer ещё создаётся — иначе теряются и связь не поднимается. */
  const pendingSignalsByPeerRef = useRef<Record<string, unknown[]>>({});
  const rawStreamRef = useRef<MediaStream | null>(null);
  const screenStreamRef = useRef<MediaStream | null>(null);
  const localStreamRef = useRef<MediaStream | null>(null);
  const isMountedRef = useRef(true);
  const firestore = useFirestore();
  const { toast } = useToast();
  const router = useRouter();

  const logCtxRef = useRef({ meetingId: meeting.id, selfId: currentUser.id });
  logCtxRef.current = { meetingId: meeting.id, selfId: currentUser.id };
  const mlog = {
    v: (area: string, msg: string, extra?: Record<string, unknown>) =>
      meetingWebRtcLog.v(logCtxRef.current.meetingId, logCtxRef.current.selfId, area, msg, extra),
    info: (area: string, msg: string, extra?: Record<string, unknown>) =>
      meetingWebRtcLog.info(logCtxRef.current.meetingId, logCtxRef.current.selfId, area, msg, extra),
    warn: (area: string, msg: string, extra?: Record<string, unknown>) =>
      meetingWebRtcLog.warn(logCtxRef.current.meetingId, logCtxRef.current.selfId, area, msg, extra),
    err: (area: string, msg: string, err?: unknown, extra?: Record<string, unknown>) =>
      meetingWebRtcLog.error(logCtxRef.current.meetingId, logCtxRef.current.selfId, area, msg, err, extra),
  };

  /**
   * Трекер попыток reconnect по пиру:
   *   count — сколько полных пересозданий peer было за последние RECONNECT_WINDOW_MS;
   *   lastTriedAt — timestamp последней попытки (сбрасывает count после окна);
   *   disconnectTimerId — таймер отложенного restartIce (см. обработчик iceConnectionState).
   * Ограничение попыток защищает от бесконечной петли при фундаментальном отсутствии связи.
   */
  const peerReconnect = useRef<Record<string, {
    count: number;
    lastTriedAt: number;
    disconnectTimerId: ReturnType<typeof setTimeout> | null;
    /** Уже запланировано пересоздание (ICE failed + connection failed не должны дублировать таймер). */
    recreateTimerId: ReturnType<typeof setTimeout> | null;
  }>>({});

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
        // Снимаем все отложенные ICE-disconnect таймеры (см. attachResilience).
        Object.values(peerReconnect.current).forEach((entry) => {
            if (entry?.disconnectTimerId) clearTimeout(entry.disconnectTimerId);
            if (entry?.recreateTimerId) clearTimeout(entry.recreateTimerId);
        });
        peerReconnect.current = {};
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
    mlog.v('media', 'safeReplaceTrack', {
      kind: newTrack.kind,
      id: newTrack.id,
      enabled: newTrack.enabled,
      peerCount: Object.keys(peers.current).length,
    });
    Object.values(peers.current).forEach(p => {
        if (!p || p.destroyed || !p._pc || p._pc.signalingState === 'closed') return;
        try {
            const senders = p._pc.getSenders();
            const sender = senders.find((s: RTCRtpSender) => s.track?.kind === newTrack.kind);
            if (sender) {
                sender.replaceTrack(newTrack).catch((err: Error) => {
                    mlog.warn('media', 'replaceTrack peer sender rejected', { err: String(err) });
                });
            } else {
              mlog.v('media', 'safeReplaceTrack: no sender for kind on peer', { kind: newTrack.kind });
            }
        } catch (e) {
            mlog.warn('media', 'replaceTrack error', { err: String(e) });
        }
    });
  }, []);

  const stopAllMedia = useCallback(() => {
    mlog.info('media', 'stopAllMedia');
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
        } catch (e: any) {
            // NotAllowedError — пользователь отменил диалог выбора экрана: не шумим в тосте.
            // Прочие ошибки (NotSupported, AbortError, permission в policy) — логируем и
            // информируем пользователя, иначе UI молчит и выглядит как баг.
            if (e?.name !== 'NotAllowedError') {
                logger.warn('webrtc', 'getDisplayMedia failed', e);
                toast({ variant: 'destructive', title: 'Не удалось запустить демонстрацию экрана' });
            }
        }
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
  }, [isScreenSharing, safeReplaceTrack, firestore, meeting.id, currentUser.id, toast]);

  /**
   * Устойчивость соединения: ICE restart и полный пересоздание peer при провалах.
   *
   * Стратегия:
   *   - `disconnected` (ICE) — мягкий путь: ждём `DISCONNECT_DEBOUNCE_MS`; если состояние не
   *     восстановилось само, инициатор (`currentUser.id < remoteId`) вызывает
   *     `pc.restartIce()` + `p.negotiate()`, что перегоняет offer с новым ICE-сбором.
   *   - `iceConnectionState === 'failed'` и **`connectionState === 'failed'`** — жёсткий путь:
   *     simple-peer часто рвёт PC именно по `connectionState`; без этого слушателя пир
   *     закрывался без `recreatePeer`.
   *   - `failed` — пересоздание: короткий бэкофф, затем `setupPeer` с той же ролью инициатора.
   *   - Защита от петли: не более `MAX_RECONNECTS` пересозданий за `RECONNECT_WINDOW_MS`
   *     на один пир; превышение — оставляем peer закрытым, участник увидит плейсхолдер.
   *   - Ответственным за restart является только initiator-сторона, чтобы не сгенерировать
   *     два одновременных offer с обоих концов.
   *
   * Хук вешается на `p._pc` в `setupPeer`. Таймеры снимаются в `p.on('close')` и при
   * глобальном unmount.
   */
  const DISCONNECT_DEBOUNCE_MS = 4000;
  const RECONNECT_WINDOW_MS = 60000;
  const MAX_RECONNECTS = 3;
  const FAILED_BACKOFF_MS = 1000;

  const recreatePeer = useCallback((remoteId: string) => {
    if (!isMountedRef.current) return;
    const now = Date.now();
    const entry = peerReconnect.current[remoteId] || {
      count: 0,
      lastTriedAt: 0,
      disconnectTimerId: null,
      recreateTimerId: null,
    };
    if (entry.recreateTimerId != null) {
      mlog.v('peer', 'recreatePeer: skip (already scheduled)', { remoteId });
      return;
    }
    if (now - entry.lastTriedAt > RECONNECT_WINDOW_MS) entry.count = 0;
    if (entry.count >= MAX_RECONNECTS) {
      mlog.warn('peer', `recreatePeer: limit reached for ${remoteId}`, {
        remoteId,
        count: entry.count,
        max: MAX_RECONNECTS,
      });
      return;
    }
    entry.count += 1;
    entry.lastTriedAt = now;
    peerReconnect.current[remoteId] = entry;

    const initiator = currentUser.id < remoteId;
    const old = peers.current[remoteId];
    delete peers.current[remoteId];
    creatingPeers.current.delete(remoteId);
    try { if (old && !old.destroyed) old.destroy(); } catch {}

    mlog.info('peer', 'recreatePeer scheduled', {
      remoteId,
      initiator,
      backoffMs: FAILED_BACKOFF_MS,
      attempt: entry.count,
    });
    entry.recreateTimerId = setTimeout(() => {
      const cur = peerReconnect.current[remoteId];
      if (cur) cur.recreateTimerId = null;
      if (!isMountedRef.current) return;
      setupPeerRef.current?.(remoteId, initiator);
    }, FAILED_BACKOFF_MS);
    peerReconnect.current[remoteId] = entry;
  }, [currentUser.id]);

  const attachResilience = useCallback((p: any, remoteId: string) => {
    const pc: RTCPeerConnection | undefined = p?._pc;
    if (!pc) return;

    const initiator = currentUser.id < remoteId;

    const bumpReconnectEntry = () =>
      peerReconnect.current[remoteId] || {
        count: 0,
        lastTriedAt: 0,
        disconnectTimerId: null,
        recreateTimerId: null,
      };

    pc.addEventListener('connectionstatechange', () => {
      if (!isMountedRef.current || p.destroyed) return;
      const cs = pc.connectionState;
      mlog.v('conn', `connectionstatechange remote=${remoteId}`, { remoteId, connectionState: cs });
      const entry = bumpReconnectEntry();
      if (cs === 'connected') {
        if (entry.recreateTimerId) {
          clearTimeout(entry.recreateTimerId);
          entry.recreateTimerId = null;
        }
        entry.count = 0;
        peerReconnect.current[remoteId] = entry;
        mlog.v('conn', `connection healthy remote=${remoteId}`, { connectionState: cs });
        return;
      }
      if (cs === 'failed') {
        mlog.warn('conn', `RTCPeerConnection failed remote=${remoteId}, scheduling recreate`, {
          remoteId,
        });
        recreatePeer(remoteId);
      }
    });

    pc.addEventListener('iceconnectionstatechange', () => {
      if (!isMountedRef.current || p.destroyed) return;
      const state = pc.iceConnectionState;
      const sig = pc.signalingState;
      const ice = pc.iceGatheringState;
      mlog.v('ice', `iceconnectionstatechange remote=${remoteId}`, {
        remoteId,
        iceConnectionState: state,
        signalingState: sig,
        iceGatheringState: ice,
        initiator,
      });
      const entry = bumpReconnectEntry();

      if (state === 'connected' || state === 'completed') {
        if (entry.disconnectTimerId) { clearTimeout(entry.disconnectTimerId); entry.disconnectTimerId = null; }
        if (entry.recreateTimerId) {
          clearTimeout(entry.recreateTimerId);
          entry.recreateTimerId = null;
        }
        entry.count = 0;
        peerReconnect.current[remoteId] = entry;
        mlog.info('ice', `ICE stable remote=${remoteId}`, { state });
        return;
      }

      if (state === 'disconnected') {
        mlog.warn('ice', `ICE disconnected remote=${remoteId}, debounce ${DISCONNECT_DEBOUNCE_MS}ms`, {
          remoteId,
          initiator,
        });
        if (entry.disconnectTimerId) clearTimeout(entry.disconnectTimerId);
        entry.disconnectTimerId = setTimeout(() => {
          if (!isMountedRef.current || p.destroyed) return;
          const curState = pc.iceConnectionState;
          if (curState === 'connected' || curState === 'completed') return;
          if (initiator) {
            try {
              pc.restartIce();
              p.negotiate?.();
              mlog.info('ice', `ICE restart requested remote=${remoteId}`, { curState });
            } catch (e) {
              mlog.warn('ice', `restartIce failed, recreate remote=${remoteId}`, { err: String(e) });
              recreatePeer(remoteId);
            }
          } else {
            mlog.v('ice', 'ICE still bad after disconnect; non-initiator waits for remote', {
              remoteId,
              curState,
            });
          }
        }, DISCONNECT_DEBOUNCE_MS);
        peerReconnect.current[remoteId] = entry;
        return;
      }

      if (state === 'failed') {
        if (entry.disconnectTimerId) { clearTimeout(entry.disconnectTimerId); entry.disconnectTimerId = null; }
        peerReconnect.current[remoteId] = entry;
        mlog.warn('ice', `ICE failed, recreating peer remote=${remoteId}`, { remoteId });
        recreatePeer(remoteId);
      }
    });
  }, [currentUser.id, recreatePeer]);

  /**
   * Нужен forward-ref, т.к. `recreatePeer` вызывает `setupPeer`, а `setupPeer` ниже.
   * Альтернатива — реорганизовать файл; минимальное изменение через ref безопаснее.
   */
  const setupPeerRef = useRef<((remoteId: string, initiator: boolean) => Promise<any>) | null>(null);

  const setupPeer = useCallback(async (remoteId: string, initiator: boolean) => {
    if (!isMountedRef.current) {
      mlog.v('peer', 'setupPeer skipped: unmounted', { remoteId, initiator });
      return null;
    }
    if (peers.current[remoteId]) {
      mlog.v('peer', 'setupPeer skipped: peer exists', { remoteId, initiator });
      return null;
    }
    if (creatingPeers.current.has(remoteId)) {
      mlog.v('peer', 'setupPeer skipped: already creating', { remoteId, initiator });
      return null;
    }
    if (!localStreamRef.current) {
      mlog.warn('peer', 'setupPeer skipped: no localStreamRef', { remoteId, initiator });
      return null;
    }
    const localTracks = localStreamRef.current.getTracks().map((t) => ({
      kind: t.kind,
      id: t.id,
      enabled: t.enabled,
    }));
    mlog.info('peer', 'setupPeer start', { remoteId, initiator, localTracks });
    creatingPeers.current.add(remoteId);
    
    try {
        const Peer = (await import('simple-peer')).default;
        const rtcConfig = await getWebRtcIceConfig();
        mlog.v('peer', 'setupPeer ICE config', {
          remoteId,
          ...summarizeRtcConfiguration(rtcConfig),
        });
        const p = new Peer({
          initiator,
          trickle: true,
          stream: localStreamRef.current || undefined,
          config: rtcConfig,
        });

        p.on('signal', (data: any) => {
          if (firestore && !p.destroyed && isMountedRef.current) {
            const summary = summarizeSignalPayload(data);
            mlog.v('signal', `outgoing → ${remoteId}`, { remoteId, ...summary });
            setDoc(doc(collection(firestore, `meetings/${meeting.id}/signals`)), {
              from: currentUser.id, to: remoteId, type: data.type || 'candidate', data, createdAt: serverTimestamp()
            }).catch((e) => {
              mlog.err('signal', 'setDoc signals failed', e, { remoteId, ...summary });
            });
          } else {
            mlog.v('signal', 'outgoing dropped (no firestore or destroyed)', {
              remoteId,
              hasFirestore: !!firestore,
              peerDestroyed: p.destroyed,
              mounted: isMountedRef.current,
            });
          }
        });

        p.on('stream', (remoteStream: MediaStream) => {
          if (!isMountedRef.current) return;
          const at = remoteStream.getAudioTracks().length;
          const vt = remoteStream.getVideoTracks().length;
          mlog.info('peer', `remote stream from ${remoteId}`, {
            remoteId,
            audioTracks: at,
            videoTracks: vt,
            streamId: remoteStream.id,
          });
          setParticipants(prev => ({ ...prev, [remoteId]: { ...prev[remoteId], id: remoteId, stream: remoteStream } }));
        });

        p.on('error', (err: any) => { 
            mlog.err('peer', `simple-peer error remote=${remoteId}`, err, { remoteId, initiator });
            creatingPeers.current.delete(remoteId); 
        });

        // Метрики качества соединения; отписка — при close.
        const statsPc = getSimplePeerRTCPeerConnection(p);
        const unsubStats = statsPc
          ? watchPeerStats(statsPc, (sample) => {
              if (!isMountedRef.current) return;
              setParticipants(prev => prev[remoteId]
                ? ({ ...prev, [remoteId]: { ...prev[remoteId], connectionQuality: sample.quality } })
                : prev);
            })
          : () => {};

        p.on('close', () => { 
            if (!isMountedRef.current) return;
            mlog.info('peer', `peer close remote=${remoteId}`, { remoteId, initiator });
            try { unsubStats(); } catch {}
            setParticipants(prev => {
                const next = { ...prev };
                delete next[remoteId];
                return next;
            });
            const entry = peerReconnect.current[remoteId];
            if (entry?.disconnectTimerId) { clearTimeout(entry.disconnectTimerId); entry.disconnectTimerId = null; }
            // Не трогаем recreateTimerId: при ICE/connection failed `recreatePeer` ставит таймер на
            // новый setupPeer, затем simple-peer закрывает пир — отмена здесь ломала автопереподключение.
            delete peers.current[remoteId]; 
            creatingPeers.current.delete(remoteId);
            delete pendingSignalsByPeerRef.current[remoteId];
        });

        attachResilience(p, remoteId);

        peers.current[remoteId] = p;
        creatingPeers.current.delete(remoteId);
        const queued = pendingSignalsByPeerRef.current[remoteId];
        if (queued?.length) {
          mlog.info('signal', `flush ${queued.length} queued signal(s) for ${remoteId}`, { remoteId });
          for (const data of queued) {
            try {
              if (!p.destroyed) (p as { signal: (d: unknown) => void }).signal(data);
            } catch (e) {
              mlog.err('signal', `queued signal apply failed remote=${remoteId}`, e);
            }
          }
          delete pendingSignalsByPeerRef.current[remoteId];
        }
        mlog.info('peer', 'setupPeer ready', { remoteId, initiator });
        return p;
    } catch (err) {
        mlog.err('peer', 'setupPeer load/construct failed', err, { remoteId, initiator });
        creatingPeers.current.delete(remoteId);
        const dropped = pendingSignalsByPeerRef.current[remoteId]?.length ?? 0;
        if (dropped) {
          mlog.warn('signal', `dropping ${dropped} queued signals (setupPeer failed)`, { remoteId });
          delete pendingSignalsByPeerRef.current[remoteId];
        }
        return null;
    }
  }, [firestore, meeting.id, currentUser.id, attachResilience]);

  useEffect(() => {
    setupPeerRef.current = setupPeer;
  }, [setupPeer]);

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
        } catch (e) {
          mlog.err('virtualBg', 'SelfieSegmentation engine init failed', e);
        }
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
        mlog.info('media', 'getUserMedia OK', {
          audioTracks: stream.getAudioTracks().length,
          videoTracks: stream.getVideoTracks().length,
          isVideoOffInitial: isVideoOff,
          isMicMutedInitial: isMicMuted,
        });
      } catch (e) {
        mlog.err('media', 'getUserMedia failed', e, { isVideoOff, isMicMuted });
        if (isMounted) setIsMediaReady(true);
      }
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
    if (!firestore || !currentUser.id || !isMediaReady || !isParticipantSynced) return;
    const myRef = doc(firestore, `meetings/${meeting.id}/participants`, currentUser.id);
    updateDoc(myRef, { 
        backgroundConfig: { type: backgroundConfig.type, url: backgroundConfig.url || null }, 
        lastSeen: new Date().toISOString() 
    }).catch(() => {});
  }, [backgroundConfig, firestore, meeting.id, currentUser.id, isMediaReady, isParticipantSynced]);

  useEffect(() => {
    if (!firestore || !currentUser.id || !isMediaReady) {
      setIsParticipantSynced(false);
      return;
    }

    let isMounted = true;
    setIsParticipantSynced(false);
    const myRef = doc(firestore, `meetings/${meeting.id}/participants`, currentUser.id);

    let heartbeat: ReturnType<typeof setInterval> | undefined;
    let unsubMyDoc: (() => void) | undefined;
    let unsubParticipants: (() => void) | undefined;
    let unsubSignals: (() => void) | undefined;
    let tokenRefreshTimer: ReturnType<typeof setInterval> | undefined;
    let pageHideHandler: (() => void) | undefined;

    mlog.info('lifecycle', 'participant effect: registering in Firestore', {
      isMediaReady,
      path: `meetings/${meeting.id}/participants/${currentUser.id}`,
    });

    void (async () => {
      try {
        await setDoc(
          myRef,
          {
            id: currentUser.id,
            name: initialSettings.name || currentUser.name,
            avatar: currentUser.avatar || '',
            avatarThumb: currentUser.avatarThumb?.trim() || '',
            role: currentUser.role || 'worker',
            joinedAt: serverTimestamp(),
            lastSeen: new Date().toISOString(),
            isAudioMuted: isMicMuted,
            isVideoMuted: isVideoOff,
            isHandRaised: isHandRaised,
            backgroundConfig: { type: backgroundConfig.type, url: backgroundConfig.url || null },
          },
          { merge: true },
        );
        mlog.info('lifecycle', 'participant setDoc OK', { participantPath: myRef.path });
      } catch (e) {
        mlog.err('lifecycle', 'participant setDoc failed', e);
        if (isMounted) {
          toast({
            variant: 'destructive',
            title: 'Не удалось войти в комнату',
            description: 'Проверьте доступ к встрече и попробуйте снова.',
          });
        }
        return;
      }

      if (!isMounted) return;
      setIsParticipantSynced(true);
      mlog.info('lifecycle', 'isParticipantSynced=true, attaching listeners');

      heartbeat = setInterval(() => {
        if (!isMounted) return;
        updateDoc(myRef, { lastSeen: new Date().toISOString() }).catch(() => {});
      }, 20000);

      // Гарантированный leave при закрытии вкладки/браузера/приложения.
      // React-cleanup deleteDoc не успевает на pagehide, потому что Firestore SDK
      // ставит запрос в очередь и неблокирующе шлёт его — браузер прерывает.
      // Используем `fetch keepalive` к Firestore REST (DELETE), который браузер
      // обязан довести до конца, даже если страница уже исчезла.
      const leaveUrl = `https://firestore.googleapis.com/v1/projects/${firebaseConfig.projectId}/databases/(default)/documents/meetings/${meeting.id}/participants/${currentUser.id}`;
      let cachedIdToken: string | null = null;
      const refreshIdToken = async () => {
        try {
          const u = getAuth().currentUser;
          if (!u) return;
          cachedIdToken = await u.getIdToken();
        } catch (e) {
          mlog.v('lifecycle', 'cache idToken failed', { err: String(e) });
        }
      };
      void refreshIdToken();
      tokenRefreshTimer = setInterval(refreshIdToken, 30 * 60 * 1000);
      pageHideHandler = () => {
        if (!cachedIdToken) return;
        try {
          fetch(leaveUrl, {
            method: 'DELETE',
            headers: { Authorization: `Bearer ${cachedIdToken}` },
            keepalive: true,
          }).catch(() => {});
        } catch {}
      };
      window.addEventListener('pagehide', pageHideHandler);
      window.addEventListener('beforeunload', pageHideHandler);

      unsubMyDoc = onSnapshot(myRef, (snap) => {
        if (!isMounted) return;
        if (!snap.exists()) {
            mlog.warn('participantDoc', 'own participant doc deleted (kicked?)');
            // Ejection logic: if our document is gone, we are out
            if (isMediaReady) {
                stopAllMedia();
                router.push('/dashboard/meetings');
                toast({ variant: 'destructive', title: 'Вы были исключены', description: 'Вас удалили из конференции.' });
            }
            return;
        }
        const data = snap.data();
        mlog.v('participantDoc', 'snapshot', {
          hasForceMuteAudio: !!data.forceMuteAudio,
          hasForceMuteVideo: !!data.forceMuteVideo,
          metadataFromCache: snap.metadata.fromCache,
        });
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

      unsubParticipants = onSnapshot(collection(firestore, `meetings/${meeting.id}/participants`), (snap) => {
      if (!isMounted) return;
      const changes = snap.docChanges().map((c) => ({
        type: c.type,
        id: c.doc.id,
      }));
      mlog.v('participants', `collection snapshot docs=${snap.size} changes=${changes.length}`, {
        docIds: snap.docs.map((d) => d.id),
        changes,
        fromCache: snap.metadata.fromCache,
      });
      snap.docChanges().forEach(async (change) => {
        const remoteId = change.doc.id;
        if (remoteId === currentUser.id) return;
        if (change.type === 'added') {
          mlog.info('participants', `doc added ${remoteId}`, {
            willInitiate: currentUser.id < remoteId,
          });
          setParticipants(prev => ({ ...prev, [remoteId]: { ...change.doc.data(), id: remoteId } as ParticipantState }));
          if (currentUser.id < remoteId) setupPeer(remoteId, true);
        } else if (change.type === 'modified') {
          mlog.v('participants', `doc modified ${remoteId}`);
          setParticipants(prev => ({ ...prev, [remoteId]: { ...prev[remoteId], ...change.doc.data() } as ParticipantState }));
        } else if (change.type === 'removed') {
          mlog.info('participants', `doc removed ${remoteId}`);
          setParticipants(prev => { const next = { ...prev }; delete next[remoteId]; return next; });
          const reEntry = peerReconnect.current[remoteId];
          if (reEntry?.disconnectTimerId) clearTimeout(reEntry.disconnectTimerId);
          if (reEntry?.recreateTimerId) clearTimeout(reEntry.recreateTimerId);
          delete peerReconnect.current[remoteId];
          const peerToDestroy = peers.current[remoteId];
          if (peerToDestroy) {
            delete peers.current[remoteId];
            creatingPeers.current.delete(remoteId);
            setTimeout(() => {
                try { if (peerToDestroy && !peerToDestroy.destroyed) peerToDestroy.destroy(); } catch (e) {
                  mlog.v('participants', 'peer destroy after remove failed', { remoteId, err: String(e) });
                }
            }, 0);
          }
        }
      });
      // Подстраховка mesh: иногда начальный snapshot не отдаёт всех в docChanges так,
      // что инициатор не вызывает setupPeer — тогда пиры не видят/не слышат друг друга.
      let meshRepairIndex = 0;
      for (const d of snap.docs) {
        const remoteId = d.id;
        if (remoteId === currentUser.id) continue;
        if (currentUser.id >= remoteId) continue;
        if (peers.current[remoteId] || creatingPeers.current.has(remoteId)) continue;
        if (!localStreamRef.current) continue;
        const staggerMs = meshRepairIndex * 160;
        meshRepairIndex += 1;
        mlog.info('participants', `mesh repair: ensure initiator peer → ${remoteId}`, { staggerMs });
        setParticipants(prev => ({
          ...prev,
          [remoteId]: { ...d.data(), ...prev[remoteId], id: remoteId } as ParticipantState,
        }));
        setTimeout(() => {
          if (!isMounted) return;
          if (peers.current[remoteId] || creatingPeers.current.has(remoteId)) return;
          if (!localStreamRef.current) return;
          void setupPeer(remoteId, true);
        }, staggerMs);
      }
    });

      unsubSignals = onSnapshot(query(collection(firestore, `meetings/${meeting.id}/signals`), where('to', '==', currentUser.id)), (snap) => {
      if (!isMounted) return;
      void (async () => {
        for (const change of snap.docChanges()) {
          if (change.type !== 'added') continue;
          const signal = change.doc.data() as MeetingSignal;
          const from = signal.from;
          const payload = normalizeInboundSignalForSimplePeer(signal);
          const summary = summarizeSignalPayload(payload);
          mlog.v('signal', `incoming from=${from}`, {
            from,
            type: signal.type,
            ...summary,
          });

          let p = peers.current[from];
          if (!p && !creatingPeers.current.has(from)) {
            mlog.info('signal', `creating peer as answerer for ${from}`);
            await setupPeer(from, false);
          }
          p = peers.current[from];

          if (p && !p.destroyed) {
            try {
              p.signal(payload);
            } catch (e) {
              mlog.err('signal', `p.signal() failed from=${from}`, e, summary);
            }
          } else if (creatingPeers.current.has(from)) {
            pendingSignalsByPeerRef.current[from] ??= [];
            pendingSignalsByPeerRef.current[from].push(payload);
            mlog.v('signal', 'queued (peer still creating)', {
              from,
              queueLen: pendingSignalsByPeerRef.current[from].length,
            });
          } else {
            mlog.warn('signal', 'no peer to apply signal', { from, hadPeer: !!p });
          }

          await deleteDoc(change.doc.ref).catch((e) => {
            mlog.v('signal', 'deleteDoc signal failed (non-fatal)', { err: String(e) });
          });
        }
      })();
    });
    })();

    return () => {
        mlog.info('lifecycle', 'participant effect cleanup: leave meeting listeners');
        isMounted = false;
        setIsParticipantSynced(false);
        if (heartbeat) clearInterval(heartbeat);
        if (tokenRefreshTimer) clearInterval(tokenRefreshTimer);
        if (pageHideHandler) {
          window.removeEventListener('pagehide', pageHideHandler);
          window.removeEventListener('beforeunload', pageHideHandler);
        }
        unsubMyDoc?.();
        unsubParticipants?.();
        unsubSignals?.();
        if (firestore && currentUser.id) {
          deleteDoc(doc(firestore, `meetings/${meeting.id}/participants`, currentUser.id)).catch((e) => {
            mlog.v('lifecycle', 'deleteDoc own participant on cleanup failed', { err: String(e) });
          });
        }
    };
  }, [firestore, meeting.id, currentUser.id, isMediaReady, setupPeer, router, stopAllMedia, toast, initialSettings]);

  return {
    participants, localStream, isMicMuted, isVideoOff, isScreenSharing, isHandRaised, backgroundConfig, facingMode,
    toggleMic, toggleVideo, toggleHand, switchCamera, toggleScreenShare, setBackgroundConfig, stopAllMedia, 
    isParticipantSynced,
    setIsHandRaised: (val: boolean) => { 
        setIsHandRaised(val); 
        if (firestore) updateDoc(doc(firestore, `meetings/${meeting.id}/participants`, currentUser.id), { isHandRaised: val, lastSeen: new Date().toISOString() });
    }
  };
}
