import 'package:flutter/material.dart';

/// Unified application backdrop used by screens that "sit on the background".
///
/// Dark mode must match the chats list background (see `ChatListScreen`).
class AppBackdrop extends StatelessWidget {
  const AppBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (dark) _DarkChatsBackdrop(scheme: scheme) else _LightWashBackdrop(scheme: scheme),
        child,
      ],
    );
  }
}

class _DarkChatsBackdrop extends StatelessWidget {
  const _DarkChatsBackdrop({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    // In auto-theme mode the `seedColor` is derived from the chat wallpaper,
    // so we bind the backdrop glow to the theme scheme to reflect it.
    final glowA = scheme.primary;
    final glowB = scheme.tertiary;
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(decoration: BoxDecoration(color: Color(0xFF04070C))),
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
                    glowA.withValues(alpha: 0.34),
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
                    glowB.withValues(alpha: 0.28),
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
                  Colors.black.withValues(alpha: 0.28),
                  Colors.black.withValues(alpha: 0.50),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LightWashBackdrop extends StatelessWidget {
  const _LightWashBackdrop({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(color: Color(0xFFF1F5F9)),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.primary.withValues(alpha: 0.18),
                  scheme.secondary.withValues(alpha: 0.10),
                  scheme.tertiary.withValues(alpha: 0.14),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

