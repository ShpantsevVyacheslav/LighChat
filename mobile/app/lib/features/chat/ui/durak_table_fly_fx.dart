import 'dart:math';

import 'package:flutter/material.dart';

class DurakTableFlyFx extends StatefulWidget {
  const DurakTableFlyFx({
    super.key,
    required this.kind,
    required this.cardCount,
    required this.onDone,
  });

  final String kind; // "beat" | "take" | "penalty"
  final int cardCount;
  final VoidCallback onDone;

  @override
  State<DurakTableFlyFx> createState() => _DurakTableFlyFxState();
}

class _DurakTableFlyFxState extends State<DurakTableFlyFx>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _anim;
  late final List<_FlyCard> _cards;
  bool _doneInvoked = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _anim = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    final n = widget.cardCount.clamp(1, 12);
    final r = Random();
    _cards = List.generate(n, (i) {
      final dx = (r.nextDouble() - 0.5) * 40;
      final dy = (r.nextDouble() - 0.5) * 26;
      final rot = (r.nextDouble() - 0.5) * 0.25;
      return _FlyCard(offset: Offset(dx, dy), rotation: rot);
    });

    _c.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_doneInvoked) {
        _doneInvoked = true;
        widget.onDone();
      }
    });
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final anim = _anim;

    Alignment endAlignment() {
      switch (widget.kind) {
        case 'take':
          return const Alignment(0.0, 1.15); // towards hand
        case 'penalty':
          return const Alignment(-0.9, 1.10); // towards cheater side-ish
        case 'beat':
        default:
          return const Alignment(0.95, -1.05); // towards discard/top-right
      }
    }

    final end = endAlignment();

    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) {
        final raw = anim.value;
        if (!raw.isFinite) return const SizedBox.shrink();
        final t = raw.clamp(0.0, 1.0).toDouble();
        if (t >= 1.0) return const SizedBox.shrink();
        double ld(double a, double b) => a + (b - a) * t;
        final alignment = Alignment.lerp(Alignment.center, end, t);
        if (alignment == null ||
            !alignment.x.isFinite ||
            !alignment.y.isFinite) {
          return const SizedBox.shrink();
        }
        return IgnorePointer(
          ignoring: true,
          child: Stack(
            children: [
              for (final c in _cards)
                Builder(builder: (_) {
                  final off = Offset.lerp(c.offset, Offset.zero, t);
                  final angle = ld(c.rotation, 0.0);
                  if (off == null ||
                      !off.dx.isFinite ||
                      !off.dy.isFinite ||
                      !angle.isFinite) {
                    return const SizedBox.shrink();
                  }
                  return Align(
                    alignment: alignment,
                    child: Transform.translate(
                      offset: off,
                      child: Transform.rotate(
                        angle: angle,
                        child: Opacity(
                          opacity: (1.0 - t).clamp(0.0, 1.0),
                          child: _CardBack(scale: 1.0 - t * 0.12),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class _FlyCard {
  const _FlyCard({required this.offset, required this.rotation});

  final Offset offset;
  final double rotation;
}

class _CardBack extends StatelessWidget {
  const _CardBack({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale.clamp(0.75, 1.0);
    return Transform.scale(
      scale: s,
      child: Container(
        width: 56,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF1D2B4A).withValues(alpha: 0.92),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 14,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'LC',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ),
      ),
    );
  }
}
