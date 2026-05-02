import 'package:flutter/material.dart';

import 'durak_card_widget.dart';

/// Flies a face-down card from the deck position to the player's hand area.
///
/// Both [from] and [to] are global rectangles. The widget is intended to be
/// inserted as a [Positioned.fill] overlay over the table area; coordinates
/// are translated into the local frame via [overlayTopLeft].
class DurakDrawFlight extends StatefulWidget {
  const DurakDrawFlight({
    super.key,
    required this.from,
    required this.to,
    required this.overlayTopLeft,
    required this.delay,
    required this.onDone,
  });

  final Rect from;
  final Rect to;
  final Offset overlayTopLeft;
  final Duration delay;
  final VoidCallback onDone;

  @override
  State<DurakDrawFlight> createState() => _DurakDrawFlightState();
}

class _DurakDrawFlightState extends State<DurakDrawFlight>
    with SingleTickerProviderStateMixin {
  static const _flightDuration = Duration(milliseconds: 460);

  late final AnimationController _c;
  late final Animation<double> _t;
  bool _doneInvoked = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: _flightDuration);
    _t = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _c.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_doneInvoked) {
        _doneInvoked = true;
        widget.onDone();
      }
    });
    Future<void>.delayed(widget.delay, () {
      if (!mounted) return;
      _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, _) {
        final v = _t.value.clamp(0.0, 1.0);
        final fromCenter = widget.from.center - widget.overlayTopLeft;
        final toCenter = widget.to.center - widget.overlayTopLeft;
        if (!fromCenter.dx.isFinite ||
            !fromCenter.dy.isFinite ||
            !toCenter.dx.isFinite ||
            !toCenter.dy.isFinite) {
          return const SizedBox.shrink();
        }
        final cx = fromCenter.dx + (toCenter.dx - fromCenter.dx) * v;
        final cy = fromCenter.dy + (toCenter.dy - fromCenter.dy) * v;
        // gentle arc — peak in the middle
        final arc = -28.0 * (1 - (2 * v - 1).abs());
        // shrink a bit while flying
        final scale = 1.0 - 0.12 * v;
        const w = 56.0;
        const h = 80.0;
        return Positioned(
          left: cx - w / 2,
          top: cy - h / 2 + arc,
          width: w,
          height: h,
          child: IgnorePointer(
            ignoring: true,
            child: Opacity(
              opacity: v < 0.05 ? v / 0.05 : (v > 0.92 ? (1 - v) / 0.08 : 1.0),
              child: Transform.scale(
                scale: scale,
                child: Transform.rotate(
                  angle: -0.12 + 0.18 * v,
                  child: const DurakCardWidget(
                    rankLabel: '',
                    suitLabel: '',
                    isRed: false,
                    faceUp: false,
                    disabled: true,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
