"use client";

import * as React from "react";
import Cropper, { type Area } from "react-easy-crop";
import { getCircularCroppedImageBlob } from "@/lib/circular-crop-to-blob";
import { Button } from "@/components/ui/button";
import { Loader2 } from "lucide-react";
import { cn } from "@/lib/utils";
import { useI18n } from "@/hooks/use-i18n";

export type RegisterAvatarCropVariant = "fullscreen" | "compact";

export interface RegisterAvatarCropOverlayProps {
  open: boolean;
  /** Blob-URL выбранного фото для Cropper. */
  imageSrc: string | null;
  onCancel: () => void;
  /**
   * Круглое превью 512×512 JPEG — уходит в `avatarThumb`; полный кадр передаёт родитель отдельно в Storage как `avatar`.
   */
  onApply: (circleJpegFile: File) => void;
  /**
   * `fullscreen` — как при регистрации на лендинге.
   * `compact` — стеклянная карточка по центру с размытием фона (профиль в дашборде).
   */
  variant?: RegisterAvatarCropVariant;
  /**
   * Вместе с `compact`: затемнение и blur только над этим элементом (правая колонка дашборда),
   * модалка центрируется в его границах. Без пропа — на весь viewport (лендинг и т.д.).
   */
  scopeWithinElement?: () => HTMLElement | null;
}

/** Диаметр круга предпросмотра (px). `scopeDims` — габариты правой колонки при scoped compact. */
function computeCropDiameter(
  compact: boolean,
  scopeDims?: { width: number; height: number } | null
): number {
  if (!compact) {
    if (typeof window === "undefined") return 232;
    const w = window.innerWidth;
    const h = window.innerHeight;
    const side = Math.min(w, h);
    return Math.round(Math.min(260, Math.max(200, side * 0.52)));
  }
  if (typeof window === "undefined") return scopeDims ? 200 : 228;
  const side =
    scopeDims && scopeDims.width > 0 && scopeDims.height > 0
      ? Math.min(scopeDims.width, scopeDims.height)
      : Math.min(window.innerWidth, window.innerHeight);
  /** ~1.5× от базового диаметра — в одном стиле с увеличенной стеклянной карточкой. */
  return Math.round(Math.min(176, Math.max(128, side * 0.34)) * 1.5);
}

/**
 * Предпросмотр и экспорт аватара «в круге» (pan + zoom).
 * В `onApply` уходит JPEG круга для миниатюр; полноразмерное фото сохраняет вызывающий код.
 */
