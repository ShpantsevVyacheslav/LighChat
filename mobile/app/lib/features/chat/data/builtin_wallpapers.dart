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
