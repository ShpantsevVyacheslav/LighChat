import 'dart:async';

import 'package:flutter/material.dart';

import '../data/location_scroll_diagnostics.dart';

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
    // Bug #16: формат теперь Xч Yм / Yм / mm:ss, поэтому пересчёт раз
    // в секунду нужен только когда осталось < 1 мин. Иначе раз в
    // 15 секунд — отдельный wakeup на каждый ватчер не нужен.
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final exp = DateTime.tryParse(widget.expiresAtIso);
      if (exp != null) {
        final left = exp.difference(DateTime.now());
        if (left.inMinutes >= 1 && DateTime.now().second % 15 != 0) {
          return;
        }
      }
      LocationScrollDiag.tickCountdown();
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
    if (left.isNegative) return '0м';
    // Bug #16: было «688:00» — глаз ломается. Человеческий формат:
    //   >= 1ч → «11ч 28м» (или «11h 28m» — выбираем по локали через
    //     отдельную короткую буквенную систему; в чате это компактная
    //     капсула, числа важнее текста, поэтому без числовых единиц
    //     «h/ч» становится непонятным символом).
    //   >= 1м → «28м».
    //   < 1м → «0:42» (mm:ss, как Apple на финальных секундах).
    final totalSec = left.inSeconds;
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    final s = totalSec % 60;
    if (h >= 1) {
      // ignore: unnecessary_brace_in_string_interps
      return '${h}ч ${m}м';
    }
    if (m >= 1) {
      // ignore: unnecessary_brace_in_string_interps
      return '${m}м';
    }
    return '0:${s.toString().padLeft(2, '0')}';
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
