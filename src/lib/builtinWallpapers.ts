/**
 * Встроенные фирменные обои чата. Источник правды для web и mobile.
 *
 * Значение поля `chatSettings.chatWallpaper` для встроенного обоя имеет вид
 * `builtin:<slug>` — клиент сам резолвит slug в конкретный ассет и подбирает
 * вариант под текущую тему интерфейса. Параллельный manifest для Flutter:
 * `mobile/app/lib/features/chat/data/builtin_wallpapers.dart`.
 */
export const BUILTIN_WALLPAPER_PREFIX = 'builtin:';

export type BuiltinWallpaperSlug =
  | 'lighthouse-dawn'
  | 'keeper-watch'
  | 'crab-shore'
  | 'lighthouse-aurora'
  | 'keeper-cabin'
  | 'crew-shore'
  | 'mark-constellation'
  | 'ocean-waves'
  | 'doodle-marine'
  | 'doodle-stickers'
  | 'doodle-formula'
  | 'mountains-mist'
  | 'pine-deer'
  | 'fuji-wave'
  | 'fuji-natural'
  | 'sakura-branch'
  | 'misty-forest'
  | 'autumn-leaves'
  | 'galaxy-nebula'
  | 'rain-bokeh'
  | 'bamboo-zen'
  | 'arctic-aurora'
  | 'desert-dunes'
  | 'city-skyline'
  | 'neon-grid'
  | 'lavender-field'
  | 'kitten-yarn'
  | 'cute-fox'
  | 'panda-bamboo'
  | 'owl-night'
  | 'bunny-meadow'
  | 'lighthouse-3d'
  | 'crab-3d'
  | 'cosmos-3d'
  | 'ocean-3d'
  | 'starry-night'
  | 'deep-ocean'
  | 'night-sea'
  | 'clean-galaxy';

export interface BuiltinWallpaper {
  slug: BuiltinWallpaperSlug;
  /** i18n key under `chatSettings.builtinWallpaperLabel.*` */
  labelKey: string;
  /** Public path for the light-theme variant. */
  light: string;
  /** Public path for the dark-theme variant. */
  dark: string;
  /** Lightweight CSS gradient used for instant preview before the WebP loads. */
  previewGradient: string;
}