export function RegisterAvatarCropOverlay({
  open,
  imageSrc,
  onCancel,
  onApply,
  variant = "fullscreen",
  scopeWithinElement,
}: RegisterAvatarCropOverlayProps) {
  const { t } = useI18n();
  const isCompact = variant === "compact";
  const isScopedTarget = isCompact && typeof scopeWithinElement === "function";
  const [scopeLayoutVersion, setScopeLayoutVersion] = React.useState(0);
  const [crop, setCrop] = React.useState({ x: 0, y: 0 });
  const [zoom, setZoom] = React.useState(1);
  const [croppedAreaPixels, setCroppedAreaPixels] = React.useState<Area | null>(null);
  const [resetKey, setResetKey] = React.useState(0);
  const [busy, setBusy] = React.useState(false);
  const [cropDiameter, setCropDiameter] = React.useState(() => computeCropDiameter(false));

  const scopeRect = React.useMemo(() => {
    if (!open || !isScopedTarget || !scopeWithinElement) return null;
    const el = scopeWithinElement();
    if (!el) return null;
    const r = el.getBoundingClientRect();
    if (r.width < 2 || r.height < 2) return null;
    return { top: r.top, left: r.left, width: r.width, height: r.height };
  }, [open, isScopedTarget, scopeWithinElement, scopeLayoutVersion]);

  React.useLayoutEffect(() => {
    if (!open || !isScopedTarget || !scopeWithinElement) return;
    const el = scopeWithinElement();
    if (!el) return;
    const bump = () => setScopeLayoutVersion((v) => v + 1);
    const ro = new ResizeObserver(bump);
    ro.observe(el);
    window.addEventListener("resize", bump);
    bump();
    return () => {
      ro.disconnect();
      window.removeEventListener("resize", bump);
    };
  }, [open, isScopedTarget, scopeWithinElement]);

  React.useEffect(() => {
    if (!open) return;
    const prev = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      document.body.style.overflow = prev;
    };
  }, [open]);

  React.useEffect(() => {
    if (!open || !imageSrc) return;
    setCrop({ x: 0, y: 0 });
    setZoom(1);
    setCroppedAreaPixels(null);
    let dims: { width: number; height: number } | null = null;
    if (isScopedTarget && scopeWithinElement) {
      const el = scopeWithinElement();
      if (el) {
        const r = el.getBoundingClientRect();
        dims = { width: r.width, height: r.height };
      }
    }
    setCropDiameter(computeCropDiameter(isCompact, isScopedTarget ? dims : null));
    setResetKey((k) => k + 1);
  }, [open, imageSrc, isCompact, isScopedTarget, scopeWithinElement]);

  /** Сужение/расширение правой колонки — только размер круга; без сброса pan/zoom. */
  React.useEffect(() => {
    if (!open || !isScopedTarget || !scopeWithinElement) return;
    const el = scopeWithinElement();
    if (!el) return;
    const r = el.getBoundingClientRect();
    setCropDiameter(computeCropDiameter(true, { width: r.width, height: r.height }));
  }, [open, isScopedTarget, scopeWithinElement, scopeLayoutVersion]);

  React.useEffect(() => {
    if (!open) return;
    const onResize = () => {
      if (!isScopedTarget) {
        setCropDiameter(computeCropDiameter(isCompact, null));
      }
    };
    if (isScopedTarget) return;
    window.addEventListener("resize", onResize);
    return () => window.removeEventListener("resize", onResize);
  }, [open, isCompact, isScopedTarget]);

  React.useEffect(() => {
    if (!open || !isCompact) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onCancel();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open, isCompact, onCancel]);

  const onCropComplete = React.useCallback((_area: Area, pixels: Area) => {
    setCroppedAreaPixels(pixels);
  }, []);

  const stop = (e: React.SyntheticEvent) => {
    e.preventDefault();
    e.stopPropagation();
  };

  const handleReset = (e: React.MouseEvent) => {
    stop(e);
    setCrop({ x: 0, y: 0 });
    setZoom(1);
    setResetKey((k) => k + 1);
  };

  const handleCancel = (e: React.MouseEvent) => {
    stop(e);
    onCancel();
  };

  const handleApply = async (e: React.MouseEvent) => {
    stop(e);
    if (!imageSrc || !croppedAreaPixels) return;
    setBusy(true);
    try {
      const blob = await getCircularCroppedImageBlob(imageSrc, croppedAreaPixels);
      const file = new File([blob], "avatar.jpg", { type: "image/jpeg" });
      onApply(file);
    } catch (err) {
      console.error("[RegisterAvatarCropOverlay] экспорт обрезки", err);
    } finally {
      setBusy(false);
    }
  };

  if (!open || !imageSrc) return null;

  const cropSize = { width: cropDiameter, height: cropDiameter };

  const controls = (
    <div
      className={cn(
        "relative z-30 isolate flex shrink-0 flex-col pointer-events-auto",
        isCompact
          ? "space-y-3 border-t border-white/10 bg-white/[0.06] px-4 pb-[max(0.85rem,env(safe-area-inset-bottom))] pt-3 backdrop-blur-xl"
          : "space-y-3 bg-neutral-950 px-4 pb-[max(1rem,env(safe-area-inset-bottom))] pt-3"
      )}
      onPointerDown={(e) => e.stopPropagation()}
      onClick={(e) => e.stopPropagation()}
    >
      <div className={cn("mx-auto w-full space-y-2", isCompact ? "max-w-[270px]" : "max-w-[200px]")}>
        <p className="text-center text-[11px] font-medium uppercase tracking-wide text-white/50">
          {t('avatarCrop.scaleLabel')}
        </p>
        <input
          type="range"
          min={1}
          max={3}
          step={0.02}
          value={zoom}
          aria-valuemin={1}
          aria-valuemax={3}
          aria-valuenow={zoom}
          aria-label={t('avatarCrop.scaleAria')}
          onChange={(e) => setZoom(Number(e.target.value))}
          className={cn(
            "h-3 w-full cursor-pointer appearance-none rounded-full bg-white/15",
            "[&::-webkit-slider-thumb]:h-4 [&::-webkit-slider-thumb]:w-4 [&::-webkit-slider-thumb]:cursor-grab [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:rounded-full [&::-webkit-slider-thumb]:border-2 [&::-webkit-slider-thumb]:border-primary [&::-webkit-slider-thumb]:bg-background",
            "[&::-moz-range-thumb]:h-4 [&::-moz-range-thumb]:w-4 [&::-moz-range-thumb]:cursor-grab [&::-moz-range-thumb]:rounded-full [&::-moz-range-thumb]:border-2 [&::-moz-range-thumb]:border-primary [&::-moz-range-thumb]:bg-background"
          )}
          style={{ touchAction: "manipulation" }}
        />
      </div>
      <p
        className={cn(
          "px-1 text-center text-white/55",
          isCompact ? "text-[11px] leading-snug sm:text-xs" : "px-2 text-xs"
        )}
      >
        {t('avatarCrop.hint')}
      </p>
      <div className={cn("grid grid-cols-3 gap-2", isCompact && "gap-2 sm:gap-2.5")}>
        <Button
          type="button"
          variant="ghost"
          className={cn(
            "rounded-xl border border-white/20 bg-transparent px-1 font-semibold uppercase tracking-wide text-white hover:bg-white/10",
            isCompact ? "h-11 text-[11px] sm:h-12 sm:text-xs" : "h-11 text-[11px] sm:text-xs"
          )}
          onClick={handleCancel}
          onPointerDown={(e) => e.stopPropagation()}
          disabled={busy}
        >
          {t('avatarCrop.cancel')}
        </Button>
        <Button
          type="button"
          variant="ghost"
          className={cn(
            "rounded-xl border border-white/20 bg-transparent px-1 font-semibold uppercase tracking-wide text-white hover:bg-white/10",
            isCompact ? "h-11 text-[11px] sm:h-12 sm:text-xs" : "h-11 text-[11px] sm:text-xs"
          )}
          onClick={handleReset}
          onPointerDown={(e) => e.stopPropagation()}
          disabled={busy}
        >
          {t('avatarCrop.reset')}
        </Button>
        <Button
          type="button"
          className={cn(
            "rounded-xl px-1 font-semibold",
            isCompact ? "h-11 text-[11px] sm:h-12 sm:text-xs" : "h-11 text-[11px] sm:text-xs"
          )}
          onClick={handleApply}
          onPointerDown={(e) => e.stopPropagation()}
          disabled={busy || !croppedAreaPixels}
        >
          {busy ? <Loader2 className="h-4 w-4 animate-spin" aria-label={t('avatarCrop.saving')} /> : t('avatarCrop.save')}
        </Button>
      </div>
    </div>
  );

  const cropper = (
    <div
      className={cn(
        "relative z-0 w-full",
        isCompact ? "h-[270px] shrink-0 sm:h-[315px]" : "min-h-0 flex-1"
      )}
    >
      <Cropper
        key={resetKey}
        image={imageSrc}
        crop={crop}
        cropSize={cropSize}
        zoom={zoom}
        aspect={1}
        cropShape="round"
        showGrid={false}
        minZoom={1}
        maxZoom={3}
        zoomSpeed={0.5}
        onCropChange={setCrop}
        onZoomChange={setZoom}
        onCropComplete={onCropComplete}
        objectFit="contain"
        restrictPosition
        classes={{
          containerClassName: cn(
            "relative h-full w-full",
            isCompact ? "rounded-t-3xl bg-black/20 backdrop-blur-sm" : "bg-neutral-950"
          ),
          mediaClassName: "max-h-full max-w-full",
        }}
      />
    </div>
  );

  const title = (
    <h2 id="register-crop-title" className="sr-only">
      {t('avatarCrop.title')}
    </h2>
  );

  const compactBackdropAndCard = (
    <>
      <button
        type="button"
        className="absolute inset-0 bg-black/40 backdrop-blur-2xl backdrop-saturate-150"
        aria-label={t('avatarCrop.closeAria')}
        onClick={onCancel}
      />
      <div
        className={cn(
          "relative z-10 flex w-full flex-col overflow-hidden rounded-3xl border border-white/20",
          "bg-gradient-to-b from-white/[0.12] to-white/[0.05] shadow-[0_25px_60px_-15px_rgba(0,0,0,0.65)]",
          "backdrop-blur-2xl backdrop-saturate-150 ring-1 ring-inset ring-white/[0.12]",
          "max-h-[min(88dvh,780px)] max-w-[min(100%,450px)] sm:max-w-[510px]"
        )}
        onPointerDown={(e) => e.stopPropagation()}
      >
        {cropper}
        {controls}
      </div>
    </>
  );

  /** Blur только над правой колонкой; список чатов слева остаётся чётким. */
  if (isCompact && isScopedTarget && scopeRect) {
    return (
      <div
        className="relative flex items-center justify-center overflow-hidden p-3 sm:p-5"
        style={{
          position: "fixed",
          top: scopeRect.top,
          left: scopeRect.left,
          width: scopeRect.width,
          height: scopeRect.height,
          zIndex: 200,
        }}
        role="dialog"
        aria-modal="true"
        aria-labelledby="register-crop-title"
      >
        {title}
        {compactBackdropAndCard}
      </div>
    );
  }

  return (
    <div
      className={cn(
        "fixed inset-0 z-[200]",
        isCompact
          ? "flex items-center justify-center p-3 sm:p-5"
          : "flex flex-col bg-neutral-950"
      )}
      role="dialog"
      aria-modal="true"
      aria-labelledby="register-crop-title"
    >
      {title}

      {isCompact ? (
        compactBackdropAndCard
      ) : (
        <>
          <div
            className="pointer-events-none shrink-0 pt-[max(0.75rem,env(safe-area-inset-top))]"
            aria-hidden
          />
          <div className="flex min-h-0 w-full flex-1 flex-col bg-neutral-950">
            {cropper}
            {controls}
          </div>
        </>
      )}
    </div>
  );
}
