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
    case 'rain-on-glass':
      return _RainOnGlassPainter(t: t, brightness: brightness);
    case 'drifting-clouds':
      return _DriftingCloudsPainter(t: t, brightness: brightness);
    case 'aurora-pulse':
      return _AuroraPulsePainter(t: t, brightness: brightness);
    case 'gentle-snowfall':
      return _GentleSnowfallPainter(t: t, brightness: brightness);
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

// ---------------------------------------------------------------------------
// Реалистичные painter'ы — приглушённая палитра, мягкий blur, физика
// движения вместо линейных траекторий.
// ---------------------------------------------------------------------------

/// Капли дождя на стекле. Часть капель неподвижна (мелкие брызги, осели
/// на стекле), часть медленно стекает вниз с лёгким зигзагом, оставляя
/// размытый «след». В конце капли исчезают — стекло «высыхает».
class _RainOnGlassPainter extends CustomPainter {
  _RainOnGlassPainter({required this.t, required this.brightness});

  final double t;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final baseColor = brightness == Brightness.dark
        ? const Color(0xFFB4C8DC)
        : const Color(0xFF8FA0B8);
    final fade = t < 0.85 ? 1.0 : (1.0 - (t - 0.85) / 0.15);
    final rng = math.Random(13);

    // 38 неподвижных мелких капель — рассеяны по всему стеклу
    for (var i = 0; i < 38; i++) {
      final x = rng.nextDouble() * w;
      final y = rng.nextDouble() * h;
      final r = 1.5 + rng.nextDouble() * 4.0;
      // Капли проявляются волной от 0 до 0.15 t
      final appear = (t / 0.15).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = baseColor.withValues(alpha: 0.55 * appear * fade)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      );
      // Лёгкий блик внутри капли (имитация преломления)
      canvas.drawCircle(
        Offset(x - r * 0.3, y - r * 0.3),
        r * 0.4,
        Paint()
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.4 * appear * fade),
      );
    }

    // 8 крупных стекающих капель — каждая со своей траекторией
    for (var i = 0; i < 8; i++) {
      final dropDelay = i * 0.06; // капли начинают стекать с задержкой
      final dropTime = (t - dropDelay).clamp(0.0, 1.0);
      if (dropTime <= 0) continue;
      final startX = w * (0.10 + (i / 8) * 0.85);
      // Зигзаг — синусоида с периодом ~h*0.3
      final yPos = dropTime * h * 1.10;
      if (yPos > h * 1.05) continue;
      final swing = math.sin(dropTime * math.pi * 4 + i) * 6.0;
      final cx = startX + swing;
      final r = 5.0 + rng.nextDouble() * 4.0;

      // След капли — серия точек выше текущей позиции (с убывающим alpha)
      for (var j = 1; j <= 14; j++) {
        final trailY = yPos - j * 6;
        if (trailY < 0) break;
        final trailAlpha = (1 - j / 14) * 0.35 * fade;
        canvas.drawCircle(
          Offset(cx + math.sin((trailY / h) * math.pi * 4 + i) * 4, trailY),
          r * 0.4,
          Paint()
            ..color = baseColor.withValues(alpha: trailAlpha)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
      }
      // Сама капля
      canvas.drawCircle(
        Offset(cx, yPos),
        r,
        Paint()
          ..color = baseColor.withValues(alpha: 0.78 * fade)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6),
      );
      // Преломляющий блик
      canvas.drawCircle(
        Offset(cx - r * 0.3, yPos - r * 0.3),
        r * 0.45,
        Paint()
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.55 * fade),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RainOnGlassPainter old) =>
      old.t != t || old.brightness != brightness;
}

/// Дрейфующие облака — несколько мягких полупрозрачных овалов плывут
/// слева направо с разной скоростью и плотностью. Появляются и исчезают
/// с экрана через alpha-fade.
class _DriftingCloudsPainter extends CustomPainter {
  _DriftingCloudsPainter({required this.t, required this.brightness});

  final double t;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cloudColor = brightness == Brightness.dark
        ? const Color(0xFFB0BCD0)
        : const Color(0xFFFFFFFF);
    final rng = math.Random(31);

    // 5 облаков на разных высотах со своими скоростями
    final clouds = <_CloudConfig>[
      _CloudConfig(yFrac: 0.18, speed: 0.45, scale: 1.6, alpha: 0.42),
      _CloudConfig(yFrac: 0.27, speed: 0.30, scale: 2.2, alpha: 0.34),
      _CloudConfig(yFrac: 0.36, speed: 0.55, scale: 1.3, alpha: 0.48),
      _CloudConfig(yFrac: 0.46, speed: 0.22, scale: 2.6, alpha: 0.28),
      _CloudConfig(yFrac: 0.13, speed: 0.40, scale: 1.0, alpha: 0.50),
    ];

