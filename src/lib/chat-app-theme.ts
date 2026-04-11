/**
 * Третья тема интерфейса («по фону чата»): цвета из градиента или усреднение загруженного изображения.
 */

import { wallpaperImageUrlForThemeSampling } from "@/lib/wallpaper-theme-image-url";

function parseHexToRgb(hex: string): { r: number; g: number; b: number } | null {
  let h = hex.replace('#', '').trim();
  if (h.length === 3) {
    h = h[0] + h[0] + h[1] + h[1] + h[2] + h[2];
  }
  if (h.length !== 6 && h.length !== 8) return null;
  const n = parseInt(h.slice(0, 6), 16);
  if (Number.isNaN(n)) return null;
  return { r: (n >> 16) & 255, g: (n >> 8) & 255, b: n & 255 };
}

/** Извлекает hex-цвета из CSS linear-gradient / произвольной строки. */
export function parseGradientHexColors(wallpaper: string): string[] {
  const m = wallpaper.match(/#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})\b/g);
  return m ?? [];
}

function parseGradientRgbColors(wallpaper: string): { r: number; g: number; b: number }[] {
  const out: { r: number; g: number; b: number }[] = [];
  const re = /rgb\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*\)/gi;
  let m: RegExpExecArray | null;
  while ((m = re.exec(wallpaper)) !== null) {
    out.push({ r: +m[1], g: +m[2], b: +m[3] });
  }
  return out;
}

function averageRgb(colors: { r: number; g: number; b: number }[]): { r: number; g: number; b: number } {
  if (colors.length === 0) return { r: 40, g: 50, b: 80 };
  let r = 0;
  let g = 0;
  let b = 0;
  for (const c of colors) {
    r += c.r;
    g += c.g;
    b += c.b;
  }
  const n = colors.length;
  return { r: Math.round(r / n), g: Math.round(g / n), b: Math.round(b / n) };
}

function relativeLuminance(r: number, g: number, b: number): number {
  const lin = [r, g, b].map((v) => {
    const x = v / 255;
    return x <= 0.03928 ? x / 12.92 : Math.pow((x + 0.055) / 1.055, 2.4);
  });
  return 0.2126 * lin[0] + 0.7152 * lin[1] + 0.0722 * lin[2];
}

/** H S% L% для переменных shadcn (без обёртки hsl()). */
function rgbToHslSpace(r: number, g: number, b: number): string {
  const r1 = r / 255;
  const g1 = g / 255;
  const b1 = b / 255;
  const max = Math.max(r1, g1, b1);
  const min = Math.min(r1, g1, b1);
  const l = (max + min) / 2;
  let h = 0;
  let s = 0;
  const d = max - min;
  if (d > 1e-6) {
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
    switch (max) {
      case r1:
        h = ((g1 - b1) / d + (g1 < b1 ? 6 : 0)) / 6;
        break;
      case g1:
        h = ((b1 - r1) / d + 2) / 6;
        break;
      default:
        h = ((r1 - g1) / d + 4) / 6;
        break;
    }
  }
  const sP = Math.max(0, Math.min(100, Math.round(s * 100)));
  const lP = Math.max(0, Math.min(100, Math.round(l * 100)));
  return `${Math.round(h * 360)} ${sP}% ${lP}%`;
}

export async function sampleWallpaperImageAverageRgb(
  url: string
): Promise<{ r: number; g: number; b: number } | null> {
  if (typeof window === 'undefined') return null;
  const src = wallpaperImageUrlForThemeSampling(url);
  const usedProxy = src !== url;
  return new Promise((resolve) => {
    const img = new Image();
    /** Прокси same-origin — canvas не «tainted»; прямой внешний URL без прокси требует CORS (в Safari часто падает). */
    if (
      !usedProxy &&
      (url.startsWith('http://') || url.startsWith('https://'))
    ) {
      img.crossOrigin = 'anonymous';
    }
    const done = (v: { r: number; g: number; b: number } | null) => resolve(v);
    img.onload = () => {
      try {
        const canvas = document.createElement('canvas');
        const w = 48;
        const h = 48;
        canvas.width = w;
        canvas.height = h;
        const ctx = canvas.getContext('2d');
        if (!ctx) {
          done(null);
          return;
        }
        ctx.drawImage(img, 0, 0, w, h);
        const data = ctx.getImageData(0, 0, w, h).data;
        let r = 0;
        let g = 0;
        let b = 0;
        let n = 0;
        for (let i = 0; i < data.length; i += 4) {
          r += data[i];
          g += data[i + 1];
          b += data[i + 2];
          n++;
        }
        done({ r: Math.round(r / n), g: Math.round(g / n), b: Math.round(b / n) });
      } catch {
        done(null);
      }
    };
    img.onerror = () => done(null);
    img.src = src;
  });
}

/** Собирает 1+ акцентных RGB из фона: градиент (hex) или усреднение картинки. */
export async function resolveWallpaperAccentRgbs(
  wallpaper: string | null
): Promise<{ r: number; g: number; b: number }[]> {
  if (!wallpaper) return [];
  if (wallpaper.startsWith('http') || wallpaper.startsWith('data:')) {
    const one = await sampleWallpaperImageAverageRgb(wallpaper);
    return one ? [one] : [];
  }
  const fromRgb = parseGradientRgbColors(wallpaper);
  if (fromRgb.length > 0) return fromRgb;
  const hexes = parseGradientHexColors(wallpaper);
  const rgbs: { r: number; g: number; b: number }[] = [];
  for (const h of hexes) {
    const c = parseHexToRgb(h);
    if (c) rgbs.push(c);
  }
  return rgbs;
}

