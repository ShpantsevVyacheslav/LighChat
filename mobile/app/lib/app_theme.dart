import 'package:flutter/material.dart';
import 'package:lighchat_ui/lighchat_ui.dart';

ThemeData buildAppTheme({required Brightness brightness, Color? seedColor}) {
  final seed = seedColor ?? const Color(0xFF7C3AED);
  final base = lighChatTheme(brightness: brightness);
  final isDark = brightness == Brightness.dark;
  final pageBg = isDark ? const Color(0xFF04070C) : const Color(0xFFF1F5F9);
  final surface = isDark ? const Color(0xFF0B1018) : Colors.white;
  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
  ).copyWith(
    surface: surface,
    surfaceContainerLowest: pageBg,
    surfaceContainerLow: isDark
        ? const Color(0xFF101826)
        : const Color(0xFFF7FAFD),
    surfaceContainer: isDark
        ? const Color(0xFF121C2B)
        : const Color(0xFFF4F8FC),
    surfaceContainerHigh: isDark
        ? const Color(0xFF162233)
        : const Color(0xFFEFF4FA),
    surfaceContainerHighest: isDark
        ? const Color(0xFF1A273A)
        : const Color(0xFFE9EFF7),
  );

  // Match the typographic scale and density of `ChatListScreen` across the app.
  final baseText = base.textTheme;
  final text = baseText.copyWith(
    titleLarge: baseText.titleLarge?.copyWith(fontSize: 18, height: 1.15),
    titleMedium: baseText.titleMedium?.copyWith(fontSize: 16, height: 1.15),
    titleSmall: baseText.titleSmall?.copyWith(fontSize: 14, height: 1.2),
    bodyLarge: baseText.bodyLarge?.copyWith(fontSize: 15, height: 1.25),
    bodyMedium: baseText.bodyMedium?.copyWith(fontSize: 14, height: 1.25),
    bodySmall: baseText.bodySmall?.copyWith(fontSize: 12, height: 1.2),
    labelLarge: baseText.labelLarge?.copyWith(fontSize: 13, height: 1.15),
    labelMedium: baseText.labelMedium?.copyWith(fontSize: 12, height: 1.15),
    labelSmall: baseText.labelSmall?.copyWith(fontSize: 11, height: 1.1),
  );

  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: pageBg,
    canvasColor: pageBg,
    cardColor: surface,
    textTheme: text,
    visualDensity: VisualDensity.compact,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    dialogTheme: (base.dialogTheme).copyWith(backgroundColor: surface),
    dividerColor: isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08),
    appBarTheme: (base.appBarTheme).copyWith(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    listTileTheme: (base.listTileTheme).copyWith(
      dense: true,
      minVerticalPadding: 0,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    ),
    inputDecorationTheme: (base.inputDecorationTheme).copyWith(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
    bottomSheetTheme: (base.bottomSheetTheme).copyWith(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: Colors.transparent,
    ),
    navigationBarTheme: (base.navigationBarTheme).copyWith(
      backgroundColor: isDark ? const Color(0xFF060A12) : Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
  );
}
