import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../brand_colors.dart';

/// Звёзды на фоне (фаза F0). Мерцают по синусу.
class StarsPainter extends CustomPainter {
  StarsPainter({required this.t, required this.seeds});

  final double t; // 0..1 общий прогресс
  final List<StarSeed> seeds;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (final s in seeds) {
      final blink =
          0.35 + 0.65 * (0.5 + 0.5 * math.sin(t * 2 * math.pi * s.speed + s.phase));
      paint.color = Colors.white.withValues(alpha: s.baseOpacity * blink);
      canvas.drawCircle(
        Offset(s.dx * size.width, s.dy * size.height),
        s.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant StarsPainter oldDelegate) => oldDelegate.t != t;
}

class StarSeed {
  StarSeed(this.dx, this.dy, this.radius, this.baseOpacity, this.phase, this.speed);
  final double dx;
  final double dy;
  final double radius;
  final double baseOpacity;
  final double phase;
  final double speed;

  static List<StarSeed> generate(int count) {
    final rng = math.Random(42);
    return List.generate(count, (_) {
      return StarSeed(
        rng.nextDouble(),
        rng.nextDouble() * 0.7, // концентрируем в верхней части неба
        0.4 + rng.nextDouble() * 1.4,
        0.45 + rng.nextDouble() * 0.5,
        rng.nextDouble() * math.pi * 2,
        0.4 + rng.nextDouble() * 1.2,
      );
    });
  }
}

/// Готовый seed-список звёзд (стабильный между билдами).
final List<StarSeed> kStarSeeds = StarSeed.generate(30);

/// Маяк — code-drawn placeholder (используется пока нет SVG).
class LighthousePainter extends CustomPainter {
  const LighthousePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Скала под маяком
    final rockPaint = Paint()..color = const Color(0xFF0A1626);
    final rockPath = Path()
      ..moveTo(0, h)
      ..lineTo(w, h)
      ..lineTo(w * 0.85, h * 0.85)
      ..quadraticBezierTo(w * 0.5, h * 0.78, w * 0.15, h * 0.85)
      ..close();
    canvas.drawPath(rockPath, rockPaint);

    // Башня маяка (трапеция)
    final towerPaint = Paint()..color = Colors.white.withValues(alpha: 0.92);
    final stripePaint = Paint()..color = kBrandCoral;
    final towerPath = Path()
      ..moveTo(w * 0.42, h * 0.85)
      ..lineTo(w * 0.58, h * 0.85)
      ..lineTo(w * 0.55, h * 0.32)
      ..lineTo(w * 0.45, h * 0.32)
      ..close();
    canvas.drawPath(towerPath, towerPaint);

    // Полоски на башне
    for (int i = 0; i < 3; i++) {
      final yTop = h * (0.42 + i * 0.15);
      final stripe = Path()
        ..moveTo(w * (0.435 + i * 0.002), yTop)
        ..lineTo(w * (0.565 - i * 0.002), yTop)
        ..lineTo(w * (0.563 - i * 0.002), yTop + h * 0.06)
        ..lineTo(w * (0.437 + i * 0.002), yTop + h * 0.06)
        ..close();
      canvas.drawPath(stripe, stripePaint);
    }

    // Балкон
    final balconyPaint = Paint()..color = const Color(0xFF1B2A45);
    canvas.drawRect(
      Rect.fromLTWH(w * 0.40, h * 0.30, w * 0.20, h * 0.025),
      balconyPaint,
    );

    // Фонарная комната (стеклянный купол)
    final lampPaint = Paint()..color = kBrandCoral.withValues(alpha: 0.85);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(w * 0.43, h * 0.20, w * 0.14, h * 0.10),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      ),
      lampPaint,
    );
    // Свечение лампы
    final glow = Paint()
      ..color = kBrandCoral.withValues(alpha: 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(Offset(w * 0.5, h * 0.245), w * 0.07, glow);

    // Купол
    final domePaint = Paint()..color = kBrandNavy;
    final dome = Path()
      ..moveTo(w * 0.42, h * 0.20)
      ..quadraticBezierTo(w * 0.5, h * 0.10, w * 0.58, h * 0.20)
      ..close();
    canvas.drawPath(dome, domePaint);

    // Шпиль
    final spirePaint = Paint()
      ..color = kBrandCoral
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(w * 0.5, h * 0.13),
      Offset(w * 0.5, h * 0.06),
      spirePaint,
    );
  }

  @override
  bool shouldRepaint(covariant LighthousePainter oldDelegate) => false;
}

/// Луч маяка (конус с радиальным gradient + opacity).
class LighthouseBeamPainter extends CustomPainter {
  LighthouseBeamPainter({
    required this.angle,
    required this.intensity,
  });

  /// Угол поворота в радианах относительно вертикали (вверх).
  final double angle;

