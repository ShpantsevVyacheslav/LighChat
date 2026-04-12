import 'package:flutter/material.dart';

/// Подложка и цвета для подписей поверх фото-обоев чата (тёмная тема).
BoxDecoration chatWallpaperSafePillDecoration(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return BoxDecoration(
    borderRadius: BorderRadius.circular(999),
    color: isDark
        ? Colors.black.withValues(alpha: 0.62)
        : Colors.black.withValues(alpha: 0.18),
    border: Border.all(
      color: isDark
          ? Colors.white.withValues(alpha: 0.32)
          : Colors.white.withValues(alpha: 0.14),
    ),
  );
}

Color chatWallpaperSafePrimaryTextColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  if (isDark) return Colors.white.withValues(alpha: 0.95);
  return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85);
}

Color chatWallpaperSafeSecondaryIconColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  if (isDark) return Colors.white.withValues(alpha: 0.78);
  return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);
}
