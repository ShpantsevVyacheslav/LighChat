'use client';

import React, { useState, useRef, useEffect, useCallback, useMemo } from 'react';
import { createPortal } from 'react-dom';
import { useI18n } from '@/hooks/use-i18n';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Slider } from '@/components/ui/slider';
import { 
  X, Check, RotateCw, Volume2, VolumeX, 
  Pencil, Trash2, Undo2, Loader2, SendHorizonal,
  Play, Pause, Crop, RefreshCcw, 
  Image as ImageIcon, Clock
} from 'lucide-react';
import { cn } from '@/lib/utils';
import { logger } from '@/lib/logger';
import {
  clientDeltaToVideoDelta,
  elementPointToVideoIntrinsics,
  intrinsicCropRectToOverlayBoxPx,
} from '@/lib/video-editor-display-geometry';

interface VideoEditorModalProps {
  file: File;
  onSave: (editedFile: File, caption?: string) => void;
  onClose: () => void;
}

const COLORS = [
  { name: 'white', hex: '#FFFFFF' },
  { name: 'blue', hex: '#3b82f6' },
  { name: 'green', hex: '#22c55e' },
  { name: 'yellow', hex: '#eab308' },
  { name: 'red', hex: '#ef4444' },
];

const ASPECT_RATIOS = [
    { label: 'Free', value: 'free' },
    { label: '1:1', value: 1 },
    { label: '4:5', value: 4/5 },
    { label: '16:9', value: 16/9 },
    { label: '9:16', value: 9/16 },
];

type ToolType = 'none' | 'draw' | 'crop';
type ResizeHandle = 'nw' | 'ne' | 'sw' | 'se' | 'n' | 's' | 'e' | 'w';

/** Без `opus` в типе Chrome часто пишет только видео — звук в файле пропадает. */
function pickVideoRecorderMimeType(includeAudio: boolean): string | undefined {
  const withAudio = [
    'video/webm;codecs=vp9,opus',
    'video/webm;codecs=vp8,opus',
    'video/webm;codecs=vp9',
    'video/webm;codecs=vp8',
    'video/webm',
  ];
  const videoOnly = [
    'video/webm;codecs=vp9',
    'video/webm;codecs=vp8',
    'video/webm',
    'video/mp4',
  ];
  const candidates = includeAudio ? withAudio : videoOnly;
  for (const c of candidates) {
    if (typeof MediaRecorder !== 'undefined' && MediaRecorder.isTypeSupported(c)) {
      return c;
    }
  }
  return undefined;
}

interface Rect {
  x: number;
  y: number;
  width: number;
  height: number;
}

interface EditorState {
    rotation: number;
    cropRect: Rect;
    isMuted: boolean;
    range: [number, number];
    canvasData: string | null;
}

