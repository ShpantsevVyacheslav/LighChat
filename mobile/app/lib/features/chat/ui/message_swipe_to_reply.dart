import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Live "swipe-left to reply" gesture wrapper for a chat message row.
///
/// The wrapped [child] follows the finger while the user drags left:
///   • a fade-in reply icon is revealed on the right side of the row;
///   • when the pull passes [triggerOffset] (or the gesture ends with a
///     sufficiently fast left fling), [onSwipeReply] is invoked;
///   • in every case the child is smoothly animated back to the idle
///     position when the finger is lifted.
///
/// A right-swipe still triggers [onSwipeBack] via velocity (parity with
/// the pre-existing behaviour), but it does NOT animate the child — the
/// gesture is meant for "navigate back", not for a visible pull.
///
/// The widget is intentionally self-contained (one `AnimationController`,
/// no external state) so it can be dropped in per message without
/// coupling to the list's state.
class MessageSwipeToReply extends StatefulWidget {
  const MessageSwipeToReply({
    super.key,
    required this.child,
    required this.enabled,
    this.onSwipeReply,
    this.onSwipeBack,
    this.maxPull = 96,
    this.triggerOffset = 64,
    this.flingVelocity = 280,
    this.iconColor,
    this.iconBackgroundColor,
  });

  /// The row content (bubble + paddings) being wrapped.
  final Widget child;

  /// When `false`, the widget behaves as a transparent passthrough.
  /// Used for deleted rows / selection mode.
  final bool enabled;

  /// Fired once per gesture when the pull crosses [triggerOffset]
  /// (or when the drag ends with a fast left fling).
  final VoidCallback? onSwipeReply;

  /// Fired on a fast right fling (gesture-end only, not animated).
  final VoidCallback? onSwipeBack;

  /// Hard cap on the visible pull (positive px, to the left).
  final double maxPull;

  /// Distance at which the reply action becomes armed (haptic + full icon).
  final double triggerOffset;

  /// Velocity (px/s) above which a flick triggers the action even if
  /// the visible pull hasn't reached [triggerOffset].
  final double flingVelocity;

  final Color? iconColor;
  final Color? iconBackgroundColor;

  @override
  State<MessageSwipeToReply> createState() => _MessageSwipeToReplyState();
}

class _MessageSwipeToReplyState extends State<MessageSwipeToReply>
    with SingleTickerProviderStateMixin {
  /// Current visible offset. Negative = pulled to the left.
  double _dx = 0;

  /// Set to `true` once the current drag has crossed [triggerOffset]
  /// so we only fire haptics once per gesture.
  bool _armed = false;

  late final AnimationController _returnCtrl;
  Animation<double>? _returnAnim;

  @override
  void initState() {
    super.initState();
    _returnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(_onReturnTick);
  }

  @override
  void dispose() {
    _returnCtrl.removeListener(_onReturnTick);
    _returnCtrl.dispose();
    super.dispose();
  }

  void _onReturnTick() {
    final anim = _returnAnim;
    if (anim == null) return;
    setState(() => _dx = anim.value);
  }

  void _animateBackToZero() {
    if (_dx == 0) {
      _armed = false;
      return;
    }
    _returnCtrl.stop();
    _returnAnim = Tween<double>(begin: _dx, end: 0).animate(
      CurvedAnimation(parent: _returnCtrl, curve: Curves.easeOutCubic),
    );
    _returnCtrl.forward(from: 0);
    _armed = false;
  }

  void _onDragStart(DragStartDetails _) {
    _returnCtrl.stop();
    _returnAnim = null;
    _armed = _dx <= -widget.triggerOffset;
  }

  void _onDragUpdate(DragUpdateDetails d) {
    var next = _dx + d.delta.dx;
    // Hard cap on the left; allow a tiny amount to the right so an
    // accidental right drift before a left swipe doesn't feel locked.
    if (next > 0) next = 0;
    if (next < -widget.maxPull) next = -widget.maxPull;
    if (next == _dx) return;

    final wasArmed = _armed;
    final nowArmed = next <= -widget.triggerOffset;
    if (nowArmed && !wasArmed) {
      // Light confirmation at the arming threshold.
      HapticFeedback.selectionClick();
    }
    setState(() {
      _dx = next;
      _armed = nowArmed;
    });
  }

  void _onDragEnd(DragEndDetails d) {
    final vx = d.primaryVelocity ?? 0;
    final shouldReply =
        _armed || (vx <= -widget.flingVelocity && _dx < 0);
    final shouldBack = vx >= widget.flingVelocity && _dx == 0;

    if (shouldReply) {
      HapticFeedback.mediumImpact();
      widget.onSwipeReply?.call();
    } else if (shouldBack) {
      widget.onSwipeBack?.call();
    }
    _animateBackToZero();
  }

  void _onDragCancel() {
    _animateBackToZero();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    final progress = (-_dx / widget.triggerOffset).clamp(0.0, 1.0);
    final scheme = Theme.of(context).colorScheme;
    final iconColor = widget.iconColor ?? scheme.primary;
    final bgColor = widget.iconBackgroundColor ??
        scheme.primary.withValues(alpha: 0.10);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      onHorizontalDragCancel: _onDragCancel,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerRight,
        children: [
          // Reply icon revealed on the right as the child slides left.
          // The icon scales & fades in with the pull progress so it
          // naturally feels like it emerges from under the bubble edge.
          if (_dx < 0)
            Positioned(
              right: 12 + (-_dx * 0.35),
              top: 0,
              bottom: 0,
              child: Center(
                child: Opacity(
                  opacity: progress,
                  child: Transform.scale(
                    scale: 0.6 + 0.4 * progress,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: bgColor,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.reply_rounded,
                        size: 22,
                        color: iconColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Transform.translate(
            offset: Offset(_dx, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
