import type { BottomNavIconVisualStyle } from '@/lib/types';

/**
 * Слой пункта меню поверх универсального: непустые поля `perHref` заменяют значения из `global`.
 */
export function mergeBottomNavIconVisualStyles(
  global: BottomNavIconVisualStyle | undefined | null,
  perHref: BottomNavIconVisualStyle | undefined | null
): BottomNavIconVisualStyle {
  const g = global && typeof global === 'object' ? global : {};
  const p = perHref && typeof perHref === 'object' ? perHref : {};
  const out: BottomNavIconVisualStyle = {};

  const pickStr = (pk: unknown, gk: unknown): string | undefined => {
    if (typeof pk === 'string' && pk.trim()) return pk.trim();
    if (typeof gk === 'string' && gk.trim()) return gk.trim();
    return undefined;
  };

  const iconColor = pickStr(p.iconColor, g.iconColor);
  if (iconColor) out.iconColor = iconColor;

  const strokeP = p.strokeWidth;
  const strokeG = g.strokeWidth;
  const strokeWidth =
    typeof strokeP === 'number' && Number.isFinite(strokeP) && strokeP >= 0.75
      ? strokeP
      : typeof strokeG === 'number' && Number.isFinite(strokeG) && strokeG >= 0.75
        ? strokeG
        : undefined;
  if (strokeWidth !== undefined) out.strokeWidth = strokeWidth;

  const tile = pickStr(p.tileBackground, g.tileBackground);
  if (tile) out.tileBackground = tile;

  return out;
}
