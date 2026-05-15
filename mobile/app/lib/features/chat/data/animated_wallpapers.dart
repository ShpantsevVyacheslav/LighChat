import 'package:flutter/material.dart';

/// Анимированные обои чата.
///
/// Принципиально отличается от [BuiltinWallpaper] двумя вещами:
///   1. Поверх статичного preview-ассета рисуется живой [CustomPainter] с
///      привязкой к [AnimationController] (см. `AnimatedWallpaperLayer`).
///   2. Анимация **одноразовая**: проигрывается один раз при открытии чата
///      (`controller.forward()`) и затем замирает на финальном кадре —
///      не отвлекает от переписки.
///
/// Значение поля `users.chatSettings.chatWallpaper` для анимированного
/// обоя имеет вид `animated:<slug>`. Превью статичной версии лежит в
/// `assets/wallpapers/animated-<slug>-{light,dark}.webp` — оно показывается
/// в UI-пикерах и как fallback если контроллер ещё не запущен.
const String kAnimatedWallpaperPrefix = 'animated:';

@immutable
class AnimatedWallpaper {
  const AnimatedWallpaper({
    required this.slug,
    required this.lightAsset,
    required this.darkAsset,
    required this.previewGradient,
    required this.durationMs,
  });

  final String slug;
  final String lightAsset;
  final String darkAsset;
  final LinearGradient previewGradient;

  /// Сколько длится одна проигрываемая анимация (миллисекунды). После
  /// этого она замирает в финальном состоянии.
  final int durationMs;

  String get value => '$kAnimatedWallpaperPrefix$slug';

  String assetFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkAsset : lightAsset;
}

const List<AnimatedWallpaper> kAnimatedWallpapers = <AnimatedWallpaper>[
  AnimatedWallpaper(
    slug: 'falling-star',
    lightAsset: 'assets/wallpapers/animated-falling-star-light.webp',
    darkAsset: 'assets/wallpapers/animated-falling-star-dark.webp',
    previewGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF04061C), Color(0xFF0A0C24)],
    ),
    durationMs: 2400,
  ),
  AnimatedWallpaper(
    slug: 'lighthouse-beam',
    lightAsset: 'assets/wallpapers/animated-lighthouse-beam-light.webp',
    darkAsset: 'assets/wallpapers/animated-lighthouse-beam-dark.webp',
    previewGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0E1626), Color(0xFF182840)],
    ),
    durationMs: 4200,
  ),
  AnimatedWallpaper(
    slug: 'milky-way',
    lightAsset: 'assets/wallpapers/animated-milky-way-light.webp',
    darkAsset: 'assets/wallpapers/animated-milky-way-dark.webp',
    previewGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF04061C), Color(0xFF0A0C20)],
    ),
    durationMs: 3600,
  ),
  AnimatedWallpaper(
    slug: 'wave-motion',
    lightAsset: 'assets/wallpapers/animated-wave-motion-light.webp',
    darkAsset: 'assets/wallpapers/animated-wave-motion-dark.webp',
    previewGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0A1730), Color(0xFF081B36)],
    ),
    durationMs: 4800,
  ),
  AnimatedWallpaper(
    slug: 'rain',
    lightAsset: 'assets/wallpapers/animated-rain-light.webp',
    darkAsset: 'assets/wallpapers/animated-rain-dark.webp',
    previewGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0E1622), Color(0xFF181E2E)],
    ),
    durationMs: 4000,
  ),
  AnimatedWallpaper(
    slug: 'fireflies',
    lightAsset: 'assets/wallpapers/animated-fireflies-light.webp',
    darkAsset: 'assets/wallpapers/animated-fireflies-dark.webp',
    previewGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF080F12), Color(0xFF0E1518)],
    ),
    durationMs: 5000,
  ),
];

bool isAnimatedWallpaperValue(String? value) =>
    value != null && value.startsWith(kAnimatedWallpaperPrefix);

AnimatedWallpaper? resolveAnimatedWallpaper(String? value) {
  if (!isAnimatedWallpaperValue(value)) return null;
  final slug = value!.substring(kAnimatedWallpaperPrefix.length);
  for (final w in kAnimatedWallpapers) {
    if (w.slug == slug) return w;
  }
  return null;
}
