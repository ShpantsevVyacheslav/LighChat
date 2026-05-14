import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../brand_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../welcome/ui/welcome_painters.dart';

/// Карточка-пустышка для чата без сообщений: маяк на фоне, краб, хранитель
/// с лицом, машущий рукой, и кнопка быстрого приветствия.
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
      duration: const Duration(milliseconds: 1600),
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
    // Solid (а не полупрозрачный) фон, который не сливается с обоями чата.
    final cardColor = dark
        ? const Color(0xFF182338)
        : Colors.white;
    final cardBorder = dark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);
    final textColor = dark ? Colors.white : scheme.onSurface;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Material(
            color: cardColor,
            elevation: 0,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              decoration: BoxDecoration(
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
                  const SizedBox(height: 12),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final t = _controller.value;
                      // Махание рукой 0.30..0.95 (тот же диапазон, что в
                      // welcome — но цикл, без полного завершения броска).
                      final wave =
                          0.30 + 0.65 * (0.5 + 0.5 * math.sin(t * 2 * math.pi));
                      // Crab claws — лёгкое покачивание клешнями.
                      final crabL = -10 + 12 * math.sin(t * 2 * math.pi);
                      final crabR = 10 - 12 * math.sin(t * 2 * math.pi + 0.5);
                      return SizedBox(
                        width: 220,
                        height: 170,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Маленький маяк фоном (справа за хранителем).
                            Positioned(
                              left: 130,
                              top: 18,
                              width: 70,
                              height: 110,
                              child: Opacity(
                                opacity: 0.55,
                                child: CustomPaint(
                                  painter: const LighthousePainter(),
                                ),
                              ),
                            ),
                            // Луч маяка
                            Positioned(
                              left: 110,
                              top: 36,
                              width: 90,
                              height: 22,
                              child: Opacity(
                                opacity: 0.55,
                                child: CustomPaint(
                                  painter: _StaticBeamPainter(),
                                ),
                              ),
                            ),
                            // Земля под персонажами (тонкая линия)
                            Positioned(
                              left: 14,
                              right: 14,
                              bottom: 8,
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                            // Краб слева внизу
                            Positioned(
                              left: 24,
                              bottom: 12,
                              width: 56,
                              height: 36,
                              child: CustomPaint(
                                painter: CrabPainter(
                                  clawWaveL: crabL,
                                  clawWaveR: crabR,
                                  pupilOffset: const Offset(0.2, 0.0),
                                ),
                              ),
                            ),
                            // Хранитель по центру
                            Positioned(
                              left: 70,
                              top: 6,
                              width: 90,
                              height: 152,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  CustomPaint(
                                    painter: KeeperPainter(throwProgress: wave),
                                  ),
                                  // Лицо поверх головы хранителя
                                  CustomPaint(
                                    painter: const _KeeperFacePainter(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
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
                        icon: const Icon(Icons.waving_hand_outlined, size: 18),
                        label: Text(greetLabel),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Маленький статичный coral-луч из лампы маяка (для фоновой иконки).
class _StaticBeamPainter extends CustomPainter {
  const _StaticBeamPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final shader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [kBrandOrange.withValues(alpha: 0.7), kBrandOrange.withValues(alpha: 0.0)],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final path = Path()
      ..moveTo(0, size.height * 0.30)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height * 0.70)
      ..close();
    canvas.drawPath(path, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _StaticBeamPainter old) => false;
}

/// Глаза, нос и улыбка поверх головы хранителя (которая рисуется в
/// `KeeperPainter`). Координаты согласованы с головой: cx=0.50, cy=0.07,
/// радиус ≈ w*0.08.
class _KeeperFacePainter extends CustomPainter {
  const _KeeperFacePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final eyeWhite = Paint()..color = Colors.white.withValues(alpha: 0.95);
    final eyeDark = Paint()..color = const Color(0xFF0A1626);

    final cy = h * 0.058;
    final eyeR = w * 0.018;
    final pupilR = w * 0.010;

    // Глаза — два маленьких белых кружочка
    canvas.drawCircle(Offset(w * 0.470, cy), eyeR, eyeWhite);
    canvas.drawCircle(Offset(w * 0.530, cy), eyeR, eyeWhite);
    // Зрачки
    canvas.drawCircle(Offset(w * 0.472, cy + 0.002 * h), pupilR, eyeDark);
    canvas.drawCircle(Offset(w * 0.532, cy + 0.002 * h), pupilR, eyeDark);

    // Маленькая улыбка (дуга)
    final smileRect = Rect.fromCenter(
      center: Offset(w * 0.500, h * 0.085),
      width: w * 0.038,
      height: w * 0.026,
    );
    canvas.drawArc(
      smileRect,
      0,
      math.pi,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.4,
    );
  }

  @override
  bool shouldRepaint(covariant _KeeperFacePainter old) => false;
}
