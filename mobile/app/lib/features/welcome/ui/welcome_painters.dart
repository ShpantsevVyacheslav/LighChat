import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../brand_colors.dart';

// ============================================================================
// Background — звёзды на тёмно-синем градиенте, луна, дальние волны моря
// ============================================================================

/// Звёзды на фоне — мерцают по синусу.
class StarsPainter extends CustomPainter {
  StarsPainter({required this.t, required this.seeds, required this.fade});

  final double t;
  final double fade;
  final List<StarSeed> seeds;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final s in seeds) {
      final blink = 0.35 +
          0.65 * (0.5 + 0.5 * math.sin(t * 2 * math.pi * s.speed * 1.5 + s.phase));
      paint.color = Colors.white.withValues(alpha: s.baseOpacity * blink * fade);
      canvas.drawCircle(
        Offset(s.dx * size.width, s.dy * size.height),
        s.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant StarsPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.fade != fade;
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
        rng.nextDouble() * 0.65,
        0.4 + rng.nextDouble() * 1.6,
        0.4 + rng.nextDouble() * 0.55,
        rng.nextDouble() * math.pi * 2,
        0.3 + rng.nextDouble() * 1.0,
      );
    });
  }
}

final List<StarSeed> kStarSeeds = StarSeed.generate(50);

/// Луна с мягким glow.
class MoonPainter extends CustomPainter {
  MoonPainter({required this.opacity});
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0.01) return;
    final cx = size.width * 0.82;
    final cy = size.height * 0.14;
    // Glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD9B0).withValues(alpha: 0.45 * opacity),
          const Color(0xFFFFD9B0).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy + 5), radius: 60));
    canvas.drawCircle(Offset(cx, cy + 5), 60, glowPaint);
    // Body
    final body = Paint()..color = const Color(0xFFFFEDD5).withValues(alpha: 0.85 * opacity);
    canvas.drawCircle(Offset(cx, cy), 22, body);
  }

  @override
  bool shouldRepaint(covariant MoonPainter oldDelegate) => oldDelegate.opacity != opacity;
}

/// Дальние волны моря (две параллаксных линии с лёгким покачиванием).
class SeaPainter extends CustomPainter {
  SeaPainter({required this.opacity, required this.t});
  final double opacity;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0.01) return;
    final w = size.width;
    final yBase = size.height * 0.78;
    final wsh = math.sin(t * math.pi * 6) * 6;

    // Заливка под волнами (затемнение нижней части)
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0x000A1626).withValues(alpha: 0),
          const Color(0xFF0A1626).withValues(alpha: 0.85 * opacity),
          const Color(0xFF06101E).withValues(alpha: opacity),
        ],
        stops: const [0, 0.6, 1],
      ).createShader(Rect.fromLTWH(0, yBase, w, size.height - yBase));
    canvas.drawRect(Rect.fromLTWH(0, yBase, w, size.height - yBase), fill);

    // Две волны
    final wave1 = Paint()..color = const Color(0xFF0A1B30).withValues(alpha: 0.7 * opacity);
    final wave2 = Paint()..color = const Color(0xFF081626).withValues(alpha: 0.85 * opacity);

    final p1 = Path();
    p1.moveTo(0 + wsh * 0.6, yBase + 22);
    for (double x = 0; x <= w; x += w / 4) {
      p1.quadraticBezierTo(
        x + w / 8 + wsh * 0.6,
        yBase + 18,
        x + w / 4 + wsh * 0.6,
        yBase + 22,
      );
    }
    p1.lineTo(w, size.height);
    p1.lineTo(0, size.height);
    p1.close();
    canvas.drawPath(p1, wave1);

    final p2 = Path();
    p2.moveTo(0 - wsh * 0.5, yBase + 40);
    for (double x = 0; x <= w; x += w / 3) {
      p2.quadraticBezierTo(
        x + w / 6 - wsh * 0.5,
        yBase + 36,
        x + w / 3 - wsh * 0.5,
        yBase + 40,
      );
    }
    p2.lineTo(w, size.height);
    p2.lineTo(0, size.height);
    p2.close();
    canvas.drawPath(p2, wave2);
  }

  @override
  bool shouldRepaint(covariant SeaPainter oldDelegate) =>
      oldDelegate.opacity != opacity || oldDelegate.t != t;
}

// ============================================================================
// Island — скалистый силуэт под маяком
// ============================================================================

