"use client";

import * as React from "react";
import Cropper, { type Area } from "react-easy-crop";
import { getCircularCroppedImageBlob } from "@/lib/circular-crop-to-blob";
import { Button } from "@/components/ui/button";
import { Slider } from "@/components/ui/slider";
import { Loader2, X } from "lucide-react";

export interface RegisterAvatarCropOverlayProps {
  open: boolean;
  imageSrc: string | null;
  onCancel: () => void;
  /** Готовый JPEG после круговой обрезки. */
  onApply: (file: File) => void;
}

/**
 * Полноэкранная обрезка аватара под круг (pan + zoom), в духе Telegram.
 */
export function RegisterAvatarCropOverlay({
  open,
  imageSrc,
  onCancel,
  onApply,
}: RegisterAvatarCropOverlayProps) {
  const [crop, setCrop] = React.useState({ x: 0, y: 0 });
  const [zoom, setZoom] = React.useState(1);
  const [croppedAreaPixels, setCroppedAreaPixels] = React.useState<Area | null>(null);
  const [resetKey, setResetKey] = React.useState(0);
  const [busy, setBusy] = React.useState(false);

  React.useEffect(() => {
    if (!open || !imageSrc) return;
    setCrop({ x: 0, y: 0 });
    setZoom(1);
    setCroppedAreaPixels(null);
    setResetKey((k) => k + 1);
  }, [open, imageSrc]);

  const onCropComplete = React.useCallback((_area: Area, pixels: Area) => {
    setCroppedAreaPixels(pixels);
  }, []);

  const handleReset = () => {
    setCrop({ x: 0, y: 0 });
    setZoom(1);
    setResetKey((k) => k + 1);
  };

  const handleApply = async () => {
    if (!imageSrc || !croppedAreaPixels) return;
    setBusy(true);
    try {
      const blob = await getCircularCroppedImageBlob(imageSrc, croppedAreaPixels);
      const file = new File([blob], "avatar.jpg", { type: "image/jpeg" });
      onApply(file);
    } catch (e) {
      console.error("[RegisterAvatarCropOverlay] экспорт обрезки", e);
    } finally {
      setBusy(false);
    }
  };

  if (!open || !imageSrc) return null;

  return (
    <div
      className="fixed inset-0 z-[200] flex flex-col bg-neutral-950"
      role="dialog"
      aria-modal="true"
      aria-labelledby="register-crop-title"
    >
      <div className="flex shrink-0 items-center justify-between px-3 pt-[max(0.75rem,env(safe-area-inset-top))] pb-2">
        <h2 id="register-crop-title" className="sr-only">
          Обрезка фото для аватара
        </h2>
        <Button
          type="button"
          variant="ghost"
          size="icon"
          className="h-10 w-10 rounded-full text-white hover:bg-white/15"
          onClick={onCancel}
          aria-label="Закрыть"
        >
          <X className="h-5 w-5" />
        </Button>
      </div>

      <div className="relative min-h-0 flex-1 w-full">
        <Cropper
          key={resetKey}
          image={imageSrc}
          crop={crop}
          zoom={zoom}
          aspect={1}
          cropShape="round"
          showGrid={false}
          minZoom={1}
          maxZoom={3}
          zoomSpeed={0.4}
          onCropChange={setCrop}
          onZoomChange={setZoom}
          onCropComplete={onCropComplete}
          objectFit="cover"
          restrictPosition
          style={{}}
          mediaProps={{}}
          cropperProps={{}}
          classes={{
            containerClassName: "relative h-full w-full bg-neutral-950",
            mediaClassName: "max-h-full max-w-full touch-none",
          }}
        />
      </div>

      <div className="shrink-0 space-y-4 px-4 pb-[max(1rem,env(safe-area-inset-bottom))] pt-2">
        <div className="space-y-2">
          <p className="text-center text-[11px] font-medium uppercase tracking-wide text-white/50">
            Масштаб
          </p>
          <Slider
            value={[zoom]}
            min={1}
            max={3}
            step={0.02}
            onValueChange={(v) => setZoom(v[0] ?? 1)}
            className="w-full px-1"
          />
        </div>
        <p className="text-center text-xs text-white/55">
          Перетащите фото, настройте масштаб — в круге видна область аватара.
        </p>
        <div className="flex gap-3">
          <Button
            type="button"
            variant="ghost"
            className="h-11 flex-1 rounded-xl border border-white/20 bg-transparent text-sm font-semibold uppercase tracking-wide text-white hover:bg-white/10"
            onClick={handleReset}
            disabled={busy}
          >
            Сбросить
          </Button>
          <Button
            type="button"
            className="h-11 flex-1 rounded-xl font-semibold"
            onClick={handleApply}
            disabled={busy || !croppedAreaPixels}
          >
            {busy ? (
              <>
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                Сохранение…
              </>
            ) : (
              "Готово"
            )}
          </Button>
        </div>
      </div>
    </div>
  );
}
