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
    this.onTap,
  });

  final String rankLabel;
  final String suitLabel;
  final bool isRed;
  final bool faceUp;
  final bool selected;
  final bool highlight;
  final bool disabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final base = faceUp ? const Color(0xFFF6F7FB) : const Color(0xFF1D2B4A);
    final border = selected
        ? const Color(0xFF2E86FF)
        : (highlight ? const Color(0xFF6EE7B7) : Colors.black.withValues(alpha: 0.15));

    final effectiveBg = disabled ? base.withValues(alpha: 0.55) : base;
    final fg = isRed ? const Color(0xFFDC2626) : const Color(0xFF111827);
    final textColor = faceUp ? fg : Colors.white.withValues(alpha: 0.92);

    final scale = selected ? 1.06 : 1.0;
    final shadowAlpha = disabled ? 0.05 : (selected ? 0.22 : 0.14);

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: disabled ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            width: 56,
            height: 80,
            decoration: BoxDecoration(
              color: effectiveBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border.withValues(alpha: disabled ? 0.35 : 0.95), width: selected ? 2 : 1),
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
                    color: textColor.withValues(alpha: disabled ? 0.50 : 1.0),
                  )
                : _Back(
                    disabled: disabled,
                  ),
          ),
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
  });

  final String rankLabel;
  final String suitLabel;
  final Color color;

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
                fontSize: 14,
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
                fontSize: 26,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Transform.rotate(
              angle: 3.14159,
              child: Text(
                '$rankLabel$suitLabel',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: color,
                  fontSize: 14,
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
    final c1 = const Color(0xFF355CFF).withValues(alpha: disabled ? 0.45 : 0.70);
    final c2 = const Color(0xFF22C55E).withValues(alpha: disabled ? 0.30 : 0.45);
    return Padding(
      padding: const EdgeInsets.all(8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c1, c2],
          ),
        ),
        child: Center(
          child: Text(
            'LC',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: Colors.white.withValues(alpha: disabled ? 0.55 : 0.90),
            ),
          ),
        ),
      ),
    );
  }
}