    for (var i = 0; i < clouds.length; i++) {
      final c = clouds[i];
      // Сдвиг по X — равномерный за весь период
      final phase = (t * c.speed + i * 0.23) % 1.0;
      final cx = -w * 0.25 + phase * w * 1.50;
      final cy = h * c.yFrac;
      // Облако = композит из 4-6 перекрывающихся овалов с blur
      final puffCount = 5;
      for (var k = 0; k < puffCount; k++) {
        rng.nextDouble(); // прогрев генератора
      }
      final localRng = math.Random(31 + i);
      for (var k = 0; k < puffCount; k++) {
        final ox = (localRng.nextDouble() - 0.5) * 80 * c.scale;
        final oy = (localRng.nextDouble() - 0.5) * 26 * c.scale;
        final r = (40 + localRng.nextDouble() * 30) * c.scale;
        canvas.drawCircle(
          Offset(cx + ox, cy + oy),
          r,
          Paint()
            ..color = cloudColor.withValues(alpha: c.alpha * 0.6)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DriftingCloudsPainter old) =>
      old.t != t || old.brightness != brightness;
}

class _CloudConfig {
  const _CloudConfig({
    required this.yFrac,
    required this.speed,
    required this.scale,
    required this.alpha,
  });
  final double yFrac;
  final double speed;
  final double scale;
  final double alpha;
}

/// Реалистичное полярное сияние — несколько вертикальных «лент»-вуалей
/// плавно колышутся, цвета переходят между зелёным/бирюзовым/фиолетовым,
/// амплитуда «дышит» (увеличивается → уменьшается).
class _AuroraPulsePainter extends CustomPainter {
  _AuroraPulsePainter({required this.t, required this.brightness});

  final double t;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final breathe = math.sin(t * math.pi) * 0.6 + 0.5;

    final palette = brightness == Brightness.dark
        ? <Color>[
            const Color(0xFF55E0A0),
            const Color(0xFF50C8E0),
            const Color(0xFFB888E0),
          ]
        : <Color>[
            const Color(0xFF95DCC0),
            const Color(0xFF95C8DC),
            const Color(0xFFC8B0E0),
          ];

    // 3 ленты разной длины. Каждая — вертикальный мягкий «занавес» с
    // плавным боковым колебанием.
    for (var bandIdx = 0; bandIdx < 3; bandIdx++) {
      final color = palette[bandIdx];
      final baseX = w * (0.20 + bandIdx * 0.30);
      final segments = 22;
      // Строим путь как многоугольник вокруг волнистой средней линии
      final left = Path();
      final right = Path();
      for (var i = 0; i <= segments; i++) {
        final fy = i / segments;
        // Y от 0.10 до 0.55 от высоты
        final y = h * (0.10 + fy * 0.45);
        // Колебание X — синусоида с фазой по времени
        final wave = math.sin(t * math.pi * 1.6 + bandIdx * 1.3 + fy * math.pi * 2.5) *
            (60 + 40 * breathe);
        final cx = baseX + wave;
        // Ширина ленты сужается к нижнему краю
        final halfW = (40 - fy * 14) * (0.6 + 0.4 * breathe);
        if (i == 0) {
          left.moveTo(cx - halfW, y);
          right.moveTo(cx + halfW, y);
        } else {
          left.lineTo(cx - halfW, y);
          right.lineTo(cx + halfW, y);
        }
      }
      // Рисуем «занавес» как двойной stroke с большой шириной — даёт
      // мягкое размытое поле, не нужно строить замкнутый ribbon.
      canvas.drawPath(
        left,
        Paint()
          ..color = color.withValues(alpha: 0.55 * (0.5 + breathe * 0.5))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 70 + 30 * breathe
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
      );
      canvas.drawPath(
        right,
        Paint()
          ..color = color.withValues(alpha: 0.45 * (0.5 + breathe * 0.5))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 50 + 25 * breathe
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26),
      );
      // Яркое ядро по центру ленты
      final core = Path();
      for (var i = 0; i <= segments; i++) {
        final fy = i / segments;
        final y = h * (0.10 + fy * 0.45);
        final wave = math.sin(t * math.pi * 1.6 + bandIdx * 1.3 + fy * math.pi * 2.5) *
            (60 + 40 * breathe);
        final cx = baseX + wave;
        if (i == 0) {
          core.moveTo(cx, y);
        } else {
          core.lineTo(cx, y);
        }
      }
      canvas.drawPath(
        core,
        Paint()
          ..color = color.withValues(alpha: 0.85 * (0.5 + breathe * 0.5))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 16
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraPulsePainter old) =>
      old.t != t || old.brightness != brightness;
}

/// Мягкий снегопад — снежинки разного размера падают с разной скоростью,
/// с лёгким боковым колебанием (имитация ветра). Большие — быстрее,
/// мелкие плывут медленнее (parallax). К концу снегопад затухает.
class _GentleSnowfallPainter extends CustomPainter {
  _GentleSnowfallPainter({required this.t, required this.brightness});

  final double t;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final color = brightness == Brightness.dark
        ? const Color(0xFFEFF4FF)
        : const Color(0xFFFFFFFF);
    final fade = t < 0.85 ? 1.0 : (1.0 - (t - 0.85) / 0.15);
    final rng = math.Random(91);

    // 90 снежинок с разными параметрами
    for (var i = 0; i < 90; i++) {
      final flakeR = 0.6 + rng.nextDouble() * 4.5;
      // Скорость зависит от размера (parallax) — большие ближе и быстрее
      final speed = 0.35 + (flakeR / 5.1) * 0.85;
      final phase = (t * speed + rng.nextDouble()) % 1.0;
      final x0 = rng.nextDouble() * w;
      // Боковое колебание — синусоида по позиции и времени
      final swayAmp = 8.0 + rng.nextDouble() * 18.0;
      final swayFreq = 0.5 + rng.nextDouble() * 1.5;
      final y = -h * 0.05 + phase * h * 1.10;
      if (y < -10 || y > h + 10) continue;
      final sway = math.sin(phase * math.pi * 2 * swayFreq + rng.nextDouble() * 6) *
          swayAmp;
      final x = x0 + sway;
      // Большие снежинки чуть размыты (depth-of-field эффект)
      final blur = flakeR > 3 ? 1.2 : 0.4;
      canvas.drawCircle(
        Offset(x, y),
        flakeR,
        Paint()
          ..color = color.withValues(alpha: (0.55 + flakeR / 12) * fade)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GentleSnowfallPainter old) =>
      old.t != t || old.brightness != brightness;
}
