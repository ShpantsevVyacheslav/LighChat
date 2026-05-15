/**
 * Анимированные обои чата.
 *
 * Web рендерит статичный preview-asset; «живая» анимация пока реализована
 * только на mobile (Flutter `AnimatedWallpaperLayer` поверх preview),
 * см. `mobile/app/lib/features/chat/data/animated_wallpapers.dart`.
 *
 * Значение поля `chatSettings.chatWallpaper` для анимированного обоя имеет
 * вид `animated:<slug>` — отличается от builtin (`builtin:<slug>`).
 */
export const ANIMATED_WALLPAPER_PREFIX = 'animated:';

export type AnimatedWallpaperSlug =
  | 'falling-star'
  | 'lighthouse-beam'
  | 'milky-way'
  | 'wave-motion'
  | 'rain'
  | 'fireflies';

export interface AnimatedWallpaper {
  slug: AnimatedWallpaperSlug;
  /** i18n key under `chatSettings.animatedWallpaperLabel.*` */
  labelKey: string;
  /** Public path for the light-theme preview image. */
  light: string;
  /** Public path for the dark-theme preview image. */
  dark: string;
  /** Lightweight CSS gradient used for instant preview before the WebP loads. */
  previewGradient: string;
}

export const ANIMATED_WALLPAPERS: readonly AnimatedWallpaper[] = [
  {
    slug: 'falling-star',
    labelKey: 'fallingStar',
    light: '/wallpapers/animated-falling-star-light.webp',
    dark: '/wallpapers/animated-falling-star-dark.webp',
    previewGradient: 'linear-gradient(180deg, #04061C 0%, #0A0C24 100%)',
  },
  {
    slug: 'lighthouse-beam',
    labelKey: 'lighthouseBeam',
    light: '/wallpapers/animated-lighthouse-beam-light.webp',
    dark: '/wallpapers/animated-lighthouse-beam-dark.webp',
    previewGradient: 'linear-gradient(180deg, #0E1626 0%, #182840 100%)',
  },
  {
    slug: 'milky-way',
    labelKey: 'milkyWay',
    light: '/wallpapers/animated-milky-way-light.webp',
    dark: '/wallpapers/animated-milky-way-dark.webp',
    previewGradient: 'linear-gradient(180deg, #04061C 0%, #0A0C20 100%)',
  },
  {
    slug: 'wave-motion',
    labelKey: 'waveMotion',
    light: '/wallpapers/animated-wave-motion-light.webp',
    dark: '/wallpapers/animated-wave-motion-dark.webp',
    previewGradient: 'linear-gradient(180deg, #0A1730 0%, #081B36 100%)',
  },
  {
    slug: 'rain',
    labelKey: 'rain',
    light: '/wallpapers/animated-rain-light.webp',
    dark: '/wallpapers/animated-rain-dark.webp',
    previewGradient: 'linear-gradient(180deg, #0E1622 0%, #181E2E 100%)',
  },
  {
    slug: 'fireflies',
    labelKey: 'fireflies',
    light: '/wallpapers/animated-fireflies-light.webp',
    dark: '/wallpapers/animated-fireflies-dark.webp',
    previewGradient: 'linear-gradient(180deg, #080F12 0%, #0E1518 100%)',
  },
] as const;

const ANIMATED_BY_SLUG: Record<string, AnimatedWallpaper> = Object.fromEntries(
  ANIMATED_WALLPAPERS.map((w) => [w.slug, w]),
);

export function isAnimatedWallpaperValue(value: string | null | undefined): boolean {
  return !!value && value.startsWith(ANIMATED_WALLPAPER_PREFIX);
}

export function parseAnimatedWallpaperSlug(value: string | null | undefined): AnimatedWallpaperSlug | null {
  if (!isAnimatedWallpaperValue(value)) return null;
  const slug = value!.slice(ANIMATED_WALLPAPER_PREFIX.length);
  return ANIMATED_BY_SLUG[slug] ? (slug as AnimatedWallpaperSlug) : null;
}

export function resolveAnimatedWallpaper(value: string | null | undefined): AnimatedWallpaper | null {
  const slug = parseAnimatedWallpaperSlug(value);
  return slug ? ANIMATED_BY_SLUG[slug] : null;
}

export function animatedWallpaperValue(slug: AnimatedWallpaperSlug): string {
  return `${ANIMATED_WALLPAPER_PREFIX}${slug}`;
}

export function pickAnimatedWallpaperSrc(
  wallpaper: AnimatedWallpaper,
  resolvedTheme: 'light' | 'dark' | null | undefined,
): string {
  return resolvedTheme === 'dark' ? wallpaper.dark : wallpaper.light;
}