export function VideoEditorModal({ file, onSave, onClose }: VideoEditorModalProps) {
  const { t } = useI18n();
  const [mounted, setMounted] = useState(false);
  const [videoUrl, setVideoUrl] = useState<string | null>(null);
  const [isProcessing, setIsProcessing] = useState(false);
  const [processingProgress, setProcessingProgress] = useState(0);
  const [thumbnails, setThumbnails] = useState<string[]>([]);
  const [isThumbnailsLoading, setIsThumbnailsLoading] = useState(false);
  const [thumbnailProgress, setThumbnailProgress] = useState(0);
  const [isHovered, setIsHovered] = useState(false);
  
  const [duration, setDuration] = useState(0);
  const [currentTime, setCurrentTime] = useState(0);
  const [isPlaying, setIsPlaying] = useState(false);
  const [isMuted, setIsMuted] = useState(false);
  const [rotation, setRotation] = useState(0);
  const [range, setRange] = useState<[number, number]>([0, 100]);
  const [cropRect, setCropRect] = useState<Rect | null>(null);
  const [selectedRatio, setSelectedRatio] = useState<string | number>('free');
  
  const [activeTool, setActiveTool] = useState<ToolType>('none');
  const [brushColor, setBrushColor] = useState(COLORS[4].hex);
  const [brushSize, setBrushSize] = useState(8);
  const [caption, setCaption] = useState('');
  const [history, setHistory] = useState<EditorState[]>([]);
  
  const [tempCropRect, setTempCropRect] = useState<Rect | null>(null);
  const [isResizingCrop, setIsResizingCrop] = useState(false);
  const [isDraggingCrop, setIsDraggingCrop] = useState(false);
  
  const videoRef = useRef<HTMLVideoElement>(null);
  const drawCanvasRef = useRef<HTMLCanvasElement>(null);
  const processingCanvasRef = useRef<HTMLCanvasElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  
  const isDrawing = useRef(false);
  const activeHandle = useRef<ResizeHandle | null>(null);
  const startPos = useRef({ x: 0, y: 0, rect: { x: 0, y: 0, width: 0, height: 0 } });
  const [, setVideoLayoutTick] = useState(0);

  useEffect(() => {
    setMounted(true);
    const url = URL.createObjectURL(file);
    setVideoUrl(url);
    return () => { if (url) URL.revokeObjectURL(url); };
  }, [file]);

  const startTime = useMemo(() => {
    if (!isFinite(duration) || duration <= 0) return 0;
    return (range[0] / 100) * duration;
  }, [range, duration]);

  const endTime = useMemo(() => {
    if (!isFinite(duration) || duration <= 0) return 0;
    return (range[1] / 100) * duration;
  }, [range, duration]);

  const formatMMSS = (seconds: number) => {
    if (!isFinite(seconds) || seconds < 0) return '00:00';
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  };

  const saveToHistory = useCallback(() => {
    const currentState: EditorState = {
        rotation,
        cropRect: cropRect || { x: 0, y: 0, width: videoRef.current?.videoWidth || 0, height: videoRef.current?.videoHeight || 0 },
        isMuted,
        range: [...range],
        canvasData: drawCanvasRef.current?.toDataURL() || null
    };
    setHistory(prev => [...prev, currentState]);
  }, [rotation, cropRect, isMuted, range]);

  const handleUndo = () => {
    if (history.length === 0) return;
    const last = history[history.length - 1];
    setHistory(prev => prev.slice(0, -1));

    setRotation(last.rotation);
    setCropRect(last.cropRect);
    setTempCropRect(last.cropRect);
    setIsMuted(last.isMuted);
    setRange(last.range);

    if (last.canvasData && drawCanvasRef.current) {
        const img = new Image();
        img.src = last.canvasData;
        img.onload = () => {
            const ctx = drawCanvasRef.current?.getContext('2d');
            ctx?.clearRect(0, 0, drawCanvasRef.current!.width, drawCanvasRef.current!.height);
            ctx?.drawImage(img, 0, 0);
        };
    } else {
        const ctx = drawCanvasRef.current?.getContext('2d');
        ctx?.clearRect(0, 0, drawCanvasRef.current!.width, drawCanvasRef.current!.height);
    }
  };

  const handleResetAll = () => {
    setHistory([]);
    setRotation(0);
    const v = videoRef.current;
    if (v) {
        const initialRect = { x: 0, y: 0, width: v.videoWidth, height: v.videoHeight };
        setCropRect(initialRect);
        setTempCropRect(initialRect);
    }
    setIsMuted(false);
    setRange([0, 100]);
    setActiveTool('none');
    const ctx = drawCanvasRef.current?.getContext('2d');
    ctx?.clearRect(0, 0, drawCanvasRef.current!.width, drawCanvasRef.current!.height);
  };

  const handleRotate = () => {
    saveToHistory();
    setRotation((prev) => (prev + 90) % 360);
  };

  useEffect(() => {
    if (!videoUrl) return;
    
    const generate = async () => {
        setIsThumbnailsLoading(true);
        setThumbnailProgress(0);
        
        const v = document.createElement('video');
        v.src = videoUrl; 
        v.muted = true; 
        v.playsInline = true;
        v.preload = "metadata";
        
        try {
            await new Promise((resolve, reject) => {
                const timeout = setTimeout(() => reject(new Error("Metadata timeout")), 5000);
                v.onloadedmetadata = () => {
                    clearTimeout(timeout);
                    resolve(null);
                };
                if (v.readyState >= 1) {
                    clearTimeout(timeout);
                    resolve(null);
                }
            });

            let videoDuration = v.duration;
            if (videoDuration === Infinity) {
                v.currentTime = 1e10; 
                await new Promise(r => {
                    const onSeeked = () => { v.removeEventListener('seeked', onSeeked); r(null); };
                    v.addEventListener('seeked', onSeeked);
                });
                videoDuration = v.duration;
                v.currentTime = 0.1;
                await new Promise(r => {
                    const onSeeked = () => { v.removeEventListener('seeked', onSeeked); r(null); };
                    v.addEventListener('seeked', onSeeked);
                });
            }

            setDuration(videoDuration);

            const count = 10;
            const thumbs = [];
            const canvas = document.createElement('canvas');
            canvas.width = 160; canvas.height = 90;
            const ctx = canvas.getContext('2d', { alpha: false });
            
            for (let i = 0; i < count; i++) {
                const seekTime = Math.max(0.1, (i / (count - 1)) * videoDuration);
                if (isFinite(seekTime)) {
                    v.currentTime = seekTime;
                    await new Promise(r => {
                        const onSeeked = () => { v.removeEventListener('seeked', onSeeked); r(null); };
                        v.addEventListener('seeked', onSeeked);
                    });
                    ctx?.drawImage(v, 0, 0, canvas.width, canvas.height);
                    thumbs.push(canvas.toDataURL('image/jpeg', 0.5));
                    setThumbnailProgress(Math.round(((i + 1) / count) * 100));
                }
            }
            setThumbnails(thumbs);
        } catch (err: unknown) {
            const msg = err instanceof Error ? err.message : String(err);
            logger.error('video-editor', 'Thumbnails error', msg);
        } finally {
            setIsThumbnailsLoading(false);
        }
    };
    generate();
  }, [videoUrl]);

  useEffect(() => {
    const v = videoRef.current;
    if (!v) return;
    const onTimeUpdate = () => {
      if (!isFinite(v.currentTime)) return;
      setCurrentTime(v.currentTime);
      if (v.currentTime >= endTime - 0.1) v.currentTime = startTime;
      if (v.currentTime < startTime) v.currentTime = startTime;
    };
    v.addEventListener('timeupdate', onTimeUpdate);
    return () => v.removeEventListener('timeupdate', onTimeUpdate);
  }, [startTime, endTime]);

  const handleLoadedMetadata = async (e: React.SyntheticEvent<HTMLVideoElement>) => {
    const v = e.currentTarget;
    let videoDuration = v.duration;
    
    if (videoDuration === Infinity) {
        v.currentTime = 1e10;
        await new Promise(r => {
            const onSeeked = () => { v.removeEventListener('seeked', onSeeked); r(null); };
            v.addEventListener('seeked', onSeeked);
        });
        videoDuration = v.duration;
        v.currentTime = 0.1;
    }

    if (isFinite(videoDuration)) {
        setDuration(videoDuration);
        const initialRect = { x: 0, y: 0, width: v.videoWidth, height: v.videoHeight };
        setCropRect(initialRect);
        setTempCropRect(initialRect);
        if (drawCanvasRef.current) {
            drawCanvasRef.current.width = v.videoWidth;
            drawCanvasRef.current.height = v.videoHeight;
        }
    }
  };

  useEffect(() => {
    const el = videoRef.current;
    if (!el) return;
    const ro = new ResizeObserver(() => setVideoLayoutTick((t) => t + 1));
    ro.observe(el);
    return () => ro.disconnect();
  }, [videoUrl]);

  const startDrawing = useCallback((e: React.MouseEvent | React.TouchEvent) => {
    if (activeTool !== 'draw' || isProcessing || !drawCanvasRef.current || !videoRef.current) return;
    const canvas = drawCanvasRef.current;
    const video = videoRef.current;
    const clientX = 'touches' in e ? e.touches[0].clientX : e.clientX;
    const clientY = 'touches' in e ? e.touches[0].clientY : e.clientY;
    const br = video.getBoundingClientRect();
    const p = elementPointToVideoIntrinsics(video, clientX - br.left, clientY - br.top);
    if (!p) return;
    const x = p.x;
    const y = p.y;
    const ctx = canvas.getContext('2d');
    if (ctx) {
      saveToHistory();
      isDrawing.current = true;
      ctx.beginPath(); ctx.moveTo(x, y);
      ctx.strokeStyle = brushColor; ctx.lineWidth = brushSize;
      ctx.lineCap = 'round'; ctx.lineJoin = 'round';
    }
  }, [activeTool, isProcessing, brushColor, brushSize, saveToHistory]);

  const draw = useCallback((e: React.MouseEvent | React.TouchEvent) => {
    if (!isDrawing.current || !drawCanvasRef.current || !videoRef.current) return;
    const canvas = drawCanvasRef.current;
    const video = videoRef.current;
    const clientX = 'touches' in e ? e.touches[0].clientX : e.clientX;
    const clientY = 'touches' in e ? e.touches[0].clientY : e.clientY;
    const br = video.getBoundingClientRect();
    const p = elementPointToVideoIntrinsics(video, clientX - br.left, clientY - br.top);
    if (!p) return;
    const ctx = canvas.getContext('2d');
    if (ctx) {
      ctx.lineTo(p.x, p.y);
      ctx.stroke();
    }
  }, []);

  const stopDrawing = useCallback(() => {
    isDrawing.current = false;
  }, []);

  const onCropDown = (e: React.MouseEvent | React.TouchEvent, handle: ResizeHandle | 'drag') => {
    e.stopPropagation();
    if (!tempCropRect || !videoRef.current) return;
    const clientX = 'touches' in e ? e.touches[0].clientX : e.clientX;
    const clientY = 'touches' in e ? e.touches[0].clientY : e.clientY;
    if (handle === 'drag') setIsDraggingCrop(true); else { setIsResizingCrop(true); activeHandle.current = handle; }
    startPos.current = { x: clientX, y: clientY, rect: { ...tempCropRect } };
  };

  useEffect(() => {
    if (!isResizingCrop && !isDraggingCrop) return;
    const onMove = (e: MouseEvent | TouchEvent) => {
      if (!videoRef.current) return;
      const clientX = 'touches' in e ? e.touches[0].clientX : e.clientX;
      const clientY = 'touches' in e ? e.touches[0].clientY : e.clientY;

      const dClientX = clientX - startPos.current.x;
      const dClientY = clientY - startPos.current.y;
      const delta = clientDeltaToVideoDelta(videoRef.current, dClientX, dClientY);
      if (!delta) return;
      const { dx, dy } = delta;

      const newRect = { ...startPos.current.rect };
      if (isDraggingCrop) { 
          newRect.x += dx; 
          newRect.y += dy; 
      } else {
          const h = activeHandle.current;
          if (h?.includes('n')) { newRect.y += dy; newRect.height -= dy; }
          if (h?.includes('s')) { newRect.height += dy; }
          if (h?.includes('w')) { newRect.x += dx; newRect.width -= dx; }
          if (h?.includes('e')) { newRect.width += dx; }
          
          if (typeof selectedRatio === 'number') {
              if (h === 'e' || h === 'w' || h === 'n' || h === 's') {
                  if (h === 'e' || h === 'w') newRect.height = newRect.width / selectedRatio;
                  else newRect.width = newRect.height * selectedRatio;
              } else {
                  newRect.height = newRect.width / selectedRatio;
              }
          }
      }
      
      const vw = videoRef.current.videoWidth; const vh = videoRef.current.videoHeight;
      if (newRect.width < 50) newRect.width = 50; if (newRect.height < 50) newRect.height = 50;
      if (newRect.x < 0) newRect.x = 0; if (newRect.y < 0) newRect.y = 0;
      if (newRect.x + newRect.width > vw) newRect.x = vw - newRect.width;
      if (newRect.y + newRect.height > vh) newRect.y = vh - newRect.height;
      setTempCropRect(newRect);
    };
    const onUp = () => { setIsResizingCrop(false); setIsDraggingCrop(false); activeHandle.current = null; };
    window.addEventListener('mousemove', onMove); window.addEventListener('mouseup', onUp);
    window.addEventListener('touchmove', onMove); window.addEventListener('touchend', onUp);
    return () => { window.removeEventListener('mousemove', onMove); window.removeEventListener('mouseup', onUp); window.removeEventListener('touchmove', onMove); window.removeEventListener('touchend', onUp); };
  }, [isResizingCrop, isDraggingCrop, selectedRatio]);

  const applyCrop = () => { saveToHistory(); setCropRect(tempCropRect); setActiveTool('none'); };
  const cancelCrop = () => { setTempCropRect(cropRect); setActiveTool('none'); };

  const handleFinish = async () => {
    const v = videoRef.current; const drawCanvas = drawCanvasRef.current; const procCanvas = processingCanvasRef.current;
    if (!v || !procCanvas || !drawCanvas || !isFinite(startTime) || !isFinite(endTime) || !cropRect) return;

    const ctx = procCanvas.getContext('2d');
    if (!ctx) return;

    const rw = cropRect.width;
    const rh = cropRect.height;
    const rotNorm = ((rotation % 360) + 360) % 360;
    const outW = rotNorm % 180 === 0 ? rw : rh;
    const outH = rotNorm % 180 === 0 ? rh : rw;
    procCanvas.width = outW;
    procCanvas.height = outH;

    const composite = document.createElement('canvas');
    composite.width = rw;
    composite.height = rh;
    const cctx = composite.getContext('2d');
    if (!cctx) return;

    setIsProcessing(true);
    v.pause();

    const prevMuted = v.muted;
    const prevVolume = v.volume;

    v.currentTime = startTime;
    await new Promise(res => { const onS = () => { v.removeEventListener('seeked', onS); res(null); }; v.addEventListener('seeked', onS); });

    /** Звук в файл: элемент не должен быть muted; громкость 0 — чтобы не орало в динамики при кодировании. */
    if (!isMuted) {
      v.muted = false;
      v.volume = 0;
    } else {
      v.muted = true;
    }

    try {
      await v.play();
    } catch (playErr) {
      logger.error('video-editor', 'play before encode failed', playErr);
      v.muted = prevMuted;
      v.volume = prevVolume;
      setIsProcessing(false);
      return;
    }

    await new Promise<void>((r) => {
      requestAnimationFrame(() => r());
    });

    const stream = procCanvas.captureStream(30);

    let hasAudioTrack = false;
    if (!isMuted && typeof (v as HTMLVideoElement & { captureStream?: () => MediaStream }).captureStream === 'function') {
      try {
        const vStream = (v as HTMLVideoElement & { captureStream: () => MediaStream }).captureStream();
        for (const t of vStream.getAudioTracks()) {
          stream.addTrack(t);
          hasAudioTrack = true;
        }
      } catch (audioErr) {
        logger.warn('video-editor', 'captureStream audio', audioErr);
      }
    }

    const mimeType = pickVideoRecorderMimeType(hasAudioTrack);
    let recorder: MediaRecorder;
    try {
      recorder =
        mimeType != null
          ? new MediaRecorder(stream, { mimeType })
          : new MediaRecorder(stream);
    } catch (e) {
      logger.error('video-editor', 'MediaRecorder constructor failed', e);
      v.pause();
      v.muted = prevMuted;
      v.volume = prevVolume;
      setIsProcessing(false);
      return;
    }
    const chunks: Blob[] = [];
    const outType = recorder.mimeType || pickVideoRecorderMimeType(hasAudioTrack) || 'video/webm';
    const outExt = outType.includes('mp4') ? 'mp4' : 'webm';
    recorder.ondataavailable = (e) => chunks.push(e.data);
    recorder.onstop = () => {
      v.pause();
      v.muted = prevMuted;
      v.volume = prevVolume;
      const processedFile = new File(
        [new Blob(chunks, { type: outType })],
        `processed.${outExt}`,
        { type: outType },
      );
      setIsProcessing(false);
      onSave(processedFile, caption);
    };

    try {
      recorder.start();
    } catch (recErr) {
      logger.error('video-editor', 'MediaRecorder.start failed', recErr);
      v.pause();
      v.muted = prevMuted;
      v.volume = prevVolume;
      setIsProcessing(false);
      return;
    }

    const renderFrame = () => {
      if (v.currentTime >= endTime - 0.05 || v.paused) {
        if (recorder.state === 'recording') recorder.stop();
        return;
      }

      cctx.fillStyle = '#000000';
      cctx.fillRect(0, 0, rw, rh);
      cctx.drawImage(v, cropRect.x, cropRect.y, cropRect.width, cropRect.height, 0, 0, rw, rh);
      cctx.drawImage(drawCanvas, cropRect.x, cropRect.y, cropRect.width, cropRect.height, 0, 0, rw, rh);

      ctx.fillStyle = '#000000';
      ctx.fillRect(0, 0, outW, outH);
      ctx.save();
      ctx.translate(outW / 2, outH / 2);
      ctx.rotate((rotNorm * Math.PI) / 180);
      ctx.drawImage(composite, -rw / 2, -rh / 2);
      ctx.restore();

      setProcessingProgress(((v.currentTime - startTime) / (endTime - startTime)) * 100);
      requestAnimationFrame(renderFrame);
    };

    renderFrame();
  };

  const togglePlay = () => {
      if (videoRef.current) {
          if (videoRef.current.paused) videoRef.current.play();
          else videoRef.current.pause();
          setIsPlaying(!videoRef.current.paused);
      }
  };

  const handleSeek = (time: number) => {
    if (videoRef.current && isFinite(time)) {
        videoRef.current.currentTime = time;
    }
  };

  const setRatio = (ratio: string | number) => {
      setSelectedRatio(ratio);
      if (!tempCropRect || !videoRef.current) return;
      
      const v = videoRef.current;
      let newW = v.videoWidth;
      let newH = v.videoHeight;
      
      if (ratio === 'free') {
          setTempCropRect({ x: 0, y: 0, width: v.videoWidth, height: v.videoHeight });
          return;
      }
      
      const r = ratio as number;
      if (v.videoWidth / v.videoHeight > r) {
          newH = v.videoHeight;
          newW = newH * r;
      } else {
          newW = v.videoWidth;
          newH = newW / r;
      }
      
      setTempCropRect({
          x: (v.videoWidth - newW) / 2,
          y: (v.videoHeight - newH) / 2,
          width: newW,
          height: newH
      });
  };

  const cropOverlayBox =
    activeTool === 'crop' &&
    tempCropRect &&
    videoRef.current &&
    videoRef.current.videoWidth > 0
      ? intrinsicCropRectToOverlayBoxPx(videoRef.current, tempCropRect)
      : null;

  if (!mounted || !videoUrl) return null;

  return createPortal(
    <div className="fixed inset-0 z-[200] bg-background/20 backdrop-blur-3xl flex flex-col text-white animate-in fade-in duration-300 overflow-hidden font-body">
      <header className="absolute left-0 right-0 top-0 z-[210] box-border flex min-h-20 items-center justify-between bg-gradient-to-b from-black/40 to-transparent pl-[max(1rem,env(safe-area-inset-left,0px))] pr-[max(1rem,env(safe-area-inset-right,0px))] pb-2 pt-[env(safe-area-inset-top,0px)]">
        <Button variant="glass" size="icon" className="h-10 w-10 shadow-xl" onClick={onClose} disabled={isProcessing}><X className="h-6 w-6" /></Button>
        
        <div className="flex items-center gap-2">
          {activeTool === 'crop' ? (
            <>
              <div className="flex gap-1 mr-4 bg-black/20 p-1 rounded-full backdrop-blur-md border border-white/5">
                  {ASPECT_RATIOS.map(ar => (
                      <Button key={ar.label} variant="ghost" size="sm" onClick={() => setRatio(ar.value)} className={cn("h-8 rounded-full text-[10px] font-black uppercase border-none px-3", selectedRatio === ar.value ? "bg-white text-black" : "text-white/60 hover:bg-white/10")}>{ar.label}</Button>
                  ))}
              </div>
              <Button variant="glass" size="icon" className="bg-red-500/50 hover:bg-red-600/50 h-10 w-10 border-none" onClick={cancelCrop}><X className="h-5 w-5" /></Button>
              <Button variant="glass" size="icon" className="bg-green-500/50 hover:bg-green-600/50 h-10 w-10 border-none" onClick={applyCrop}><Check className="h-5 w-5" /></Button>
            </>
          ) : (
            <>
              <Button variant="glass" size="icon" onClick={handleResetAll} disabled={isProcessing} title={t('chat.videoEditor.resetAll')} className="border-none"><RefreshCcw className="h-5 w-5" /></Button>
              <Button variant="glass" size="icon" className={cn("border-none", isMuted && "bg-red-500/50")} onClick={() => { saveToHistory(); setIsMuted(!isMuted); }} disabled={isProcessing}>{isMuted ? <VolumeX className="h-5 w-5" /> : <Volume2 className="h-5 w-5" />}</Button>
              <Button variant="glass" size="icon" onClick={handleRotate} disabled={isProcessing} className="border-none"><RotateCw className="h-5 w-5" /></Button>
              <Button variant="glass" size="icon" className="border-none transition-all" onClick={() => setActiveTool('crop')} disabled={isProcessing}><Crop className="h-5 w-5" /></Button>
              <Button variant="glass" size="icon" className={cn("border-none transition-all", activeTool === 'draw' && "bg-primary/50 scale-110")} onClick={() => setActiveTool('draw')} disabled={isProcessing}><Pencil className="h-5 w-5" /></Button>
              <Button variant="glass" size="icon" disabled={isProcessing || history.length === 0} onClick={handleUndo} className="border-none disabled:opacity-20"><Undo2 className="h-5 w-5" /></Button>
            </>
          )}
        </div>
      </header>

      <main 
        ref={containerRef} className="flex-1 relative flex items-center justify-center overflow-hidden w-full h-full p-0" 
        onMouseEnter={() => setIsHovered(true)} onMouseLeave={() => setIsHovered(false)}
        onMouseDown={startDrawing} onMouseMove={draw} onMouseUp={stopDrawing} onTouchStart={startDrawing} onTouchMove={draw} onTouchEnd={stopDrawing}
      >
        <div 
            className="relative transition-all duration-500 ease-out flex items-center justify-center w-full h-full" 
            style={{ 
                transform: `rotate(${rotation}deg)`,
                aspectRatio: videoRef.current && videoRef.current.videoWidth > 0 ? `${videoRef.current.videoWidth}/${videoRef.current.videoHeight}` : 'auto'
            }}
        >
          <video 
            ref={videoRef} src={videoUrl} 
            className={cn("w-full h-full object-contain shadow-2xl transition-transform duration-300")} 
            style={activeTool !== 'crop' && cropRect && videoRef.current ? {
                transform: `scale(${videoRef.current.videoWidth / cropRect.width}) translate(${(videoRef.current.videoWidth/2 - (cropRect.x + cropRect.width/2)) / videoRef.current.videoWidth * 100}%, ${(videoRef.current.videoHeight/2 - (cropRect.y + cropRect.height/2)) / videoRef.current.videoHeight * 100}%)`
            } : {}}
            muted={isMuted} onLoadedMetadata={handleLoadedMetadata} playsInline loop 
          />
          <canvas ref={drawCanvasRef} className={cn("absolute inset-0 w-full h-full pointer-events-none z-10", activeTool === 'draw' && "pointer-events-auto cursor-crosshair")} />
          
          {cropOverlayBox && (
              <div 
                className="absolute box-border border-2 border-white shadow-[0_0_0_9999px_rgba(0,0,0,0.5)] z-20 cursor-move"
                style={{
                    left: cropOverlayBox.left,
                    top: cropOverlayBox.top,
                    width: cropOverlayBox.width,
                    height: cropOverlayBox.height,
                }}
                onMouseDown={(e) => onCropDown(e, 'drag')} onTouchStart={(e) => onCropDown(e, 'drag')}
              >
                  <div className="absolute inset-0 grid grid-cols-3 grid-rows-3 opacity-30 pointer-events-none">
                      <div className="border-r border-b border-white" /><div className="border-r border-b border-white" /><div className="border-b border-white" />
                      <div className="border-r border-b border-white" /><div className="border-r border-b border-white" /><div className="border-b border-white" />
                      <div className="border-r border-white" /><div className="border-r border-white" /><div />
                  </div>
                  {(['nw', 'ne', 'sw', 'se', 'n', 's', 'e', 'w'] as ResizeHandle[]).map(h => (
                      <div key={h} className={cn("absolute flex items-center justify-center transition-transform hover:scale-110 pointer-events-auto", h.length === 2 ? "w-10 h-10" : h === 'n' || h === 's' ? "w-16 h-8" : "w-8 h-16", h === 'nw' && "-top-5 -left-5 cursor-nw-resize", h === 'ne' && "-top-5 -right-5 cursor-ne-resize", h === 'sw' && "-bottom-5 -left-5 cursor-sw-resize", h === 'se' && "-bottom-5 -right-5 cursor-se-resize", h === 'n' && "-top-4 left-1/2 -translate-x-1/2 cursor-n-resize", h === 's' && "-bottom-4 left-1/2 -translate-x-1/2 cursor-s-resize", h === 'e' && "-right-4 top-1/2 -translate-y-1/2 cursor-e-resize", h === 'w' && "-left-4 top-1/2 -translate-y-1/2 cursor-w-resize")} onMouseDown={(e) => onCropDown(e, h)} onTouchStart={(e) => onCropDown(e, h)}><div className={cn("bg-white shadow-xl", h.length === 2 ? "w-4 h-4 rounded-full border-2 border-primary" : h === 'n' || h === 's' ? "w-8 h-1.5 rounded-full" : "w-1.5 h-8 rounded-full")} /></div>
                  ))}
              </div>
          )}
        </div>
        {(!isPlaying || isHovered) && !isProcessing && activeTool === 'none' && (
            <Button variant="glass" size="icon" className="absolute z-30 h-20 w-20 rounded-full bg-white/10 border-none hover:scale-110 shadow-2xl" onClick={togglePlay}>{isPlaying ? <Pause className="h-10 w-10 fill-white" /> : <Play className="h-10 w-10 fill-white ml-1" />}</Button>
        )}
        {isProcessing && (
            <div className="absolute inset-0 z-50 bg-black/60 backdrop-blur-sm flex flex-col items-center justify-center gap-4">
                <Loader2 className="h-12 w-12 animate-spin text-primary" /><div className="text-center space-y-1"><p className="font-bold text-xl">{t('chat.videoEditor.processingVideo')}</p><p className="text-sm text-white/60">{Math.round(processingProgress)}%</p></div>
            </div>
        )}
      </main>

      <footer className="relative z-[210] shrink-0 space-y-6 bg-gradient-to-t from-black/80 to-transparent pb-[max(1.5rem,env(safe-area-inset-bottom,0px))] pl-[max(1.5rem,env(safe-area-inset-left,0px))] pr-[max(1.5rem,env(safe-area-inset-right,0px))] pt-6">
        {activeTool !== 'crop' && (
            <div className="max-w-3xl mx-auto space-y-3 relative">
                <div className="relative h-12 bg-black/40 rounded-xl border border-white/5 flex items-center shadow-inner overflow-visible">
                    {isThumbnailsLoading ? (
                        <div className="absolute inset-0 flex items-center justify-center gap-3 bg-white/5 backdrop-blur-sm z-30">
                            <Loader2 className="h-4 w-4 animate-spin text-primary" />
                            <span className="text-[10px] font-black uppercase tracking-widest text-white/60">{t('chat.videoEditor.loadingStoryboard', { progress: thumbnailProgress })}</span>
                        </div>
                    ) : (
                        <div className="absolute inset-0 flex overflow-hidden rounded-xl">
                            {thumbnails.map((thumb, i) => (
                                <div key={i} className="flex-1 h-full overflow-hidden">
                                    <img src={thumb} alt="" className="w-full h-full object-cover opacity-40" />
                                </div>
                            ))}
                        </div>
                    )}
                    <TimelineRangeSelector range={range} onRangeChange={(r) => { saveToHistory(); setRange(r); }} onSeek={handleSeek} duration={duration} currentTime={currentTime} />
                </div>
                <div className="flex justify-between items-center px-1">
                    <div className="text-[10px] font-mono font-bold opacity-60 text-white flex items-center gap-2">
                        <Clock className="h-3 w-3" />
                        <span>{formatMMSS(currentTime)} / {formatMMSS(duration)}</span>
                    </div>
                    <span className="text-[10px] font-mono font-bold opacity-90 bg-primary/80 backdrop-blur-md px-3 py-1 rounded-full border border-white/10 text-white shadow-lg">
                        {formatMMSS(endTime - startTime)}
                    </span>
                </div>
            </div>
        )}
        <div className="max-w-2xl mx-auto flex items-center gap-3">
            {activeTool === 'draw' ? (
                <div className="flex-1 flex flex-col gap-4 p-4 bg-black/40 backdrop-blur-md rounded-2xl border border-white/10 animate-in slide-in-from-bottom-2">
                    <div className="flex items-center gap-4">
                        <span className="text-[10px] font-black uppercase tracking-widest text-white/40">{t('chat.videoEditor.thickness')}</span>
                        <Slider 
                            value={[brushSize]} 
                            min={2} 
                            max={40} 
                            step={1} 
                            onValueChange={([val]) => setBrushSize(val)} 
                            className="flex-1"
                        />
                        <div className="w-8 h-8 rounded-full border border-white/20 flex items-center justify-center bg-black/20">
                            <div className="rounded-full bg-white" style={{ width: `${brushSize/2}px`, height: `${brushSize/2}px` }} />
                        </div>
                    </div>
                    <div className="flex gap-3 justify-center">
                        {COLORS.map(c => (
                            <button 
                                key={c.hex} 
                                onClick={() => { saveToHistory(); setBrushColor(c.hex); }} 
                                className={cn(
                                    "h-8 w-8 rounded-full border-2 transition-all shadow-lg", 
                                    brushColor === c.hex ? "border-white scale-125 ring-4 ring-primary/30" : "border-transparent opacity-50"
                                )} 
                                style={{ backgroundColor: c.hex }} 
                            />
                        ))}
                    </div>
                </div>
            ) : (
                <div className="flex-1 relative group">
                    <Input placeholder={t('chat.videoEditor.addCaption')} value={caption} onChange={e => setCaption(e.target.value)} className="h-12 rounded-2xl bg-white/10 backdrop-blur-3xl border-none text-white placeholder:text-white/40 pl-14 pr-14 focus-visible:ring-primary shadow-2xl" disabled={isProcessing} />
                    <ImageIcon className="absolute left-4 top-1/2 -translate-y-1/2 h-5 w-5 text-white/40 group-focus-within:text-primary transition-colors pointer-events-none" />
                </div>
            )}
            <Button onClick={handleFinish} disabled={isProcessing || !isFinite(duration) || duration === 0} className="h-12 w-12 rounded-full bg-primary shadow-2xl shadow-primary/40 shrink-0 transition-transform active:scale-90 border-none"><SendHorizonal className="h-6 w-6" /></Button>
        </div>
      </footer>
      <canvas ref={processingCanvasRef} className="hidden" />
    </div>,
    document.body
  );
}

