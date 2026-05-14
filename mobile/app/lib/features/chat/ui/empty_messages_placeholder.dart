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
  static const double _h = 130;

  @override
  Widget build(BuildContext context) {
    final wavePhase = math.sin(t * 2 * math.pi);
    // Махание рукой капитана: -10°..+45° по синусу
    final keeperWave = 18 + 28 * wavePhase;
    // Клешни краба
    final crabL = -12 + 10 * math.sin(t * 2 * math.pi + 0.4);
    final crabR = 12 - 10 * math.sin(t * 2 * math.pi + 0.9);
    // Beam intensity — лёгкая пульсация
    final beamI = 0.65 + 0.20 * (0.5 + 0.5 * math.sin(t * 2 * math.pi * 0.6));
    // Цвет силуэтов — должен контрастировать с frosted-glass фоном.
    final silhouette = isDark
        ? const Color(0xFFD6E0EE) // чуть тёплый светло-серый-голубой
        : const Color(0xFF1E3A5F);
    final silhouetteAccent = isDark
        ? const Color(0xFFA9B8CC)
        : const Color(0xFF2C4A70);

    return SizedBox(
      width: _w,
      height: _h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ───── звёзды (фон) ─────
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
              painter: _IslandPainter(color: silhouetteAccent),
            ),
          ),
          // ───── маяк ─────
          // По центру островка. Лампа маяка приходится на верх башни →
          // beam стартует именно оттуда.
          const Positioned(
            left: 102,
            top: 8,
            width: 56,
            height: 100,
            child: CustomPaint(painter: LighthousePainter()),
          ),
          // ───── coral beam из лампы маяка ─────
          // В LighthousePainter лампа = верх башни, y~0.40 от высоты,
          // x = центр (0.50). Для нашего бокса 56×100 это (28, 40),
          // плюс смещение Positioned(102, 8) → (130, 48) в координатах сцены.
          Positioned(
            left: 130,
            top: 38,
            width: 100,
            height: 24,
            child: IgnorePointer(
              child: CustomPaint(
                painter: _BeamPainter(intensity: beamI),
              ),
            ),
          ),
          // ───── капитан-хранитель ─────
          Positioned(
            left: 38,
            bottom: 12,
            width: 56,
            height: 92,
            child: CustomPaint(
              painter: _CaptainPainter(
                bodyColor: silhouette,
                accentColor: silhouetteAccent,
                waveDeg: keeperWave,
              ),
            ),
          ),
          // ───── краб ─────
          Positioned(
            left: 170,
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

/// Компактный «капитан» — голова в фуражке с coral околышем, торс,
/// одна рука вниз (статичная), вторая поднята и махает (угол управляется
/// `waveDeg`).
class _CaptainPainter extends CustomPainter {
  const _CaptainPainter({
    required this.bodyColor,
    required this.accentColor,
    required this.waveDeg,
  });
  final Color bodyColor;
  final Color accentColor;
  final double waveDeg;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final fill = Paint()..color = bodyColor;
    final accent = Paint()..color = accentColor;

    // ── Торс — закруглённая трапеция-капля ──
    final torso = Path()
      ..moveTo(w * 0.30, h * 0.46)
      ..quadraticBezierTo(w * 0.50, h * 0.40, w * 0.70, h * 0.46)
      ..lineTo(w * 0.78, h * 0.90)
      ..quadraticBezierTo(w * 0.50, h * 0.96, w * 0.22, h * 0.90)
      ..close();
    canvas.drawPath(torso, fill);

    // ── Воротник (тёмный accent) ──
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.36, h * 0.46)
        ..lineTo(w * 0.50, h * 0.56)
        ..lineTo(w * 0.64, h * 0.46)
        ..close(),
      accent,
    );

    // ── Coral шарф/галстук ──
    final scarfRect = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.58),
      width: w * 0.10,
      height: h * 0.10,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(scarfRect, const Radius.circular(2)),
      Paint()..color = kBrandOrange,
    );

    // ── Левая рука (статичная, вниз) ──
    canvas.drawLine(
      Offset(w * 0.30, h * 0.50),
      Offset(w * 0.22, h * 0.78),
      Paint()
        ..color = bodyColor
        ..strokeWidth = w * 0.10
        ..strokeCap = StrokeCap.round,
    );

    // ── Правая рука (машет) ──
    canvas.save();
    final shoulder = Offset(w * 0.70, h * 0.50);
    canvas.translate(shoulder.dx, shoulder.dy);
    canvas.rotate(-waveDeg * math.pi / 180);
    canvas.drawLine(
      Offset.zero,
      Offset(0, h * 0.28),
      Paint()
        ..color = bodyColor
        ..strokeWidth = w * 0.10
        ..strokeCap = StrokeCap.round,
    );
    // Маленькая «ладошка»
    canvas.drawCircle(Offset(0, h * 0.30), w * 0.07, fill);
    canvas.restore();

    // ── Голова (круг) ──
    final headCenter = Offset(w * 0.50, h * 0.28);
    canvas.drawCircle(headCenter, h * 0.13, fill);

    // ── Лицо: глаза + улыбка ──
    final faceColor = accentColor;
    canvas.drawCircle(
      Offset(w * 0.43, h * 0.27),
      h * 0.018,
      Paint()..color = faceColor,
    );
    canvas.drawCircle(
      Offset(w * 0.57, h * 0.27),
      h * 0.018,
      Paint()..color = faceColor,
    );
    final smileRect = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.33),
      width: w * 0.18,
      height: h * 0.05,
    );
    canvas.drawArc(
      smileRect,
      0.2,
      math.pi - 0.4,
      false,
      Paint()
        ..color = faceColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.3,
    );

    // ── Капитанская фуражка: околыш + поля + макушка + кокарда ──
    // Поля
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.16),
        width: w * 0.40,
        height: h * 0.045,
      ),
      fill,
    );
    // Coral околыш
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.14),
        width: w * 0.30,
        height: h * 0.035,
      ),
      Paint()..color = kBrandOrange,
    );
    // Макушка
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.50, h * 0.08),
          width: w * 0.30,
          height: h * 0.10,
        ),
        const Radius.circular(3),
      ),
      fill,
    );
    // Кокарда — маленький coral круг
    canvas.drawCircle(
      Offset(w * 0.50, h * 0.07),
      h * 0.022,
      Paint()..color = kBrandOrange,
    );
  }

  @override
  bool shouldRepaint(covariant _CaptainPainter old) =>
      old.waveDeg != waveDeg ||
      old.bodyColor != bodyColor ||
      old.accentColor != accentColor;
}
