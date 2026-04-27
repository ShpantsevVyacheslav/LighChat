import 'package:flutter/material.dart';

/// Heuristic: should foreground content prefer light colors on this chat wallpaper?
///
/// This is intentionally simple and deterministic:
/// - Default backdrop and photo wallpapers are treated as "dark" (light foreground),
///   because photo wallpapers receive a dark overlay in `ChatWallpaperBackground`.
/// - For known gradient presets we classify a few as "light" (dark foreground).
bool chatWallpaperPrefersLightForeground(String? wallpaper) {
  final raw = wallpaper?.trim();
  if (raw == null || raw.isEmpty) return true; // default backdrop is dark
  if (raw.startsWith('http')) return true; // photo wallpaper is dimmed by overlay

  // Known light gradients where dark foreground reads better.
  const lightGradients = <String>{
    'linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)',
    'linear-gradient(135deg, #43e97b 0%, #38f9d7 100%)',
    'linear-gradient(135deg, #fa709a 0%, #fee140 100%)',
    'linear-gradient(135deg, #a18cd1 0%, #fbc2eb 100%)',
    'linear-gradient(135deg, #d4fc79 0%, #96e6a1 100%)',
    'linear-gradient(135deg, #C6E8EB 0%, #E9D0DE 100%)',
    'linear-gradient(135deg, #D9F904 0%, #6CEB00 100%)',
  };
  if (lightGradients.contains(raw)) return false;

  // Known dark gradients (and any unknown preset) default to light foreground.
  return true;
}

Color chatWallpaperAdaptivePrimaryTextColor({
  required BuildContext context,
  required String? wallpaper,
}) {
  final prefersLight = chatWallpaperPrefersLightForeground(wallpaper);
  if (prefersLight) return Colors.white.withValues(alpha: 0.95);
  return Colors.black.withValues(alpha: 0.90);
}

Color chatWallpaperAdaptiveSecondaryTextColor({
  required BuildContext context,
  required String? wallpaper,
}) {
  final prefersLight = chatWallpaperPrefersLightForeground(wallpaper);
  if (prefersLight) return Colors.white.withValues(alpha: 0.62);
  return Colors.black.withValues(alpha: 0.55);
}

