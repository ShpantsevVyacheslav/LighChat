import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../brand_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../welcome/ui/welcome_painters.dart';

/// Карточка-пустышка для чата без сообщений в стиле welcome-анимации:
/// маяк на скалистом острове бросает coral-луч в сторону, рядом
/// капитан-хранитель машет рукой, у его ног краб поводит клешнёй.
/// Под сценой — кнопка «Поздороваться 👋».
class EmptyMessagesPlaceholder extends StatefulWidget {
  const EmptyMessagesPlaceholder({super.key, this.onQuickGreet});

  /// Колбэк при тапе по кнопке «Привет». Если null — кнопка скрыта.
  final VoidCallback? onQuickGreet;

  @override
  State<EmptyMessagesPlaceholder> createState() =>
      _EmptyMessagesPlaceholderState();
}

class _EmptyMessagesPlaceholderState extends State<EmptyMessagesPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = l10n?.chat_empty_title ?? 'Сообщений пока нет';
    final subtitle = l10n?.chat_empty_subtitle ?? 'Напишите первое сообщение';
    final greetLabel = l10n?.chat_empty_quick_greet ?? 'Поздороваться 👋';

    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    // Frosted glass поверх обоев чата.
    final tintColor = dark
        ? Colors.black.withValues(alpha: 0.42)
        : Colors.white.withValues(alpha: 0.62);
    final cardBorder = dark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final textColor = dark ? Colors.white : scheme.onSurface;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                decoration: BoxDecoration(
                  color: tintColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: cardBorder, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.7),
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 14),
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) => _Scene(
                        t: _controller.value,
                        isDark: dark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (widget.onQuickGreet != null)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: widget.onQuickGreet,
                          style: FilledButton.styleFrom(
                            backgroundColor: kBrandOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          icon: const Icon(
                            Icons.waving_hand_outlined,
                            size: 18,
                          ),
                          label: Text(greetLabel),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Мини-сцена «маяк + хранитель + краб + звёзды».
class _Scene extends StatelessWidget {
  const _Scene({required this.t, required this.isDark});

  final double t; // 0..1 (repeat-controller)
  final bool isDark;

  static const double _w = 240;
  static const double _h = 140;

  @override
  Widget build(BuildContext context) {
    // Махание рукой хранителя — 0.30..0.95 (как в welcome), цикл по
    // синусу, без полного броска: рука то поднимается вверх, то
    // опускается обратно.
    final wave = 0.30 + 0.65 * (0.5 + 0.5 * math.sin(t * 2 * math.pi));
    final crabL = -12 + 10 * math.sin(t * 2 * math.pi + 0.4);
    final crabR = 12 - 10 * math.sin(t * 2 * math.pi + 0.9);
    final beamI = 0.65 + 0.20 * (0.5 + 0.5 * math.sin(t * 2 * math.pi * 0.6));
    // Пальто хранителя — насыщенный морской teal: контрастирует и с
    // тёмным frosted-glass, и с синими/светлыми обоями, не уходит ни в
    // белый, ни в чёрный, и хорошо сочетается с coral-шарфом.
    final coatBody = isDark
        ? const Color(0xFF2C5F6E)
        : const Color(0xFF1E3A5F);
    final coatAccent = isDark
        ? const Color(0xFF1A454F)
        : const Color(0xFF0F2438);
    // Островок — отдельный тёмно-синевато-серый, чтобы хранитель и грунт
    // не сливались в один силуэт.
    final islandColor = isDark
        ? const Color(0xFF34465B)
        : const Color(0xFF6B7A8E);
    // Лицо рисуется контрастным к телу: светлый face на тёмном пальто.
    final faceColor = isDark
        ? const Color(0xFFE6EDF7)
        : const Color(0xFFEDF2F8);

    return SizedBox(
      width: _w,
      height: _h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ───── звёзды ─────
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _StarsBgPainter(t: t, isDark: isDark),
              ),
            ),
          ),
          // ───── островок ─────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 26,
            child: CustomPaint(
              painter: _IslandPainter(color: islandColor),
            ),
          ),
          // ───── маяк (по центру островка) ─────
          // Маяк больше хранителя — верхушка купола над фуражкой.
          const Positioned(
            left: 100,
            top: 0,
            width: 64,
            height: 116,
            child: CustomPaint(painter: LighthousePainter()),
          ),
          // ───── coral beam из лампы маяка ─────
          // Лампа = верх башни (y ≈ 0.40h). В боксе 64×116 + Positioned(100,0)
          // абсолютная точка лампы ≈ (132, 46).
          Positioned(
            left: 132,
            top: 36,
            width: 96,
            height: 24,
            child: IgnorePointer(
              child: CustomPaint(painter: _BeamPainter(intensity: beamI)),
            ),
          ),
          // ───── хранитель маяка ─────
          // Использует KeeperPainter из welcome (длинное пальто, шарф,
          // шляпа, фонарь в одной руке, машет другой) + лицо поверх
          // головы. Высота специально меньше маяка, чтобы шляпа
          // приходилась ниже фонарной комнаты.
          Positioned(
            left: 30,
            bottom: 14,
            width: 60,
            height: 96,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: KeeperPainter(
                      throwProgress: wave,
                      bodyColor: coatBody,
                      accentColor: coatAccent,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _KeeperFacePainter(strokeColor: faceColor),
                  ),
                ),
              ],
            ),
          ),
          // ───── краб ─────
          Positioned(
            left: 174,
            bottom: 6,
            width: 48,
            height: 30,
            child: CustomPaint(
              painter: CrabPainter(
                clawWaveL: crabL,
                clawWaveR: crabR,
                pupilOffset: const Offset(-0.6, 0.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Лицо хранителя — рисуется поверх головы KeeperPainter в тех же
/// координатах (cx ≈ 0.50, cy ≈ 0.07, r ≈ 0.08). Глаза и улыбка цвета
/// `strokeColor`, чтобы читались на любом фоне силуэта.
class _KeeperFacePainter extends CustomPainter {
  const _KeeperFacePainter({required this.strokeColor});
  final Color strokeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Центр головы из KeeperPainter
    final headCx = w * 0.50;
    final headCy = h * 0.07;
    final headR = w * 0.08;

    final eyePaint = Paint()..color = strokeColor;
    final eyeR = headR * 0.20;
    canvas.drawCircle(Offset(headCx - headR * 0.42, headCy - 0.06 * headR), eyeR, eyePaint);
    canvas.drawCircle(Offset(headCx + headR * 0.42, headCy - 0.06 * headR), eyeR, eyePaint);

    // Улыбка — маленькая дуга
    final smileRect = Rect.fromCenter(
      center: Offset(headCx, headCy + headR * 0.30),
      width: headR * 0.85,
      height: headR * 0.55,
    );
    canvas.drawArc(
      smileRect,
      0.25,
      math.pi - 0.5,
      false,
      Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _KeeperFacePainter old) =>
      old.strokeColor != strokeColor;
}

// ────────────────────────────────────────────────────────────────────────────
// Painters
// ────────────────────────────────────────────────────────────────────────────

/// Островок-полукруг под маяком.
class _IslandPainter extends CustomPainter {
  const _IslandPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.65)
      ..quadraticBezierTo(
        size.width * 0.20,
        size.height * 0.15,
        size.width * 0.50,
        size.height * 0.15,
      )
      ..quadraticBezierTo(
        size.width * 0.80,
        size.height * 0.15,
        size.width,
        size.height * 0.65,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    // Тонкая линия «прибоя»
    canvas.drawLine(
      Offset(0, size.height * 0.65),
      Offset(size.width, size.height * 0.65),
      Paint()
        ..color = color.withValues(alpha: 0.35)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _IslandPainter old) => old.color != color;
}

/// Coral-луч из лампы маяка: трапеция-конус с gradient fade и лёгкой
/// внутренней «полосой».
class _BeamPainter extends CustomPainter {
  const _BeamPainter({required this.intensity});
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0.01) return;
    final w = size.width;
    final h = size.height;
    final shader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        kBrandOrange.withValues(alpha: 0.8 * intensity),
        kBrandOrange.withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromLTWH(0, 0, w, h));
    // Конус: узкий слева у лампы, расширяется вправо.
    final path = Path()
      ..moveTo(0, h * 0.35)
      ..lineTo(0, h * 0.65)
      ..lineTo(w, h)
      ..lineTo(w, 0)
      ..close();
    canvas.drawPath(path, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _BeamPainter old) =>
      old.intensity != intensity;
}

/// Звёздное небо: 5 мерцающих точек в верхней половине сцены.
class _StarsBgPainter extends CustomPainter {
  const _StarsBgPainter({required this.t, required this.isDark});
  final double t;
  final bool isDark;

  static final _seeds = <List<double>>[
    [0.10, 0.18, 1.1, 0.2],
    [0.28, 0.08, 1.4, 1.1],
    [0.48, 0.22, 1.0, 2.0],
    [0.70, 0.10, 1.3, 3.0],
    [0.88, 0.26, 1.1, 4.1],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final base = isDark ? Colors.white : const Color(0xFF1E3A5F);
    for (final s in _seeds) {
      final dx = s[0] * size.width;
      final dy = s[1] * size.height;
      final r = s[2];
      final phase = s[3];
      final blink = 0.45 +
          0.35 * (0.5 + 0.5 * math.sin(t * 2 * math.pi + phase));
      canvas.drawCircle(
        Offset(dx, dy),
        r,
        Paint()..color = base.withValues(alpha: blink),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarsBgPainter old) => old.t != t;
}

