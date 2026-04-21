import 'package:flutter/material.dart';

/// Фон «оболочки» приложения (список чатов, контакты, звонки, профиль собеседника и т.д.),
/// без обоев отдельного чата (`chatWallpaper`).
class ChatShellBackdrop extends StatelessWidget {
  const ChatShellBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final glowA = dark ? scheme.primary : const Color(0xFF4B7FFF);
    final glowB = dark ? scheme.tertiary : const Color(0xFF9C74FF);
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF04070C) : const Color(0xFFF3F6FC),
          ),
        ),
        Positioned(
          left: -130,
          top: -160,
          child: IgnorePointer(
            child: Container(
              width: 410,
              height: 410,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    glowA.withValues(alpha: dark ? 0.34 : 0.18),
                    glowA.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: -95,
          bottom: -120,
          child: IgnorePointer(
            child: Container(
              width: 330,
              height: 330,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    glowB.withValues(alpha: dark ? 0.28 : 0.14),
                    glowB.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  (dark ? Colors.black : const Color(0xFF6B7280)).withValues(
                    alpha: dark ? 0.28 : 0.06,
                  ),
                  (dark ? Colors.black : const Color(0xFF6B7280)).withValues(
                    alpha: dark ? 0.50 : 0.10,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
