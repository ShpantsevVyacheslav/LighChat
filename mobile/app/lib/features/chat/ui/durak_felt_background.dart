import 'dart:math' as math;

import 'package:flutter/material.dart';

class DurakFeltBackground extends StatelessWidget {
  const DurakFeltBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FeltPainter(
        base: const Color(0xFF0B2B2B),
        tint: const Color(0xFF0F4C3A),
      ),
      child: child,
    );
  }
}

class _FeltPainter extends CustomPainter {
  _FeltPainter({
    required this.base,
    required this.tint,
  });

  final Color base;
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Base felt gradient.
    final bg = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.3),
        radius: 1.2,
        colors: [
          tint.withValues(alpha: 0.95),
          base.withValues(alpha: 0.98),
          Colors.black.withValues(alpha: 0.92),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, bg);

    // Subtle noise texture (deterministic grid).
    final noise = Paint()..color = Colors.white.withValues(alpha: 0.04);
    const step = 6.0;
    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        final v = math.sin(x * 0.15) * math.cos(y * 0.17);
        if (v > 0.35) {
          canvas.drawRect(Rect.fromLTWH(x, y, 1.2, 1.2), noise);
        }
      }
    }

    // Vignette.
    final vignette = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.15,
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.35),
        ],
        stops: const [0.55, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, vignette);
  }

  @override
  bool shouldRepaint(covariant _FeltPainter oldDelegate) {
    return oldDelegate.base != base || oldDelegate.tint != tint;
  }
}

