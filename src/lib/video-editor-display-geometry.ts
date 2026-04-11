/**
 * Геометрия видео в layout: `object-contain` даёт letterbox; crop/рисунок живут в
 * координатах intrinsic (videoWidth × videoHeight).
 */

export type VideoObjectContainMapping = {
  offsetX: number;
  offsetY: number;
  /** Ширина нарисованного кадра в CSS px внутри элемента <video>. */
  cssW: number;
  cssH: number;
  vw: number;
  vh: number;
  /** Множитель intrinsic px на 1 CSS px в области кадра (1/scale от object-fit). */
  scale: number;
};

export function getVideoObjectContainMapping(el: HTMLVideoElement): VideoObjectContainMapping | null {
  const vw = el.videoWidth;
  const vh = el.videoHeight;
  const ew = el.clientWidth;
  const eh = el.clientHeight;
  if (!ew || !eh || !vw || !vh) return null;
  const s = Math.min(ew / vw, eh / vh);
  const cssW = vw * s;
  const cssH = vh * s;
  const offsetX = (ew - cssW) / 2;
  const offsetY = (eh - cssH) / 2;
  return { offsetX, offsetY, cssW, cssH, vw, vh, scale: s };
}

/**
 * Точка в системе координат элемента (0,0 — левый верх клиентской области тега) → intrinsic px.
 */
export function elementPointToVideoIntrinsics(
  video: HTMLVideoElement,
  relX: number,
  relY: number,
): { x: number; y: number } | null {
  const m = getVideoObjectContainMapping(video);
  if (!m) return null;
  const u = (relX - m.offsetX) / m.cssW;
  const v = (relY - m.offsetY) / m.cssH;
  return {
    x: Math.min(m.vw, Math.max(0, u * m.vw)),
    y: Math.min(m.vh, Math.max(0, v * m.vh)),
  };
}

/**
 * Смещение мыши в клиентских px → смещение в intrinsic px (для drag/resize crop).
 */
export function clientDeltaToVideoDelta(video: HTMLVideoElement, dClientX: number, dClientY: number): { dx: number; dy: number } | null {
  const m = getVideoObjectContainMapping(video);
  if (!m) return null;
  return { dx: dClientX / m.scale, dy: dClientY / m.scale };
}

export function intrinsicCropRectToOverlayBoxPx(
  video: HTMLVideoElement,
  rect: { x: number; y: number; width: number; height: number },
): { left: number; top: number; width: number; height: number } | null {
  const m = getVideoObjectContainMapping(video);
  if (!m) return null;
  return {
    left: m.offsetX + (rect.x / m.vw) * m.cssW,
    top: m.offsetY + (rect.y / m.vh) * m.cssH,
    width: (rect.width / m.vw) * m.cssW,
    height: (rect.height / m.vh) * m.cssH,
  };
}