class IslandPainter extends CustomPainter {
  const IslandPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Контур острова: расширяется вниз, неровные вершины
    final p = Path()
      ..moveTo(w * 0.13, h * 0.85)
      ..quadraticBezierTo(w * 0.26, h * 0.81, w * 0.41, h * 0.81)
      ..quadraticBezierTo(w * 0.51, h * 0.80, w * 0.61, h * 0.81)
      ..quadraticBezierTo(w * 0.77, h * 0.82, w * 0.87, h * 0.85)
      ..lineTo(w * 0.92, h * 0.90)
      ..lineTo(w * 0.08, h * 0.90)
      ..close();
    final paint = Paint()..color = const Color(0xFF0A1626);
    canvas.drawPath(p, paint);

    // Скальные выступы
    final rock = Paint()..color = const Color(0xFF152843).withValues(alpha: 0.7);
    final r1 = Path()
      ..moveTo(w * 0.23, h * 0.846)
      ..quadraticBezierTo(w * 0.28, h * 0.828, w * 0.33, h * 0.842)
      ..lineTo(w * 0.36, h * 0.85);
    canvas.drawPath(r1..close(), rock);

    final r2 = Path()
      ..moveTo(w * 0.59, h * 0.842)
      ..quadraticBezierTo(w * 0.64, h * 0.826, w * 0.69, h * 0.842)
      ..lineTo(w * 0.72, h * 0.85);
    canvas.drawPath(r2..close(), rock);

    // Линия травы/прибоя
    final shoreline = Paint()
      ..color = kBrandNavy.withValues(alpha: 0.55)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final shore = Path()
      ..moveTo(w * 0.13, h * 0.85)
      ..quadraticBezierTo(w * 0.26, h * 0.81, w * 0.41, h * 0.81)
      ..quadraticBezierTo(w * 0.51, h * 0.80, w * 0.61, h * 0.81)
      ..quadraticBezierTo(w * 0.77, h * 0.82, w * 0.87, h * 0.85);
    canvas.drawPath(shore, shoreline);
  }

  @override
  bool shouldRepaint(covariant IslandPainter oldDelegate) => false;
}

// ============================================================================
// Lighthouse — outlined silhouette: белая башня с navy stroke + coral элементы
// ============================================================================

class LighthousePainter extends CustomPainter {
  const LighthousePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = w * 0.022;

    // Постамент (filled navy трапеция)
    final base = Path()
      ..moveTo(w * 0.32, h * 0.88)
      ..lineTo(w * 0.68, h * 0.88)
      ..lineTo(w * 0.74, h * 0.97)
      ..lineTo(w * 0.26, h * 0.97)
      ..close();
    canvas.drawPath(base, Paint()..color = kBrandNavy);

    // Башня — outlined trapezoid (белая внутри + navy stroke)
    final tower = Path()
      ..moveTo(w * 0.36, h * 0.40)
      ..lineTo(w * 0.64, h * 0.40)
      ..lineTo(w * 0.69, h * 0.88)
      ..lineTo(w * 0.31, h * 0.88)
      ..close();
    canvas.drawPath(tower, Paint()..color = Colors.white);
    canvas.drawPath(
      tower,
      Paint()
        ..color = kBrandNavy
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeJoin = StrokeJoin.round,
    );

    // Coral диагональ — наклонённый параллелограмм по центру башни
    final diag = Path()
      ..moveTo(w * 0.51, h * 0.46)
      ..lineTo(w * 0.58, h * 0.46)
      ..lineTo(w * 0.49, h * 0.83)
      ..lineTo(w * 0.41, h * 0.83)
      ..close();
    canvas.drawPath(diag, Paint()..color = kBrandOrange);

    // Балкон (тонкая навы-полоса)
    canvas.drawRect(
      Rect.fromLTWH(w * 0.34, h * 0.376, w * 0.32, h * 0.018),
      Paint()..color = kBrandNavy,
    );