/** Имена CSS-переменных, которые выставляет тема «chat» (нужно сбрасывать при смене темы). */
export const CHAT_THEME_CSS_VAR_NAMES: string[] = [
  '--background',
  '--foreground',
  '--card',
  '--card-foreground',
  '--popover',
  '--popover-foreground',
  '--primary',
  '--primary-foreground',
  '--secondary',
  '--secondary-foreground',
  '--muted',
  '--muted-foreground',
  '--accent',
  '--accent-foreground',
  '--border',
  '--input',
  '--ring',
  '--sidebar-background',
  '--sidebar-foreground',
  '--sidebar-accent',
  '--sidebar-accent-foreground',
  '--sidebar-border',
  '--sidebar-ring',
  '--glass-background',
  '--glass-border',
];

/**
 * Строит значения CSS-переменных (формат «H S% L%» или с альфой «H S% L% / a») из набора акцентных цветов.
 */
export function buildChatThemeStyleProps(
  accentRgbs: { r: number; g: number; b: number }[]
): Record<string, string> {
  const avg = averageRgb(accentRgbs);
  const lum = relativeLuminance(avg.r, avg.g, avg.b);
  const isLightBackdrop = lum > 0.52;
  const hPrimary = rgbToHslSpace(avg.r, avg.g, avg.b);
  const [, , pLraw] = hPrimary.split(' ');
  const pL = parseInt(pLraw.replace('%', ''), 10) || 50;

  if (isLightBackdrop) {
    const bgH = hPrimary.split(' ')[0];
    return {
      '--background': `${bgH} 32% 96%`,
      '--foreground': `${bgH} 28% 12%`,
      '--card': `0 0% 100%`,
      '--card-foreground': `${bgH} 28% 12%`,
      '--popover': `0 0% 100%`,
      '--popover-foreground': `${bgH} 28% 12%`,
      '--primary': `${bgH} 72% ${Math.min(48, Math.max(38, pL))}%`,
      '--primary-foreground': `0 0% 100%`,
      '--secondary': `${bgH} 25% 92%`,
      '--secondary-foreground': `${bgH} 30% 18%`,
      '--muted': `${bgH} 20% 90%`,
      '--muted-foreground': `${bgH} 12% 38%`,
      '--accent': `${bgH} 40% 90%`,
      '--accent-foreground': `${bgH} 30% 18%`,
      '--border': `${bgH} 18% 88%`,
      '--input': `${bgH} 18% 88%`,
      '--ring': `${bgH} 72% 45%`,
      '--sidebar-background': `${bgH} 25% 98% / 0.95`,
      '--sidebar-foreground': `${bgH} 28% 12%`,
      '--sidebar-accent': `${bgH} 22% 94% / 0.85`,
      '--sidebar-accent-foreground': `${bgH} 28% 12%`,
      '--sidebar-border': `${bgH} 18% 90% / 0.55`,
      '--sidebar-ring': `${bgH} 72% 45%`,
      '--glass-background': `0 0% 100% / 0.72`,
      '--glass-border': `0 0% 0% / 0.06`,
    };
  }

  const h = hPrimary.split(' ')[0];
  return {
    '--background': `${h} 28% 8%`,
    '--foreground': `${h} 12% 96%`,
    '--card': `${h} 24% 11%`,
    '--card-foreground': `${h} 12% 96%`,
    '--popover': `${h} 26% 10%`,
    '--popover-foreground': `${h} 12% 96%`,
    '--primary': `${h} 68% ${Math.min(58, Math.max(48, Math.round(56 + (50 - pL) * 0.08)))}%`,
    '--primary-foreground': `0 0% 100%`,
    '--secondary': `${h} 18% 14%`,
    '--secondary-foreground': `${h} 12% 95%`,
    '--muted': `${h} 16% 16%`,
    '--muted-foreground': `${h} 10% 62%`,
    '--accent': `${h} 22% 18%`,
    '--accent-foreground': `${h} 12% 96%`,
    '--border': `${h} 18% 20% / 0.55`,
    '--input': `${h} 18% 20%`,
    '--ring': `${h} 68% 52%`,
    '--sidebar-background': `${h} 26% 11% / 0.42`,
    '--sidebar-foreground': `${h} 12% 95%`,
    '--sidebar-accent': `${h} 22% 18% / 0.6`,
    '--sidebar-accent-foreground': `${h} 12% 95%`,
    '--sidebar-border': `${h} 18% 18% / 0.5`,
    '--sidebar-ring': `${h} 68% 52%`,
    '--glass-background': `0 0% 0% / 0.38`,
    '--glass-border': `0 0% 100% / 0.08`,
  };
}

export function defaultChatThemeWhenNoWallpaper(): Record<string, string> {
  return buildChatThemeStyleProps([{ r: 80, g: 100, b: 200 }]);
}

/** Для Tailwind `dark:` при теме `chat`: true — светлый UI, false — тёмный. */
export function isLightChatBackdropFromRgbs(
  accentRgbs: { r: number; g: number; b: number }[]
): boolean {
  const avg = averageRgb(
    accentRgbs.length > 0 ? accentRgbs : [{ r: 40, g: 50, b: 80 }]
  );
  return relativeLuminance(avg.r, avg.g, avg.b) > 0.52;
}
