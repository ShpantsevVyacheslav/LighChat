import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../data/animated_wallpapers.dart';

/// Виджет «живого слоя» поверх статичного preview-обоя. Создаёт
/// собственный [AnimationController], проигрывает анимацию ОДИН раз
/// (`forward`) и замирает в финальном кадре, чтобы не отвлекать
/// пользователя от чата.
///
/// Сам preview-фон рисует [chat_wallpaper_background.dart] —
/// этот виджет нужен только для оверлея с painter'ом.
class AnimatedWallpaperLayer extends StatefulWidget {
  const AnimatedWallpaperLayer({super.key, required this.wallpaper});

  final AnimatedWallpaper wallpaper;

  @override
  State<AnimatedWallpaperLayer> createState() => _AnimatedWallpaperLayerState();
}

class _AnimatedWallpaperLayerState extends State<AnimatedWallpaperLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.wallpaper.durationMs),
    );
    // Запускаем один раз. По окончании контроллер остаётся на 1.0 — painter
    // отрисует финальный кадр и больше не будет тикать (no rebuild).
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).colorScheme.brightness;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return CustomPaint(
            painter: _painterFor(widget.wallpaper.slug, _ctrl.value, brightness),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

CustomPainter _painterFor(String slug, double t, Brightness brightness) {
  switch (slug) {
    case 'falling-star':
      return _FallingStarPainter(t: t, brightness: brightness);
    case 'lighthouse-beam':
      return _LighthouseBeamPainter(t: t, brightness: brightness);
    case 'milky-way':
      return _MilkyWayPainter(t: t, brightness: brightness);
    case 'wave-motion':
      return _WaveMotionPainter(t: t, brightness: brightness);
    case 'rain':
      return _RainPainter(t: t, brightness: brightness);
    case 'fireflies':
      return _FirefliesPainter(t: t, brightness: brightness);
    default:
      return _NoopPainter();
  }
}

class _NoopPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {}
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Падающая звезда — белый штрих с длинным затухающим хвостом, идёт по
/// диагонали справа-сверху → влево-вниз. Пик яркости в середине, затем
/// затухает.
class _FallingStarPainter extends CustomPainter {
  _FallingStarPainter({required this.t, required this.brightness});

  final double t;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    if (t >= 1.0) return; // финальный кадр — звезда ушла, ничего не рисуем
    final w = size.width;
    final h = size.height;

    // Траектория: с (1.05, 0.05) до (0.10, 0.55) — диагональ через верх
    final start = Offset(w * 1.05, h * 0.05);
    final end = Offset(w * 0.10, h * 0.55);
    final head = Offset.lerp(start, end, t)!;
    final dir = (end - start);
    final dirLen = dir.distance;
    final unit = dir / dirLen;

    // Длина хвоста ≈ 22% диагонали, плавно нарастает в первой трети
    // и затухает в последней.
    final tailFactor = t < 0.3
        ? (t / 0.3).clamp(0.0, 1.0)
        : (1.0 - ((t - 0.3) / 0.7).clamp(0.0, 1.0));
    final tailLen = dirLen * 0.22 * tailFactor;
    final tail = head - unit * tailLen;

    // Хвост — градиент от прозрачного к яркому, рисуем как несколько
    // линий с убывающей альфой.
    const segments = 18;
    for (var i = 0; i < segments; i++) {
      final a = i / segments;
      final p1 = Offset.lerp(tail, head, a)!;
      final p2 = Offset.lerp(tail, head, a + 1.0 / segments)!;
      final alpha = (a * a * 220).round();
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = const Color(0xFFFFFFFF).withValues(alpha: alpha / 255.0)
          ..strokeWidth = 2.0 + a * 2.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // Голова — яркая точка с halo
    final haloPaint = Paint()
      ..color = const Color(0xFFFFE6B3).withValues(alpha: 0.55 * (1 - t * 0.5))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(head, 12, haloPaint);
    canvas.drawCircle(
      head,
      4,
      Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 1 - t * 0.4),
    );
  }

  @override
  bool shouldRepaint(covariant _FallingStarPainter old) =>
      old.t != t || old.brightness != brightness;
}

/// Свечение маяка — вращающийся конус луча от точки в правой части
/// неба. Проходит ~1.5 оборота за длительность, затем замирает,
/// направленный «вверх».
class _LighthouseBeamPainter extends CustomPainter {
  _LighthouseBeamPainter({required this.t, required this.brightness});

  final double t;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Источник луча — позиция фонарной комнаты на preview-картинке
    // animated-lighthouse-beam (ориентир: центр маяка по горизонтали,
    // y ≈ 0.42 экрана).
    final origin = Offset(w * 0.50, h * 0.42);

