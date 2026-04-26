import 'package:flutter/material.dart';

/// Пресеты градиента (совпадают с [`ChatSettingsScreen`] и веб-настройками чата).
const List<({String value, String label})> kChatWallpaperGradientPresets =
    <({String value, String label})>[
      (
        value: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
        label: 'Фиолетовый',
      ),
      (
        value: 'linear-gradient(135deg, #f093fb 0%, #f5576c 100%)',
        label: 'Розовый',
      ),
      (
        value: 'linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)',
        label: 'Голубой',
      ),
      (
        value: 'linear-gradient(135deg, #43e97b 0%, #38f9d7 100%)',
        label: 'Зелёный',
      ),
      (value: 'linear-gradient(135deg, #fa709a 0%, #fee140 100%)', label: 'Закат'),
      (value: 'linear-gradient(135deg, #C6E8EB 0%, #E9D0DE 100%)', label: 'Нежный'),
      (value: 'linear-gradient(135deg, #D9F904 0%, #6CEB00 100%)', label: 'Лайм'),
      (value: 'linear-gradient(135deg, #151619 0%, #23242A 100%)', label: 'Графит'),
    ];

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
