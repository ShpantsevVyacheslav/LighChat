import 'dart:math';

import 'package:flutter/material.dart';

import 'durak_card_widget.dart';

/// Simple flight overlay for "deal/draw" and "hand -> table" moves.
/// Uses card backs (cheap) for draw/deal and face-up when source card is known.
class DurakCardFlightLayer extends StatefulWidget {
  const DurakCardFlightLayer({super.key, required this.child});

  final Widget child;

  static DurakCardFlightController? of(BuildContext context) {
    return context
        .findAncestorStateOfType<_DurakCardFlightLayerState>()
        ?._controller;
  }

  @override
  State<DurakCardFlightLayer> createState() => _DurakCardFlightLayerState();
}

class _DurakCardFlightLayerState extends State<DurakCardFlightLayer> {
  final _flights = <_Flight>[];
  late final DurakCardFlightController _controller =
      DurakCardFlightController._(this);

  Rect? _rectOf(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject();
    if (box is! RenderBox) return null;
    if (!box.attached) return null;
    final p = box.localToGlobal(Offset.zero);
    final size = box.size;
    if (!p.dx.isFinite ||
        !p.dy.isFinite ||
        !size.width.isFinite ||
        !size.height.isFinite ||
        size.width <= 0 ||
        size.height <= 0) {
      return null;
    }
    return p & size;
  }

  void _flyBacks({
    required GlobalKey from,
    required GlobalKey to,
    required int count,
  }) {
    final a = _rectOf(from);
    final b = _rectOf(to);
    if (a == null || b == null) return;
    final n = count.clamp(1, 8);
    final r = Random();
    for (var i = 0; i < n; i++) {
      final spread = n <= 1 ? 0.0 : 14.0;
      final x = (i - (n - 1) / 2.0) * spread + (r.nextDouble() - 0.5) * 10;
      final y = (r.nextDouble() - 0.5) * 6;
      final jitterFrom = Offset(
        (r.nextDouble() - 0.5) * 18,
        (r.nextDouble() - 0.5) * 10,
      );
      final rot0 = (i - (n - 1) / 2.0) * 0.06 + (r.nextDouble() - 0.5) * 0.05;
      _start(
        _Flight(
          from: a.center + jitterFrom,
          to: b.center + Offset(x, y),
          faceUp: false,
          label: null,
          isRed: false,
          popAtEnd: false,
          baseRotation: rot0,
          delayMs: i * 45,
        ),
      );
    }
  }

  void _flyCard({
    required GlobalKey from,
    required GlobalKey to,
    required String rankLabel,
    required String suitLabel,
    required bool isRed,
    bool popAtEnd = true,
  }) {
    final a = _rectOf(from);
    final b = _rectOf(to);
    if (a == null || b == null) return;
    _start(
      _Flight(
        from: a.center,
        to: b.center,
        faceUp: true,
        label: (rankLabel, suitLabel),
        isRed: isRed,
        popAtEnd: popAtEnd,
        baseRotation: 0.0,
        delayMs: 0,
      ),
    );
  }

  void _start(_Flight f) {
    if (!f.from.dx.isFinite ||
        !f.from.dy.isFinite ||
        !f.to.dx.isFinite ||
        !f.to.dy.isFinite ||
        !f.baseRotation.isFinite) {
      return;
    }
    setState(() => _flights.add(f));
  }

  void _finish(_Flight f) {
    if (!mounted) return;
    setState(() => _flights.remove(f));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        ..._flights.map((f) => _FlightWidget(f: f, onDone: () => _finish(f))),
      ],
    );
  }
}

class DurakCardFlightController {
  DurakCardFlightController._(this._s);
  final _DurakCardFlightLayerState _s;

  void flyBacks({
    required GlobalKey from,
    required GlobalKey to,
    required int count,
  }) => _s._flyBacks(from: from, to: to, count: count);

  void flyCard({
    required GlobalKey from,
    required GlobalKey to,
    required String rankLabel,
    required String suitLabel,
    required bool isRed,
    bool popAtEnd = true,
  }) => _s._flyCard(
    from: from,
    to: to,
    rankLabel: rankLabel,
    suitLabel: suitLabel,
    isRed: isRed,
    popAtEnd: popAtEnd,
  );
}

class _Flight {
  const _Flight({
    required this.from,
    required this.to,
    required this.faceUp,
    required this.label,
    required this.isRed,
    required this.popAtEnd,
    required this.baseRotation,
    required this.delayMs,
  });

  final Offset from;
  final Offset to;
  final bool faceUp;
  final (String, String)? label;
  final bool isRed;
  final bool popAtEnd;
  final double baseRotation;
  final int delayMs;
}

class _FlightWidget extends StatefulWidget {
  const _FlightWidget({required this.f, required this.onDone});

  final _Flight f;
  final VoidCallback onDone;

  @override
  State<_FlightWidget> createState() => _FlightWidgetState();
}

class _FlightWidgetState extends State<_FlightWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final AnimationController _pop;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..stop();
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    Future<void>.delayed(Duration(milliseconds: widget.f.delayMs), () {
      if (!mounted) return;
      _c.forward(from: 0);
    });
    if (widget.f.popAtEnd) {
      Future<void>.delayed(Duration(milliseconds: widget.f.delayMs + 320), () {
        if (!mounted) return;
        _pop.forward(from: 0);
      });
    }
    Future<void>.delayed(
      Duration(milliseconds: widget.f.delayMs + 440),
      widget.onDone,
    );
  }

  @override
  void dispose() {
    _c.dispose();
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final anim = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    final popAnim = CurvedAnimation(parent: _pop, curve: Curves.easeOutBack);
    return AnimatedBuilder(
      animation: Listenable.merge([anim, popAnim]),
      builder: (context, _) {
        final t = anim.value;
        if (!t.isFinite) return const SizedBox.shrink();
        final p = Offset.lerp(widget.f.from, widget.f.to, t)!;
        if (!p.dx.isFinite || !p.dy.isFinite) return const SizedBox.shrink();
        final rot = widget.f.baseRotation + (1.0 - t) * 0.08;
        if (!rot.isFinite) return const SizedBox.shrink();
        final popT = widget.f.popAtEnd ? popAnim.value : 0.0;
        return Positioned(
          left: p.dx - 34,
          top: p.dy - 48,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (popT > 0.001)
                Positioned(
                  left: 0,
                  top: 0,
                  child: Opacity(
                    opacity: (1.0 - popT).clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 1.0 + popT * 0.25,
                      child: Container(
                        width: 68,
                        height: 96,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(
                              0xFFFFC107,
                            ).withValues(alpha: 0.55),
                            width: 2,
                          ),
                          color: const Color(
                            0xFFFFC107,
                          ).withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                  ),
                ),
              Transform.rotate(
                angle: rot,
                child: Opacity(
                  opacity: (1.0 - (t * 0.35)).clamp(0.0, 1.0),
                  child: DurakCardWidget(
                    rankLabel: widget.f.label?.$1 ?? '',
                    suitLabel: widget.f.label?.$2 ?? '',
                    isRed: widget.f.isRed,
                    faceUp: widget.f.faceUp,
                    disabled: true,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