    // Фонарная комната — навы-прямоугольник с coral-окном
    canvas.drawRect(
      Rect.fromLTWH(w * 0.385, h * 0.27, w * 0.23, h * 0.105),
      Paint()..color = kBrandNavy,
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.42, h * 0.295, w * 0.16, h * 0.062),
      Paint()..color = kBrandOrange,
    );

    // Купол — Т-образный (макушка + поля)
    canvas.drawRect(
      Rect.fromLTWH(w * 0.355, h * 0.236, w * 0.30, h * 0.034),
      Paint()..color = kBrandNavy,
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.44, h * 0.180, w * 0.12, h * 0.060),
      Paint()..color = kBrandNavy,
    );

    // Шпиль с шариком
    canvas.drawRect(
      Rect.fromLTWH(w * 0.495, h * 0.118, w * 0.01, h * 0.062),
      Paint()..color = kBrandNavy,
    );
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.118),
      w * 0.012,
      Paint()..color = kBrandNavy,
    );
  }

  @override
  bool shouldRepaint(covariant LighthousePainter oldDelegate) => false;
}

/// Луч маяка — конус с радиальным gradient.
class LighthouseBeamPainter extends CustomPainter {
  LighthouseBeamPainter({
    required this.angle,
    required this.intensity,
    required this.origin,
  });

  final double angle;
  final double intensity;
  final Offset origin;

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0.001) return;
    final length = size.height * 1.4;
    const halfAngle = 0.18;

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
        kBrandOrange.withValues(alpha: 0.65 * intensity),
        kBrandOrange.withValues(alpha: 0.0),
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

// ============================================================================
// Keeper — выразительный силуэт: пальто, шляпа, шарф, фонарь, замах рукой
// ============================================================================

/// `throwProgress` 0..1 управляет правой рукой (замах назад → бросок вперёд).
class KeeperPainter extends CustomPainter {
  const KeeperPainter({
    required this.throwProgress,
    this.bodyColor = const Color(0xFF0A1626),
    this.accentColor = const Color(0xFF1B2A45),
  });
  final double throwProgress;

  /// Базовый цвет силуэта (пальто, ноги, голова, шляпа). По умолчанию —
  /// тёмно-сине-чёрный из welcome-сцены. Empty-state карточки передают
  /// более светлый оттенок, чтобы хранитель не сливался с frosted-glass
  /// фоном.
  final Color bodyColor;

  /// Тёмный accent (балкон, складка пальто).
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // `developer.log` → os_log; видно в Xcode Console и в release-сборке.
    developer.log(
      'paint size=${w.toStringAsFixed(1)}x${h.toStringAsFixed(1)} body=0x${bodyColor.toARGB32().toRadixString(16)}',
      name: 'lighchat.keeper',
    );
    // координаты в долях; ноги внизу, голова вверху
    final fill = Paint()..color = bodyColor;
    final accent = Paint()..color = accentColor;

    // Ноги
    final legL = Path()
      ..moveTo(w * 0.40, h)
      ..lineTo(w * 0.36, h * 0.66)
      ..lineTo(w * 0.46, h * 0.66)
      ..lineTo(w * 0.48, h)
      ..close();
    canvas.drawPath(legL, fill);
    final legR = Path()
      ..moveTo(w * 0.52, h)
      ..lineTo(w * 0.54, h * 0.66)
      ..lineTo(w * 0.64, h * 0.66)
      ..lineTo(w * 0.60, h)
      ..close();
    canvas.drawPath(legR, fill);

    // Пальто (длинное, расширяется к низу)
    final coat = Path()
      ..moveTo(w * 0.32, h * 0.66)
      ..quadraticBezierTo(w * 0.30, h * 0.45, w * 0.34, h * 0.27)
      ..lineTo(w * 0.34, h * 0.13)
      ..lineTo(w * 0.66, h * 0.13)
      ..lineTo(w * 0.66, h * 0.27)
      ..quadraticBezierTo(w * 0.70, h * 0.45, w * 0.68, h * 0.66)
      ..lineTo(w * 0.62, h * 0.74)
      ..quadraticBezierTo(w * 0.50, h * 0.78, w * 0.38, h * 0.74)
      ..close();
    canvas.drawPath(coat, fill);

    // Центральная складка пальто
    canvas.drawLine(
      Offset(w * 0.50, h * 0.15),
      Offset(w * 0.50, h * 0.70),
      Paint()
        ..color = accentColor
        ..strokeWidth = 1.2,
    );

    // Шарф (coral)
    final scarf = Path()
      ..moveTo(w * 0.40, h * 0.13)
      ..quadraticBezierTo(w * 0.50, h * 0.16, w * 0.60, h * 0.13)
      ..lineTo(w * 0.59, h * 0.20)
      ..quadraticBezierTo(w * 0.50, h * 0.23, w * 0.41, h * 0.20)
      ..close();
    canvas.drawPath(scarf, Paint()..color = kBrandOrange.withValues(alpha: 0.9));