export const BUILTIN_WALLPAPERS: readonly BuiltinWallpaper[] = [
  {
    slug: 'lighthouse-dawn',
    labelKey: 'lighthouseDawn',
    light: '/wallpapers/lighthouse-dawn-light.webp',
    dark: '/wallpapers/lighthouse-dawn-dark.webp',
    previewGradient: 'linear-gradient(180deg, #FFDCBC 0%, #D4E8EB 100%)',
  },
  {
    slug: 'keeper-watch',
    labelKey: 'keeperWatch',
    light: '/wallpapers/keeper-watch-light.webp',
    dark: '/wallpapers/keeper-watch-dark.webp',
    previewGradient: 'linear-gradient(180deg, #C8DCF0 0%, #F5E6D2 100%)',
  },
  {
    slug: 'crab-shore',
    labelKey: 'crabShore',
    light: '/wallpapers/crab-shore-light.webp',
    dark: '/wallpapers/crab-shore-dark.webp',
    previewGradient: 'linear-gradient(180deg, #C8E6EB 0%, #F4DCB2 100%)',
  },
  {
    slug: 'lighthouse-aurora',
    labelKey: 'lighthouseAurora',
    light: '/wallpapers/lighthouse-aurora-light.webp',
    dark: '/wallpapers/lighthouse-aurora-dark.webp',
    previewGradient: 'linear-gradient(180deg, #EBF0FA 0%, #D7EBF0 100%)',
  },
  {
    slug: 'keeper-cabin',
    labelKey: 'keeperCabin',
    light: '/wallpapers/keeper-cabin-light.webp',
    dark: '/wallpapers/keeper-cabin-dark.webp',
    previewGradient: 'linear-gradient(180deg, #D2DCE6 0%, #B4C3D2 100%)',
  },
  {
    slug: 'crew-shore',
    labelKey: 'crewShore',
    light: '/wallpapers/crew-shore-light.webp',
    dark: '/wallpapers/crew-shore-dark.webp',
    previewGradient: 'linear-gradient(180deg, #F0DEC8 0%, #C8DCE8 100%)',
  },
  {
    slug: 'mark-constellation',
    labelKey: 'markConstellation',
    light: '/wallpapers/mark-constellation-light.webp',
    dark: '/wallpapers/mark-constellation-dark.webp',
    previewGradient: 'linear-gradient(180deg, #E1EBFA 0%, #C8DCF0 100%)',
  },
  {
    slug: 'ocean-waves',
    labelKey: 'oceanWaves',
    light: '/wallpapers/ocean-waves-light.webp',
    dark: '/wallpapers/ocean-waves-dark.webp',
    previewGradient: 'linear-gradient(135deg, #E0EAFF 0%, #E3D7F5 100%)',
  },
  {
    slug: 'doodle-marine',
    labelKey: 'doodleMarine',
    light: '/wallpapers/doodle-marine-light.webp',
    dark: '/wallpapers/doodle-marine-dark.webp',
    previewGradient: 'linear-gradient(180deg, #DAEAF4 0%, #BED7E6 100%)',
  },
  {
    slug: 'doodle-stickers',
    labelKey: 'doodleStickers',
    light: '/wallpapers/doodle-stickers-light.webp',
    dark: '/wallpapers/doodle-stickers-dark.webp',
    previewGradient: 'linear-gradient(180deg, #FCE6C8 0%, #EBDAE8 100%)',
  },
  {
    slug: 'doodle-formula',
    labelKey: 'doodleFormula',
    light: '/wallpapers/doodle-formula-light.webp',
    dark: '/wallpapers/doodle-formula-dark.webp',
    previewGradient: 'linear-gradient(180deg, #DCE6F5 0%, #C8DAEC 100%)',
  },
  {
    slug: 'mountains-mist',
    labelKey: 'mountainsMist',
    light: '/wallpapers/mountains-mist-light.webp',
    dark: '/wallpapers/mountains-mist-dark.webp',
    previewGradient: 'linear-gradient(180deg, #FADABC 0%, #DCE8F0 100%)',
  },
  {
    slug: 'pine-deer',
    labelKey: 'pineDeer',
    light: '/wallpapers/pine-deer-light.webp',
    dark: '/wallpapers/pine-deer-dark.webp',
    previewGradient: 'linear-gradient(180deg, #FCD7C3 0%, #D7E6F0 100%)',
  },
  {
    slug: 'fuji-wave',
    labelKey: 'fujiWave',
    light: '/wallpapers/fuji-wave-light.webp',
    dark: '/wallpapers/fuji-wave-dark.webp',
    previewGradient: 'linear-gradient(180deg, #FAE8C8 0%, #DAE8F4 100%)',
  },
  {
    slug: 'fuji-natural',
    labelKey: 'fujiNatural',
    light: '/wallpapers/fuji-natural-light.webp',
    dark: '/wallpapers/fuji-natural-dark.webp',
    previewGradient: 'linear-gradient(180deg, #FCD7C3 0%, #DCE8F0 100%)',
  },
  {
    slug: 'sakura-branch',
    labelKey: 'sakuraBranch',
    light: '/wallpapers/sakura-branch-light.webp',
    dark: '/wallpapers/sakura-branch-dark.webp',
    previewGradient: 'linear-gradient(180deg, #FFEBF0 0%, #EBE8FA 100%)',
  },
  {
    slug: 'misty-forest',
    labelKey: 'mistyForest',
    light: '/wallpapers/misty-forest-light.webp',
    dark: '/wallpapers/misty-forest-dark.webp',
    previewGradient: 'linear-gradient(180deg, #DCDED9 0%, #B4C3C3 100%)',
  },
  {
    slug: 'autumn-leaves',
    labelKey: 'autumnLeaves',
    light: '/wallpapers/autumn-leaves-light.webp',
    dark: '/wallpapers/autumn-leaves-dark.webp',
    previewGradient: 'linear-gradient(180deg, #FCDCAF 0%, #F4C396 100%)',
  },
  {
    slug: 'galaxy-nebula',
    labelKey: 'galaxyNebula',
    light: '/wallpapers/galaxy-nebula-light.webp',
    dark: '/wallpapers/galaxy-nebula-dark.webp',
    previewGradient: 'linear-gradient(180deg, #D2D7EB 0%, #B4C3DE 100%)',
  },
  {
    slug: 'rain-bokeh',
    labelKey: 'rainBokeh',
    light: '/wallpapers/rain-bokeh-light.webp',
    dark: '/wallpapers/rain-bokeh-dark.webp',
    previewGradient: 'linear-gradient(180deg, #BEC8DC 0%, #A0AFC8 100%)',
  },
  {
    slug: 'bamboo-zen',
    labelKey: 'bambooZen',
    light: '/wallpapers/bamboo-zen-light.webp',
    dark: '/wallpapers/bamboo-zen-dark.webp',
    previewGradient: 'linear-gradient(180deg, #EBF0DC 0%, #C3D7C3 100%)',
  },
  {
    slug: 'arctic-aurora',
    labelKey: 'arcticAurora',
    light: '/wallpapers/arctic-aurora-light.webp',
    dark: '/wallpapers/arctic-aurora-dark.webp',
    previewGradient: 'linear-gradient(180deg, #D7E6F5 0%, #EBF0F5 100%)',
  },
  {
    slug: 'desert-dunes',
    labelKey: 'desertDunes',
    light: '/wallpapers/desert-dunes-light.webp',
    dark: '/wallpapers/desert-dunes-dark.webp',
    previewGradient: 'linear-gradient(180deg, #FCC382 0%, #FCDCAF 100%)',
  },
  {
    slug: 'city-skyline',
    labelKey: 'citySkyline',
    light: '/wallpapers/city-skyline-light.webp',
    dark: '/wallpapers/city-skyline-dark.webp',
    previewGradient: 'linear-gradient(180deg, #F5E1C3 0%, #D7DCEB 100%)',
  },
  {
    slug: 'neon-grid',
    labelKey: 'neonGrid',
    light: '/wallpapers/neon-grid-light.webp',
    dark: '/wallpapers/neon-grid-dark.webp',
    previewGradient: 'linear-gradient(180deg, #FADCE6 0%, #DCC3EB 100%)',
  },
  {
    slug: 'lavender-field',
    labelKey: 'lavenderField',
    light: '/wallpapers/lavender-field-light.webp',
    dark: '/wallpapers/lavender-field-dark.webp',
    previewGradient: 'linear-gradient(180deg, #FCD7CD 0%, #DCC8E6 100%)',
  },
  {
    slug: 'kitten-yarn',
    labelKey: 'kittenYarn',
    light: '/wallpapers/kitten-yarn-light.webp',
    dark: '/wallpapers/kitten-yarn-dark.webp',
    previewGradient: 'linear-gradient(180deg, #FCE8D7 0%, #F0D7DC 100%)',
  },
  {
    slug: 'cute-fox',
    labelKey: 'cuteFox',
    light: '/wallpapers/cute-fox-light.webp',
    dark: '/wallpapers/cute-fox-dark.webp',
    previewGradient: 'linear-gradient(180deg, #FCDAC3 0%, #DCE6D7 100%)',
  },
  {
    slug: 'panda-bamboo',
    labelKey: 'pandaBamboo',
    light: '/wallpapers/panda-bamboo-light.webp',
    dark: '/wallpapers/panda-bamboo-dark.webp',
    previewGradient: 'linear-gradient(180deg, #EBF5DC 0%, #D7E6C3 100%)',
  },
  {
    slug: 'owl-night',
    labelKey: 'owlNight',
    light: '/wallpapers/owl-night-light.webp',
    dark: '/wallpapers/owl-night-dark.webp',
    previewGradient: 'linear-gradient(180deg, #C8D7EB 0%, #D7DCF0 100%)',
  },
  {
    slug: 'bunny-meadow',
    labelKey: 'bunnyMeadow',
    light: '/wallpapers/bunny-meadow-light.webp',
    dark: '/wallpapers/bunny-meadow-dark.webp',
    previewGradient: 'linear-gradient(180deg, #D7E8F5 0%, #C8E6C3 100%)',
  },
  {
    slug: 'lighthouse-3d',
    labelKey: 'lighthouse3d',
    light: '/wallpapers/lighthouse-3d-light.webp',
    dark: '/wallpapers/lighthouse-3d-dark.webp',
    previewGradient: 'linear-gradient(180deg, #FADCBC 0%, #C8DCF0 100%)',
  },
  {
    slug: 'crab-3d',
    labelKey: 'crab3d',
    light: '/wallpapers/crab-3d-light.webp',
    dark: '/wallpapers/crab-3d-dark.webp',
    previewGradient: 'linear-gradient(180deg, #F5DCC3 0%, #DCE6EB 100%)',
  },
  {
    slug: 'cosmos-3d',
    labelKey: 'cosmos3d',
    light: '/wallpapers/cosmos-3d-light.webp',
    dark: '/wallpapers/cosmos-3d-dark.webp',
    previewGradient: 'linear-gradient(180deg, #1E1A30 0%, #2C2440 100%)',
  },
  {
    slug: 'ocean-3d',
    labelKey: 'ocean3d',
    light: '/wallpapers/ocean-3d-light.webp',
    dark: '/wallpapers/ocean-3d-dark.webp',
    previewGradient: 'linear-gradient(180deg, #D7E8F8 0%, #B4D2E6 100%)',
  },
  {
    slug: 'starry-night',
    labelKey: 'starryNight',
    light: '/wallpapers/starry-night-light.webp',
    dark: '/wallpapers/starry-night-dark.webp',
    previewGradient: 'linear-gradient(180deg, #04061C 0%, #0A0C24 100%)',
  },
  {
    slug: 'deep-ocean',
    labelKey: 'deepOcean',
    light: '/wallpapers/deep-ocean-light.webp',
    dark: '/wallpapers/deep-ocean-dark.webp',
    previewGradient: 'linear-gradient(180deg, #DCE8F0 0%, #285F8C 100%)',
  },
  {
    slug: 'night-sea',
    labelKey: 'nightSea',
    light: '/wallpapers/night-sea-light.webp',
    dark: '/wallpapers/night-sea-dark.webp',
    previewGradient: 'linear-gradient(180deg, #0A132C 0%, #0E1A2C 100%)',
  },
  {
    slug: 'clean-galaxy',
    labelKey: 'cleanGalaxy',
    light: '/wallpapers/clean-galaxy-light.webp',
    dark: '/wallpapers/clean-galaxy-dark.webp',
    previewGradient: 'linear-gradient(180deg, #050714 0%, #0A0E22 100%)',
  },
] as const;

