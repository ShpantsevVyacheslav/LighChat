'use client';

import React, { useState, useRef, useEffect, useCallback } from 'react';
import { createPortal } from 'react-dom';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { 
  Undo2, RefreshCcw, 
  SendHorizonal, Image as ImageIcon,
  Plus, Check, Crop, X, RotateCw, Loader2, Pencil
} from 'lucide-react';
import { cn } from '@/lib/utils';
import { ScrollArea, ScrollBar } from '@/components/ui/scroll-area';
import { TransformWrapper, TransformComponent, type ReactZoomPanPinchRef } from 'react-zoom-pan-pinch';

type ToolType = 'none' | 'draw' | 'crop';
type ResizeHandle = 'n' | 's' | 'e' | 'w' | 'nw' | 'ne' | 'sw' | 'se';

interface Rect {
  x: number;
  y: number;
  width: number;
  height: number;
}

type HistoryStep = {
    type: 'canvas';
    dataUrl: string;
} | {
    type: 'file';
    files: File[];
};

interface ImageEditorModalProps {
  files: File[];
  initialIndex: number;
  onSave: (editedFiles: File[], caption?: string) => void;
  onClose: () => void;
  onDeleteImage: (index: number) => void;
}

const COLORS = [
  { name: 'white', hex: '#FFFFFF' },
  { name: 'blue', hex: '#3b82f6' },
  { name: 'green', hex: '#22c55e' },
  { name: 'yellow', hex: '#eab308' },
  { name: 'red', hex: '#ef4444' },
];

const PADDING = 24;