interface TimelineRangeSelectorProps {
  range: [number, number];
  onRangeChange: (r: [number, number]) => void;
  onSeek: (t: number) => void;
  duration: number;
  currentTime: number;
}

function TimelineRangeSelector({ range, onRangeChange, onSeek, duration, currentTime }: TimelineRangeSelectorProps) {
    const containerRef = useRef<HTMLDivElement>(null);
    const [dragging, setDragging] = useState<'start' | 'end' | 'seek' | null>(null);
    
    const handleSeek = useCallback((clientX: number) => {
        if (!containerRef.current || !isFinite(duration) || duration <= 0) return;
        const rect = containerRef.current.getBoundingClientRect();
        const pos = Math.max(0, Math.min(1, (clientX - rect.left) / rect.width));
        onSeek(pos * duration);
    }, [duration, onSeek]);

    const handleTimelineClick = (e: React.MouseEvent) => {
        handleSeek(e.clientX);
    };

    const handleMouseDown = (e: React.MouseEvent | React.TouchEvent, type: 'start' | 'end' | 'seek') => {
        e.stopPropagation();
        setDragging(type);
        if (type === 'seek') {
            const clientX = 'touches' in e ? e.touches[0].clientX : e.clientX;
            handleSeek(clientX);
        }
    };

    useEffect(() => {
        if (!dragging) return;
        const onMove = (e: MouseEvent | TouchEvent) => {
            if (!containerRef.current) return;
            const rect = containerRef.current.getBoundingClientRect();
            const clientX = 'touches' in e ? e.touches[0].clientX : e.clientX;
            const pos = Math.max(0, Math.min(100, ((clientX - rect.left) / rect.width) * 100));
            
            if (dragging === 'seek') {
                handleSeek(clientX);
            } else {
                onRangeChange(dragging === 'start' ? [Math.min(pos, range[1] - 1), range[1]] : [range[0], Math.max(pos, range[0] + 1)]);
            }
        };
        const onUp = () => setDragging(null);
        window.addEventListener('mousemove', onMove); window.addEventListener('mouseup', onUp);
        window.addEventListener('touchmove', onMove); window.addEventListener('touchend', onUp);
        return () => { window.removeEventListener('mousemove', onMove); window.removeEventListener('mouseup', onUp); window.removeEventListener('touchmove', onMove); window.removeEventListener('touchend', onUp); };
    }, [dragging, range, onRangeChange, handleSeek]);

    return (
        <div ref={containerRef} className="absolute inset-0 z-20 cursor-pointer" onClick={handleTimelineClick}>
            <div className="absolute inset-y-0 left-0 bg-black/60" style={{ width: `${range[0]}%` }} />
            <div className="absolute inset-y-0 right-0 bg-black/60" style={{ left: `${range[1]}%` }} />
            <div className="absolute inset-y-0 border-y-2 border-primary" style={{ left: `${range[0]}%`, right: `${100 - range[1]}%` }}>
                <div className="absolute -left-1 inset-y-0 w-3 bg-primary rounded-l-md cursor-ew-resize flex items-center justify-center" onMouseDown={(e) => handleMouseDown(e, 'start')} onTouchStart={(e) => handleMouseDown(e, 'start')}><div className="w-0.5 h-4 bg-white/40 rounded-full" /></div>
                <div className="absolute -right-1 inset-y-0 w-3 bg-primary rounded-r-md cursor-ew-resize flex items-center justify-center" onMouseDown={(e) => handleMouseDown(e, 'end')} onTouchStart={(e) => handleMouseDown(e, 'end')}><div className="w-0.5 h-4 bg-white/40 rounded-full" /></div>
            </div>
            {isFinite(currentTime / duration) && duration > 0 && (
                <div 
                    className="absolute inset-y-0 w-0.5 bg-white z-30 shadow-lg group/playhead" 
                    style={{ left: `${(currentTime / duration) * 100}%` }}
                    onMouseDown={(e) => handleMouseDown(e, 'seek')}
                    onTouchStart={(e) => handleMouseDown(e, 'seek')}
                >
                    <div className="absolute -top-1.5 left-1/2 -translate-x-1/2 w-3 h-3 bg-white rounded-full shadow-xl border-2 border-primary scale-100 group-hover/playhead:scale-125 transition-transform" />
                </div>
            )}
        </div>
    );
}
