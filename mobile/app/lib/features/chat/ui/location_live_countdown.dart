import 'dart:async';

import 'package:flutter/material.dart';

/// Компактный обратный отсчёт до `expiresAt` (ISO).
class LocationLiveCountdown extends StatefulWidget {
  const LocationLiveCountdown({
    super.key,
    required this.expiresAtIso,
    this.compact = true,
  });

  final String expiresAtIso;
  final bool compact;

  @override
  State<LocationLiveCountdown> createState() => _LocationLiveCountdownState();
}

class _LocationLiveCountdownState extends State<LocationLiveCountdown> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _scheduleTick();
  }

  @override
  void didUpdateWidget(covariant LocationLiveCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiresAtIso != widget.expiresAtIso) {
      _t?.cancel();
      _scheduleTick();
    }
  }

  void _scheduleTick() {
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  String _label() {
    final exp = DateTime.tryParse(widget.expiresAtIso);
    if (exp == null) return '—';
    final left = exp.difference(DateTime.now());
    if (left.isNegative) return '0:00';
    final m = left.inMinutes;
    final s = left.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.black.withValues(alpha: 0.52),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: widget.compact ? 8 : 10,
          vertical: widget.compact ? 4 : 6,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.schedule_rounded,
              size: widget.compact ? 14 : 16,
              color: Colors.white.withValues(alpha: 0.92),
            ),
            const SizedBox(width: 4),
            Text(
              _label(),
              style: TextStyle(
                fontSize: widget.compact ? 11 : 13,
                fontWeight: FontWeight.w800,
                color: Colors.white.withValues(alpha: 0.95),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
