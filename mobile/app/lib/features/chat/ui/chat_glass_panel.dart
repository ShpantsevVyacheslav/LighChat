import 'dart:ui';

import 'package:flutter/material.dart';

/// Размытый тёмный фон как у [ChatHeader] / капсулы даты — читаемость на обоях.
/// Используется для опроса, системных карточек (геолокация и т.п.).
class ChatGlassPanel extends StatelessWidget {
  const ChatGlassPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final cs = base.colorScheme;
    final glassScheme = cs.copyWith(
      onSurface: Colors.white.withValues(alpha: 0.96),
      onSurfaceVariant: Colors.white.withValues(alpha: 0.72),
      surfaceContainerHighest: Colors.white.withValues(alpha: 0.22),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.26),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Theme(
            data: base.copyWith(colorScheme: glassScheme),
            child: IconTheme.merge(
              data: IconThemeData(color: Colors.white.withValues(alpha: 0.82)),
              child: DefaultTextStyle.merge(
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.96),
                  fontWeight: FontWeight.w600,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
