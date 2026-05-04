import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Gradient preset CSS values (constant; labels are localized via [chatWallpaperGradientPresets]).
const List<String> kChatWallpaperGradientValues = <String>[
  'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
  'linear-gradient(135deg, #f093fb 0%, #f5576c 100%)',
  'linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)',
  'linear-gradient(135deg, #43e97b 0%, #38f9d7 100%)',
  'linear-gradient(135deg, #fa709a 0%, #fee140 100%)',
  'linear-gradient(135deg, #C6E8EB 0%, #E9D0DE 100%)',
  'linear-gradient(135deg, #D9F904 0%, #6CEB00 100%)',
  'linear-gradient(135deg, #151619 0%, #23242A 100%)',
];

/// Returns gradient presets with localized labels.
List<({String value, String label})> chatWallpaperGradientPresets(AppLocalizations l10n) {
  return <({String value, String label})>[
    (value: kChatWallpaperGradientValues[0], label: l10n.wallpaper_purple),
    (value: kChatWallpaperGradientValues[1], label: l10n.wallpaper_pink),
    (value: kChatWallpaperGradientValues[2], label: l10n.wallpaper_blue),
    (value: kChatWallpaperGradientValues[3], label: l10n.wallpaper_green),
    (value: kChatWallpaperGradientValues[4], label: l10n.wallpaper_sunset),
    (value: kChatWallpaperGradientValues[5], label: l10n.wallpaper_tender),
    (value: kChatWallpaperGradientValues[6], label: l10n.wallpaper_lime),
    (value: kChatWallpaperGradientValues[7], label: l10n.wallpaper_graphite),
  ];
}

Gradient? wallpaperPreviewGradient(String? value) {
  switch (value) {
    case 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)':
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
      );
    case 'linear-gradient(135deg, #f093fb 0%, #f5576c 100%)':
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
      );
    case 'linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)':
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
      );
    case 'linear-gradient(135deg, #43e97b 0%, #38f9d7 100%)':
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF43E97B), Color(0xFF38F9D7)],
      );
    case 'linear-gradient(135deg, #fa709a 0%, #fee140 100%)':
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFA709A), Color(0xFFFEE140)],
      );
    case 'linear-gradient(135deg, #C6E8EB 0%, #E9D0DE 100%)':
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFC6E8EB), Color(0xFFE9D0DE)],
      );
    case 'linear-gradient(135deg, #D9F904 0%, #6CEB00 100%)':
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFD9F904), Color(0xFF6CEB00)],
      );
    case 'linear-gradient(135deg, #151619 0%, #23242A 100%)':
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF151619), Color(0xFF23242A)],
      );
    default:
      return null;
  }
}

/// Миниатюра пресета / своего URL для сетки выбора фона.
BoxDecoration wallpaperPreviewDecoration(BuildContext context, String? value) {
  final scheme = Theme.of(context).colorScheme;
  final dark = scheme.brightness == Brightness.dark;
  if (value == null || value.isEmpty) {
    return BoxDecoration(
      color: (dark ? Colors.white : scheme.surfaceContainerHigh).withValues(
        alpha: dark ? 0.06 : 0.9,
      ),
      borderRadius: BorderRadius.circular(20),
    );
  }
  if (value.startsWith('http')) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      image: DecorationImage(image: NetworkImage(value), fit: BoxFit.cover),
    );
  }
  final gradient = wallpaperPreviewGradient(value);
  return BoxDecoration(
    borderRadius: BorderRadius.circular(20),
    gradient: gradient,
    color: gradient == null
        ? (dark ? Colors.white : scheme.surfaceContainerHigh).withValues(
            alpha: dark ? 0.06 : 0.9,
          )
        : null,
  );
}
