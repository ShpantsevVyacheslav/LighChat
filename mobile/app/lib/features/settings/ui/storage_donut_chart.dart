import 'dart:math';

import 'package:flutter/material.dart';

class DonutSegment {
  const DonutSegment({
    required this.value,
    required this.color,
    required this.label,
  });

  final double value;
  final Color color;
  final String label;
}

const kStorageVideoColor = Color(0xFFFF9800);
const kStoragePhotoColor = Color(0xFF42A5F5);
const kStorageFileColor = Color(0xFF66BB6A);
const kStorageOtherColor = Color(0xFF78909C);

class StorageDonutChart extends StatelessWidget {
  const StorageDonutChart({
    super.key,
    required this.segments,
    required this.centerText,
    this.centerSubtext,
    this.size = 200,
    this.strokeFraction = 0.22,
  });

  final List<DonutSegment> segments;
  final String centerText;
  final String? centerSubtext;
  final double size;
  final double strokeFraction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DonutChartPainter(
              segments: segments,
              strokeFraction: strokeFraction,
              gapDegrees: 2.0,
              emptyColor: dark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerText,
                style: TextStyle(
                  fontSize: size * 0.13,
                  fontWeight: FontWeight.w800,
                  color: dark ? Colors.white : scheme.onSurface,
                  height: 1.1,
                ),
              ),
              if (centerSubtext != null) ...[
                const SizedBox(height: 2),
                Text(
                  centerSubtext!,
                  style: TextStyle(
                    fontSize: size * 0.065,
                    fontWeight: FontWeight.w500,
                    color: dark
                        ? Colors.white.withValues(alpha: 0.55)
                        : scheme.onSurface.withValues(alpha: 0.50),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  _DonutChartPainter({
    required this.segments,
    required this.strokeFraction,
    required this.gapDegrees,
    required this.emptyColor,
  });

  final List<DonutSegment> segments;
  final double strokeFraction;
  final double gapDegrees;
  final Color emptyColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = min(size.width, size.height) / 2;
    final innerRadius = outerRadius * (1 - strokeFraction);

    final total = segments.fold<double>(0, (s, seg) => s + seg.value);
    if (total <= 0) {
      _drawRing(canvas, center, outerRadius, innerRadius, emptyColor);
      return;
    }

    final activeSegments = segments.where((s) => s.value > 0).toList();
    if (activeSegments.length == 1) {
      _drawRing(canvas, center, outerRadius, innerRadius,
          activeSegments.first.color);
      _drawPercentLabel(canvas, center, outerRadius, innerRadius,
          -pi / 2 + pi, '100%');
      return;
    }

    final gapRad = gapDegrees * pi / 180;
    final totalGap = gapRad * activeSegments.length;
    final available = 2 * pi - totalGap;

    double startAngle = -pi / 2;
    for (final seg in activeSegments) {
      final fraction = seg.value / total;
      final sweepAngle = available * fraction;
      _drawArc(canvas, center, outerRadius, innerRadius, startAngle,
          sweepAngle, seg.color);

      if (fraction >= 0.05) {
        final pct = '${(fraction * 100).toStringAsFixed(fraction >= 0.1 ? 0 : 1)}%';
        _drawPercentLabel(canvas, center, outerRadius, innerRadius,
            startAngle + sweepAngle / 2, pct);
      }
      startAngle += sweepAngle + gapRad;
    }
  }

  void _drawRing(
      Canvas canvas, Offset center, double outer, double inner, Color color) {
    final path = Path()
      ..addOval(Rect.fromCircle(center: center, radius: outer))
      ..addOval(Rect.fromCircle(center: center, radius: inner));
    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawArc(Canvas canvas, Offset center, double outer, double inner,
      double startAngle, double sweepAngle, Color color) {
    final outerRect = Rect.fromCircle(center: center, radius: outer);
    final innerRect = Rect.fromCircle(center: center, radius: inner);

    final path = Path()
      ..arcTo(outerRect, startAngle, sweepAngle, true)
      ..arcTo(innerRect, startAngle + sweepAngle, -sweepAngle, false)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawPercentLabel(Canvas canvas, Offset center, double outer,
      double inner, double angle, String text) {
    final midRadius = (outer + inner) / 2;
    final pos = Offset(
      center.dx + midRadius * cos(angle),
      center.dy + midRadius * sin(angle),
    );
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: (outer - inner) * 0.36,
          fontWeight: FontWeight.w700,
          shadows: const [Shadow(blurRadius: 4, color: Colors.black54)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_DonutChartPainter old) =>
      segments != old.segments || strokeFraction != old.strokeFraction;
}

class StorageCategoryRow extends StatelessWidget {
  const StorageCategoryRow({
    super.key,
    required this.color,
    required this.label,
    required this.sizeText,
    required this.percent,
    this.selected = true,
    this.onSelectedChanged,
  });

  final Color color;
  final String label;
  final String sizeText;
  final String percent;
  final bool selected;
  final ValueChanged<bool>? onSelectedChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          if (onSelectedChanged != null) ...[
            SizedBox(
              width: 28,
              height: 28,
              child: Checkbox(
                value: selected,
                onChanged: (v) => onSelectedChanged?.call(v ?? false),
                shape: const CircleBorder(),
                activeColor: color,
                side: BorderSide(color: color, width: 2),
              ),
            ),
            const SizedBox(width: 8),
          ] else ...[
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: dark
                    ? Colors.white.withValues(alpha: 0.92)
                    : scheme.onSurface.withValues(alpha: 0.90),
              ),
            ),
          ),
          Text(
            percent,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: dark
                  ? Colors.white.withValues(alpha: 0.55)
                  : scheme.onSurface.withValues(alpha: 0.50),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            sizeText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: dark
                  ? Colors.white.withValues(alpha: 0.78)
                  : scheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}