  /// 0..1 общая интенсивность луча.
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0.001) return;
    final origin = Offset(size.width * 0.5, size.height * 0.245);
    final length = size.height * 1.4;
    const halfAngle = 0.18; // ~10°

    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(angle);

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(math.sin(-halfAngle) * length, -math.cos(halfAngle) * length)
      ..lineTo(math.sin(halfAngle) * length, -math.cos(halfAngle) * length)
      ..close();

    final shader = RadialGradient(
      colors: [
        kBrandCoral.withValues(alpha: 0.55 * intensity),
        kBrandCoral.withValues(alpha: 0.0),
      ],
      radius: 0.9,
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: length));

    final paint = Paint()
      ..shader = shader
      ..blendMode = BlendMode.plus;
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LighthouseBeamPainter oldDelegate) =>
      oldDelegate.angle != angle || oldDelegate.intensity != intensity;
}

/// Силуэт смотрителя на балконе. `throwProgress` 0..1 управляет позой:
/// 0 = idle, 1 = вытянутая рука с самолётиком (pre-throw → release).
class KeeperPainter extends CustomPainter {
  const KeeperPainter({required this.throwProgress});

  final double throwProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = const Color(0xFF0A1626)
      ..style = PaintingStyle.fill;

    // Голова
    canvas.drawCircle(Offset(w * 0.5, h * 0.18), w * 0.10, paint);
    // Тело (трапеция)
    final body = Path()
      ..moveTo(w * 0.40, h * 0.30)
      ..lineTo(w * 0.60, h * 0.30)
      ..lineTo(w * 0.62, h * 0.78)
      ..lineTo(w * 0.38, h * 0.78)
      ..close();
    canvas.drawPath(body, paint);

    // Рука: idle вниз, throw — поднята вперёд-вверх
    final shoulder = Offset(w * 0.42, h * 0.34);
    final idleHand = Offset(w * 0.32, h * 0.62);
    final throwHand = Offset(w * 0.16, h * 0.20);
    final hand = Offset.lerp(idleHand, throwHand, throwProgress)!;
    final armPaint = Paint()
      ..color = const Color(0xFF0A1626)
      ..strokeWidth = w * 0.07
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(shoulder, hand, armPaint);
  }

  @override
  bool shouldRepaint(covariant KeeperPainter oldDelegate) =>
      oldDelegate.throwProgress != throwProgress;
}

/// Бумажный самолётик. Рисуется в системе координат, центрированной в (0,0).
class PaperPlanePainter extends CustomPainter {
  const PaperPlanePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.translate(w / 2, h / 2);

    final body = Path()
      ..moveTo(-w * 0.5, 0)
      ..lineTo(w * 0.5, -h * 0.35)
      ..lineTo(0, h * 0.05)
      ..close();
    final fold = Path()
      ..moveTo(-w * 0.5, 0)
      ..lineTo(w * 0.5, -h * 0.35)
      ..lineTo(-w * 0.05, h * 0.30)
      ..close();

    final fill = Paint()..color = Colors.white;
    final shadow = Paint()..color = const Color(0xFFE8EEF8);
    final stroke = Paint()
      ..color = kBrandNavy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawPath(fold, shadow);
    canvas.drawPath(body, fill);
    canvas.drawPath(body, stroke);
    canvas.drawPath(fold, stroke);
    canvas.drawLine(
      Offset(-w * 0.5, 0),
      Offset(w * 0.5, -h * 0.35),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant PaperPlanePainter oldDelegate) => false;
}

/// След от самолётика: убывающая по opacity линия из последних позиций.
class PaperPlaneTrailPainter extends CustomPainter {
  PaperPlaneTrailPainter({required this.points});

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    for (var i = 1; i < points.length; i++) {
      final t = i / points.length;
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.12 * t)
        ..strokeWidth = 1.4 * t
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(points[i - 1], points[i], paint);
    }
  }

  @override
  bool shouldRepaint(covariant PaperPlaneTrailPainter oldDelegate) =>
      !identical(oldDelegate.points, points);
}

/// Кубическая Безье-кривая через 4 контрольные точки.
Offset cubicBezier(double t, Offset p0, Offset p1, Offset p2, Offset p3) {
  final mt = 1 - t;
  final mt2 = mt * mt;
  final t2 = t * t;
  final dx = mt2 * mt * p0.dx +
      3 * mt2 * t * p1.dx +
      3 * mt * t2 * p2.dx +
      t2 * t * p3.dx;
  final dy = mt2 * mt * p0.dy +
      3 * mt2 * t * p1.dy +
      3 * mt * t2 * p2.dy +
      t2 * t * p3.dy;
  return Offset(dx, dy);
}

/// Производная кубической Безье — для расчёта tilt самолётика по тангенсу.
Offset cubicBezierTangent(
  double t,
  Offset p0,
  Offset p1,
  Offset p2,
  Offset p3,
) {
  final mt = 1 - t;
  final dx = 3 * mt * mt * (p1.dx - p0.dx) +
      6 * mt * t * (p2.dx - p1.dx) +
      3 * t * t * (p3.dx - p2.dx);
  final dy = 3 * mt * mt * (p1.dy - p0.dy) +
      6 * mt * t * (p2.dy - p1.dy) +
      3 * t * t * (p3.dy - p2.dy);
  return Offset(dx, dy);
}
