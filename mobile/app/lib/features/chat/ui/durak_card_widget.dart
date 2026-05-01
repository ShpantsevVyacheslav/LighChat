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
    return Padding(
      padding: const EdgeInsets.all(6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2C3E66).withValues(alpha: disabled ? 0.85 : 1.0),
              const Color(0xFF1A2540).withValues(alpha: disabled ? 0.85 : 1.0),
            ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: disabled ? 0.10 : 0.18),
            width: 1,
          ),
        ),
        child: Center(
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.32),
                width: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