    // Голова
    canvas.drawCircle(Offset(w * 0.50, h * 0.07), w * 0.08, fill);

    // Шляпа: поля + макушка
    canvas.save();
    canvas.translate(w * 0.50, h * 0.0);
    final brim = Path()
      ..addOval(Rect.fromCenter(center: Offset.zero, width: w * 0.28, height: h * 0.025));
    canvas.drawPath(brim, fill);
    canvas.drawRect(
      Rect.fromCenter(center: Offset(0, -h * 0.045), width: w * 0.12, height: h * 0.075),
      fill,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, -h * 0.012), width: w * 0.12, height: h * 0.012),
      Paint()..color = kBrandOrange.withValues(alpha: 0.75),
    );
    canvas.restore();

    // Левая рука (держит фонарь) — статична
    final lShoulder = Offset(w * 0.36, h * 0.27);
    final lHand = Offset(w * 0.24, h * 0.46);
    canvas.drawLine(
      lShoulder,
      lHand,
      Paint()
        ..color = bodyColor
        ..strokeWidth = w * 0.06
        ..strokeCap = StrokeCap.round,
    );

    // Фонарь
    final lantern = lHand;
    canvas.drawLine(
      Offset(lantern.dx, lantern.dy - 6),
      Offset(lantern.dx, lantern.dy + 2),
      Paint()
        ..color = bodyColor
        ..strokeWidth = 1.4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(lantern.dx, lantern.dy + 8), width: 9, height: 12),
        const Radius.circular(1.5),
      ),
      Paint()..color = accent.color,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(lantern.dx, lantern.dy + 8), width: 9, height: 12),
        const Radius.circular(1.5),
      ),
      Paint()
        ..color = kBrandOrange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
    canvas.drawCircle(
      Offset(lantern.dx, lantern.dy + 8),
      6,
      Paint()
        ..color = const Color(0xFFFFD89A).withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(
      Offset(lantern.dx, lantern.dy + 8),
      2,
      Paint()..color = const Color(0xFFFFE3B2).withValues(alpha: 0.95),
    );

    // Правая рука с замахом
    final rShoulder = Offset(w * 0.64, h * 0.27);
    final idleHand = Offset(w * 0.78, h * 0.46);
    final upHand = Offset(w * 0.92, h * 0.10);
    final forwardHand = Offset(w * 0.68, h * 0.18);

    Offset hand;
    if (throwProgress < 0.7) {
      // backswing
      final p = throwProgress / 0.7;
      hand = Offset.lerp(idleHand, upHand, p)!;
    } else {
      // forward swing
      final p = (throwProgress - 0.7) / 0.3;
      hand = Offset.lerp(upHand, forwardHand, p)!;
    }
    canvas.drawLine(
      rShoulder,
      hand,
      Paint()
        ..color = bodyColor
        ..strokeWidth = w * 0.06
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant KeeperPainter oldDelegate) =>
      oldDelegate.throwProgress != throwProgress ||
      oldDelegate.bodyColor != bodyColor ||
      oldDelegate.accentColor != accentColor;
}

// ============================================================================
// Crab — coral тело, два глаза, две клешни (анимируются), 4 лапки
// ============================================================================

class CrabPainter extends CustomPainter {
  const CrabPainter({
    required this.clawWaveL,
    required this.clawWaveR,
    required this.pupilOffset,
  });

  final double clawWaveL; // angle for left claw, deg
  final double clawWaveR; // angle for right claw, deg
  final Offset pupilOffset; // -1..1 normalized; eye tracking direction

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.translate(w / 2, h / 2);
    // Scale unit: 1 unit ≈ w*0.012
    final s = w / 70.0;

    final coral = Paint()..color = const Color(0xFFE9876A);
    final coralLight = Paint()..color = const Color(0xFFF2A589).withValues(alpha: 0.7);
    final dark = Paint()..color = const Color(0xFF9F4828);

