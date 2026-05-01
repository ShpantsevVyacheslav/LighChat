import 'package:flutter/material.dart';

class DurakCardWidget extends StatelessWidget {
  const DurakCardWidget({
    super.key,
    required this.rankLabel,
    required this.suitLabel,
    required this.isRed,
    required this.faceUp,
    this.selected = false,
    this.highlight = false,
    this.disabled = false,
    this.width = 68,
    this.height = 96,
    this.onTap,
  });

  final String rankLabel;
  final String suitLabel;
  final bool isRed;
  final bool faceUp;
  final bool selected;
  final bool highlight;
  final bool disabled;
  final double width;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final base = faceUp ? const Color(0xFFF6F7FB) : const Color(0xFF1D2B4A);
    final border = selected
        ? const Color(0xFF2E86FF)
        : (highlight
              ? const Color(0xFF6EE7B7)
              : Colors.black.withValues(alpha: 0.15));

    final effectiveBg = base;
    final fg = isRed ? const Color(0xFFDC2626) : const Color(0xFF111827);
    final textColor = faceUp ? fg : Colors.white.withValues(alpha: 0.92);

    final shadowAlpha = disabled ? 0.05 : (selected ? 0.22 : 0.14);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: disabled ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: effectiveBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: border.withValues(alpha: disabled ? 0.35 : 0.95),
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: shadowAlpha),
                blurRadius: selected ? 12 : 8,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: faceUp
              ? _Face(
                  rankLabel: rankLabel,
                  suitLabel: suitLabel,
                  color: textColor,
                  scale: width.isFinite && width > 0 ? width / 68 : 1,
                )
              : _Back(disabled: disabled),
        ),
      ),
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({
    required this.rankLabel,
    required this.suitLabel,
    required this.color,
    required this.scale,
  });

  final String rankLabel;
  final String suitLabel;
  final Color color;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Text(
              '$rankLabel$suitLabel',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: color,
                fontSize: 16 * scale.clamp(0.72, 1.0).toDouble(),
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Text(
              suitLabel,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: color.withValues(alpha: 0.92),
                fontSize: 32 * scale.clamp(0.72, 1.0).toDouble(),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: RotatedBox(
              quarterTurns: 2,
              child: Text(
                '$rankLabel$suitLabel',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: color,
                  fontSize: 16 * scale.clamp(0.72, 1.0).toDouble(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Back extends StatelessWidget {
  const _Back({required this.disabled});

  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final line = const Color(
      0xFF7CB69A,
    ).withValues(alpha: disabled ? 0.28 : 0.50);
    final base = const Color(
      0xFFE9F5EF,
    ).withValues(alpha: disabled ? 0.72 : 1.0);
    return Padding(
      padding: const EdgeInsets.all(8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: base,
          backgroundBlendMode: BlendMode.multiply,
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: disabled ? 0.35 : 0.65),
              const Color(0xFFCDE7D8).withValues(alpha: disabled ? 0.35 : 0.75),
            ],
          ),
        ),
        child: CustomPaint(
          painter: _BackPatternPainter(line),
          child: Center(
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: disabled ? 0.22 : 0.46),
                border: Border.all(color: line.withValues(alpha: 0.7)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackPatternPainter extends CustomPainter {
  const _BackPatternPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2;
    for (double x = -size.height; x < size.width; x += 8) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(x + 4, size.height),
        Offset(x + size.height + 4, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BackPatternPainter oldDelegate) =>
      oldDelegate.color != color;
}
