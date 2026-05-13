import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lighchat_mobile/brand_colors.dart';
import 'package:lighchat_mobile/l10n/app_localizations.dart';

import 'confetti_overlay.dart';

/// Интерактивная модалка «задуй свечу и загадай желание». Возвращает
/// текст желания (или `null` если пользователь закрыл). Само сообщение
/// собирает вызывающий экран — мы лишь даём UX «торта» и текст.
class BirthdayCakeSheet extends StatefulWidget {
  const BirthdayCakeSheet({super.key, required this.contactName});

  final String contactName;

  static Future<String?> show(
    BuildContext context, {
    required String contactName,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => BirthdayCakeSheet(contactName: contactName),
    );
  }

  @override
  State<BirthdayCakeSheet> createState() => _BirthdayCakeSheetState();
}

class _BirthdayCakeSheetState extends State<BirthdayCakeSheet>
    with TickerProviderStateMixin {
  bool _blown = false;
  late final AnimationController _flameCtrl;
  late final AnimationController _smokeCtrl;
  final TextEditingController _wish = TextEditingController();

  @override
  void initState() {
    super.initState();
    _flameCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _smokeCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _flameCtrl.dispose();
    _smokeCtrl.dispose();
    _wish.dispose();
    super.dispose();
  }

  Future<void> _blowOut() async {
    if (_blown) return;
    HapticFeedback.mediumImpact();
    _flameCtrl.stop();
    _smokeCtrl.forward(from: 0);
    setState(() => _blown = true);
  }

  void _submit() {
    final wish = _wish.text.trim();
    Navigator.of(context).pop<String?>(wish.isEmpty ? null : wish);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: kBrandOrange.withValues(alpha: 0.3)),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: scheme.onSurface.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Stack(
              alignment: Alignment.center,
              children: [
                if (_blown)
                  const SizedBox(
                    height: 200,
                    child: ConfettiOverlay(
                      particleCount: 36,
                      loop: false,
                      intensity: 1.2,
                      duration: Duration(seconds: 2),
                    ),
                  ),
                SizedBox(
                  height: 200,
                  child: GestureDetector(
                    onTap: _blowOut,
                    child: _CakeDrawing(
                      flameCtrl: _flameCtrl,
                      smokeCtrl: _smokeCtrl,
                      blown: _blown,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _blown
                  ? l10n.birthday_cake_wish_placeholder(widget.contactName)
                  : l10n.birthday_cake_prompt,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            if (_blown) ...[
              TextField(
                controller: _wish,
                maxLines: 3,
                minLines: 2,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: l10n.birthday_cake_wish_hint,
                  filled: true,
                  fillColor:
                      scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: kBrandOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _submit,
                  child: Text(l10n.birthday_cake_send),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CakeDrawing extends StatelessWidget {
  const _CakeDrawing({
    required this.flameCtrl,
    required this.smokeCtrl,
    required this.blown,
  });

  final AnimationController flameCtrl;
  final AnimationController smokeCtrl;
  final bool blown;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([flameCtrl, smokeCtrl]),
      builder: (context, _) => CustomPaint(
        painter: _CakePainter(
          flamePhase: flameCtrl.value,
          smokePhase: smokeCtrl.value,
          blown: blown,
        ),
        size: const Size.fromHeight(200),
      ),
    );
  }
}

class _CakePainter extends CustomPainter {
  _CakePainter({
    required this.flamePhase,
    required this.smokePhase,
    required this.blown,
  });

  final double flamePhase;
  final double smokePhase;
  final bool blown;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // Тарелка.
    final plate = Paint()..color = const Color(0xFFE5E7EB);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, h - 12), width: w * 0.7, height: 14),
      plate,
    );

    // Нижний ярус.
    final baseRect = Rect.fromCenter(
      center: Offset(cx, h - 50),
      width: w * 0.55,
      height: 70,
    );
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF9D7A8), Color(0xFFE3A663)],
      ).createShader(baseRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(baseRect, const Radius.circular(10)),
      basePaint,
    );

    // Глазурь на нижнем ярусе.
    final icing = Paint()..color = const Color(0xFFFEEDC9);
    final path = Path()
      ..moveTo(baseRect.left + 6, baseRect.top + 6)
      ..lineTo(baseRect.left + 6, baseRect.top - 4);
    for (var x = baseRect.left + 6.0; x < baseRect.right - 6; x += 14) {
      path.relativeQuadraticBezierTo(7, 14, 14, 0);
    }
    path.lineTo(baseRect.right - 6, baseRect.top + 6);
    path.close();
    canvas.drawPath(path, icing);

    // Верхний ярус.
    final topRect = Rect.fromCenter(
      center: Offset(cx, h - 100),
      width: w * 0.38,
      height: 38,
    );
    final topPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF5C8DA), Color(0xFFE48BB1)],
      ).createShader(topRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(topRect, const Radius.circular(8)),
      topPaint,
    );

    // Свеча.
    final candleRect = Rect.fromCenter(
      center: Offset(cx, h - 134),
      width: 6,
      height: 32,
    );
    final candlePaint = Paint()..color = const Color(0xFF9CCBE9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(candleRect, const Radius.circular(2)),
      candlePaint,
    );

    final wickStart = Offset(cx, h - 150);
    canvas.drawLine(
      wickStart,
      Offset(cx, h - 156),
      Paint()
        ..color = const Color(0xFF333333)
        ..strokeWidth = 1.4,
    );

    if (!blown) {
      // Пламя — два эллипса с лёгкой пульсацией.
      final flameAmp = 1 + math.sin(flamePhase * math.pi * 2) * 0.08;
      final outerRect = Rect.fromCenter(
        center: Offset(cx, h - 162),
        width: 10 * flameAmp,
        height: 16 * flameAmp,
      );
      final innerRect = Rect.fromCenter(
        center: Offset(cx, h - 160),
        width: 5 * flameAmp,
        height: 10 * flameAmp,
      );
      canvas.drawOval(
        outerRect,
        Paint()..color = const Color(0xFFFFB347),
      );
      canvas.drawOval(
        innerRect,
        Paint()..color = const Color(0xFFFFE066),
      );
    } else {
      // Дымок.
      final t = smokePhase;
      final smoke = Paint()
        ..color = const Color(0xFFB0B0B0)
            .withValues(alpha: (0.6 * (1 - t)).clamp(0, 1));
      for (var i = 0; i < 3; i++) {
        final dy = -20 - i * 14 - t * 30;
        final dx = math.sin((t + i * 0.3) * math.pi * 2) * 6;
        canvas.drawCircle(
          Offset(cx + dx, h - 156 + dy),
          4 + i * 1.5,
          smoke,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CakePainter old) =>
      old.flamePhase != flamePhase ||
      old.smokePhase != smokePhase ||
      old.blown != blown;
}
