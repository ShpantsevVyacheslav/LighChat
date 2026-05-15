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