const BUILTIN_BY_SLUG: Record<string, BuiltinWallpaper> = Object.fromEntries(
  BUILTIN_WALLPAPERS.map((w) => [w.slug, w]),
);

export function isBuiltinWallpaperValue(value: string | null | undefined): boolean {
  return !!value && value.startsWith(BUILTIN_WALLPAPER_PREFIX);
}

export function parseBuiltinWallpaperSlug(value: string | null | undefined): BuiltinWallpaperSlug | null {
  if (!isBuiltinWallpaperValue(value)) return null;
  const slug = value!.slice(BUILTIN_WALLPAPER_PREFIX.length);
  return BUILTIN_BY_SLUG[slug] ? (slug as BuiltinWallpaperSlug) : null;
}

export function resolveBuiltinWallpaper(value: string | null | undefined): BuiltinWallpaper | null {
  const slug = parseBuiltinWallpaperSlug(value);
  return slug ? BUILTIN_BY_SLUG[slug] : null;
}

export function builtinWallpaperValue(slug: BuiltinWallpaperSlug): string {
  return `${BUILTIN_WALLPAPER_PREFIX}${slug}`;
}

export function pickBuiltinWallpaperSrc(
  wallpaper: BuiltinWallpaper,
  resolvedTheme: 'light' | 'dark' | null | undefined,
): string {
  return resolvedTheme === 'dark' ? wallpaper.dark : wallpaper.light;
}