    // Угол поворота — 1.5 полных оборота, easing-out в конце
    final ease = 1 - math.pow(1 - t, 2.4).toDouble();
    final rotations = 1.5;
    // Стартовый угол — вверх (-90°), идёт по часовой
    final angle = -math.pi / 2 + ease * rotations * math.pi * 2;

    final beamLen = math.sqrt(w * w + h * h) * 1.1;
    final beamHalfWidth = (math.pi / 14).toDouble(); // ширина конуса

    // Затухание яркости после первого оборота
    final intensity = t < 0.6 ? 1.0 : (1.0 - (t - 0.6) / 0.4 * 0.6);

    final color = brightness == Brightness.dark
        ? const Color(0xFFFFD68A)
        : const Color(0xFFFFE2B5);

    final path = Path()
      ..moveTo(origin.dx, origin.dy)
      ..lineTo(
        origin.dx + math.cos(angle - beamHalfWidth) * beamLen,
        origin.dy + math.sin(angle - beamHalfWidth) * beamLen,
      )
      ..lineTo(
        origin.dx + math.cos(angle + beamHalfWidth) * beamLen,
        origin.dy + math.sin(angle + beamHalfWidth) * beamLen,
      )
      ..close();

    final paint = Paint()
      ..color = color.withValues(alpha: 0.40 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    canvas.drawPath(path, paint);

    // Внутренний более яркий конус
    final inner = Path()
      ..moveTo(origin.dx, origin.dy)
      ..lineTo(
        origin.dx + math.cos(angle - beamHalfWidth * 0.45) * beamLen,
        origin.dy + math.sin(angle - beamHalfWidth * 0.45) * beamLen,
      )
      ..lineTo(
        origin.dx + math.cos(angle + beamHalfWidth * 0.45) * beamLen,
        origin.dy + math.sin(angle + beamHalfWidth * 0.45) * beamLen,
      )
      ..close();
    canvas.drawPath(
      inner,
      Paint()
        ..color = color.withValues(alpha: 0.75 * intensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );

    // Лампа — тёплое пульсирующее ядро
    canvas.drawCircle(
      origin,
      18,
      Paint()
        ..color = color.withValues(alpha: 0.95 * intensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  @override
  bool shouldRepaint(covariant _LighthouseBeamPainter old) =>
      old.t != t || old.brightness != brightness;
}

/// Млечный путь — мягкая диагональная полоса с пульсирующей яркостью.
/// Полупериод — главный пик, плавно растёт, потом затухает.
class _MilkyWayPainter extends CustomPainter {
  _MilkyWayPainter({required this.t, required this.brightness});

  final double t;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Пульсация: 0 → 1 → 0.6 (на финале остаётся слабое свечение)
    final pulse = t < 0.5 ? (t / 0.5) : (1.0 - (t - 0.5) * 0.8);
    final intensity = pulse.clamp(0.2, 1.0);

    final color = brightness == Brightness.dark
        ? const Color(0xFFC8DCFF)
        : const Color(0xFFFFFFFF);
    // Диагональная полоса от (0, 0.20*h) до (w, 0.55*h)
    final path = Path()
      ..moveTo(0, h * 0.20)
      ..lineTo(w, h * 0.55)
      ..lineTo(w, h * 0.62)
      ..lineTo(0, h * 0.27)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.35 * intensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60),
    );
    // Мерцающие звёздные «островки» вдоль полосы
    final rng = math.Random(42);
    for (var i = 0; i < 14; i++) {
      final tt = i / 13;
      final cx = w * tt;
      final cy = h * (0.235 + tt * 0.035) + rng.nextDouble() * h * 0.04 - h * 0.02;
      // Каждая звезда мерцает со своим фазой
      final phase = (t * 4 + i * 0.7) % 1.0;
      final twinkle = (math.sin(phase * 2 * math.pi) * 0.5 + 0.5);
      final r = 6.0 + twinkle * 4.0;
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..color = color.withValues(alpha: 0.55 * intensity * twinkle)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(
        Offset(cx, cy),
        2.0,
        Paint()
          ..color = color.withValues(alpha: 0.95 * intensity * twinkle),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MilkyWayPainter old) =>
      old.t != t || old.brightness != brightness;
}

/// Движение волн — три горизонтальных синусоидальных слоя движутся
/// горизонтально с разной фазой и амплитудой. К концу анимации движение
/// замедляется до полной остановки.
class _WaveMotionPainter extends CustomPainter {
  _WaveMotionPainter({required this.t, required this.brightness});

  final double t;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Easing-out: к концу скорость падает. Берём время-сдвиг как t*4 (волны
    // прокручиваются ~4 раза за период).
    final phase = (1 - math.pow(1 - t, 2.6)).toDouble() * 4;

    final foam = brightness == Brightness.dark
        ? const Color(0xFFB4D2EB)
        : const Color(0xFFFFFFFF);

    // 3 слоя — глубже → выше альфа, выше → ниже альфа
    for (var layer = 0; layer < 3; layer++) {
      final baseY = h * (0.62 + layer * 0.10);
      final amp = h * (0.012 + layer * 0.006);
      final freq = 2.4 + layer * 0.6;
      final phaseShift = phase * (1 + layer * 0.2);
      final color = foam.withValues(alpha: 0.45 - layer * 0.10);

      final path = Path()..moveTo(0, baseY);
      for (var x = 0.0; x <= w; x += 8) {
        final y = baseY +
            math.sin((x / w) * math.pi * freq + phaseShift) * amp;
        path.lineTo(x, y);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveMotionPainter old) =>
      old.t != t || old.brightness != brightness;
}

/// Падающий дождь — диагональные капли с равномерным движением. К концу
/// плотность падает (затухает).
class _RainPainter extends CustomPainter {
  _RainPainter({required this.t, required this.brightness});

  final double t;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final color = brightness == Brightness.dark
        ? const Color(0xFFC8D7F0)
        : const Color(0xFF6F8AAA);
    // Капли — 80 штук, каждая со своим offset; падают с одинаковой
    // скоростью, но «появляются» в разные моменты времени.
    final rng = math.Random(7);
    final fade = t < 0.85 ? 1.0 : (1.0 - (t - 0.85) / 0.15);
    for (var i = 0; i < 80; i++) {
      final dropPhase = (t * 1.6 + rng.nextDouble()) % 1.0;
      final x0 = rng.nextDouble() * (w * 1.4) - w * 0.1;
      // Капли сдвигаются по диагонали (вниз-вправо со слабым углом)
      final x = x0 + dropPhase * w * 0.18;
      final y = -h * 0.05 + dropPhase * h * 1.10;
      if (y < 0 || y > h) continue;
      final length = 24.0 + rng.nextDouble() * 18.0;
      canvas.drawLine(
        Offset(x, y),
        Offset(x - 6, y - length),
        Paint()
          ..color = color.withValues(alpha: 0.55 * fade)
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round,
      );
    }
    // Мелкие брызги на «земле» (ниже 0.85h) — точки от падения
    for (var i = 0; i < 30; i++) {
      final p = ((t * 2 + i * 0.13) % 1.0);
      if (p > 0.4) continue;
      final x = rng.nextDouble() * w;
      final y = h * (0.85 + rng.nextDouble() * 0.13);
      canvas.drawCircle(
        Offset(x, y),
        2.0 * (1 - p / 0.4),
        Paint()..color = color.withValues(alpha: 0.4 * fade),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter old) =>
      old.t != t || old.brightness != brightness;
}

/// Светлячки — 12 пульсирующих жёлтых точек, каждая мерцает со своей
/// фазой. На финале остаются — продолжают мерцать, но без движения
/// контроллера (последний кадр).
class _FirefliesPainter extends CustomPainter {
  _FirefliesPainter({required this.t, required this.brightness});

  final double t;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // На финале — оставляем последний кадр, но фиксируем «среднее» состояние
    final time = t < 1.0 ? t * 6 : 5.0;
    final glow = brightness == Brightness.dark
        ? const Color(0xFFFFE680)
        : const Color(0xFFE0A400);

    final rng = math.Random(101);
    for (var i = 0; i < 12; i++) {
      // Базовая позиция светлячка — рассеяна по верхней 70% экрана
      final baseX = rng.nextDouble() * w;
      final baseY = h * (0.20 + rng.nextDouble() * 0.55);
      // Лёгкое «парение» — кругооборот вокруг базовой точки
      final orbit = 14.0 + rng.nextDouble() * 18.0;
      final orbitSpeed = 0.4 + rng.nextDouble() * 0.6;
      final ang = time * orbitSpeed + i * 0.7;
      final x = baseX + math.cos(ang) * orbit;
      final y = baseY + math.sin(ang * 1.3) * orbit * 0.7;
      // Мерцание — синусоида с разной фазой
      final twinkle = (math.sin(time * 1.8 + i * 1.2) * 0.5 + 0.5);
      final r = 5.0 + twinkle * 5.0;
      canvas.drawCircle(
        Offset(x, y),
        r * 2.5,
        Paint()
          ..color = glow.withValues(alpha: 0.35 * twinkle)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = glow.withValues(alpha: 0.85 * twinkle)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(
        Offset(x, y),
        2.0,
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: twinkle),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FirefliesPainter old) =>
      old.t != t || old.brightness != brightness;
}
