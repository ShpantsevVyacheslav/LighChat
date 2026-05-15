import 'package:flutter/material.dart';

/// Встроенные фирменные обои чата. Параллельный manifest для web:
/// `src/lib/builtinWallpapers.ts` — slug-и совпадают, оба клиента читают
/// то же значение поля `chatSettings.chatWallpaper` вида `builtin:<slug>`.
const String kBuiltinWallpaperPrefix = 'builtin:';

@immutable
class BuiltinWallpaper {
  const BuiltinWallpaper({
    required this.slug,
    required this.lightAsset,
    required this.darkAsset,
    required this.previewGradient,
  });

  final String slug;
  final String lightAsset;
  final String darkAsset;

  /// Градиент для мгновенного превью в сетке выбора до загрузки картинки.
  final LinearGradient previewGradient;

  String get value => '$kBuiltinWallpaperPrefix$slug';

  String assetFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkAsset : lightAsset;
}

const List<BuiltinWallpaper> kBuiltinWallpapers = <BuiltinWallpaper>[
  BuiltinWallpaper(
    slug: 'lighthouse-dawn',
    lightAsset: 'assets/wallpapers/lighthouse-dawn-light.webp',
    darkAsset: 'assets/wallpapers/lighthouse-dawn-dark.webp',
    previewGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFDCBC), Color(0xFFD4E8EB)],
    ),
  ),
  BuiltinWallpaper(
    slug: 'keeper-watch',
    lightAsset: 'assets/wallpapers/keeper-watch-light.webp',
    darkAsset: 'assets/wallpapers/keeper-watch-dark.webp',
    previewGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFC8DCF0), Color(0xFFF5E6D2)],
    ),
  ),
  BuiltinWallpaper(
    slug: 'crab-shore',
    lightAsset: 'assets/wallpapers/crab-shore-light.webp',
    darkAsset: 'assets/wallpapers/crab-shore-dark.webp',
    previewGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFC8E6EB), Color(0xFFF4DCB2)],
    ),
  ),
  BuiltinWallpaper(
    slug: 'lighthouse-aurora',
    lightAsset: 'assets/wallpapers/lighthouse-aurora-light.webp',
    darkAsset: 'assets/wallpapers/lighthouse-aurora-dark.webp',
    previewGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFEBF0FA), Color(0xFFD7EBF0)],
    ),
  ),
  BuiltinWallpaper(
    slug: 'keeper-cabin',
    lightAsset: 'assets/wallpapers/keeper-cabin-light.webp',
    darkAsset: 'assets/wallpapers/keeper-cabin-dark.webp',
    previewGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFD2DCE6), Color(0xFFB4C3D2)],
    ),
  ),
  BuiltinWallpaper(
    slug: 'crew-shore',
    lightAsset: 'assets/wallpapers/crew-shore-light.webp',
    darkAsset: 'assets/wallpapers/crew-shore-dark.webp',
    previewGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFF0DEC8), Color(0xFFC8DCE8)],
    ),
  ),
  BuiltinWallpaper(
    slug: 'mark-constellation',
    lightAsset: 'assets/wallpapers/mark-constellation-light.webp',
    darkAsset: 'assets/wallpapers/mark-constellation-dark.webp',
    previewGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFE1EBFA), Color(0xFFC8DCF0)],
    ),
  ),
  BuiltinWallpaper(
    slug: 'ocean-waves',
    lightAsset: 'assets/wallpapers/ocean-waves-light.webp',
    darkAsset: 'assets/wallpapers/ocean-waves-dark.webp',
    previewGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE0EAFF), Color(0xFFE3D7F5)],
    ),
  ),
  BuiltinWallpaper(
    slug: 'doodle-marine',
    lightAsset: 'assets/wallpapers/doodle-marine-light.webp',
    darkAsset: 'assets/wallpapers/doodle-marine-dark.webp',
    previewGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFDAEAF4), Color(0xFFBED7E6)],
    ),
  ),
  BuiltinWallpaper(
    slug: 'doodle-stickers',
    lightAsset: 'assets/wallpapers/doodle-stickers-light.webp',
    darkAsset: 'assets/wallpapers/doodle-stickers-dark.webp',
    previewGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFCE6C8), Color(0xFFEBDAE8)],
    ),
  ),
  BuiltinWallpaper(
    slug: 'doodle-formula',
    lightAsset: 'assets/wallpapers/doodle-formula-light.webp',
    darkAsset: 'assets/wallpapers/doodle-formula-dark.webp',
    previewGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFDCE6F5), Color(0xFFC8DAEC)],
    ),
  ),
  BuiltinWallpaper(
    slug: 'mountains-mist',
    lightAsset: 'assets/wallpapers/mountains-mist-light.webp',
    darkAsset: 'assets/wallpapers/mountains-mist-dark.webp',
    previewGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFADABC), Color(0xFFDCE8F0)],
    ),
  ),
  BuiltinWallpaper(
    slug: 'pine-deer',
    lightAsset: 'assets/wallpapers/pine-deer-light.webp',
    darkAsset: 'assets/wallpapers/pine-deer-dark.webp',
    previewGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFCD7C3), Color(0xFFD7E6F0)],
    ),
  ),
  BuiltinWallpaper(
    slug: 'fuji-wave',
    lightAsset: 'assets/wallpapers/fuji-wave-light.webp',
    darkAsset: 'assets/wallpapers/fuji-wave-dark.webp',
    previewGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFAE8C8), Color(0xFFDAE8F4)],
    ),
  ),
  BuiltinWallpaper(
    slug: 'fuji-natural',
    lightAsset: 'assets/wallpapers/fuji-natural-light.webp',
    darkAsset: 'assets/wallpapers/fuji-natural-dark.webp',
    previewGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFCD7C3), Color(0xFFDCE8F0)],
    ),
  ),
  BuiltinWallpaper(
    slug: 'sakura-branch',
    lightAsset: 'assets/wallpapers/sakura-branch-light.webp',
    darkAsset: 'assets/wallpapers/sakura-branch-dark.webp',
    previewGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFEBF0), Color(0xFFEBE8FA)],
    ),
  ),
  BuiltinWallpaper(
    slug: 'misty-forest',
    lightAsset: 'assets/wallpapers/misty-forest-light.webp',
    darkAsset: 'assets/wallpapers/misty-forest-dark.webp',
    previewGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFDCDED9), Color(0xFFB4C3C3)],
    ),
  ),
  BuiltinWallpaper(
    slug: 'autumn-leaves',
    lightAsset: 'assets/wallpapers/autumn-leaves-light.webp',
    darkAsset: 'assets/wallpapers/autumn-leaves-dark.webp',
    previewGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFCDCAF), Color(0xFFF4C396)],
    ),
  ),
  BuiltinWallpaper(
    slug: 'galaxy-nebula',
    lightAsset: 'assets/wallpapers/galaxy-nebula-light.webp',
    darkAsset: 'assets/wallpapers/galaxy-nebula-dark.webp',
    previewGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFD2D7EB), Color(0xFFB4C3DE)],
    ),
  ),
  BuiltinWallpaper(
    slug: 'rain-bokeh',
    lightAsset: 'assets/wallpapers/rain-bokeh-light.webp',
    darkAsset: 'assets/wallpapers/rain-bokeh-dark.webp',
    previewGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFBEC8DC), Color(0xFFA0AFC8)],
    ),
  ),
  BuiltinWallpaper(
    slug: 'bamboo-zen',
    lightAsset: 'assets/wallpapers/bamboo-zen-light.webp',
    darkAsset: 'assets/wallpapers/bamboo-zen-dark.webp',
    previewGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFEBF0DC), Color(0xFFC3D7C3)],
    ),
  ),
  BuiltinWallpaper(
    slug: 'arctic-aurora',
    lightAsset: 'assets/wallpapers/arctic-aurora-light.webp',
    darkAsset: 'assets/wallpapers/arctic-aurora-dark.webp',
    previewGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFD7E6F5), Color(0xFFEBF0F5)],
    ),
  ),
  BuiltinWallpaper(
    slug: 'desert-dunes',
    lightAsset: 'assets/wallpapers/desert-dunes-light.webp',
    darkAsset: 'assets/wallpapers/desert-dunes-dark.webp',
    previewGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFCC382), Color(0xFFFCDCAF)],
    ),
  ),
  BuiltinWallpaper(
    slug: 'city-skyline',
    lightAsset: 'assets/wallpapers/city-skyline-light.webp',
    darkAsset: 'assets/wallpapers/city-skyline-dark.webp',
    previewGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFF5E1C3), Color(0xFFD7DCEB)],
    ),
  ),
  BuiltinWallpaper(
    slug: 'neon-grid',
    lightAsset: 'assets/wallpapers/neon-grid-light.webp',
    darkAsset: 'assets/wallpapers/neon-grid-dark.webp',
    previewGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFADCE6), Color(0xFFDCC3EB)],
    ),
  ),
  BuiltinWallpaper(
    slug: 'lavender-field',
    lightAsset: 'assets/wallpapers/lavender-field-light.webp',
    darkAsset: 'assets/wallpapers/lavender-field-dark.webp',
    previewGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFCD7CD), Color(0xFFDCC8E6)],
    ),
  ),
  BuiltinWallpaper(
    slug: 'kitten-yarn',
    lightAsset: 'assets/wallpapers/kitten-yarn-light.webp',
    darkAsset: 'assets/wallpapers/kitten-yarn-dark.webp',
    previewGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFCE8D7), Color(0xFFF0D7DC)],
    ),
  ),
  BuiltinWallpaper(
    slug: 'cute-fox',
    lightAsset: 'assets/wallpapers/cute-fox-light.webp',
    darkAsset: 'assets/wallpapers/cute-fox-dark.webp',
    previewGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFCDAC3), Color(0xFFDCE6D7)],
    ),
  ),
  BuiltinWallpaper(
    slug: 'panda-bamboo',
    lightAsset: 'assets/wallpapers/panda-bamboo-light.webp',
    darkAsset: 'assets/wallpapers/panda-bamboo-dark.webp',
    previewGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFEBF5DC), Color(0xFFD7E6C3)],
    ),
  ),
  BuiltinWallpaper(
    slug: 'owl-night',
    lightAsset: 'assets/wallpapers/owl-night-light.webp',
    darkAsset: 'assets/wallpapers/owl-night-dark.webp',
    previewGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFC8D7EB), Color(0xFFD7DCF0)],
    ),
  ),
  BuiltinWallpaper(
    slug: 'bunny-meadow',
    lightAsset: 'assets/wallpapers/bunny-meadow-light.webp',
    darkAsset: 'assets/wallpapers/bunny-meadow-dark.webp',
    previewGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFD7E8F5), Color(0xFFC8E6C3)],
    ),
  ),
];

bool isBuiltinWallpaperValue(String? value) =>
    value != null && value.startsWith(kBuiltinWallpaperPrefix);

BuiltinWallpaper? resolveBuiltinWallpaper(String? value) {
  if (!isBuiltinWallpaperValue(value)) return null;
  final slug = value!.substring(kBuiltinWallpaperPrefix.length);
  for (final w in kBuiltinWallpapers) {
    if (w.slug == slug) return w;
  }
  return null;
}