export function ImageEditorModal({ files: initialFiles, initialIndex, onSave, onClose, onDeleteImage }: ImageEditorModalProps) {
  const [mounted, setMounted] = useState(false);
  const [files, setFiles] = useState<File[]>(initialFiles);
  const [currentIndex, setCurrentIndex] = useState(initialIndex);
  const [caption, setCaption] = useState('');
  const [activeTool, setActiveTool] = useState<ToolType>('none');
  const [activeColor, setActiveColor] = useState(COLORS[4].hex);
  const [history, setHistory] = useState<HistoryStep[]>([]);
  const [isImageLoading, setIsImageLoading] = useState(true);
  
  const [cropRect, setCropRect] = useState<Rect | null>(null);
  const [isResizingCrop, setIsResizingCrop] = useState(false);
  const activeHandle = useRef<ResizeHandle | null>(null);
  const startCropPos = useRef({ x: 0, y: 0, rect: { x: 0, y: 0, width: 0, height: 0 } });

  const canvasRef = useRef<HTMLCanvasElement>(null);
  const workingImageRef = useRef<HTMLImageElement | null>(null);
  const lastLoadedFileRef = useRef<File | null>(null);
  const isDrawing = useRef(false);
  const transformRef = useRef<ReactZoomPanPinchRef | null>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    setMounted(true);
  }, []);

  const updateCanvasDisplaySize = useCallback(() => {
    const canvas = canvasRef.current;
    const container = containerRef.current;
    if (!canvas || !container) return;

    const containerW = container.clientWidth;
    const containerH = container.clientHeight;
    
    const isCrop = activeTool === 'crop';
    const horizontalPadding = isCrop ? PADDING * 2 : 0;
    const verticalPadding = isCrop ? PADDING * 2 : 0;

    const availableW = containerW - horizontalPadding;
    const availableH = containerH - verticalPadding;

    const w = canvas.width;
    const h = canvas.height;

    const scale = Math.min(availableW / w, availableH / h, 1);
    
    canvas.style.width = `${w * scale}px`;
    canvas.style.height = `${h * scale}px`;
  }, [activeTool]);

  const saveToHistory = useCallback((type: 'canvas' | 'file' = 'canvas') => {
    const canvas = canvasRef.current;
    if (canvas) {
      const step: HistoryStep = type === 'file' 
        ? { type: 'file', files: [...files] }
        : { type: 'canvas', dataUrl: canvas.toDataURL('image/jpeg', 0.9) };
      setHistory(prev => [...prev, step]);
    }
  }, [files]);

  const initCanvas = useCallback((source: HTMLImageElement | HTMLCanvasElement) => {
    const canvas = canvasRef.current;
    if (!canvas || !source) return;

    const w = (source as any).naturalWidth || (source as any).width || 0;
    const h = (source as any).naturalHeight || (source as any).height || 0;

    if (w <= 0 || h <= 0) return;

    const ctx = canvas.getContext('2d', { alpha: false, willReadFrequently: true });
    if (!ctx) return;
    
    canvas.width = w;
    canvas.height = h;

    ctx.clearRect(0, 0, w, h);
    ctx.fillStyle = '#000000';
    ctx.fillRect(0, 0, w, h);
    ctx.drawImage(source as any, 0, 0);
    
    updateCanvasDisplaySize();
  }, [updateCanvasDisplaySize]);

  useEffect(() => {
    if (currentIndex >= 0 && currentIndex < files.length) {
        const file = files[currentIndex];
        
        if (file === lastLoadedFileRef.current) {
            updateCanvasDisplaySize();
            return;
        }

        setIsImageLoading(true);
        const url = URL.createObjectURL(file);
        const img = new Image();
        
        img.onload = () => {
          // Double check natural size for pasted blobs
          if (img.naturalWidth === 0 || img.naturalHeight === 0) {
              setTimeout(() => {
                  lastLoadedFileRef.current = file;
                  workingImageRef.current = img;
                  initCanvas(img);
                  setIsImageLoading(false);
                  URL.revokeObjectURL(url);
              }, 100);
          } else {
              lastLoadedFileRef.current = file;
              workingImageRef.current = img;
              initCanvas(img);
              setIsImageLoading(false);
              URL.revokeObjectURL(url);
          }
        };
        img.onerror = () => {
            console.error("Failed to load image for editor");
            setIsImageLoading(false);
            URL.revokeObjectURL(url);
        };
        img.src = url;
    }
  }, [currentIndex, files, initCanvas, updateCanvasDisplaySize]);

  // Update layout when tool changes
  useEffect(() => {
    updateCanvasDisplaySize();
  }, [activeTool, updateCanvasDisplaySize]);

  // Sync crop rect when entering crop mode
  useEffect(() => {
    if (activeTool === 'crop' && !cropRect && canvasRef.current) {
      const timer = setTimeout(() => {
        const canvas = canvasRef.current;
        if (canvas) {
          const rect = canvas.getBoundingClientRect();
          setCropRect({
            x: rect.left,
            y: rect.top,
            width: rect.width,
            height: rect.height
          });
        }
      }, 100);
      return () => clearTimeout(timer);
    }
  }, [activeTool, cropRect]);

  const handleUndo = () => {
    if (history.length === 0) return;
    
    const lastStep = history[history.length - 1];
    setHistory(prev => prev.slice(0, -1));

    if (lastStep.type === 'file') {
        lastLoadedFileRef.current = null;
        setFiles(lastStep.files);
        setActiveTool('none');
        setCropRect(null);
    } else {
        const img = new Image();
        img.src = lastStep.dataUrl;
        img.onload = () => {
          const canvas = canvasRef.current;
          if (canvas) {
            canvas.width = img.width;
            canvas.height = img.height;
            const ctx = canvas.getContext('2d', { willReadFrequently: true });
            if (ctx) {
              ctx.drawImage(img, 0, 0);
              updateCanvasDisplaySize();
            }
          }
        };
    }
  };

  const handleResetAll = () => {
    lastLoadedFileRef.current = null;
    setFiles([...initialFiles]);
    setHistory([]);
    setActiveTool('none');
    setCropRect(null);
    transformRef.current?.resetTransform(0);
  };

  const handleRotate = () => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    saveToHistory();
    
    const tempCanvas = document.createElement('canvas');
    tempCanvas.width = canvas.width;
    tempCanvas.height = canvas.height;
    const tCtx = tempCanvas.getContext('2d');
    if (!tCtx) return;
    tCtx.drawImage(canvas, 0, 0);

    canvas.width = tempCanvas.height;
    canvas.height = tempCanvas.width;

    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    ctx.save();
    ctx.translate(canvas.width / 2, canvas.height / 2);
    ctx.rotate(90 * Math.PI / 180);
    ctx.drawImage(tempCanvas, -tempCanvas.width / 2, -tempCanvas.height / 2);
    ctx.restore();
    
    updateCanvasDisplaySize();
    transformRef.current?.resetTransform(0);
  };

  const handleMouseDown = (e: any) => {
    if (activeTool !== 'draw' || isImageLoading || !canvasRef.current) return;
    
    const canvas = canvasRef.current;
    const rect = canvas.getBoundingClientRect();
    const clientX = 'touches' in e ? e.touches[0].clientX : e.clientX;
    const clientY = 'touches' in e ? e.touches[0].clientY : e.clientY;
    
    const x = (clientX - rect.left) * (canvas.width / rect.width);
    const y = (clientY - rect.top) * (canvas.height / rect.height);

    const ctx = canvas.getContext('2d');
    if (ctx) {
      saveToHistory();
      isDrawing.current = true;
      ctx.beginPath();
      ctx.moveTo(x, y);
      ctx.strokeStyle = activeColor;
      ctx.lineWidth = Math.max(4, canvas.width / 150);
      ctx.lineCap = 'round';
      ctx.lineJoin = 'round';
    }
  };

  const handleMouseMove = (e: any) => {
    if (activeTool === 'draw' && isDrawing.current && canvasRef.current) {
      const canvas = canvasRef.current;
      const rect = canvas.getBoundingClientRect();
      const clientX = 'touches' in e ? e.touches[0].clientX : e.clientX;
      const clientY = 'touches' in e ? e.touches[0].clientY : e.clientY;
      
      const x = (clientX - rect.left) * (canvas.width / rect.width);
      const y = (clientY - rect.top) * (canvas.height / rect.height);

      const ctx = canvas.getContext('2d');
      if (ctx) {
        ctx.lineTo(x, y);
        ctx.stroke();
      }
    }
  };

  const handleMouseUp = () => {
    isDrawing.current = false;
  };

  const onCropHandleDown = (e: React.MouseEvent | React.TouchEvent, handle: ResizeHandle) => {
    e.stopPropagation();
    if (!cropRect) return;
    
    const clientX = 'touches' in e ? e.touches[0].clientX : e.clientX;
    const clientY = 'touches' in e ? e.touches[0].clientY : e.clientY;
    
    setIsResizingCrop(true);
    activeHandle.current = handle;
    startCropPos.current = { x: clientX, y: clientY, rect: { ...cropRect } };
  };

  useEffect(() => {
    if (!isResizingCrop) return;

    const onMove = (e: MouseEvent | TouchEvent) => {
      if (!cropRect) return;
      const clientX = 'touches' in e ? e.touches[0].clientX : e.clientX;
      const clientY = 'touches' in e ? e.touches[0].clientY : e.clientY;
      
      const dx = clientX - startCropPos.current.x;
      const dy = clientY - startCropPos.current.y;
      
      let newRect = { ...startCropPos.current.rect };
      const h = activeHandle.current;

      if (h?.includes('n')) { newRect.y += dy; newRect.height -= dy; }
      if (h?.includes('s')) { newRect.height += dy; }
      if (h?.includes('w')) { newRect.x += dx; newRect.width -= dx; }
      if (h?.includes('e')) { newRect.width += dx; }

      if (newRect.width < 40) newRect.width = 40;
      if (newRect.height < 40) newRect.height = 40;
      
      setCropRect(newRect);
    };

    const onUp = () => {
      setIsResizingCrop(false);
      activeHandle.current = null;
    };

    window.addEventListener('mousemove', onMove);
    window.addEventListener('mouseup', onUp);
    window.addEventListener('touchmove', onMove);
    window.addEventListener('touchend', onUp);
    return () => {
      window.removeEventListener('mousemove', onMove);
      window.removeEventListener('mouseup', onUp);
      window.removeEventListener('touchmove', onMove);
      window.removeEventListener('touchend', onUp);
    };
  }, [isResizingCrop, cropRect]);

  const applyCrop = () => {
    const canvas = canvasRef.current;
    if (canvas && cropRect) {
      const rect = canvas.getBoundingClientRect();
      
      const scaleX = canvas.width / rect.width;
      const scaleY = canvas.height / rect.height;
      
      const sourceX = (cropRect.x - rect.left) * scaleX;
      const sourceY = (cropRect.y - rect.top) * scaleY;
      const sourceW = cropRect.width * scaleX;
      const sourceH = cropRect.height * scaleY;

      const tempCanvas = document.createElement('canvas');
      tempCanvas.width = sourceW;
      tempCanvas.height = sourceH;
      const tCtx = tempCanvas.getContext('2d');
      
      if (tCtx) {
        saveToHistory('file');
        tCtx.drawImage(canvas, sourceX, sourceY, sourceW, sourceH, 0, 0, sourceW, sourceH);
        
        tempCanvas.toBlob(async (blob) => {
            if (blob) {
                const newFile = new File([blob], files[currentIndex].name, { type: 'image/jpeg' });
                
                lastLoadedFileRef.current = newFile;
                setFiles(prev => {
                    const next = [...prev];
                    next[currentIndex] = newFile;
                    return next;
                });
                
                canvas.width = sourceW;
                canvas.height = sourceH;
                const ctx = canvas.getContext('2d');
                ctx?.drawImage(tempCanvas, 0, 0);
                
                setActiveTool('none');
                setCropRect(null);
                updateCanvasDisplaySize();
                transformRef.current?.resetTransform(0);
            }
        }, 'image/jpeg', 1.0);
      }
    }
  };

  const handleFinish = () => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    canvas.toBlob((blob) => {
      if (blob) {
        const editedFile = new File([blob], files[currentIndex].name, { type: 'image/jpeg' });
        const finalFiles = [...files];
        finalFiles[currentIndex] = editedFile;
        onSave(finalFiles, caption);
      }
    }, 'image/jpeg', 0.9);
  };

  if (!mounted) return null;

  return createPortal(
    <div className="fixed inset-0 z-[200] bg-black flex flex-col text-white animate-in fade-in duration-300 overflow-hidden font-body">
      
      <header className="absolute top-0 left-0 right-0 z-[210] h-20 bg-gradient-to-b from-black/60 to-transparent px-4 flex items-center justify-between pointer-events-none">
        <div className="pointer-events-auto">
          <Button variant="ghost" size="icon" className="rounded-full bg-white/10 backdrop-blur-xl hover:bg-white/20 transition-all border-none h-10 w-10 shadow-xl" onClick={onClose}>
            <X className="h-6 w-6" />
          </Button>
        </div>

        <div className="flex items-center gap-2 pointer-events-auto">
          {activeTool === 'crop' ? (
            <>
              <Button variant="ghost" size="icon" className="rounded-full bg-red-500 text-white hover:bg-red-600 border-none h-10 w-10 shadow-lg" onClick={() => { setActiveTool('none'); setCropRect(null); }}><X className="h-5 w-5" /></Button>
              <Button variant="ghost" size="icon" className="rounded-full bg-green-500 text-white hover:bg-green-600 border-none h-10 w-10 shadow-lg" onClick={applyCrop}><Check className="h-5 w-5" /></Button>
            </>
          ) : (
            <>
              <Button variant="ghost" size="icon" disabled={history.length === 0} className="rounded-full bg-white/10 backdrop-blur-xl hover:bg-white/20 border-none h-10 w-10 disabled:opacity-20 transition-all" onClick={handleUndo} title="Отменить действие"><Undo2 className="h-5 w-5" /></Button>
              <Button variant="ghost" size="icon" className="rounded-full bg-white/10 backdrop-blur-xl hover:bg-white/20 border-none h-10 w-10" onClick={handleResetAll} title="Сбросить все"><RefreshCcw className="h-5 w-5" /></Button>
              <Button variant="ghost" size="icon" className="rounded-full bg-white/10 backdrop-blur-xl hover:bg-white/20 border-none h-10 w-10" onClick={handleRotate} title="Повернуть"><RotateCw className="h-5 w-5" /></Button>
              <Button variant="ghost" size="icon" className={cn("rounded-full transition-all border-none h-10 w-10 backdrop-blur-xl", activeTool === 'draw' ? "bg-primary text-white scale-110 shadow-primary/40 shadow-lg" : "bg-white/10 text-white hover:bg-white/20")} onClick={() => setActiveTool(activeTool === 'draw' ? 'none' : 'draw')}><Pencil className="h-5 w-5" /></Button>
              <Button variant="ghost" size="icon" className="rounded-full bg-white/10 backdrop-blur-xl hover:bg-white/20 border-none h-10 w-10" onClick={() => setActiveTool('crop')} title="Обрезать"><Crop className="h-5 w-5" /></Button>
            </>
          )}
        </div>
      </header>

      <main 
        ref={containerRef}
        className={cn(
            "flex-1 flex items-center justify-center overflow-hidden w-full relative transition-all duration-300",
            activeTool === 'crop' ? "p-6" : "p-0"
        )}
        onMouseDown={handleMouseDown}
        onMouseMove={handleMouseMove}
        onMouseUp={handleMouseUp}
        onTouchStart={handleMouseDown}
        onTouchMove={handleMouseMove}
        onTouchEnd={handleMouseUp}
      >
        <TransformWrapper
            ref={transformRef}
            disabled={activeTool === 'draw' || isResizingCrop}
            initialScale={1}
            minScale={1}
            maxScale={8}
            centerOnInit
            limitToBounds={true}
        >
          <TransformComponent wrapperClass="!w-full !h-full" contentClass="w-full h-full flex items-center justify-center">
            <div className="relative">
              {isImageLoading && (
                  <div className="absolute inset-0 flex items-center justify-center z-10">
                      <Loader2 className="h-10 w-10 animate-spin text-primary opacity-50" />
                  </div>
              )}
              <canvas ref={canvasRef} className="shadow-2xl" />
            </div>
          </TransformComponent>
        </TransformWrapper>

        {activeTool === 'crop' && cropRect && (
            <div 
                className="fixed border-2 border-white shadow-[0_0_0_9999px_rgba(0,0,0,0.5)] z-[250] pointer-events-none"
                style={{
                    left: `${cropRect.x}px`,
                    top: `${cropRect.y}px`,
                    width: `${cropRect.width}px`,
                    height: `${cropRect.height}px`,
                }}
            >
                <div className="absolute inset-0 grid grid-cols-3 grid-rows-3 opacity-30 pointer-events-none">
                    <div className="border-r border-b border-white" /><div className="border-r border-b border-white" /><div className="border-b border-white" />
                    <div className="border-r border-b border-white" /><div className="border-r border-b border-white" /><div className="border-b border-white" />
                    <div className="border-r border-white" /><div className="border-r border-white" /><div />
                </div>

                {(['nw', 'ne', 'sw', 'se', 'n', 's', 'e', 'w'] as ResizeHandle[]).map(h => (
                    <div
                        key={h}
                        className={cn(
                            "absolute flex items-center justify-center transition-transform hover:scale-110 pointer-events-auto",
                            h.length === 2 ? "w-10 h-10" : h === 'n' || h === 's' ? "w-16 h-8" : "w-8 h-16",
                            h === 'nw' && "-top-5 -left-5 cursor-nw-resize",
                            h === 'ne' && "-top-5 -right-5 cursor-ne-resize",
                            h === 'sw' && "-bottom-5 -left-5 cursor-sw-resize",
                            h === 'se' && "-bottom-5 -right-5 cursor-se-resize",
                            h === 'n' && "-top-4 left-1/2 -translate-x-1/2 cursor-n-resize",
                            h === 's' && "-bottom-4 left-1/2 -translate-x-1/2 cursor-s-resize",
                            h === 'e' && "-right-4 top-1/2 -translate-y-1/2 cursor-e-resize",
                            h === 'w' && "-left-4 top-1/2 -translate-y-1/2 cursor-w-resize"
                        )}
                        onMouseDown={(e) => onCropHandleDown(e, h)}
                        onTouchStart={(e) => onCropHandleDown(e, h)}
                    >
                        <div className={cn(
                            "bg-white shadow-xl",
                            h.length === 2 ? "w-4 h-4 rounded-full border-2 border-primary" : h === 'n' || h === 's' ? "w-8 h-1.5 rounded-full" : "w-1.5 h-8 rounded-full"
                        )} />
                    </div>
                ))}
            </div>
        )}

        {activeTool === 'draw' && (
          <div className="absolute left-6 top-1/2 -translate-y-1/2 flex flex-col gap-4 z-50 pointer-events-auto">
            {COLORS.map(color => (
              <button 
                key={color.hex} 
                onClick={() => setActiveColor(color.hex)} 
                className={cn("w-8 h-8 rounded-full border-2 transition-all active:scale-125 shadow-2xl", activeColor === color.hex ? "border-white scale-125 ring-4 ring-primary/30" : "border-white/10")} 
                style={{ backgroundColor: color.hex }} 
              />
            ))}
          </div>
        )}
      </main>

      {activeTool !== 'crop' && (
        <footer className="absolute bottom-0 left-0 right-0 z-[210] p-6 space-y-6 bg-gradient-to-t from-black/80 via-black/20 to-transparent">
            <div className="max-w-3xl mx-auto flex items-center gap-2 overflow-hidden pointer-events-auto">
                <ScrollArea className="flex-1 w-full">
                    <div className="flex items-center gap-3 pb-2 px-2 pt-2">
                        <label className="flex-shrink-0 w-14 h-14 rounded-2xl border-2 border-dashed border-white/20 flex items-center justify-center bg-white/5 backdrop-blur-xl cursor-pointer hover:bg-white/10 transition-colors">
                            <Plus className="h-6 w-6 text-white/60" />
                            <input type="file" multiple className="hidden" accept="image/*" onChange={(e) => {
                                if (e.target.files) {
                                    const newFiles = Array.from(e.target.files);
                                    const currentCount = files.length;
                                    setFiles(prev => [...prev, ...newFiles]);
                                    setCurrentIndex(currentCount);
                                }
                            }} />
                        </label>
                        {files.map((file, idx) => (
                            <div 
                                key={idx} 
                                onClick={() => setCurrentIndex(idx)}
                                className={cn(
                                    "relative w-14 h-14 rounded-2xl overflow-hidden cursor-pointer transition-all border-none shrink-0",
                                    idx === currentIndex ? "scale-110 opacity-100" : "opacity-40 scale-95"
                                )}
                            >
                                <img src={URL.createObjectURL(file)} alt="" className="w-full h-full object-cover rounded-xl" />
                            </div>
                        ))}
                    </div>
                    <ScrollBar orientation="horizontal" className="opacity-0" />
                </ScrollArea>
            </div>
            <div className="max-w-2xl mx-auto flex items-center gap-3 pointer-events-auto">
                <div className="flex-1 relative group">
                    <Input placeholder="Добавить подпись..." value={caption} onChange={(e) => setCaption(e.target.value)} className="h-12 rounded-2xl bg-white/10 backdrop-blur-3xl border-none text-white placeholder:text-white/40 pl-10 focus-visible:ring-primary shadow-none" />
                    <ImageIcon className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-white/40 group-focus-within:text-primary transition-colors" />
                </div>
                <button className="h-12 w-12 rounded-full bg-primary flex items-center justify-center text-white shadow-2xl shadow-primary/40 shrink-0 transition-transform active:scale-90" onClick={handleFinish}><SendHorizonal className="h-6 w-6" /></button>
            </div>
        </footer>
      )}
    </div>,
    document.body
  );
}
