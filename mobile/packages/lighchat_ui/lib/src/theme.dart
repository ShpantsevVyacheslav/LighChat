import 'package:flutter/material.dart';

/// Uses the platform UI font (no runtime download). Avoids `google_fonts` HTTP fetches,
/// which fail under macOS sandbox / offline and broke cold start.
ThemeData lighChatTheme({required Brightness brightness}) {
  return ThemeData(
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF7C3AED),
      brightness: brightness,
    ),
    useMaterial3: true,
  );
}

