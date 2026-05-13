import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Лёгкий «дождь» конфетти на CustomPainter, без новой зависимости.
/// Используется как:
///   * фоновый эффект на экране поздравления (плотность low, бесконечный
///     цикл с приглушёнными цветами);
///   * «взрыв» при отправке поздравления (плотность high, один цикл).
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({
    super.key,
    this.particleCount = 28,
    this.duration = const Duration(seconds: 6),
    this.loop = true,
    this.intensity = 1.0,
  });

  /// Количество одновременно живущих частиц.
  final int particleCount;

  /// Длительность одного «цикла». При [loop]=false виджет тушит частицы
  /// после полного прохода.
  final Duration duration;
  final bool loop;

  /// Множитель вертикальной скорости и размера частиц. 0.5 — спокойный фон,
  /// 1.5 — мощный взрыв.
  final double intensity;

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;
  final math.Random _rng = math.Random(42);

  static const _palette = <Color>[
    Color(0xFFF4A12C), // brand orange
    Color(0xFFE94E77),
    Color(0xFF1D9BF0),
    Color(0xFFFFC83D),
    Color(0xFF8B5CF6),
    Color(0xFF21C685),
  ];

  @override
  void initState() {
    super.initState();
    _particles = List.generate(widget.particleCount, _spawn);
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _controller.addListener(() => setState(() {}));
    if (widget.loop) {
      _controller.repeat();
    } else {
      _controller.forward();
    }
  }

  _Particle _spawn(int i) {
    return _Particle(
      seed: _rng.nextDouble(),
      x: _rng.nextDouble(),
      size: 4 + _rng.nextDouble() * 6,
      color: _palette[_rng.nextInt(_palette.length)],
      rotation: _rng.nextDouble() * math.pi * 2,
      rotationSpeed: (_rng.nextDouble() - 0.5) * 6,
      swayAmp: 12 + _rng.nextDouble() * 32,
      swaySpeed: 0.5 + _rng.nextDouble() * 1.5,
      verticalSpeed: 0.6 + _rng.nextDouble() * 0.6,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ConfettiPainter(
          particles: _particles,
          progress: _controller.value,
          intensity: widget.intensity,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.seed,
    required this.x,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
    required this.swayAmp,
    required this.swaySpeed,
    required this.verticalSpeed,
  });

  final double seed;
  final double x;
  final double size;
  final Color color;
  final double rotation;
  final double rotationSpeed;
  final double swayAmp;
  final double swaySpeed;
  final double verticalSpeed;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({
    required this.particles,
    required this.progress,
    required this.intensity,
  });

  final List<_Particle> particles;
  final double progress;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      final phase = (progress + p.seed) % 1.0;
      final y = (phase - 0.1) * size.height * 1.2 * p.verticalSpeed * intensity;
      if (y < -p.size || y > size.height + p.size) continue;
      final sway =
          math.sin((progress + p.seed) * math.pi * 2 * p.swaySpeed) * p.swayAmp;
      final cx = p.x * size.width + sway;
      final rot = p.rotation + p.rotationSpeed * progress;

      canvas.save();
      canvas.translate(cx, y);
      canvas.rotate(rot);
      paint.color = p.color.withValues(alpha: 0.85);
      final s = p.size * intensity;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: s, height: s * 0.4),
          Radius.circular(s * 0.15),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) =>
      old.progress != progress || old.intensity != intensity;
}