    // Лапки (4)
    final legPaint = Paint()
      ..color = const Color(0xFFC7613D)
      ..strokeWidth = 2 * s
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(-22 * s, 6 * s), Offset(-32 * s, 6 * s), legPaint);
    canvas.drawLine(Offset(-20 * s, 10 * s), Offset(-28 * s, 12 * s), legPaint);
    canvas.drawLine(Offset(22 * s, 6 * s), Offset(32 * s, 6 * s), legPaint);
    canvas.drawLine(Offset(20 * s, 10 * s), Offset(28 * s, 12 * s), legPaint);

    // Тело
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, 2 * s), width: 44 * s, height: 32 * s),
      coral,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(-7 * s, -3 * s), width: 12 * s, height: 6 * s),
      coralLight,
    );

    // Левая клешня
    canvas.save();
    canvas.translate(-18 * s, -10 * s);
    canvas.rotate(clawWaveL * math.pi / 180);
    final clawL = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-4 * s, -8 * s, -2 * s, -16 * s)
      ..quadraticBezierTo(-10 * s, -18 * s, -14 * s, -10 * s)
      ..quadraticBezierTo(-16 * s, -4 * s, -10 * s, 4 * s)
      ..close();
    canvas.drawPath(clawL, coral);
    canvas.drawLine(
      Offset(-4 * s, -10 * s),
      Offset(-10 * s, -10 * s),
      Paint()
        ..color = dark.color
        ..strokeWidth = 1.2 * s
        ..style = PaintingStyle.stroke,
    );
    canvas.restore();

    // Правая клешня (побольше)
    canvas.save();
    canvas.translate(18 * s, -10 * s);
    canvas.rotate(clawWaveR * math.pi / 180);
    final clawR = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(5 * s, -10 * s, 4 * s, -20 * s)
      ..quadraticBezierTo(14 * s, -22 * s, 18 * s, -12 * s)
      ..quadraticBezierTo(20 * s, -4 * s, 12 * s, 6 * s)
      ..close();
    canvas.drawPath(clawR, coral);
    canvas.drawLine(
      Offset(6 * s, -14 * s),
      Offset(14 * s, -14 * s),
      Paint()
        ..color = dark.color
        ..strokeWidth = 1.2 * s
        ..style = PaintingStyle.stroke,
    );
    canvas.restore();

    // Стебельки глаз
    canvas.drawLine(
      Offset(-6 * s, 2 * s),
      Offset(-3 * s, -3 * s),
      Paint()
        ..color = const Color(0xFFC7613D)
        ..strokeWidth = 1.5 * s
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(6 * s, 2 * s),
      Offset(3 * s, -3 * s),
      Paint()
        ..color = const Color(0xFFC7613D)
        ..strokeWidth = 1.5 * s
        ..strokeCap = StrokeCap.round,
    );

    // Левый глаз (поменьше)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(-6 * s, -7 * s), width: 14 * s, height: 16 * s),
      Paint()..color = const Color(0xFFFFF6E5),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(-6 * s, -7 * s), width: 11 * s, height: 13 * s),
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset((-5 + pupilOffset.dx * 1.4) * s, (-5 + pupilOffset.dy * 1.2) * s),
      3 * s,
      Paint()..color = const Color(0xFF3E1B0E),
    );
    canvas.drawCircle(Offset(-3.5 * s, -7 * s), 1.1 * s, Paint()..color = Colors.white);

    // Правый глаз (большой)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(8 * s, -7 * s), width: 17 * s, height: 19 * s),
      Paint()..color = const Color(0xFFFFF6E5),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(8 * s, -7 * s), width: 14 * s, height: 16 * s),
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset((9 + pupilOffset.dx * 1.6) * s, (-5 + pupilOffset.dy * 1.4) * s),
      3.8 * s,
      Paint()..color = const Color(0xFF3E1B0E),
    );
    canvas.drawCircle(Offset(10.5 * s, -7 * s), 1.4 * s, Paint()..color = Colors.white);

    // Улыбка
    final smile = Path()
      ..moveTo(-6 * s, 4 * s)
      ..quadraticBezierTo(-2 * s, 8 * s, 2 * s, 4 * s);
    canvas.drawPath(
      smile,
      Paint()
        ..color = dark.color
        ..strokeWidth = 1.2 * s
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CrabPainter oldDelegate) =>
      oldDelegate.clawWaveL != clawWaveL ||
      oldDelegate.clawWaveR != clawWaveR ||
      oldDelegate.pupilOffset != pupilOffset;
}

// ============================================================================
// Paper plane — два слоя крыла, тень, блик, coral-акцент на хвосте
// ============================================================================

class PaperPlanePainter extends CustomPainter {
  const PaperPlanePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.translate(w / 2, h / 2);

    // Drop shadow
    final shadowRect = Rect.fromCenter(
      center: Offset(-w * 0.04, h * 0.30),
      width: w * 0.85,
      height: h * 0.15,
    );
    canvas.drawOval(
      shadowRect,
      Paint()..color = Colors.black.withValues(alpha: 0.18),
    );

    final navy = Paint()
      ..color = kBrandNavy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeJoin = StrokeJoin.round;

    // Нижнее крыло (затенённое)
    final lower = Path()
      ..moveTo(-w * 0.5, h * 0.05)
      ..lineTo(w * 0.5, -h * 0.35)
      ..lineTo(-w * 0.04, h * 0.30)
      ..close();
    canvas.drawPath(lower, Paint()..color = const Color(0xFFC7D2E0));
    canvas.drawPath(lower, navy);

    // Центральная складка (фюзеляж)
    final centerFold = Path()
      ..moveTo(-w * 0.5, h * 0.05)
      ..lineTo(w * 0.5, -h * 0.35)
      ..lineTo(0, h * 0.05)
      ..lineTo(-w * 0.04, h * 0.22)
      ..close();
    canvas.drawPath(centerFold, Paint()..color = const Color(0xFF9DAEC4));
    canvas.drawPath(centerFold, navy);

    // Верхнее крыло (светлое)
    final upper = Path()
      ..moveTo(-w * 0.5, h * 0.05)
      ..lineTo(w * 0.5, -h * 0.35)
      ..lineTo(0, h * 0.05)
      ..close();
    canvas.drawPath(upper, Paint()..color = Colors.white);
    canvas.drawPath(upper, navy);

    // Блик
    final highlight = Path()
      ..moveTo(-w * 0.42, h * 0.025)
      ..lineTo(-w * 0.08, -h * 0.20)
      ..lineTo(-w * 0.16, h * 0.025)
      ..close();
    canvas.drawPath(
      highlight,
      Paint()..color = const Color(0xFFF4F8FF).withValues(alpha: 0.85),
    );

    // Coral-акцент на хвосте
    final tail = Path()
      ..moveTo(-w * 0.5, h * 0.05)
      ..lineTo(-w * 0.38, h * 0.10)
      ..lineTo(-w * 0.42, h * 0.025)
      ..close();
    canvas.drawPath(tail, Paint()..color = kBrandOrange);

    // Складка-перо
    canvas.drawLine(
      Offset(-w * 0.5, h * 0.05),
      Offset(w * 0.5, -h * 0.35),
      Paint()
        ..color = kBrandNavy
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(0, h * 0.05),
      Offset(-w * 0.04, h * 0.22),
      Paint()
        ..color = kBrandNavy
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant PaperPlanePainter oldDelegate) => false;
}

/// След от самолётика.
class PaperPlaneTrailPainter extends CustomPainter {
  PaperPlaneTrailPainter({required this.points, required this.fade});
  final List<Offset> points;
  final double fade;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2 || fade <= 0.001) return;
    for (var i = 1; i < points.length; i++) {
      final t = i / points.length;
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.5 * t * fade)
        ..strokeWidth = 1.4 * t
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(points[i - 1], points[i], paint);
    }
  }

  @override
  bool shouldRepaint(covariant PaperPlaneTrailPainter oldDelegate) =>
      !identical(oldDelegate.points, points) || oldDelegate.fade != fade;
}

// ============================================================================
// Bezier helpers
// ============================================================================

Offset cubicBezier(double t, Offset p0, Offset p1, Offset p2, Offset p3) {
  final mt = 1 - t;
  final mt2 = mt * mt;
  final t2 = t * t;
  return Offset(
    mt2 * mt * p0.dx +
        3 * mt2 * t * p1.dx +
        3 * mt * t2 * p2.dx +
        t2 * t * p3.dx,
    mt2 * mt * p0.dy +
        3 * mt2 * t * p1.dy +
        3 * mt * t2 * p2.dy +
        t2 * t * p3.dy,
  );
}

Offset cubicBezierTangent(
  double t,
  Offset p0,
  Offset p1,
  Offset p2,
  Offset p3,
) {
  final mt = 1 - t;
  return Offset(
    3 * mt * mt * (p1.dx - p0.dx) +
        6 * mt * t * (p2.dx - p1.dx) +
        3 * t * t * (p3.dx - p2.dx),
    3 * mt * mt * (p1.dy - p0.dy) +
        6 * mt * t * (p2.dy - p1.dy) +
        3 * t * t * (p3.dy - p2.dy),
  );
}
